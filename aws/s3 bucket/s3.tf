resource "aws_s3_bucket" "terraform_data" {
  bucket = "seren.live"
  acl = "private"
  versioning {
    enabled = true
  }
}