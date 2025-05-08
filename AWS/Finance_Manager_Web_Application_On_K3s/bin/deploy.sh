#!/bin/bash
# deploy.sh - Script to deploy the Finance Manager application on K3s

# Set script to exit immediately if a command exits with a non-zero status
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Display banner
echo -e "${YELLOW}=======================================================${NC}"
echo -e "${YELLOW}    Finance Manager Web Application Deployment Tool    ${NC}"
echo -e "${YELLOW}=======================================================${NC}"

# Get the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root directory (parent of bin)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Change to project root
cd "$PROJECT_ROOT"

# Source AWS login script if exists
if [ -f "./aws-login.sh" ]; then
    echo -e "${YELLOW}Sourcing AWS login script...${NC}"
    source ./aws-login.sh
else
    echo -e "${YELLOW}Warning: aws-login.sh not found. Make sure you're authenticated with AWS.${NC}"
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
for cmd in terraform ansible-playbook aws; do
    if ! command_exists "$cmd"; then
        echo -e "${RED}Error: $cmd is not installed. Please install it before proceeding.${NC}"
        exit 1
    fi
done

# Set variables
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
KEY_NAME="finance-app-key"

# Ensure required directories exist
echo -e "${YELLOW}Checking if required directories exist...${NC}"
mkdir -p "$ANSIBLE_DIR/files"
mkdir -p "$ANSIBLE_DIR/playbooks"
mkdir -p "$ANSIBLE_DIR/inventory"
mkdir -p "$TERRAFORM_DIR/templates"
mkdir -p "$PROJECT_ROOT/bin"

# Create Kubernetes YAML files
# Create the deployment manifest if it doesn't exist
if [ ! -f "$ANSIBLE_DIR/files/finance-app-deployment.yml" ]; then
    echo -e "${YELLOW}Creating deployment manifest...${NC}"
    cat > "$ANSIBLE_DIR/files/finance-app-deployment.yml" << 'EOL'
---
# Deployment manifest for the Finance Manager application
apiVersion: apps/v1
kind: Deployment
metadata:
  name: finance-app
  labels:
    app: finance-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: finance-app
  template:
    metadata:
      labels:
        app: finance-app
    spec:
      containers:
      - name: finance-app
        image: skhan1010/finance-manager-app:v1
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
EOL
fi

# Create the service manifest if it doesn't exist
if [ ! -f "$ANSIBLE_DIR/files/finance-app-service.yml" ]; then
    echo -e "${YELLOW}Creating service manifest...${NC}"
    cat > "$ANSIBLE_DIR/files/finance-app-service.yml" << 'EOL'
---
# Service manifest for the Finance Manager application
apiVersion: v1
kind: Service
metadata:
  name: finance-app
  labels:
    app: finance-app
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30001
    protocol: TCP
    name: http
  selector:
    app: finance-app
EOL
fi

# Create Ansible playbooks if they don't exist
# Create main.yml
if [ ! -f "$ANSIBLE_DIR/playbooks/main.yml" ]; then
    echo -e "${YELLOW}Creating main playbook...${NC}"
    cat > "$ANSIBLE_DIR/playbooks/main.yml" << 'EOL'
---
# Main playbook for deploying K3s and Finance Manager application

- name: Deploy K3s and Finance Manager Application
  hosts: k3s_server
  become: true
  gather_facts: true

  tasks:
    # Check if system is ready
    - name: Check system connectivity
      ping:

    # Update system packages using shell commands to avoid module issues
    - name: Update system packages
      shell: |
        if command -v dnf &>/dev/null; then
          dnf update -y
        elif command -v yum &>/dev/null; then
          yum update -y
        else
          echo "No package manager found"
          exit 1
        fi
      args:
        executable: /bin/bash
      register: pkg_update
      changed_when: "'No packages marked for update' not in pkg_update.stdout"

    # Install required packages
    - name: Install required packages
      shell: |
        if command -v dnf &>/dev/null; then
          dnf install -y curl git python3-pip unzip jq
        elif command -v yum &>/dev/null; then
          yum install -y curl git python3-pip unzip jq
        else
          echo "No package manager found"
          exit 1
        fi
      args:
        executable: /bin/bash
      register: pkg_install
      changed_when: "'Nothing to do' not in pkg_install.stdout"

    # Include K3s installation tasks
    - name: Include K3s installation tasks
      include_tasks: install_k3s.yml

    # Wait for K3s to be ready before deploying applications
    - name: Wait for K3s to be ready
      wait_for:
        path: /etc/rancher/k3s/k3s.yaml
        state: present
        timeout: 300
      register: k3s_config

    # Set up kubectl configuration for the current user
    - name: Create .kube directory
      file:
        path: /home/ec2-user/.kube
        state: directory
        owner: ec2-user
        group: ec2-user
        mode: '0700'

    - name: Copy K3s config to user's .kube directory
      copy:
        src: /etc/rancher/k3s/k3s.yaml
        dest: /home/ec2-user/.kube/config
        remote_src: yes
        owner: ec2-user
        group: ec2-user
        mode: '0600'

    # Include application deployment tasks
    - name: Include application deployment tasks
      include_tasks: deploy_app.yml
