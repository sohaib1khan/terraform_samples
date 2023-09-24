#!/bin/bash

# Create Dockerfile
cat <<EOF > Dockerfile
# Use the official Ubuntu image as a parent image
FROM ubuntu:latest

# Set non-interactive frontend to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary tools like wget, unzip, and bash-completion
RUN apt-get update && apt-get install -y wget unzip bash-completion

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    vim \
    less \
    ssh \
    && rm -rf /var/lib/apt/lists/*

# Download the Terraform binary
WORKDIR /tmp
RUN wget https://releases.hashicorp.com/terraform/1.1.2/terraform_1.1.2_linux_amd64.zip

# Unzip and install the Terraform binary
RUN unzip terraform_1.1.2_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_1.1.2_linux_amd64.zip

# Enable tab completion
RUN terraform -install-autocomplete

# Set the entrypoint to Bash so that the user can use Terraform right away
CMD ["tail", "-f", "/dev/null"]
# Check if SSH keys exist and generate them if they don't
RUN if [ ! -f /root/.ssh/id_rsa ]; then \
        ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ""; \
    fi


EOF

# Create docker-compose.yml
cat <<EOF > docker-compose.yml
version: '3'

services:
  tf-service:
    build:
      context: .
      dockerfile: Dockerfile
    image: terraform_container
    container_name: terraform_container
    volumes:
      - ./:/home
    working_dir: /home
EOF

echo "Dockerfile and docker-compose.yml have been created in the current directory."

sleep 10s

echo "Going to launch terraform container"

docker compose up -d

# Check if the last command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to launch the terraform container."
    exit 1
fi

echo "You will now be execing into the container."

docker exec -it terraform_container /bin/bash

# Check if the exec command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to exec into the terraform container."
    exit 1
fi

