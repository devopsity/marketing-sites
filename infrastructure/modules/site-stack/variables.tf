variable "site_id" {
  description = "Unique site identifier (e.g., blog, sales)"
  type        = string
}

variable "domain" {
  description = "Production domain name (e.g., blog.perfectsystem.pl)"
  type        = string
}

variable "cert_domain" {
  description = "Root domain for ACM certificate (e.g., perfectsystem.pl). The cert covers this domain and *.cert_domain."
  type        = string
}

variable "production_bucket" {
  description = "Name of the S3 bucket for production deployments"
  type        = string
}

variable "preview_bucket" {
  description = "Name of the S3 bucket for preview deployments"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
}
