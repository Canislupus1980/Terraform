resource "aws_instance" "jenkins_instance" {
  ami                    = lookup(var.ami_id, var.region)
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.jenkins_iam_instance_profile.name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = aws_subnet.jenkins_subnet1.id
  user_data              = <<EOF
#! /bin/bash
sudo yum update -y
sudo yum install -y httpd.x86_64
sudo service httpd start
sudo service httpd enable

# install jenkins
yum install java-1.8.0-openjdk-devel -y
curl --silent --location http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo | sudo tee /etc/yum.repos.d/jenkins.repo
sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
yum install -y jenkins

# start jenkins service
sudo systemctl start jenkins.service
sudo systemctl status jenkins.service
sudo systemctl enable jenkins.service
EOF

  tags = {
    Name = var.jenkins_tf_tags
  }
}

resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins_instance.id
  vpc      = true
  tags = {
    Name = var.jenkins_tf_tags
  }
}
