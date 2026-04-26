# Implementation Plan: Netlify-Style CI/CD Pipeline (Multi-Site)

## Overview

This plan implements a multi-site Jekyll CI/CD pipeline using GitHub Actions, deploying to AWS S3/CloudFront with Terragrunt-managed infrastructure. Tasks are ordered so each step builds on the previous: site registry and directory structure first, then reusable Terraform modules, then Terragrunt environments, then GitHub Actions workflows (detect → build → validate → deploy), and finally cleanup and wiring. Utility functions for change detection, validation, URL construction, and check name generation are extracted as testable shell functions.

## Tasks

- [x] 1. Create site registry and multi-site directory structure
  - [x] 1.1 Create `sites.yml` at the repository root with site entries for `blog` (and optionally `sales`), including `id`, `source_dir`, `domain`, `preview_bucket`, `production_bucket`, `cloudfront_distribution_id`, and `terragrunt_env` fields
    - Use the schema from the design: each entry must have all required fields
    - _Requirements: 1.1_
  - [x] 1.2 Create the `sites/blog/` directory structure by relocating existing Jekyll source files (config, posts, pages, includes, layouts, sass, assets, index.html, 404.html) into `sites/blog/`
    - Move `_config.yml`, `_posts/`, `_pages/`, `_includes/`, `_layouts/`, `_sass/`, `assets/`, `index.html`, `404.html`, `feed.xml` into `sites/blog/`
    - Update `sites/blog/_config.yml` to set `url` to the blog's production domain and `baseurl` to `""`
    - _Requirements: 1.3, 9.3_
  - [x] 1.3 Update the root `Gemfile` to include `html-proofer` gem alongside existing Jekyll plugins
    - Add `gem 'html-proofer'` to the `:jekyll_plugins` group
    - _Requirements: 4.1, 5.1_

- [x] 2. Create reusable Terraform modules under `infrastructure/modules/`
  - [x] 2.1 Create `infrastructure/modules/s3-static-site/` module (`main.tf`, `variables.tf`, `outputs.tf`)
    - Variables: `bucket_name`, `is_preview` (boolean), `index_document` (default `index.html`), `error_document` (default `404.html`)
    - Production bucket: private access (no public ACL), configured for OAI access, static website hosting with index/error documents
    - Preview bucket: S3 static website hosting enabled for direct HTTP access
    - Outputs: `bucket_arn`, `bucket_regional_domain_name`, `website_endpoint`
    - _Requirements: 8.4, 8.9_
  - [x] 2.2 Create `infrastructure/modules/acm-certificate/` module (`main.tf`, `variables.tf`, `outputs.tf`)
    - Variables: `domain`
    - Provisions ACM certificate for `{domain}` and `*.{domain}` with DNS validation
    - Must use `aws.us_east_1` provider alias (CloudFront requirement)
    - Outputs: `certificate_arn`
    - _Requirements: 8.8_
  - [x] 2.3 Create `infrastructure/modules/cloudfront-distribution/` module (`main.tf`, `variables.tf`, `outputs.tf`)
    - Variables: `domain`, `s3_bucket_regional_domain_name`, `acm_certificate_arn`, `oai_id`
    - Configures OAI origin to keep production bucket private
    - Alternate domain names: `{domain}` and `www.{domain}`
    - Viewer protocol policy: redirect HTTP to HTTPS
    - Default root object: `index.html`, custom error response: 404 → `/404.html`
    - Outputs: `distribution_id`, `distribution_domain_name`
    - _Requirements: 8.5, 8.6, 8.7_
  - [x] 2.4 Create `infrastructure/modules/iam-deploy-policy/` module (`main.tf`, `variables.tf`, `outputs.tf`)
    - Variables: `site_id`, `production_bucket_arn`, `preview_bucket_arn`, `cloudfront_distribution_arn`
    - Grants: `s3:PutObject`, `s3:DeleteObject`, `s3:ListBucket`, `s3:GetBucketLocation` on site's buckets
    - Grants: `cloudfront:CreateInvalidation` on site's distribution
    - Outputs: `policy_arn`
    - _Requirements: 8.10, 10.3_
  - [x] 2.5 Create `infrastructure/modules/site-stack/` orchestrator module (`main.tf`, `variables.tf`, `outputs.tf`)
    - Variables: `site_id`, `domain`, `production_bucket`, `preview_bucket`, `aws_region`
    - Composes `s3-static-site` (twice: production + preview), `cloudfront-distribution`, `acm-certificate`, `iam-deploy-policy`
    - Outputs: all relevant IDs and ARNs
    - _Requirements: 8.1, 8.2_

- [x] 3. Checkpoint — Review Terraform modules
  - Ensure all Terraform modules have valid HCL syntax and consistent variable/output naming, ask the user if questions arise.

