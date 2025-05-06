#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED}Starting FORCE destroy script for K3s AWS Deployment...${NC}"
echo -e "${YELLOW}This script will attempt to forcibly remove ALL resources${NC}"

# Source AWS credentials if available
if [ -f "../aws-login.sh" ]; then
    echo -e "${YELLOW}Sourcing AWS credentials...${NC}"
    source ../aws-login.sh
fi

# Go to terraform directory
cd ../terraform

# Function to identify AWS resources by tags
get_resources_by_tags() {
    echo -e "${YELLOW}Identifying AWS resources by tags...${NC}"
    
    # Look for instances with our project tag
    INSTANCES=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=K3s-AWS-Deployment" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text)
    
    # Look for security groups with our project tag
    SGS=$(aws ec2 describe-security-groups --filters "Name=tag:Project,Values=K3s-AWS-Deployment" --query "SecurityGroups[*].GroupId" --output text)
    
    # Look for VPCs with our project tag
    VPCS=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=K3s-AWS-Deployment" --query "Vpcs[*].VpcId" --output text)

    # If not found by tag, try to get from tfstate
    if [ -z "$INSTANCES" ]; then
        INSTANCES=$(terraform state show aws_instance.k3s_server 2>/dev/null | grep "id =" | head -1 | awk -F= '{print $2}' | tr -d ' "' || echo "")
    fi
    
    if [ -z "$VPCS" ]; then
        VPCS=$(terraform state show aws_vpc.k3s_vpc 2>/dev/null | grep "id =" | head -1 | awk -F= '{print $2}' | tr -d ' "' || echo "")
    fi
    
    if [ -z "$SGS" ]; then
        SGS=$(terraform state show aws_security_group.k3s_sg 2>/dev/null | grep "id =" | head -1 | awk -F= '{print $2}' | tr -d ' "' || echo "")
    fi

    # Find subnets from VPC if available
    if [ ! -z "$VPCS" ]; then
        for VPC_ID in $VPCS; do
            SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[*].SubnetId" --output text)
            
            # Find internet gateways for this VPC
            IGWS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=${VPC_ID}" --query "InternetGateways[*].InternetGatewayId" --output text)
            
            # Find route tables for this VPC, excluding the main one
            MAIN_RT_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${VPC_ID}" "Name=association.main,Values=true" --query "RouteTables[*].RouteTableId" --output text)
            RTS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${VPC_ID}" --query "RouteTables[?RouteTableId!='${MAIN_RT_ID}'].RouteTableId" --output text)
        done
    fi
    
    echo -e "${GREEN}Found resources:${NC}"
    echo -e "Instances: ${INSTANCES:-None found}"
    echo -e "Security Groups: ${SGS:-None found}"
    echo -e "VPCs: ${VPCS:-None found}"
    echo -e "Subnets: ${SUBNETS:-None found}"
    echo -e "Internet Gateways: ${IGWS:-None found}"
    echo -e "Route Tables: ${RTS:-None found}"
}

# Function to force remove all resources directly with AWS CLI
force_delete_resources() {
    echo -e "${RED}FORCING deletion of ALL identified resources...${NC}"
    
    # 1. First, terminate EC2 instances
    if [ ! -z "$INSTANCES" ]; then
        for INSTANCE in $INSTANCES; do
            echo -e "${YELLOW}Force terminating EC2 instance ${INSTANCE}...${NC}"
            aws ec2 terminate-instances --instance-ids ${INSTANCE} || echo "Instance termination failed or already terminated"
        done
        
        # Wait for all instances to terminate
        echo -e "${YELLOW}Waiting for all instances to terminate...${NC}"
        for INSTANCE in $INSTANCES; do
            echo -e "${YELLOW}Waiting for instance ${INSTANCE} to terminate...${NC}"
            aws ec2 wait instance-terminated --instance-ids ${INSTANCE} || echo "Wait failed, continuing anyway"
        done
    fi
    
    # 2. Delete route table associations and route tables
    if [ ! -z "$RTS" ]; then
        for RT in $RTS; do
            # Get route table associations
            RT_ASSOCS=$(aws ec2 describe-route-tables --route-table-ids ${RT} --query "RouteTables[0].Associations[*].RouteTableAssociationId" --output text)
            
            # Delete route table associations
            for ASSOC in $RT_ASSOCS; do
                echo -e "${YELLOW}Deleting route table association ${ASSOC}...${NC}"
                aws ec2 disassociate-route-table --association-id ${ASSOC} || echo "Disassociation failed or already disassociated"
            done
            
            # Delete route table
            echo -e "${YELLOW}Deleting route table ${RT}...${NC}"
            aws ec2 delete-route-table --route-table-id ${RT} || echo "Route table deletion failed or already deleted"
        done
    fi
    
    # 3. Detach and delete internet gateways
    if [ ! -z "$IGWS" ]; then
        for IGW in $IGWS; do
            # Find attached VPC
            IGW_VPC=$(aws ec2 describe-internet-gateways --internet-gateway-ids ${IGW} --query "InternetGateways[0].Attachments[0].VpcId" --output text)
            
            if [ ! -z "$IGW_VPC" ] && [ "$IGW_VPC" != "None" ] && [ "$IGW_VPC" != "null" ]; then
                echo -e "${YELLOW}Detaching internet gateway ${IGW} from VPC ${IGW_VPC}...${NC}"
                aws ec2 detach-internet-gateway --internet-gateway-id ${IGW} --vpc-id ${IGW_VPC} || echo "Gateway detach failed or already detached"
            fi
            
            echo -e "${YELLOW}Deleting internet gateway ${IGW}...${NC}"
            aws ec2 delete-internet-gateway --internet-gateway-id ${IGW} || echo "Gateway deletion failed or already deleted"
        done
    fi
    
    # 4. Delete subnets
    if [ ! -z "$SUBNETS" ]; then
        for SUBNET in $SUBNETS; do
            echo -e "${YELLOW}Deleting subnet ${SUBNET}...${NC}"
            # Try to delete the subnet multiple times with delays
            for i in {1..5}; do
                aws ec2 delete-subnet --subnet-id ${SUBNET} && break || echo "Attempt $i: Subnet deletion failed, retrying in 20 seconds..."
                sleep 20
            done
        done
    fi
    
    # 5. Delete security groups
    if [ ! -z "$SGS" ]; then
        for SG in $SGS; do
            # Skip the default security group
            if [[ $SG == *"default"* ]]; then
                echo -e "${YELLOW}Skipping default security group ${SG}...${NC}"
                continue
            fi
            
            echo -e "${YELLOW}Deleting security group ${SG}...${NC}"
            # Try to delete the security group multiple times with delays
            for i in {1..5}; do
                aws ec2 delete-security-group --group-id ${SG} && break || echo "Attempt $i: Security group deletion failed, retrying in 20 seconds..."
                sleep 20
            done
        done
    fi
    
    # 6. Finally delete VPCs
    if [ ! -z "$VPCS" ]; then
        for VPC in $VPCS; do
            echo -e "${YELLOW}Deleting VPC ${VPC}...${NC}"
            # Try to delete the VPC multiple times with delays
            for i in {1..5}; do
                aws ec2 delete-vpc --vpc-id ${VPC} && break || echo "Attempt $i: VPC deletion failed, retrying in 20 seconds..."
                sleep 20
            done
        done
    fi
}

