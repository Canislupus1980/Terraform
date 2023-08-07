provider "aws" {
  region = var.region
}

resource "aws_instance" "keycloak" {
  ami                    = "ami-0ab1a82de7ca5889c"
  instance_type          = "t2.micro"
  user_data              = file("keycloak.sh")
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = "TestLinux"

  tags = {
    Name = "keycloak_Instance"
  }
}

data "aws_route53_zone" "selected" {
  name         = "jfrog.shop"
  private_zone = false
}

resource "aws_route53_record" "domainName" {
  name    = "keycloak"
  type    = "A"
  zone_id = data.aws_route53_zone.selected.zone_id
  records = [aws_instance.keycloak.public_ip]
  ttl     = 300
  depends_on = [
    aws_instance.keycloak
  ]
}
