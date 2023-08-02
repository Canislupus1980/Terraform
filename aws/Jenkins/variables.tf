variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "az_1" {
  type    = string
  default = "eu-central-1a"
}

variable "az_2" {
  type    = string
  default = "eu-central-1b"
}

variable "ami_id" {
  type = map(any)
  default = {
    ap-southeast-1 = "ami-0615132a0f36d24f4"
  }
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "tf_state_bucket" {
  type = string
}

variable "tf_state_key" {
  type = string
}

variable "jenkins_tf_tags" {
  type    = string
  default = "my-jenkins"
}

variable "domain" {
  type    = string
  default = "work.online"
}