- [x] 4. Create Terragrunt configuration and per-site environments
  - [x] 4.1 Create `infrastructure/terragrunt.hcl` root config with S3 remote state backend, DynamoDB locking, and AWS provider generation (including `us_east_1` alias)
    - _Requirements: 8.1, 8.11_
  - [x] 4.2 Create `infrastructure/environments/_env/common.hcl` with shared variables (`aws_region`, `account_id`)
    - _Requirements: 8.11_
  - [x] 4.3 Create `infrastructure/environments/blog/terragrunt.hcl` for the blog site, including root config, reading common.hcl, setting site-specific locals (`site_id`, `domain`, `production_bucket`, `preview_bucket`), sourcing `site-stack` module, and passing inputs
    - _Requirements: 8.2, 8.3, 8.11_

- [x] 5. Create utility shell functions for pipeline logic
  - [x] 5.1 Create `scripts/pipeline-utils.sh` with the following extracted, testable shell functions:
    - `validate_registry`: Parses `sites.yml`, checks for unique `id` values, verifies required fields are present, verifies `source_dir` paths exist. Exits non-zero with error details on failure.
    - `detect_changes`: Takes `sites.yml` path and a list of changed files. Returns JSON array of affected site objects. Returns all sites if shared files changed, only matching sites if changes are site-specific, empty array if no sites affected.
    - `build_preview_url`: Takes `preview_bucket`, `region`, and `pr_number`. Returns URL in format `http://{preview_bucket}.s3-website-{region}.amazonaws.com/pr-{pr_number}/`.
    - `build_check_name`: Takes `stage` and `site_id`. Returns `{stage}/{site_id}`.
    - Uses `yq` for YAML parsing and `jq` for JSON output
    - _Requirements: 1.4, 2.1, 2.2, 2.3, 2.4, 6.4, 11.3_

  - [ ]* 5.2 Write property test: Site registry validation rejects duplicate identifiers
    - **Property 1: Site registry validation rejects duplicate identifiers**
    - Generate `sites.yml` content with two or more entries sharing the same `id`. Verify `validate_registry` returns an error and lists the duplicate identifiers.
    - **Validates: Requirements 1.4**

  - [ ]* 5.3 Write property test: Change detection correctness
    - **Property 2: Change detection correctness**
    - Generate random valid site registries and random sets of changed file paths. Verify `detect_changes` returns: all sites when shared files are present, only matching sites when all files are under site-specific directories, empty set when no files match.
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4**

  - [ ]* 5.4 Write property test: Preview URL construction
    - **Property 3: Preview URL construction**
    - Generate random site configs (preview_bucket, region) and positive integer PR numbers. Verify `build_preview_url` produces `http://{preview_bucket}.s3-website-{region}.amazonaws.com/pr-{pr_number}/`.
    - **Validates: Requirements 6.4**

  - [ ]* 5.5 Write property test: GitHub Actions check name generation
    - **Property 4: GitHub Actions check name generation**
    - Generate random stage names and valid site identifiers. Verify `build_check_name` produces `{stage}/{site_id}`.
    - **Validates: Requirements 11.3**

  - [ ]* 5.6 Write unit tests for utility functions
    - Test `detect_changes` with infrastructure-only changes logs notice and continues
    - Test `detect_changes` treats `sites.yml` change as shared file (all sites affected)
    - Test `validate_registry` accepts valid `sites.yml` with multiple sites
    - Test `validate_registry` rejects entry with missing required fields
    - Test `detect_changes` with empty diff returns empty array
    - _Requirements: 2.3, 2.4, 2.5, 1.1, 1.4_

- [x] 6. Checkpoint — Verify utility functions and tests
  - Ensure all utility shell functions work correctly and tests pass, ask the user if questions arise.

- [x] 7. Create PR pipeline GitHub Actions workflow
  - [x] 7.1 Create `.github/workflows/pr-pipeline.yml` triggered on `pull_request` events (`opened`, `synchronize`, `reopened`)
    - **Detect job**: Checkout code, parse `sites.yml` using `scripts/pipeline-utils.sh` functions, run `detect_changes` with `git diff --name-only` against base branch, output `affected_sites` JSON for matrix consumption. If no sites affected, output empty array.
    - **Validate registry job**: Run `validate_registry` from `scripts/pipeline-utils.sh`. Fail pipeline if duplicate IDs or missing fields detected.
    - Configure AWS credentials from GitHub Actions secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 1.4, 10.1, 10.2_
  - [x] 7.2 Add **build-and-validate** matrix job to `pr-pipeline.yml`
    - Matrix: `fromJSON(needs.detect.outputs.affected_sites)` with `fail-fast: false`
    - Steps: checkout, setup Ruby, restore gem cache (`actions/cache` keyed on `Gemfile.lock` hash), `bundle install`
    - Generate `_config_preview.yml` with `baseurl: /pr-${{ github.event.pull_request.number }}`
    - Run `bundle exec jekyll build --source ${{ matrix.site.source_dir }} --config ${{ matrix.site.source_dir }}/_config.yml,_config_preview.yml`
    - Run HTML validation: `bundle exec htmlproofer ./_site --check-html --disable-external` (check name: `html-validation/${{ matrix.site.id }}`)
    - Run link check: `bundle exec htmlproofer ./_site --disable-external --allow-hash-href` (check name: `link-check/${{ matrix.site.id }}`)
    - Each site builds independently; failure in one does not block others
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 9.2, 11.3_
  - [x] 7.3 Add **deploy-preview** matrix job to `pr-pipeline.yml`
    - Depends on `build-and-validate` job
    - Matrix: same affected sites
    - Run `aws s3 sync ./_site/ s3://${{ matrix.site.preview_bucket }}/pr-${{ github.event.pull_request.number }}/ --delete`
    - _Requirements: 6.1, 6.4_
  - [x] 7.4 Add **post-comment** summary job to `pr-pipeline.yml`
    - Depends on `deploy-preview` job
    - Collects preview URLs for all deployed sites using `build_preview_url` function
    - Posts or updates a single PR comment listing preview URLs for each deployed site
    - Uses `continue-on-error: true` so comment failure doesn't fail the pipeline
    - _Requirements: 6.2_

