# Requirements Document

## Introduction

This document defines the requirements for a Netlify-style CI/CD pipeline for one or more Jekyll-based sites (blogs, sales pages) hosted within a single GitHub repository. The pipeline uses GitHub Actions to build, validate, and deploy sites to AWS S3 with CloudFront CDN distribution. AWS infrastructure is provisioned and managed using Terragrunt (wrapping Terraform). The repository supports multiple sites, each with its own S3 bucket, CloudFront distribution, and preview setup. The pipeline detects which site(s) changed and only builds/deploys those. It supports preview deployments for pull requests (the primary content authoring mechanism via a 3rd party app), quality checks (HTML validation, link checking), and automated production deployment on merge to the main branch.

## Glossary

- **Pipeline**: The GitHub Actions CI/CD workflow that builds, validates, and deploys Jekyll sites
- **Site**: An individual Jekyll site within the repository, identified by a unique site identifier (e.g., `blog`, `sales`), each with its own configuration, content directory, and deployment target
- **Site_Registry**: A configuration file (e.g., `sites.yml`) at the repository root that defines all sites, their source directories, domains, and Terragrunt environment references
- **Preview_Environment**: A temporary S3-hosted deployment of a pull request branch for a specific Site, accessible via a unique URL, used to review changes before merging
- **Production_Environment**: The live S3-hosted deployment of a Site served via its CloudFront_Distribution at the Site's custom domain
- **Quality_Gate**: A set of automated checks (HTML validation, link checking, Jekyll build verification) that must pass before deployment proceeds
- **Build_Artifact**: The static HTML/CSS/JS output produced by the Jekyll build process for a specific Site in its `_site` directory
- **Preview_Bucket**: The S3 bucket used to host preview deployments for a specific Site, organized by pull request number
- **Production_Bucket**: The S3 bucket configured for static website hosting that serves a specific Site's production content
- **CloudFront_Distribution**: An AWS CloudFront CDN distribution that serves a Site's Production_Bucket content at the Site's custom domain
- **PR_Author**: A human or 3rd party application that creates pull requests containing new content or site changes
- **Terragrunt_Configuration**: The set of Terragrunt HCL files that define and parameterize the AWS infrastructure for all Sites
- **Terragrunt_Module**: A reusable Terraform module invoked by Terragrunt to provision a specific infrastructure component (S3 bucket, CloudFront distribution, ACM certificate, IAM policy)
- **Change_Detection**: The Pipeline mechanism that determines which Site(s) have been modified in a given push or pull request by analyzing changed file paths

## Requirements

### Requirement 1: Multi-Site Repository Structure

**User Story:** As a blog owner, I want to host multiple Jekyll sites (blogs, sales pages) in a single repository, so that I can manage all my web properties from one codebase.

#### Acceptance Criteria

1. THE Site_Registry SHALL define each Site with a unique identifier, source directory path, production domain, and Terragrunt environment reference.
2. WHEN a new Site is added to the Site_Registry, THE Pipeline SHALL recognize the new Site and include it in Change_Detection and build processes without workflow file modifications.
3. THE repository SHALL organize each Site's Jekyll source files in a dedicated subdirectory as specified in the Site_Registry.
4. IF a Site identifier in the Site_Registry is not unique, THEN THE Pipeline SHALL report a validation error and halt execution.

### Requirement 2: Change Detection

**User Story:** As a PR_Author, I want the Pipeline to detect which site(s) I changed, so that only affected sites are built and deployed, saving time and resources.

#### Acceptance Criteria

1. WHEN a push event or pull request event occurs, THE Change_Detection SHALL compare changed file paths against the Site_Registry to determine which Site(s) are affected.
2. WHEN changes are detected only in Site-specific directories, THE Pipeline SHALL build and deploy only the affected Site(s).
3. WHEN changes are detected in shared files (e.g., Gemfile, shared includes, workflow files), THE Pipeline SHALL build and deploy all Sites defined in the Site_Registry.
4. IF no Site-specific or shared files are changed, THEN THE Pipeline SHALL skip build and deployment steps and report a successful status.
5. WHEN changes affect the Terragrunt_Configuration files, THE Pipeline SHALL flag the change for infrastructure review but continue with site build and deployment for affected Sites.

### Requirement 3: Jekyll Site Build

