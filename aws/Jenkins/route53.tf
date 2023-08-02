resource "aws_route53_record" "jenkins_record" {
  zone_id = data.aws_route53_zone.my_route53_zone.zone_id
  name    = "jenkins.${var.domain}"
  type    = "A"
  alias {
    name                   = aws_lb.jenkins-lb.dns_name
    zone_id                = aws_lb.jenkins-lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "jenkins_internal_record" {
  zone_id = data.aws_route53_zone.my_route53_zone.zone_id
  name    = "internal-jenkins.${var.domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.jenkins_eip.public_ip]
}

data "aws_route53_zone" "my_route53_zone" {
  name = "${var.domain}."
}

data "aws_acm_certificate" "my_jenkins_cert" {
  domain   = "*.${var.domain}"
  statuses = ["ISSUED"]
}