EOL
fi

# Create install_k3s.yml
if [ ! -f "$ANSIBLE_DIR/playbooks/install_k3s.yml" ]; then
    echo -e "${YELLOW}Creating K3s installation playbook...${NC}"
    cat > "$ANSIBLE_DIR/playbooks/install_k3s.yml" << 'EOL'
---
# Playbook for installing K3s on the EC2 instance

# Check if K3s is already installed
- name: Check if K3s is already installed
  stat:
    path: /usr/local/bin/k3s
  register: k3s_binary

# Set up K3s if not already installed
- name: Download K3s installation script
  get_url:
    url: https://get.k3s.io
    dest: /tmp/k3s-install.sh
    mode: '0755'
  when: not k3s_binary.stat.exists

# Install K3s server
- name: Install K3s server
  shell: |
    INSTALL_K3S_SKIP_DOWNLOAD=false INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh /tmp/k3s-install.sh
  args:
    creates: /usr/local/bin/k3s
  register: k3s_server_install
  when: not k3s_binary.stat.exists

# Get K3s token (for adding worker nodes later if needed)
- name: Get K3s token
  slurp:
    src: /var/lib/rancher/k3s/server/node-token
  register: node_token
  when: k3s_server_install is changed

# Display K3s token (useful if you want to add worker nodes later)
- name: Display K3s token
  debug:
    msg: "K3s token: {{ node_token['content'] | b64decode }}"
  when: node_token is defined

# Wait for K3s to start
- name: Wait for K3s to start
  systemd:
    name: k3s
    state: started
    enabled: yes

# Verify that K3s is running
- name: Verify K3s is running
  command: systemctl status k3s
  register: k3s_status
  changed_when: false

# Display K3s status
- name: Display K3s status
  debug:
    msg: "{{ k3s_status.stdout_lines }}"
EOL
fi

# Create deploy_app.yml
if [ ! -f "$ANSIBLE_DIR/playbooks/deploy_app.yml" ]; then
    echo -e "${YELLOW}Creating application deployment playbook...${NC}"
    cat > "$ANSIBLE_DIR/playbooks/deploy_app.yml" << 'EOL'
---
# Playbook for deploying the Finance Manager application to K3s

# Create a directory for Kubernetes manifests
- name: Create directory for Kubernetes manifests
  file:
    path: /home/ec2-user/finance-app
    state: directory
    owner: ec2-user
    group: ec2-user
    mode: '0755'

# Copy the deployment manifest to the server
- name: Copy deployment manifest
  copy:
    src: ../files/finance-app-deployment.yml
    dest: /home/ec2-user/finance-app/finance-app-deployment.yml
    owner: ec2-user
    group: ec2-user
    mode: '0644'

# Copy the service manifest to the server
- name: Copy service manifest
  copy:
    src: ../files/finance-app-service.yml
    dest: /home/ec2-user/finance-app/finance-app-service.yml
    owner: ec2-user
    group: ec2-user
    mode: '0644'

# Ensure kubectl is available
- name: Create symlink to k3s kubectl
  file:
    src: /usr/local/bin/k3s
    dest: /usr/local/bin/kubectl
    state: link
  ignore_errors: yes

# Apply the Kubernetes manifests to deploy the application
- name: Apply the deployment manifest
  become: false  # Run as ec2-user, not root
  command: kubectl apply -f /home/ec2-user/finance-app/finance-app-deployment.yml
  register: deploy_result
  environment:
    KUBECONFIG: /etc/rancher/k3s/k3s.yaml

