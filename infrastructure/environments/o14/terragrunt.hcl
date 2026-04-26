include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config("${get_parent_terragrunt_dir("root.hcl")}/environments/_env/common.hcl")

  site_id            = "o14"
  domain             = "o14.pl"
  production_bucket  = "o14-prod"
  preview_bucket     = "o14-preview"
}

terraform {
  source = "../../modules//site-stack"
}

inputs = {
  aws_region         = local.common.locals.aws_region
  site_id            = local.site_id
  domain             = local.domain
  production_bucket  = local.production_bucket
  preview_bucket     = local.preview_bucket
}
