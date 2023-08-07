provider "aws" {
  region = var.region
}

resource "aws_instance" "jfrog" {
  ami                    = "ami-0ab1a82de7ca5889c"
  instance_type          = "t2.medium"
  user_data              = file("jfrog.sh")
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = "TestLinux"

  tags = {
    Name = "jfrog_Instance"
  }
}


data "aws_route53_zone" "selected" {
  name         = "domen.com"
  private_zone = false
}

resource "aws_route53_record" "domainName" {
  name    = "jfrog"
  type    = "A"
  zone_id = data.aws_route53_zone.selected.zone_id
  records = [aws_instance.jfrog.public_ip]
  ttl     = 300
  depends_on = [
    aws_instance.jfrog
  ]
}
