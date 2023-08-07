variable "region" {
  description = "Region in which resources will be provisioned"
  type        = string
  default     = "eu-central-1"
}

variable "domainName" {
  description = "Domain name of the application"
  default     = "domen.com"
  type        = string
}
