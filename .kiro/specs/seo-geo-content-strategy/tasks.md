# Implementation Plan: SEO & GEO Content Strategy System

## Overview

This plan implements the SEO and GEO content strategy system for the multi-site Jekyll repository (perfectsystem.pl, o14.pl). Tasks are ordered incrementally: site registry and keyword registry first, then editorial guidelines, then Jekyll layouts and includes for both sites, then site config updates, then validation scripts, then CI/CD integration, and finally sample content to validate the full system. Validation scripts use `grep`, `jq`, and `yq` — the same tooling as the existing `pipeline-utils.sh`.

## Tasks

- [x] 1. Extend site registry and create keyword registry
  - [x] 1.1 Update `sites.yml` to add `lang` and `audience_segment` fields to each site entry
    - Add `lang: pl` and `audience_segment: startups` to the `blog` entry
    - Add `lang: pl` and `audience_segment: enterprise` to the `o14` entry
    - Preserve all existing fields (`id`, `source_dir`, `domain`, `preview_bucket`, `production_bucket`, `cloudfront_distribution_id`, `terragrunt_env`)
    - _Requirements: 2.2, 9.1_

  - [x] 1.2 Create `keywords.yml` at the repository root with initial keyword entries
    - Define the `keywords` array with at least 4 entries spanning 2 clusters, both sites, and multiple search intents
    - Each entry must have: `keyword`, `cluster`, `site_id`, `language`, `audience_segment`, `search_intent`, `status`
    - Include at least one `published` entry with `target_url` and one `planned` entry without `target_url`
    - _Requirements: 10.1, 10.3, 10.5_

- [x] 2. Create editorial guidelines document
  - [x] 2.1 Create `CONTENT_GUIDELINES.md` at the repository root
    - Define minimum word counts per content type: blog post 1200, pillar page 2500, landing page 600
    - Define heading structure rules (H1 once, H2/H3 hierarchical, no skipped levels)
    - Define image alt text requirements
    - Define internal linking minimums (at least 3 internal links per page)
    - Define backlink placement guidelines (varied anchor text, contextual placement, 40-80% ratio)
    - Define GEO content structure rules (summary paragraph after H1, FAQ section, definitions, sources)
    - _Requirements: 13.4_

- [x] 3. Create Jekyll layouts for both sites
  - [x] 3.1 Create `default.html` layout for blog site (`sites/blog/_layouts/default.html`)
    - Replace existing default layout with SEO/GEO-aware version
    - Set `<html lang="{{ site.lang }}">` attribute
    - Include `jekyll-seo-tag` for meta tags, canonical, OG, Twitter Card
    - Include `{% include hreflang.html %}` in `<head>`
    - Include `{% include jsonld.html %}` in `<head>`
    - Support `noindex` front matter field rendering `<meta name="robots" content="noindex, follow">`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 9.2, 14.1, 14.2_

  - [x] 3.2 Create `post.html` layout for blog site (`sites/blog/_layouts/post.html`)
    - Extend `default` layout
    - Include `{% include geo-summary.html %}` after H1
    - Render article body content
    - Include `{% include backlink-cta.html %}` after content
    - Include `{% include faq.html %}` if `page.faq` is defined
    - Front matter schema comment block documenting required/optional fields
    - _Requirements: 5.1, 7.1, 7.4, 8.1, 8.3, 13.1, 13.2_

  - [x] 3.3 Create `pillar.html` layout for blog site (`sites/blog/_layouts/pillar.html`)
    - Extend `default` layout
    - Include `{% include geo-summary.html %}` after H1
    - Include `{% include cluster-toc.html %}` for auto-generated cluster TOC
    - Render article body content
    - Include `{% include faq.html %}` if `page.faq` is defined
    - _Requirements: 1.3, 1.4, 5.1, 7.1, 7.4, 13.1_

  - [x] 3.4 Create `landing.html` layout for blog site (`sites/blog/_layouts/landing.html`)
    - Extend `default` layout
    - Include `{% include geo-summary.html %}` after H1
    - Render content body
    - Include `{% include backlink-cta.html %}` after content
    - _Requirements: 5.2, 7.1, 8.3, 13.1_

  - [x] 3.5 Create `product.html` layout for blog site (`sites/blog/_layouts/product.html`)
    - Extend `default` layout
    - Include `{% include geo-summary.html %}` after H1
    - Render content body with service-focused structure
    - _Requirements: 5.2, 13.1_

  - [x] 3.6 Create `info.html` layout for blog site (`sites/blog/_layouts/info.html`)
    - Extend `default` layout
    - Include `{% include breadcrumbs.html %}`
    - Include `{% include geo-summary.html %}` after H1
    - Render content body
    - _Requirements: 5.4, 13.1_

  - [x] 3.7 Create all layouts for o14 site (`sites/o14/_layouts/`)
    - Create `default.html`, `post.html`, `pillar.html`, `landing.html`, `product.html`, `info.html`
    - Same structure as blog layouts but with enterprise audience styling/voice hooks
    - _Requirements: 2.3, 13.1, 14.4_

