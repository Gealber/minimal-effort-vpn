#! /bin/bash

# exit on first command that fails
set -e

sep="-----------------------------------------------------------------------------------------------------------------------------------------------------"
# First we will need an external static ip address
# You can change the name of the ip address from vpn-address to any other name
echo $sep
echo "Creating external IP ADDRESS"
gcloud compute addresses create vpn-address --region=${REGION}

# We need to store the value of this IP Address created
IP_ADDRESS=$(gcloud compute addresses list | grep "vpn-address" | cut -d ' ' -f3)
LEN=$(echo ${#IP_ADDRESS})
echo "IP_ADDRESS: $IP_ADDRESS"

# Creating copy of old template
template=$(cat vpn-vm.yaml)

# Substitute this IP and zone in deployment manager template
sed -i "s/IP_ADDRESS/$IP_ADDRESS/g" vpn-vm.yaml
sed -i "s/ZONE/${ZONE}/g" vpn-vm.yaml
sed -i "s/PROJECT_ID/${PROJECT_ID}/g" vpn-vm.yaml

# Deploy the deployment )
echo $sep
echo "Creating deployment in deployment-manager"
gcloud deployment-manager deployments create vpn-vm --config vpn-vm.yaml

echo "Sleeping 2 minute on purpose..."
sleep 2m

# Fetch the necessaries configuration files
echo $sep
echo "Exporting default vpnclient configuration"
ssh ${USERNAME}@$IP_ADDRESS 'cd /home/${USERNAME} && sudo ikev2.sh --exportclient vpnclient'

echo $sep
echo "Copying files from remote vm"
scp ${USERNAME}@$IP_ADDRESS:/home/${USERNAME}/* .

# extracting certs from configuration file for Ubuntu
echo $sep
echo "Press enter on import password, or the password specified in the previous logs"
openssl pkcs12 -in vpnclient.p12 -cacerts -nokeys -out ikev2vpnca.cer
openssl pkcs12 -in vpnclient.p12 -clcerts -nokeys -out vpnclient.cer
openssl pkcs12 -in vpnclient.p12 -nocerts -nodes  -out vpnclient.key

echo $sep
echo "Restauring value of old template"
echo $template > vpn-vm.yaml

echo $sep
echo "DONE"
