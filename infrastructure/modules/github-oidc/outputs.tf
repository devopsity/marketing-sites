output "deploy_role_arn" {
  description = "ARN of the GitHub Actions deploy IAM role"
  value       = aws_iam_role.github_actions_deploy.arn
}