- [x] 4. Create Jekyll includes for both sites
  - [x] 4.1 Create `jsonld.html` include for blog site (`sites/blog/_includes/jsonld.html`)
    - Render Article JSON-LD for `post` and `pillar` layouts (headline, author, datePublished, dateModified, publisher, description, mainEntityOfPage, image)
    - Render WebPage JSON-LD for `landing` and `product` layouts
    - Render Organization JSON-LD on home page only (name, url, logo, sameAs, contactPoint)
    - Render BreadcrumbList JSON-LD on all non-home pages
    - Render FAQPage JSON-LD when `page.faq` is defined
    - Render DefinedTerm JSON-LD when `page.definitions` is defined
    - Use templates from design document Data Models section
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 7.3_

  - [x] 4.2 Create `hreflang.html` include for blog site (`sites/blog/_includes/hreflang.html`)
    - Render self-referencing hreflang `<link>` for current page's language
    - Iterate `page.devopsity_translations` map and render hreflang `<link>` for each language variant
    - _Requirements: 9.3, 9.4_

  - [x] 4.3 Create `breadcrumbs.html` include for blog site (`sites/blog/_includes/breadcrumbs.html`)
    - Render visible breadcrumb navigation with Home > Category/Type > Page Title
    - BreadcrumbList JSON-LD is handled by `jsonld.html`
    - _Requirements: 5.4_

  - [x] 4.4 Create `faq.html` include for blog site (`sites/blog/_includes/faq.html`)
    - Render FAQ section using `<details>` and `<summary>` HTML elements from `page.faq` array
    - Each FAQ item renders question in `<summary>` and answer in the details body
    - _Requirements: 7.4_

  - [x] 4.5 Create `backlink-cta.html` include for blog site (`sites/blog/_includes/backlink-cta.html`)
    - Render `<aside class="cta-block" role="complementary">` with configurable text from `site.backlink_cta`
    - Support per-page override via `page.backlink_target` and `page.backlink_anchor`
    - _Requirements: 8.1, 8.2, 8.3, 8.7_

  - [x] 4.6 Create `geo-summary.html` include for blog site (`sites/blog/_includes/geo-summary.html`)
    - Render the GEO-optimized summary paragraph block from `page.summary` front matter field
    - Wrap in a semantic `<div class="geo-summary">` element
    - _Requirements: 7.1_

  - [x] 4.7 Create `cluster-toc.html` include for blog site (`sites/blog/_includes/cluster-toc.html`)
    - Auto-generate table of contents for pillar pages by querying all site pages/documents with matching `cluster` front matter value
    - Render as a list of links to each cluster page
    - _Requirements: 1.3, 1.4_

  - [x] 4.8 Copy all includes to o14 site (`sites/o14/_includes/`)
    - Create `jsonld.html`, `hreflang.html`, `breadcrumbs.html`, `faq.html`, `backlink-cta.html`, `geo-summary.html`, `cluster-toc.html` in `sites/o14/_includes/`
    - Same logic as blog includes
    - _Requirements: 14.3_

- [x] 5. Checkpoint — Review layouts and includes
  - Ensure all layout and include files have valid Liquid syntax, correct include references, and proper JSON-LD templates. Ask the user if questions arise.

