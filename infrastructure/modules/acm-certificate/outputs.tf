output "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "domain_validation_options" {
  description = "DNS records to create at your domain registrar for certificate validation"
  value = [for dvo in aws_acm_certificate.this.domain_validation_options : {
    name   = dvo.resource_record_name
    type   = dvo.resource_record_type
    value  = dvo.resource_record_value
  }]
}
