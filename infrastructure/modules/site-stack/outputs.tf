# --- S3 Bucket Outputs ---

output "production_bucket_arn" {
  description = "ARN of the production S3 bucket"
  value       = module.production_bucket.bucket_arn
}

output "production_bucket_regional_domain_name" {
  description = "Regional domain name of the production S3 bucket"
  value       = module.production_bucket.bucket_regional_domain_name
}

output "production_bucket_website_endpoint" {
  description = "Website endpoint of the production S3 bucket"
  value       = module.production_bucket.website_endpoint
}

output "preview_bucket_arn" {
  description = "ARN of the preview S3 bucket"
  value       = module.preview_bucket.bucket_arn
}

output "preview_bucket_regional_domain_name" {
  description = "Regional domain name of the preview S3 bucket"
  value       = module.preview_bucket.bucket_regional_domain_name
}

output "preview_bucket_website_endpoint" {
  description = "Website endpoint of the preview S3 bucket"
  value       = module.preview_bucket.website_endpoint
}

# --- CloudFront Outputs ---

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cloudfront.distribution_domain_name
}

output "cloudfront_oai_id" {
  description = "ID of the CloudFront Origin Access Identity"
  value       = aws_cloudfront_origin_access_identity.this.id
}

# --- ACM Certificate Outputs ---

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = module.acm_certificate.certificate_arn
}

output "acm_domain_validation_records" {
  description = "CNAME records to add at your domain registrar for ACM certificate validation"
  value       = module.acm_certificate.domain_validation_options
}

# --- IAM Policy Outputs ---

output "iam_deploy_policy_arn" {
  description = "ARN of the IAM deploy policy"
  value       = module.iam_policy.policy_arn
}