- [x] 6. Update site `_config.yml` files with SEO/GEO configuration
  - [x] 6.1 Update `sites/blog/_config.yml` with SEO/GEO configuration
    - Add `lang: pl` and `audience_segment: startups`
    - Add `author` map with `name` and `twitter` fields
    - Add `twitter` config (`username`, `card: summary_large_image`)
    - Add `social.links` array
    - Add `tracking.google_site_verification` field
    - Add `backlink_cta` config (`text`, `url`) pointing to devopsity.com
    - Add `main_sales_page: "https://devopsity.com"`
    - Add `defaults` section with permalink patterns per content type (posts, landing, products, info)
    - Add `collections` for `landing`, `products`, `info`, `pillars` (all with `output: true`)
    - Ensure plugins include `jekyll-seo-tag`, `jekyll-sitemap`, `jekyll-feed`, `jekyll-paginate`
    - _Requirements: 2.1, 3.1, 8.3, 9.1, 11.1, 14.1, 14.2, 14.5_

  - [x] 6.2 Update `sites/o14/_config.yml` with SEO/GEO configuration
    - Add `lang: pl` and `audience_segment: enterprise`
    - Add same SEO/GEO config structure as blog but with o14-specific values (different audience, different backlink CTA text)
    - Add `defaults`, `collections`, `tracking`, `backlink_cta`, `main_sales_page`
    - _Requirements: 2.1, 3.1, 9.1, 11.1, 14.1, 14.2_

- [x] 7. Create robots.txt template for each site
  - [x] 7.1 Create `sites/blog/robots.txt` as a Jekyll-processed file
    - Reference `{{ site.url }}/sitemap.xml`
    - Allow all crawlers on all indexable paths
    - _Requirements: 6.2_

  - [x] 7.2 Create `sites/o14/robots.txt` as a Jekyll-processed file
    - Same structure as blog robots.txt with o14-specific URL
    - _Requirements: 6.2_

- [x] 8. Create SEO validation script
  - [x] 8.1 Create `scripts/seo-validate.sh`
    - Accept built `_site/` directory as argument
    - For each HTML file, check: `<title>` tag present, title length (30-60 chars), `<meta name="description">` present, description length (120-160 chars), canonical tag present, OG tags present (`og:title`, `og:description`, `og:type`, `og:url`), Twitter Card tags present, JSON-LD `<script type="application/ld+json">` block present, JSON-LD valid JSON syntax (via `jq`), internal link count
    - Compute per-page score as (passed_checks / total_checks × 100)
    - Flag pages scoring below 80%
    - Check backlink anchor text variety (no phrase on >2 pages per site)
    - Check backlink ratio (40-80% of pages with backlinks)
    - Check backlink placement (only within `<article>` or `<main>`, not in `<aside>`, `<footer>`, `<nav>`)
    - Output `seo-scorecard.json` following the schema from the design document
    - Exit non-zero if any required check fails (missing title, missing description, invalid JSON-LD)
    - Use `grep`, `jq` for processing — same tooling as `pipeline-utils.sh`
    - _Requirements: 4.1, 4.2, 4.6, 5.6, 8.4, 8.5, 8.6, 8.7, 8.8, 11.2, 11.3, 11.4, 15.1, 15.4, 15.5_

  - [ ]* 8.2 Write property test: SEO metadata length validation (Property 6)
    - **Property 6: SEO metadata length validation**
    - **Validates: Requirements 4.1, 4.2**

  - [ ]* 8.3 Write property test: JSON-LD syntax validation (Property 7)
    - **Property 7: JSON-LD syntax validation**
    - **Validates: Requirements 5.6**

  - [ ]* 8.4 Write property test: Backlink validation — anchor variety, ratio, placement (Property 11)
    - **Property 11: Backlink validation**
    - **Validates: Requirements 8.5, 8.6, 8.7, 8.8**

  - [ ]* 8.5 Write property test: Scorecard scoring correctness (Property 17)
    - **Property 17: Scorecard scoring correctness**
    - **Validates: Requirements 11.3, 12.2**

  - [ ]* 8.6 Write property test: Scorecard JSON schema compliance (Property 18)
    - **Property 18: Scorecard JSON schema compliance**
    - **Validates: Requirements 11.4, 12.3**

  - [ ]* 8.7 Write property test: SEO validation element detection (Property 19)
    - **Property 19: SEO/GEO validation element detection**
    - **Validates: Requirements 15.1, 15.2**

