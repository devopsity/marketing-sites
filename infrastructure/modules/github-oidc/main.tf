# -----------------------------------------------------------------------------
# GitHub OIDC — Federated authentication for GitHub Actions deployments
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

# --- OIDC Provider for GitHub Actions ---

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# --- IAM Role trusted by the OIDC provider ---

resource "aws_iam_role" "github_actions_deploy" {
  name = "github-actions-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# --- Attach each site's deploy policy to the role ---

resource "aws_iam_role_policy_attachment" "site_policies" {
  count      = length(var.site_deploy_policy_arns)
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = var.site_deploy_policy_arns[count.index]
}
