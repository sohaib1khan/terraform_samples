**What are Terraform variables?** Terraform variables are placeholders for values that are used in your Terraform code. Variables allow you to define values that can be reused across your code, making it easier to manage and maintain your infrastructure.

**How are Terraform variables declared?** Variables are declared in a separate `.tf` file or in the same file as your Terraform code using the `variable` block. The `variable` block is used to define the name, type, and default value (if any) of the variable. Here's an example of a variable block:

```
variable "region" {
  type = string
  default = "us-west-2"
}
```

**How are Terraform variables used?** Once you have defined a variable, you can use it in your Terraform code by referencing its name using the `${var.variable_name}` syntax. For example, if you have defined a `region` variable as shown above, you could use it in an AWS resource block like this:

```
resource "aws_instance" "example" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  region = "${var.region}"
}
```

**How can Terraform variables be set?** There are several ways to set the value of a Terraform variable, including:

- - Setting the variable value in a `.tfvars` file and passing it to Terraform using the `-var-file` option.
        - Setting the variable value as an environment variable using the `TF_VAR_` prefix, such as `export TF_VAR_region=us-west-2`.
        - Setting the variable value directly on the command line using the `-var` option, such as `terraform apply -var "region=us-west-2"`.
        - Setting the variable value in the Terraform Cloud or Enterprise UI.

**Why are Terraform variables useful?** Using variables in your Terraform code makes it more flexible and reusable. By defining variables, you can make your code more modular and easier to maintain, and you can customize your infrastructure deployment for different environments or use cases without changing the underlying code.

String Variables: These are the most basic type of variable in Terraform. They represent simple string values and are defined using the "string" type.

```
variable "region" {
  type = string
  default = "us-west-2"
}
```

Number Variables: These are used to represent numeric values and are defined using the "number" type.

```
variable "instance_count" {
  type = number
  default = 2
}
```

Boolean Variables: These are used to represent boolean values (true/false) and are defined using the "bool" type.

```
variable "enable_s3_bucket" {
  type = bool
  default = true
}
```

List Variables: These are used to represent lists of values and are defined using the "list" type. They can contain any type of data.

```
variable "subnets" {
  type = list(string)
  default = ["subnet-123456", "subnet-789012"]
}
```

Map Variables: These are used to represent key-value pairs and are defined using the "map" type.

```
variable "tags" {
  type = map(string)
  default = {
    Name = "my-instance"
    Environment = "dev"
  }
}
```

Object Variables: These are used to represent complex objects with multiple attributes and are defined using the "object" type.

```
variable "instance_details" {
  type = object({
    instance_type = string
    ami_id = string
    key_name = string
  })
  default = {
    instance_type = "t2.micro"
    ami_id = "ami-123456"
    key_name = "my-key"
  }
}
```

Tuple Variables: A tuple is a collection of values of different types. Here's an example of a tuple in Terraform:

```
variable "network" {
  type = tuple(string, number)
  default = ["192.168.0.0/16", 10]
}

resource "aws_vpc" "example" {
  cidr_block = var.network[0]
  instance_tenancy = "default"
  
  tags = {
    Name = "example-vpc"
    Number = var.network[1]
  }
}
```