- [ ] 9. Create GEO validation script
  - [x] 9.1 Create `scripts/geo-validate.sh`
    - Accept built `_site/` directory as argument
    - For each HTML file, check: summary paragraph present after H1, heading hierarchy (no skipped levels H1→H3 without H2), FAQ presence (via `<details>` elements or JSON-LD FAQPage), word count meets minimum for content type (blog 1200, pillar 2500, landing 600), definitions section present (via `<dfn>` elements)
    - Compute per-page GEO score as (passed_geo_checks / total_geo_checks × 100)
    - Flag pages scoring below 70%
    - Output `geo-scorecard.json` following the schema from the design document
    - Exit non-zero if any required GEO check fails
    - Use `grep`, `jq` for processing
    - _Requirements: 7.2, 7.6, 12.1, 12.2, 12.3, 13.5, 15.2, 15.4, 15.5_

  - [ ]* 9.2 Write property test: Heading hierarchy validation (Property 9)
    - **Property 9: Heading hierarchy validation**
    - **Validates: Requirements 7.2**

  - [ ]* 9.3 Write property test: Word count validation (Property 20)
    - **Property 20: Word count validation**
    - **Validates: Requirements 13.5**

- [ ] 10. Create content audit script
  - [x] 10.1 Create `scripts/content-audit.sh`
    - Accept `keywords.yml` path and site source directory as arguments
    - Cross-reference published content against keyword registry
    - Report per-cluster summary: published, in-progress, planned counts, coverage percentage
    - Detect content gaps (keywords with `status: planned` and no `target_url`)
    - Detect orphaned content (published pages whose keyword is not in the registry)
    - Detect keyword cannibalization (two pages on same site targeting same keyword)
    - Output `content-audit.json` (machine-readable) and `content-audit.md` (human-readable Markdown table)
    - Use `yq`, `jq`, `grep` for processing
    - _Requirements: 10.2, 10.4, 10.5, 16.1, 16.2, 16.3, 16.4_

  - [ ]* 10.2 Write property test: Content gap detection (Property 16)
    - **Property 16: Content gap detection**
    - **Validates: Requirements 10.5**

  - [ ]* 10.3 Write property test: Content audit coverage calculation (Property 21)
    - **Property 21: Content audit coverage calculation**
    - **Validates: Requirements 16.1, 16.2**

  - [ ]* 10.4 Write property test: Orphaned content detection (Property 22)
    - **Property 22: Orphaned content detection**
    - **Validates: Requirements 16.3**

  - [ ]* 10.5 Write property test: Keyword cannibalization detection (Property 15)
    - **Property 15: Keyword cannibalization detection**
    - **Validates: Requirements 10.4**

- [x] 11. Checkpoint — Review validation scripts
  - Ensure all three validation scripts (`seo-validate.sh`, `geo-validate.sh`, `content-audit.sh`) are executable, produce valid JSON output, and handle edge cases (empty site, missing files). Ask the user if questions arise.

- [x] 12. Integrate validation scripts into CI/CD pipeline
  - [x] 12.1 Add SEO and GEO validation steps to `.github/workflows/pr-pipeline.yml`
    - Add `SEO Validation` step after existing html-proofer steps in the `build-and-validate` job: `bash scripts/seo-validate.sh ./_site/`
    - Add `GEO Validation` step after SEO validation: `bash scripts/geo-validate.sh ./_site/`
    - Add `Content Audit` step: `bash scripts/content-audit.sh keywords.yml ${{ matrix.site.source_dir }}`
    - Upload scorecard JSON artifacts for dashboard consumption
    - _Requirements: 15.3, 15.5_

  - [x] 12.2 Add SEO and GEO validation steps to `.github/workflows/production-pipeline.yml`
    - Add same `SEO Validation`, `GEO Validation`, and `Content Audit` steps to the `build-and-validate` job
    - Upload scorecard JSON artifacts
    - _Requirements: 15.3, 15.5_

