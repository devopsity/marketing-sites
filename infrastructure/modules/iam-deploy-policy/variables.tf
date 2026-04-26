variable "site_id" {
  description = "Unique site identifier used for naming the IAM policy"
  type        = string
}

variable "production_bucket_arn" {
  description = "ARN of the site's production S3 bucket"
  type        = string
}

variable "preview_bucket_arn" {
  description = "ARN of the site's preview S3 bucket"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the site's CloudFront distribution"
  type        = string
}