# Display deployment result
- name: Display deployment result
  debug:
    msg: "{{ deploy_result.stdout_lines }}"

# Apply the service manifest
- name: Apply the service manifest
  become: false  # Run as ec2-user, not root
  command: kubectl apply -f /home/ec2-user/finance-app/finance-app-service.yml
  register: service_result
  environment:
    KUBECONFIG: /etc/rancher/k3s/k3s.yaml

# Display service result
- name: Display service result
  debug:
    msg: "{{ service_result.stdout_lines }}"

# Wait for the deployment to be ready
- name: Wait for deployment to be ready
  become: false  # Run as ec2-user, not root
  shell: kubectl rollout status deployment/finance-app --timeout=300s
  register: rollout_status
  changed_when: false
  environment:
    KUBECONFIG: /etc/rancher/k3s/k3s.yaml

# Display rollout status
- name: Display rollout status
  debug:
    msg: "{{ rollout_status.stdout_lines }}"

# Get the NodePort information for the application
- name: Get service information
  become: false  # Run as ec2-user, not root
  shell: kubectl get svc finance-app -o jsonpath='{.spec.ports[0].nodePort}'
  register: node_port
  changed_when: false
  environment:
    KUBECONFIG: /etc/rancher/k3s/k3s.yaml

# Display NodePort information
- name: Display NodePort information
  debug:
    msg: "Finance Manager app is accessible at http://{{ ansible_host }}:{{ node_port.stdout }}"
EOL
fi

# SSH Key Management
echo -e "${YELLOW}Setting up SSH key for AWS...${NC}"

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
echo -e "${YELLOW}Checking if key pair ${KEY_NAME} exists in AWS...${NC}"
if ! aws ec2 describe-key-pairs --key-names ${KEY_NAME} &>/dev/null; then
    echo -e "${YELLOW}Importing SSH key to AWS...${NC}"
    aws ec2 import-key-pair --key-name ${KEY_NAME} --public-key-material fileb://${SSH_KEY_PATH}.pub
fi

# Update variables.tf with the correct key name
VARIABLES_FILE="$TERRAFORM_DIR/variables.tf"
if [ -f "$VARIABLES_FILE" ]; then
    echo -e "${YELLOW}Updating key_name in variables.tf...${NC}"
    CURRENT_KEY_NAME=$(grep -o 'default\s*=\s*"[^"]*"' "$VARIABLES_FILE" | grep key_name | sed 's/default\s*=\s*"\([^"]*\)"/\1/')
    
    if [ "$CURRENT_KEY_NAME" != "$KEY_NAME" ]; then
        echo -e "${YELLOW}Changing key_name from $CURRENT_KEY_NAME to $KEY_NAME in variables.tf${NC}"
        sed -i "s/default\s*=\s*\"$CURRENT_KEY_NAME\"/default     = \"$KEY_NAME\"/" "$VARIABLES_FILE"
    fi
fi

# Create the templates directory and inventory template if they don't exist
mkdir -p "$TERRAFORM_DIR/templates"
if [ ! -f "$TERRAFORM_DIR/templates/inventory.tmpl" ]; then
    echo -e "${YELLOW}Creating inventory template...${NC}"
    cat > "$TERRAFORM_DIR/templates/inventory.tmpl" << EOL
# Ansible inventory generated by Terraform
# This file is auto-generated and should not be edited manually

[k3s_server]
\${public_ip} ansible_host=\${public_ip} private_ip=\${private_ip}

