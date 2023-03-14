# provider aws
provider "aws" { 
    region = "us-east-1"
}

resource "aws_instance" "lib4instance" {
    ami = "ami-005f9685cb30f234b"
    instance_type = "t1.micro"

    # name the instance using tag
    tags = {
        Name = "lib4instance"
    }
}