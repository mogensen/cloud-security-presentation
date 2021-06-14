## creates a
## - a Virtual Private Cloud
## - one public subnet
## - two private subnets
## - one EC2 instance 
## - one MYSQL RDS instance

## Based on:
## - https://amazicworld.com/wp-content/uploads/2019/11/to_post.txt
## - https://amazicworld.com/deploying-a-lamp-stack-with-terraform-databases-webservers/

## declare variables

variable "access_key" { default = "your key here" }
variable "secret_key" { default = "your key here" }
variable "region" { default = "us-east-1" }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "subnet_one_cidr" { default = "10.0.1.0/24" }
variable "subnet_two_cidr" { default = ["10.0.2.0/24", "10.0.3.0/24"] }
variable "route_table_cidr" { default = "0.0.0.0/0" }
variable "host" { default = "aws_instance.my_web_instance.public_dns" }
variable "web_ports" { default = ["22", "80", "443", "3306"] }
variable "db_ports" { default = ["22", "3306"] }
variable "images" {
  type = map
  default = {
    "us-east-1"      = "ami-02e98f78"
    "us-east-2"      = "ami-04328208f4f0cf1fe"
    "us-west-1"      = "ami-0799ad445b5727125"
    "us-west-2"      = "ami-032509850cf9ee54e"
    "ap-south-1"     = "ami-0937dcc711d38ef3f"
    "ap-northeast-2" = "ami-018a9a930060d38aa"
    "ap-southeast-1" = "ami-04677bdaa3c2b6e24"
    "ap-southeast-2" = "ami-0c9d48b5db609ad6e"
    "ap-northeast-1" = "ami-0d7ed3ddb85b521a6"
    "ca-central-1"   = "ami-0de8b8e4bc1f125fe"
    "eu-central-1"   = "ami-0eaec5838478eb0ba"
    "eu-west-1"      = "ami-0fad7378adf284ce0"
    "eu-west-2"      = "ami-0664a710233d7c148"
    "eu-west-3"      = "ami-0854d53ce963f69d8"
    "eu-north-1"     = "ami-6d27a913"
  }
}


## downloads the relevante aws provider

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

## get AZ's details
data "aws_availability_zones" "availability_zones" {}

## create VPC
resource "aws_vpc" "myvpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "myvpc"
  }
}

## create public subnet
resource "aws_subnet" "myvpc_public_subnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.subnet_one_cidr
  availability_zone       = data.aws_availability_zones.availability_zones.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "myvpc_public_subnet"
  }
}


## create private subnet one
resource "aws_subnet" "myvpc_private_subnet_one" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = element(var.subnet_two_cidr, 0)
  availability_zone = data.aws_availability_zones.availability_zones.names[0]
  tags = {
    Name = "myvpc_private_subnet_one"
  }
}
# create private subnet two
resource "aws_subnet" "myvpc_private_subnet_two" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = element(var.subnet_two_cidr, 1)
  availability_zone = data.aws_availability_zones.availability_zones.names[1]
  tags = {
    Name = "myvpc_private_subnet_two"
  }
}

## create internet gateway
resource "aws_internet_gateway" "myvpc_internet_gateway" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "myvpc_internet_gateway"
  }
}

## create public route table (assosiated with internet gateway)
resource "aws_route_table" "myvpc_public_subnet_route_table" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = var.route_table_cidr
    gateway_id = aws_internet_gateway.myvpc_internet_gateway.id
  }
  tags = {
    Name = "myvpc_public_subnet_route_table"
  }
}

## create private subnet route table
resource "aws_route_table" "myvpc_private_subnet_route_table" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "myvpc_private_subnet_route_table"
  }
}

## create default route table
resource "aws_default_route_table" "myvpc_main_route_table" {
  default_route_table_id = aws_vpc.myvpc.default_route_table_id
  tags = {
    Name = "myvpc_main_route_table"
  }
}

## associate public subnet with public route table
resource "aws_route_table_association" "myvpc_public_subnet_route_table" {
  subnet_id      = aws_subnet.myvpc_public_subnet.id
  route_table_id = aws_route_table.myvpc_public_subnet_route_table.id
}