- [x] 8. Create production pipeline GitHub Actions workflow
  - [x] 8.1 Create `.github/workflows/production-pipeline.yml` triggered on `push` to `main` branch
    - **Detect job**: Same change detection logic as PR pipeline using `scripts/pipeline-utils.sh`
    - **Validate registry job**: Same validation as PR pipeline
    - Configure AWS credentials from GitHub Actions secrets
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 1.4, 10.1, 10.2_
  - [x] 8.2 Add **build-and-validate** matrix job to `production-pipeline.yml`
    - Matrix: `fromJSON(needs.detect.outputs.affected_sites)` with `fail-fast: false`
    - Steps: checkout, setup Ruby, restore gem cache, `bundle install`
    - Generate `_config_production.yml` with `url: https://${{ matrix.site.domain }}` and `baseurl: ""`
    - Run `bundle exec jekyll build --source ${{ matrix.site.source_dir }} --config ${{ matrix.site.source_dir }}/_config.yml,_config_production.yml`
    - Run HTML validation and link check (same as PR pipeline, per-site check names)
    - _Requirements: 3.1, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 9.1, 11.3_
  - [x] 8.3 Add **deploy-production** matrix job to `production-pipeline.yml`
    - Depends on `build-and-validate` job
    - Matrix: same affected sites, `fail-fast: false`
    - Run `aws s3 sync ./_site/ s3://${{ matrix.site.production_bucket }}/ --delete`
    - Run `aws cloudfront create-invalidation --distribution-id ${{ matrix.site.cloudfront_distribution_id }} --paths "/*"`
    - Each site deploys independently; failure in one does not block others
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 9. Create cleanup preview GitHub Actions workflow
  - [x] 9.1 Create `.github/workflows/cleanup-preview.yml` triggered on `pull_request` event type `closed`
    - Parse `sites.yml` to get all site preview bucket names
    - For each site, run `aws s3 rm s3://{preview_bucket}/pr-${{ github.event.pull_request.number }}/ --recursive`
    - Iterate all sites (not just affected — can't know which were deployed for a closed PR)
    - Continue even if one site's cleanup fails
    - Configure AWS credentials from GitHub Actions secrets
    - _Requirements: 6.3, 10.1_

- [x] 10. Checkpoint — Verify all workflows
  - Ensure all three workflow YAML files have valid syntax, correct trigger events, proper `needs` dependencies, and `fail-fast: false` on matrix jobs. Ask the user if questions arise.

- [x] 11. Wire everything together and verify end-to-end
  - [x] 11.1 Verify `sites.yml` references match the Terragrunt environment configuration (bucket names, distribution IDs, domains)
    - Ensure consistency between `sites.yml` entries and `infrastructure/environments/blog/terragrunt.hcl` locals
    - _Requirements: 8.2, 10.2_
  - [x] 11.2 Verify all workflow files reference `scripts/pipeline-utils.sh` for detect/validate logic and that no site-specific values are hardcoded in workflow YAML
    - Workflows must read all site metadata from `sites.yml` dynamically
    - _Requirements: 1.2, 10.2_
  - [x] 11.3 Verify per-site GitHub Actions check names follow `{stage}/{site_id}` pattern across all workflows
    - Check names: `build/{site_id}`, `html-validation/{site_id}`, `link-check/{site_id}`, `deploy/{site_id}`
    - _Requirements: 11.1, 11.2, 11.3, 11.4_

- [x] 12. Final checkpoint — Full review
  - Ensure all tests pass, all workflow files are consistent, Terraform modules are complete, and the pipeline is ready for infrastructure provisioning and first run. Ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate the four correctness properties from the design (change detection, registry validation, preview URL, check name generation)
- Unit tests validate specific examples and edge cases for utility functions
- Terragrunt infrastructure must be provisioned (`terragrunt apply`) before the pipeline can deploy — this is an operational step outside the scope of these coding tasks
- The pipeline uses `yq` and `jq` as CLI dependencies in the GitHub Actions runners (pre-installed on `ubuntu-latest`)
