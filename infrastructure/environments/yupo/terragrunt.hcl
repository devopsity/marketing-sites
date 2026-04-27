include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config("${get_parent_terragrunt_dir("root.hcl")}/environments/_env/common.hcl")

  site_id            = "yupo"
  domain             = "blog.yupo.pl"
  cert_domain        = "yupo.pl"
  production_bucket  = "yupo-prod"
  preview_bucket     = "yupo-preview"
}

terraform {
  source = "../../modules//site-stack"
}

inputs = {
  aws_region         = local.common.locals.aws_region
  site_id            = local.site_id
  domain             = local.domain
  cert_domain        = local.cert_domain
  production_bucket  = local.production_bucket
  preview_bucket     = local.preview_bucket
}
