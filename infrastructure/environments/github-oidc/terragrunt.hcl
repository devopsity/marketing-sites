include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config("${get_parent_terragrunt_dir("root.hcl")}/environments/_env/common.hcl")
}

terraform {
  source = "../../modules//github-oidc"
}

dependency "perfectsystem" {
  config_path = "../perfectsystem"
}

dependency "o14" {
  config_path = "../o14"
}

inputs = {
  aws_region              = local.common.locals.aws_region
  github_org              = "devopsity"
  github_repo             = "marketing-sites"
  site_deploy_policy_arns = [
    dependency.perfectsystem.outputs.iam_deploy_policy_arn,
    dependency.o14.outputs.iam_deploy_policy_arn,
  ]
}