**User Story:** As a PR_Author, I want the Pipeline to build the affected Jekyll site(s) automatically on every push, so that I can verify my content compiles correctly.

#### Acceptance Criteria

1. WHEN a push event occurs on the main branch, THE Pipeline SHALL install Ruby dependencies using Bundler and build each affected Site's Jekyll source into its respective `_site` directory.
2. WHEN a pull request is opened or updated, THE Pipeline SHALL install Ruby dependencies using Bundler and build each affected Site's Jekyll source into its respective `_site` directory.
3. IF the Jekyll build fails for any Site, THEN THE Pipeline SHALL report the failure as a failed GitHub Actions check on the commit, identifying the Site by its identifier.
4. THE Pipeline SHALL cache Ruby gem dependencies between runs to reduce build time.
5. THE Pipeline SHALL build each affected Site independently, so that a build failure in one Site does not prevent other affected Sites from being built.

### Requirement 4: HTML Validation Quality Check

**User Story:** As a PR_Author, I want the Pipeline to validate the generated HTML for each affected site, so that I can catch markup errors before they reach production.

#### Acceptance Criteria

1. WHEN the Jekyll build completes successfully for a Site, THE Quality_Gate SHALL validate all HTML files in that Site's Build_Artifact for well-formedness and standards compliance.
2. IF HTML validation detects errors for a Site, THEN THE Quality_Gate SHALL report the validation errors as a failed GitHub Actions check with error details in the log output, identifying the Site by its identifier.
3. WHEN HTML validation passes with no errors for a Site, THE Quality_Gate SHALL report a successful GitHub Actions check for that Site.

### Requirement 5: Link Checking Quality Check

**User Story:** As a PR_Author, I want the Pipeline to check for broken links in each affected site, so that readers do not encounter dead links.

#### Acceptance Criteria

1. WHEN the Jekyll build completes successfully for a Site, THE Quality_Gate SHALL check all internal links in that Site's Build_Artifact for validity.
2. IF broken internal links are detected for a Site, THEN THE Quality_Gate SHALL report the broken links as a failed GitHub Actions check with the list of broken links in the log output, identifying the Site by its identifier.
3. WHEN all internal link checks pass for a Site, THE Quality_Gate SHALL report a successful GitHub Actions check for that Site.

### Requirement 6: Preview Deployment for Pull Requests

**User Story:** As a PR_Author, I want each affected site in a pull request to be deployed to a unique preview URL, so that I can review the rendered content before merging.

#### Acceptance Criteria

1. WHEN a pull request is opened or updated and the Quality_Gate passes for a Site, THE Pipeline SHALL deploy that Site's Build_Artifact to the Site's Preview_Bucket under a path namespaced by the pull request number.
2. WHEN the preview deployment completes for one or more Sites, THE Pipeline SHALL post a comment on the pull request containing the preview URL for each deployed Site.
3. WHEN a pull request is closed or merged, THE Pipeline SHALL delete the corresponding preview files from each affected Site's Preview_Bucket.
4. THE Preview_Environment for each Site SHALL be accessible via an HTTP URL derived from the Site's Preview_Bucket S3 static website hosting endpoint and the pull request number.

### Requirement 7: Production Deployment

**User Story:** As a PR_Author, I want affected sites to be automatically deployed to production when changes are merged to main, so that published content goes live without manual intervention.

#### Acceptance Criteria

1. WHEN a push event occurs on the main branch and the Quality_Gate passes for a Site, THE Pipeline SHALL sync that Site's Build_Artifact to the Site's Production_Bucket.
2. WHEN the production sync completes for a Site, THE Pipeline SHALL create a CloudFront invalidation for all paths on that Site's CloudFront_Distribution to ensure the CDN serves the updated content.
3. IF the S3 sync to a Site's Production_Bucket fails, THEN THE Pipeline SHALL report the failure as a failed GitHub Actions check, identifying the Site by its identifier.
4. IF the CloudFront invalidation fails for a Site, THEN THE Pipeline SHALL report the failure as a failed GitHub Actions check, identifying the Site by its identifier.
5. THE Pipeline SHALL deploy each affected Site independently, so that a deployment failure for one Site does not prevent other affected Sites from being deployed.

### Requirement 8: Terragrunt Infrastructure as Code

