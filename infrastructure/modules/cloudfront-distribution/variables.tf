variable "domain" {
  description = "The production domain name (e.g., perfectsystem.pl)"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the production S3 bucket"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for the domain"
  type        = string
}

variable "oai_id" {
  description = "ID of the CloudFront Origin Access Identity for S3 access"
  type        = string
}
