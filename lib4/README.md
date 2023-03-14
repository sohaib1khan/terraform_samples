# Terraform aws instance deploy


- `provider`: The `provider` block specifies the provider, in this case `aws`, and the region that resources will be created in. The region is set to `us-east-1`.
- `resource`: The `resource` block defines a new AWS EC2 instance. The `aws_instance` resource type is being used.
- `ami`: The `ami` attribute specifies the Amazon Machine Image (AMI) to use for the instance. In this example, `ami-005f9685cb30f234b` is a free tier Amazon Linux AMI.
- `instance_type`: The `instance_type` attribute specifies the type of EC2 instance to use. In this example, `t1.micro` is the smallest instance type available and is eligible for the AWS Free Tier.
- `tags`: The `tags` attribute specifies metadata to apply to the instance, in this case a `Name` tag with the value `lib4instance`. Tags are useful for organizing resources and searching for them later.

When you apply this Terraform configuration, it will create a new EC2 instance in the specified region with the specified AMI and instance type, and apply the specified tag to the instance.

```
# provider aws
provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "lib4instance" {
    ami           = "ami-005f9685cb30f234b"
    instance_type = "t1.micro"

    # name the instance using tag
    tags = {
        Name = "lib4instance"
    }
}
```