**User Story:** As a blog owner, I want the AWS infrastructure (S3 buckets, CloudFront distributions, ACM certificates, IAM policies) to be defined as code using Terragrunt, so that infrastructure is version-controlled, repeatable, and parameterized per site.

#### Acceptance Criteria

1. THE Terragrunt_Configuration SHALL define reusable Terragrunt_Modules for provisioning S3 buckets (production and preview), CloudFront distributions, ACM certificates, and IAM policies.
2. THE Terragrunt_Configuration SHALL parameterize each Site's infrastructure using the Site's identifier, production domain, and other Site-specific variables from the Site_Registry.
3. WHEN a new Site is added to the Site_Registry, THE Terragrunt_Configuration SHALL allow provisioning that Site's complete infrastructure by adding a new Terragrunt environment directory with site-specific variables.
4. THE Terragrunt_Module for Production_Bucket SHALL configure the bucket for static website hosting with `index.html` as the default index document and `404.html` as the error document.
5. THE Terragrunt_Module for CloudFront_Distribution SHALL configure the distribution to serve content from the Site's Production_Bucket using an Origin Access Identity to keep the bucket private.
6. THE Terragrunt_Module for CloudFront_Distribution SHALL configure the distribution with the Site's custom domain and www subdomain.
7. THE Terragrunt_Module for CloudFront_Distribution SHALL enforce HTTPS by redirecting HTTP requests to HTTPS.
8. THE Terragrunt_Module for CloudFront_Distribution SHALL use an ACM certificate for the Site's domain, provisioned in us-east-1 as required by CloudFront.
9. THE Terragrunt_Module for Preview_Bucket SHALL configure the bucket for S3 static website hosting to serve preview deployments for the Site.
10. THE Terragrunt_Module for IAM policy SHALL scope permissions to only the S3 buckets and CloudFront distributions belonging to the specific Site.
11. THE Terragrunt_Configuration SHALL use a DRY (Don't Repeat Yourself) structure where common settings are inherited and only site-specific values are defined per environment.

### Requirement 9: Jekyll Configuration for Production Domains

**User Story:** As a blog owner, I want each Jekyll site to be configured for its own production domain, so that all generated URLs and links are correct in production.

#### Acceptance Criteria

1. THE Pipeline SHALL build each Site's production output with `url` set to the Site's production domain (from the Site_Registry) and `baseurl` set to an empty string.
2. WHEN building a Site for a Preview_Environment, THE Pipeline SHALL set the `baseurl` to the preview path prefix so that asset and link URLs resolve correctly in the preview.
3. EACH Site's `_config.yml` SHALL define the site `url` matching the Site's production domain and `baseurl` as an empty string for production use.

### Requirement 10: GitHub Actions Secrets and Permissions

**User Story:** As a blog owner, I want AWS credentials to be securely managed, so that the Pipeline can deploy all sites without exposing sensitive information.

#### Acceptance Criteria

1. THE Pipeline SHALL authenticate to AWS using credentials stored in GitHub Actions secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION).
2. THE Pipeline SHALL reference S3 bucket names and CloudFront distribution IDs from the Site_Registry or GitHub Actions secrets/environment variables, not hardcoded values.
3. THE Pipeline SHALL use the principle of least privilege by requiring only s3:PutObject, s3:DeleteObject, s3:ListBucket, and cloudfront:CreateInvalidation permissions scoped to the relevant Site's resources.

### Requirement 11: Pipeline Status Reporting

**User Story:** As a PR_Author, I want clear feedback on the pipeline status for each affected site, so that I know whether my pull request is ready to merge.

#### Acceptance Criteria

1. WHEN all Quality_Gate checks and the preview deployment succeed for all affected Sites in a pull request, THE Pipeline SHALL report an overall successful status on the pull request.
2. IF any Quality_Gate check fails for any Site in a pull request, THEN THE Pipeline SHALL report a failed status on the pull request and prevent the preview deployment from proceeding for that Site.
3. THE Pipeline SHALL provide distinct GitHub Actions check names for each stage and each Site (e.g., `build/blog`, `html-validation/sales`, `deploy/blog`) so that the PR_Author can identify which stage and which Site failed.
4. WHEN the Change_Detection determines no Sites are affected, THE Pipeline SHALL report a successful status indicating no sites required building or deployment.
