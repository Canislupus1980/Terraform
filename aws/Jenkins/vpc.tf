resource "aws_vpc" "jenkins_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_classiclink   = false

  tags = {
    Name = var.jenkins_tf_tags
  }
}

resource "aws_internet_gateway" "jenkins_gw" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = {
    Name = var.jenkins_tf_tags
  }
}

resource "aws_subnet" "jenkins_subnet1" {
  availability_zone = var.az_1
  vpc_id            = aws_vpc.jenkins_vpc.id
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = var.jenkins_tf_tags
  }
}

resource "aws_subnet" "jenkins_subnet2" {
  availability_zone = var.az_2
  vpc_id            = aws_vpc.jenkins_vpc.id
  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = var.jenkins_tf_tags
  }
}

resource "aws_route_table" "jenkins_route_public" {
  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_gw.id
  }

  tags = {
    Name = var.jenkins_tf_tags
  }
}

resource "aws_route_table_association" "jenkins_asso_subnet_1" {
  subnet_id      = aws_subnet.jenkins_subnet1.id
  route_table_id = aws_route_table.jenkins_route_public.id
}

resource "aws_route_table_association" "jenkins_asso_subnet_2" {
  subnet_id      = aws_subnet.jenkins_subnet2.id
  route_table_id = aws_route_table.jenkins_route_public.id
}