- [ ] 13. Create sample content to validate the full system
  - [x] 13.1 Create a sample pillar page for blog site (`sites/blog/_pillars/migracja-do-chmury.md`)
    - Use `pillar` layout with full front matter (title, description, author, date, lang, content_type, cluster, keywords, summary, faq, devopsity_translations)
    - Include 2500+ words of content with proper heading hierarchy, summary paragraph, FAQ section, definitions, sources
    - _Requirements: 1.1, 1.2, 1.3, 7.1, 7.2, 7.3, 7.4, 7.5, 13.3_

  - [x] 13.2 Create a sample cluster blog post for blog site (`sites/blog/_posts/2024-01-15-migracja-do-aws.md`)
    - Use `post` layout with full front matter including `backlink_target`, `backlink_anchor`, `cluster`, `faq`, `summary`
    - Include 1200+ words with proper structure, backlink placement, internal link to pillar page
    - _Requirements: 1.1, 1.2, 7.1, 8.1, 8.2, 13.3_

  - [ ] 13.3 Create a sample pillar page for o14 site (`sites/o14/_pillars/cloud-strategy-enterprise.md`)
    - Use `pillar` layout with enterprise-audience-appropriate content and front matter
    - _Requirements: 1.1, 2.3, 13.3_

  - [ ] 13.4 Create a sample cluster blog post for o14 site (`sites/o14/_posts/2024-01-15-enterprise-cloud-migration.md`)
    - Use `post` layout with enterprise-focused content, backlink, and full front matter
    - _Requirements: 1.1, 2.3, 8.1, 13.3_

  - [x] 13.5 Create collection directories for both sites
    - Create `sites/blog/_pillars/`, `sites/blog/_landing/`, `sites/blog/_products/`, `sites/blog/_info/` directories (with `.gitkeep` if empty)
    - Create `sites/o14/_pillars/`, `sites/o14/_landing/`, `sites/o14/_products/`, `sites/o14/_info/`, `sites/o14/_posts/` directories
    - _Requirements: 14.4_

- [x] 14. Checkpoint — Validate full system end-to-end
  - Ensure all layouts, includes, configs, validation scripts, and sample content work together. Verify `sites.yml` and `keywords.yml` are consistent. Verify CI/CD pipeline files reference the new validation steps correctly. Ask the user if questions arise.

- [ ]* 15. Write remaining property tests for content validation logic
  - [ ]* 15.1 Write property test: Front matter required fields validation (Property 1)
    - **Property 1: Front matter required fields validation**
    - **Validates: Requirements 1.2, 4.6**

  - [ ]* 15.2 Write property test: Cluster reference validation (Property 2)
    - **Property 2: Cluster reference validation**
    - **Validates: Requirements 1.5**

  - [ ]* 15.3 Write property test: Pillar page cluster TOC completeness (Property 3)
    - **Property 3: Pillar page cluster TOC completeness**
    - **Validates: Requirements 1.4**

  - [ ]* 15.4 Write property test: Duplicate audience segment detection (Property 4)
    - **Property 4: Duplicate audience segment detection**
    - **Validates: Requirements 2.5**

  - [ ]* 15.5 Write property test: URL collision detection (Property 5)
    - **Property 5: URL collision detection**
    - **Validates: Requirements 3.4**

  - [ ]* 15.6 Write property test: FAQ rendering round-trip (Property 8)
    - **Property 8: FAQ rendering round-trip**
    - **Validates: Requirements 5.5, 7.4**

  - [ ]* 15.7 Write property test: Definitions rendering (Property 10)
    - **Property 10: Definitions rendering**
    - **Validates: Requirements 7.3**

  - [ ]* 15.8 Write property test: Backlink target and anchor rendering (Property 12)
    - **Property 12: Backlink target and anchor rendering**
    - **Validates: Requirements 8.2**

  - [ ]* 15.9 Write property test: Hreflang rendering from devopsity_translations (Property 13)
    - **Property 13: Hreflang rendering from devopsity_translations**
    - **Validates: Requirements 9.3, 9.4**

  - [ ]* 15.10 Write property test: Keyword registry cross-reference validation (Property 14)
    - **Property 14: Keyword registry cross-reference validation**
    - **Validates: Requirements 10.2**

- [x] 16. Final checkpoint — Full review
  - Ensure all files are consistent, validation scripts produce correct JSON scorecards, CI/CD pipelines include SEO/GEO steps, sample content passes all validation checks, and the system is ready for content production. Ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate the 22 correctness properties from the design document
- Validation scripts use `grep`, `jq`, `yq` — same tooling as the existing `pipeline-utils.sh`
- Jekyll layouts and includes are per-site (not shared) to allow audience-specific customization
- The existing blog `default.html` and `post.html` layouts will be replaced with SEO/GEO-aware versions
- CI/CD integration adds steps to existing workflow files, not new workflows
