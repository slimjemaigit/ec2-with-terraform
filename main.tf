provider "aws" {
  region = "eu-west-3"
}

#1-Create VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name= "production VPC"
  }
}

#2-Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
  tags = {
    Name= "production internet gateway"
  }
}

#3-Create Custom Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "production route table"
  }
}

#4-Create a Subnet
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "production subnet 1"
  }
}

#5-Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

#6-Create Security Group to allow port 22, 80, 443
resource "aws_security_group" "allow_tls" {
  name        = "allow_web_traffic"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  tags = {
    Name = "production security group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4_https" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0" #it used to be: aws_vpc.prod-vpc.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4_http" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0" #it used to be: aws_vpc.prod-vpc.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4_ssh" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0" #it used to be: aws_vpc.prod-vpc.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#7-Create a network interface with an IP in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_tls.id]
tags = {
    Name = "production network interface"
  }
}
#8-Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [ aws_internet_gateway.gw ]
  tags = {
    Name = "production elastic IP"
  }
}
#9-Create Ubuntu server and install/enable apache2
resource "aws_instance" "web-server-instance" {
  ami = "ami-00ac45f3035ff009e"
  availability_zone = "eu-west-3a"
  instance_type = "t2.micro"
  key_name = "Slim-key"

  network_interface {
    network_interface_id = aws_network_interface.web-server-nic.id
    device_index         = 0
  }

  user_data = <<EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt-get install apache2
              sudo systemctl start apache2
              sudo bash -c 'echo the very first web server > /var/www/html/index.html'
              EOF
              

  tags = {
    Name = "production instance"
  }
}