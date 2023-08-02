resource "aws_lb" "jenkins-lb" {
  name                       = "jenkins-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.jenkins_elb_sg.id]
  subnets                    = [aws_subnet.jenkins_subnet1.id, aws_subnet.jenkins_subnet2.id]
  enable_deletion_protection = false
  tags = {
    Name = var.jenkins_tf_tags
  }
}

resource "aws_lb_listener" "jenkins_lb_listener" {
  load_balancer_arn = aws_lb.jenkins-lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn = data.aws_acm_certificate.my_jenkins_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins-lb-target-group-1.arn
  }
}

resource "aws_lb_target_group" "jenkins-lb-target-group-1" {
  name        = "jenkins-lb-target-group-1"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.jenkins_vpc.id
  tags = {
    Name = var.jenkins_tf_tags
  }
}

resource "aws_lb_target_group_attachment" "jenkins_lb_target_group_attachment1" {
  target_group_arn = aws_lb_target_group.jenkins-lb-target-group-1.arn
  target_id        = aws_instance.jenkins_instance.id
  port             = 8080
}
