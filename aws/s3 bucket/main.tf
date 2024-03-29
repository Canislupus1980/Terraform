terraform {
    required_providers {
        aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
    }
}
    backend "s3" {
        bucket = "seren.live"
        key = "value"
    }
}

provider "aws" {
    region = "eu-central-1"
}