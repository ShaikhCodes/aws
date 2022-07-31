# PROVIDER

provider "aws" {
  region = var.region
  
}

# VPC
resource "aws_vpc" "webserver_vpc" {

  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    "Name" = "webserver_vpc"
  }
  
}

#PUBLIC SUBNET 
resource "aws_subnet" "public_subnet_1" {
  cidr_block = var.public_subnet_1_cidr
  vpc_id = aws_vpc.webserver_vpc.id
  availability_zone = "${var.region}a"
  tags = {
    "Name" = "public-subnet-1"
  }
    
}


resource "aws_subnet" "public_subnet_2" {
  cidr_block = var.public_subnet_2_cidr
  vpc_id = aws_vpc.webserver_vpc.id
  availability_zone = "${var.region}b"
  tags = {
    "Name" = "public-subnet-2"
  }
    
}

# PRIVATE SUBNET
resource "aws_subnet" "private_subnet_1" {
  cidr_block = var.private_subnet_1_cidr
  vpc_id = aws_vpc.webserver_vpc.id
  availability_zone = "${var.region}a"
  tags = {
    "Name" = "private-subnet-1"
  }
    
}

resource "aws_subnet" "private_subnet_2" {
  cidr_block = var.private_subnet_2_cidr
  vpc_id = aws_vpc.webserver_vpc.id
  availability_zone = "${var.region}b"
  tags = {
    "Name" = "private-subnet-2"
  }
    
}

#PUBLIC ROUTE TABLE

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.webserver_vpc.id
  tags = {
    "Name" = "public-route-table"
  }
  
}

#PRIVATE ROUTE TABLE

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.webserver_vpc.id
  tags = {
    "Name" = "private-route-table"
  }
  
}

# ROUTE TABLE ASSOCIATION WITH PUBLIC AND PRIVATE SUBNET

resource "aws_route_table_association" "public_subnet_1_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.public_subnet_1.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.public_subnet_2.id
}

resource "aws_route_table_association" "private_subnet_1_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id = aws_subnet.private_subnet_1.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id = aws_subnet.private_subnet_2.id
}

#ELASTIC IP

resource "aws_eip" "eip_for_ngw" {
  vpc = true
  associate_with_private_ip = var.eip_association_address
  tags = {
    "Name" = "Elastic-IP"
  }
}

#NAT GATEWAY

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip_for_ngw.id
  subnet_id = aws_subnet.public_subnet_1.id
  tags = {
    "Name" = "Nat_Gateway"
  }
  
}

resource "aws_route" "ngw_route" {
  route_table_id = aws_route_table.private_route_table.id
  nat_gateway_id = aws_nat_gateway.ngw.id
  destination_cidr_block = "0.0.0.0/0"
}

#INTERNET GATEWAY

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.webserver_vpc.id
  tags = {
    "Name" = "Internet_Gateway"
  }
  
}

resource "aws_route" "igw_route" {
  route_table_id = aws_route_table.public_route_table.id
  gateway_id = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

#INSTANCE 

resource "aws_instance" "instance1" {
  ami = "ami-085e874ff0e2cff4f"
  instance_type = "t2.micro"
  key_name = "instancekey"
  security_groups = [aws_security_group.insatnce1_SG.id]
  subnet_id = aws_subnet.private_subnet_1.id
  
}

resource "aws_instance" "instance2" {
  ami = "ami-085e874ff0e2cff4f"
  instance_type = var.ec2_instancetype
  key_name = var.ec2_keypair
  security_groups = [aws_security_group.insatnce1_SG.id]
  subnet_id = aws_subnet.private_subnet_2.id
  
}

#SECURITY GROUP

resource "aws_security_group" "insatnce1_SG" {

  vpc_id = aws_vpc.webserver_vpc.id

  name = "Instance1SG"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  
}

#LOAD BALANCER 

resource "aws_elb" "elb" {

  availability_zones = [ "ap-southeast-1a","ap-southeast1b" ]
  subnets = [ "aws_subnet.public_subnet_1.id" ,  "aws_subnet.public_subnet_1.id"]

  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 3
    target = "HTTP:8000/"
    interval = 30

  }

  
}
