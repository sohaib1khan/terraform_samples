#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting K3s AWS Deployment...${NC}"

# Source AWS credentials if available
if [ -f "../aws-login.sh" ]; then
    echo -e "${YELLOW}Sourcing AWS credentials...${NC}"
    source ../aws-login.sh
fi

# Determine SSH key location (trying multiple possible locations)
SSH_KEY_PATHS=(
    "/workspace/.ssh/id_rsa"
    "/home/devuser/.ssh/id_rsa"
    "$HOME/.ssh/id_rsa"
)

SSH_KEY_PATH=""
for path in "${SSH_KEY_PATHS[@]}"; do
    if [ -f "$path" ]; then
        SSH_KEY_PATH="$path"
        echo -e "${GREEN}Found SSH key at: $SSH_KEY_PATH${NC}"
        break
    fi
done

# If no existing key found, create one
if [ -z "$SSH_KEY_PATH" ]; then
    echo -e "${YELLOW}No SSH key found. Creating new SSH key...${NC}"
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Generate a new key
    SSH_KEY_PATH="$HOME/.ssh/id_rsa"
    ssh-keygen -t rsa -b 2048 -f "$SSH_KEY_PATH" -N ""
    chmod 600 "$SSH_KEY_PATH"
    echo -e "${GREEN}Created new SSH key at: $SSH_KEY_PATH${NC}"
fi

# Import SSH key to AWS if needed
KEY_NAME="k3s-key"
echo -e "${YELLOW}Checking if key pair ${KEY_NAME} exists in AWS...${NC}"
if ! aws ec2 describe-key-pairs --key-names ${KEY_NAME} &>/dev/null; then
    echo -e "${YELLOW}Importing SSH key to AWS...${NC}"
    aws ec2 import-key-pair --key-name ${KEY_NAME} --public-key-material fileb://${SSH_KEY_PATH}.pub
fi

# Initialize and apply Terraform
cd ../terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

echo -e "${YELLOW}Creating infrastructure with Terraform...${NC}"
terraform apply -var="key_name=${KEY_NAME}" -auto-approve

# Get server IP for Ansible
SERVER_IP=$(terraform output -raw k3s_server_public_ip)

# Create the inventory file for Ansible with SSH key info
echo -e "${YELLOW}Creating Ansible inventory file...${NC}"
echo "[k3s_server]" > ../ansible/inventory.ini
echo "${SERVER_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_PATH}" >> ../ansible/inventory.ini

# Wait for SSH to be available with timeout
echo -e "${YELLOW}Waiting for SSH to be available...${NC}"
MAX_RETRIES=30
COUNT=0
while ! ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=5 -i "${SSH_KEY_PATH}" ubuntu@${SERVER_IP} echo "SSH connection successful" 2>/dev/null
do
    echo -n "."
    sleep 10
    COUNT=$((COUNT+1))
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo -e "\n${RED}Timed out waiting for SSH to become available. Proceeding anyway...${NC}"
        break
    fi
done
echo ""

# Give the system a moment to fully initialize
echo -e "${YELLOW}Waiting for system initialization...${NC}"
sleep 20

# Create an ansible.cfg file with the right SSH key
cat > ../ansible/ansible.cfg << EOL
[defaults]
host_key_checking = False
inventory = inventory.ini
remote_user = ubuntu
private_key_file = ${SSH_KEY_PATH}
timeout = 30
interpreter_python = auto_silent

[ssh_connection]
pipelining = True
EOL

# Run Ansible playbooks with explicit SSH key
cd ../ansible
echo -e "${YELLOW}Installing K3s with Ansible...${NC}"
ANSIBLE_CONFIG=$(pwd)/ansible.cfg ansible-playbook k3s-install.yml -i inventory.ini --private-key=${SSH_KEY_PATH}

echo -e "${YELLOW}Deploying application with Ansible...${NC}"
ANSIBLE_CONFIG=$(pwd)/ansible.cfg ansible-playbook k3s-app-deploy.yml -i inventory.ini --private-key=${SSH_KEY_PATH}

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}K3s server IP: ${SERVER_IP}${NC}"
echo -e "${GREEN}Access the hello-world application at: http://${SERVER_IP}:30080${NC}"
echo -e "${GREEN}SSH access: ssh -i ${SSH_KEY_PATH} ubuntu@${SERVER_IP}${NC}"
echo -e "${GREEN}Kubeconfig has been saved to: $(pwd)/../bin/kubeconfig${NC}"
echo -e "${YELLOW}To use kubectl with this cluster, run:${NC}"
echo -e "export KUBECONFIG=$(pwd)/../bin/kubeconfig"