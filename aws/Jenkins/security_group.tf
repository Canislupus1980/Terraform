resource "aws_security_group" "jenkins_sg" {
  name   = "Jenkins Instance SG"
  vpc_id = aws_vpc.jenkins_vpc.id

  ingress {
    description = "Allow jnlp traffic"
    from_port   = 12206
    to_port     = 12206
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow 8080 traffic from Load balancer"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_elb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.jenkins_tf_tags
  }
}

resource "aws_security_group" "jenkins_elb_sg" {
  name   = "Jenkins ELB SG"
  vpc_id = aws_vpc.jenkins_vpc.id

  ingress {
    description = "allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.jenkins_tf_tags
  }
}
