resource "aws_iam_policy" "deploy" {
  name        = "${var.site_id}-deploy-policy"
  description = "Least-privilege deploy policy for site: ${var.site_id}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          var.production_bucket_arn,
          "${var.production_bucket_arn}/*",
          var.preview_bucket_arn,
          "${var.preview_bucket_arn}/*"
        ]
      },
      {
        Sid      = "CloudFrontAccess"
        Effect   = "Allow"
        Action   = "cloudfront:CreateInvalidation"
        Resource = var.cloudfront_distribution_arn
      }
    ]
  })
}
