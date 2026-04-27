# -----------------------------------------------------------------------------
# Site Stack — Orchestrator module composing all per-site infrastructure
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# --- S3 Buckets ---

module "production_bucket" {
  source = "../s3-static-site"

  bucket_name = var.production_bucket
  is_preview  = false
}

module "preview_bucket" {
  source = "../s3-static-site"

  bucket_name = var.preview_bucket
  is_preview  = true
}

# --- ACM Certificate (must be in us-east-1 for CloudFront) ---

module "acm_certificate" {
  source = "../acm-certificate"

  domain = var.cert_domain

  providers = {
    aws = aws.us_east_1
  }
}

# --- CloudFront Origin Access Identity ---

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "OAI for ${var.site_id} production bucket"
}

# --- S3 bucket policy granting OAI read access to production bucket ---

resource "aws_s3_bucket_policy" "production_oai" {
  bucket = var.production_bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.this.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${module.production_bucket.bucket_arn}/*"
      }
    ]
  })

  depends_on = [module.production_bucket]
}

# --- CloudFront Distribution ---

module "cloudfront" {
  source = "../cloudfront-distribution"

  domain                         = var.domain
  s3_bucket_regional_domain_name = module.production_bucket.bucket_regional_domain_name
  acm_certificate_arn            = module.acm_certificate.certificate_arn
  oai_id                         = aws_cloudfront_origin_access_identity.this.id
}

# --- IAM Deploy Policy ---

module "iam_policy" {
  source = "../iam-deploy-policy"

  site_id                     = var.site_id
  production_bucket_arn       = module.production_bucket.bucket_arn
  preview_bucket_arn          = module.preview_bucket.bucket_arn
  cloudfront_distribution_arn = "arn:aws:cloudfront::*:distribution/${module.cloudfront.distribution_id}"
}
