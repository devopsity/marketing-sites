variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "site_deploy_policy_arns" {
  description = "List of IAM policy ARNs (one per site) to attach to the deploy role"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
}