# Function to clean up the Terraform state
clean_terraform_state() {
    echo -e "${YELLOW}Cleaning up Terraform state...${NC}"
    
    # First try a normal destroy just to be sure
    terraform destroy -auto-approve || echo "Terraform destroy failed, continuing with state removal"
    
    # Remove resources from state
    if [ ! -z "$INSTANCES" ]; then
        echo -e "${YELLOW}Removing EC2 instance from Terraform state...${NC}"
        terraform state rm aws_instance.k3s_server || echo "Failed to remove instance from state or already removed"
    fi
    
    if [ ! -z "$SUBNETS" ]; then
        echo -e "${YELLOW}Removing subnet from Terraform state...${NC}"
        terraform state rm aws_subnet.k3s_public_subnet || echo "Failed to remove subnet from state or already removed"
    fi
    
    if [ ! -z "$RTS" ]; then
        echo -e "${YELLOW}Removing route table from Terraform state...${NC}"
        terraform state rm aws_route_table.k3s_public_rt || echo "Failed to remove route table from state or already removed"
        terraform state rm aws_route_table_association.k3s_public_rta || echo "Failed to remove route table association from state or already removed"
    fi
    
    if [ ! -z "$IGWS" ]; then
        echo -e "${YELLOW}Removing internet gateway from Terraform state...${NC}"
        terraform state rm aws_internet_gateway.k3s_igw || echo "Failed to remove internet gateway from state or already removed"
    fi
    
    if [ ! -z "$SGS" ]; then
        echo -e "${YELLOW}Removing security group from Terraform state...${NC}"
        terraform state rm aws_security_group.k3s_sg || echo "Failed to remove security group from state or already removed"
    fi
    
    if [ ! -z "$VPCS" ]; then
        echo -e "${YELLOW}Removing VPC from Terraform state...${NC}"
        terraform state rm aws_vpc.k3s_vpc || echo "Failed to remove VPC from state or already removed"
    fi
    
    echo -e "${YELLOW}Removing local file from Terraform state...${NC}"
    terraform state rm local_file.server_info || echo "Failed to remove local file from state or already removed"
    
    echo -e "${YELLOW}Final Terraform destroy attempt (should be a no-op now)...${NC}"
    terraform destroy -auto-approve || echo "Final Terraform destroy failed, but resources should be removed"
    
    # Optionally, remove the state file entirely
    echo -e "${YELLOW}Removing Terraform state files...${NC}"
    rm -f terraform.tfstate* || echo "Failed to remove state files or they don't exist"
}

# Main execution
get_resources_by_tags
force_delete_resources
clean_terraform_state

echo -e "${GREEN}Force destroy completed!${NC}"
echo -e "${YELLOW}Note: If any AWS resources still remain, you will need to manually delete them in the AWS Console.${NC}"
echo -e "${YELLOW}Resources to check in AWS Console:${NC}"
echo -e "1. EC2 Instances"
echo -e "2. VPC → Subnets"
echo -e "3. VPC → Route Tables"
echo -e "4. VPC → Internet Gateways"
echo -e "5. VPC → Security Groups"
echo -e "6. VPC → Your VPCs"