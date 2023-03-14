provider "aws" {
  region = "us-east-1"
}


resource "aws_vpc" "lib3vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = var.inputname
  }
}



# String
variable "lib3vpc" {
  type        = string
  default     = "lib3vpc"
}

# Integer
variable "sshport" {
  type        = number
  default     = 22
}

# boolean
variable "enabled" {
  default     = true
}

# list
variable "lib3list" {
  type        = list
  default     = ["Value1","Value2" ]
}

# maps
variable "lib3map" {
  type        = map(string)
  default     = {
    key1 = "Value1"
    key2 = "Value2"
  }
}

variable "inputname" {
  type        = string
  description = "set the name of vpc"
}


# output: it goes you the detail of the resource you have created 
output "vpcid" {
  value  = aws_vpc.lib3vpc.id
}
