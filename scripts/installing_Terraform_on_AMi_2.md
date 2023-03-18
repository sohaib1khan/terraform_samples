Had bit of issues installing terraform on AMI, put a script together to solve that 

Problem with: 

```
NAME="Amazon Linux"
VERSION="2"
ID="amzn"
ID_LIKE="centos rhel fedora"
VERSION_ID="2"
PRETTY_NAME="Amazon Linux 2"
ANSI_COLOR="0;33"
CPE_NAME="cpe:2.3:o:amazon:amazon_linux:2"
HOME_URL="https://amazonlinux.com/"
```

Script:

```
#!/bin/bash

# Update package repositories
sudo yum update -y

# Install Terraform
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

You can save this script to a file, for example `install-terraform.sh`, make it executable with `chmod +x install-terraform.sh`, and then run it with `./install-terraform.sh`.