## associate private subnets with private route table
resource "aws_route_table_association" "myvpc_private_subnet_one_route_table_assosiation" {
  subnet_id      = aws_subnet.myvpc_private_subnet_one.id
  route_table_id = aws_route_table.myvpc_private_subnet_route_table.id
}
resource "aws_route_table_association" "myvpc_private_subnet_two_route_table_assosiation" {
  subnet_id      = aws_subnet.myvpc_private_subnet_two.id
  route_table_id = aws_route_table.myvpc_private_subnet_route_table.id
}

## create security group for web
resource "aws_security_group" "web_security_group" {
  name        = "web_security_group"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.myvpc.id
  tags = {
    Name = "myvpc_web_security_group"
  }
}

## create security group ingress rule for web
resource "aws_security_group_rule" "web_ingress" {
  count             = length(var.web_ports)
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = element(var.web_ports, count.index)
  to_port           = element(var.web_ports, count.index)
  security_group_id = aws_security_group.web_security_group.id
}

## create security group egress rule for web
resource "aws_security_group_rule" "web_egress" {
  count             = length(var.web_ports)
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = element(var.web_ports, count.index)
  to_port           = element(var.web_ports, count.index)
  security_group_id = aws_security_group.web_security_group.id
}

## create security group for db
resource "aws_security_group" "db_security_group" {
  name        = "db_security_group"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.myvpc.id
  tags = {
    Name = "myvpc_db_security_group"
  }
}

## create security group ingress rule for db
resource "aws_security_group_rule" "db_ingress" {
  count             = length(var.db_ports)
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = element(var.db_ports, count.index)
  to_port           = element(var.db_ports, count.index)
  security_group_id = aws_security_group.db_security_group.id
}

## create security group egress rule for db
resource "aws_security_group_rule" "db_egress" {
  count             = length(var.db_ports)
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = element(var.db_ports, count.index)
  to_port           = element(var.db_ports, count.index)
  security_group_id = aws_security_group.db_security_group.id
}

## create EC2 instance
resource "aws_instance" "my_web_instance" {
  ami                    = lookup(var.images, var.region)
  instance_type          = "t2.large"
  key_name               = "myprivate"
  vpc_security_group_ids = [aws_security_group.web_security_group.id]
  subnet_id              = aws_subnet.myvpc_public_subnet.id
  tags = {
    Name = "my_web_instance"
  }
  volume_tags = {
    Name = "my_web_instance_volume"
  }
  provisioner "remote-exec" { #install apache, mysql client, php
    inline = [
      "sudo mkdir -p /var/www/html/",
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo service httpd start",
      "sudo usermod -a -G apache centos",
      "sudo chown -R centos:apache /var/www",
      "sudo yum install -y mysql php php-mysql",
    ]
  }
  provisioner "file" { #copy the index file form local to remote
    source      = "d:\\terraform\\index.php"
    destination = "/tmp/index.php"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/index.php /var/www/html/index.php"
    ]
  }

  connection {
    type     = "ssh"
    user     = "centos"
    password = ""
    host     = self.public_ip
    #copy <private.pem> to your local instance to the home directory
    #chmod 600 id_rsa.pem
    private_key = file("myprivate.pem")
  }

}

## create aws rds subnet groups
resource "aws_db_subnet_group" "my_database_subnet_group" {
  name       = "mydbsg"
  subnet_ids = [aws_subnet.myvpc_private_subnet_one.id, aws_subnet.myvpc_private_subnet_two.id]
  tags = {
    Name = "my_database_subnet_group"
  }
}

## create aws mysql rds instance
resource "aws_db_instance" "my_database_instance" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  port                   = 3306
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.my_database_subnet_group.name
  name                   = "mydb"
  identifier             = "mysqldb"
  username               = "myuser"
  password               = "mypassword"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  tags = {
    Name = "my_database_instance"
  }
}

## output webserver and dbserver address
output "db_server_address" {
  value = aws_db_instance.my_database_instance.address
}
output "web_server_address" {
  value = aws_instance.my_web_instance.public_dns
}