[k3s_server:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=${SSH_KEY_PATH}
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOL
fi

# Step 1: Terraform initialization and deployment
echo -e "${YELLOW}Step 1: Initializing and deploying infrastructure with Terraform...${NC}"
cd "$TERRAFORM_DIR"

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

# Plan Terraform deployment
echo -e "${YELLOW}Planning Terraform deployment...${NC}"
terraform plan -var="key_name=${KEY_NAME}" -out=tfplan

# Ask for confirmation
read -p "Do you want to apply the Terraform plan? (y/n): " confirm
if [[ $confirm != [Yy]* ]]; then
    echo -e "${YELLOW}Deployment aborted by user.${NC}"
    exit 0
fi

# Apply Terraform plan
echo -e "${YELLOW}Applying Terraform plan...${NC}"
terraform apply tfplan

# Get the EC2 public IP
EC2_PUBLIC_IP=$(terraform output -raw ec2_public_ip)
echo -e "${GREEN}EC2 instance deployed with public IP: $EC2_PUBLIC_IP${NC}"

# Go back to project root
cd "$PROJECT_ROOT"

# Wait for SSH to be available
echo -e "${YELLOW}Waiting for SSH to be available on the EC2 instance...${NC}"
MAX_RETRIES=30
COUNT=0
echo -n "Waiting for SSH connectivity"
while ! ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=5 -i "${SSH_KEY_PATH}" ec2-user@${EC2_PUBLIC_IP} echo "SSH connection successful" 2>/dev/null
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

# Step 2: Run Ansible playbook
echo -e "${YELLOW}Step 2: Configuring K3s and deploying the application with Ansible...${NC}"
cd "$ANSIBLE_DIR"

# Create a specific inventory file with absolute SSH key path
echo -e "${YELLOW}Creating Ansible inventory file...${NC}"
mkdir -p "$ANSIBLE_DIR/inventory"
cat > "$ANSIBLE_DIR/inventory/hosts.ini" << EOL
[k3s_server]
$EC2_PUBLIC_IP ansible_host=$EC2_PUBLIC_IP

[k3s_server:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=${SSH_KEY_PATH}
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOL

# Update ansible.cfg file
echo -e "${YELLOW}Creating ansible.cfg file...${NC}"
cat > "$ANSIBLE_DIR/ansible.cfg" << EOL
[defaults]
host_key_checking = False
inventory = inventory/hosts.ini
remote_user = ec2-user
private_key_file = ${SSH_KEY_PATH}
timeout = 30
interpreter_python = auto_silent
deprecation_warnings = False

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
EOL

# Debugging: Show the contents of the inventory file
echo -e "${YELLOW}Inventory file contents:${NC}"
cat "$ANSIBLE_DIR/inventory/hosts.ini"

# Debugging: Show the SSH key file
echo -e "${YELLOW}SSH key path: ${SSH_KEY_PATH}${NC}"
if [ -f "${SSH_KEY_PATH}" ]; then
    echo -e "${GREEN}SSH key file exists${NC}"
    ls -la "${SSH_KEY_PATH}"
else
    echo -e "${RED}SSH key file does not exist!${NC}"
fi

# Run Ansible playbooks with explicit key path
echo -e "${YELLOW}Installing K3s and deploying application with Ansible...${NC}"
ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no" ansible-playbook -i inventory/hosts.ini playbooks/main.yml --private-key="${SSH_KEY_PATH}" -v

# Go back to project root
cd "$PROJECT_ROOT"

# Create a bin/kubeconfig file for easy access
echo -e "${YELLOW}Setting up kubeconfig for local access...${NC}"
mkdir -p "$PROJECT_ROOT/bin"
scp -o StrictHostKeyChecking=no -i "${SSH_KEY_PATH}" ec2-user@${EC2_PUBLIC_IP}:/etc/rancher/k3s/k3s.yaml "$PROJECT_ROOT/bin/kubeconfig" || echo -e "${RED}Could not retrieve kubeconfig. You can get it manually later.${NC}"

# If kubeconfig was successfully copied, update it with the correct server address
if [ -f "$PROJECT_ROOT/bin/kubeconfig" ]; then
    sed -i "s/127.0.0.1/${EC2_PUBLIC_IP}/g" "$PROJECT_ROOT/bin/kubeconfig"
    chmod 600 "$PROJECT_ROOT/bin/kubeconfig"
fi

# Display application access information
echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}Finance Manager application is accessible at:${NC}"
echo -e "${GREEN}http://$EC2_PUBLIC_IP:30001${NC}"
echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}SSH access: ssh -i ${SSH_KEY_PATH} ec2-user@${EC2_PUBLIC_IP}${NC}"

if [ -f "$PROJECT_ROOT/bin/kubeconfig" ]; then
    echo -e "${YELLOW}To use kubectl with this cluster, run:${NC}"
    echo -e "export KUBECONFIG=$PROJECT_ROOT/bin/kubeconfig"
fi

echo -e "${GREEN}=======================================================${NC}"