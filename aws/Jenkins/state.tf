terraform {
  backend "s3" {}
}

data "terraform_remote_state" "state" {
  backend = "s3"
  config = {
    region  = var.region
    bucket  = var.tf_state_bucket
    key     = var.tf_state_key
    encrypt = true
  }
}
