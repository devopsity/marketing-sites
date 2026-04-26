# Requirements Document

## Introduction

This document defines the requirements for a comprehensive SEO and GEO (Generative Engine Optimization) content strategy system for a network of satellite sites (perfectsystem.pl, o14.pl, and future domains) that support lead generation for the main sales page devopsity.com. The system covers content architecture with audience-segment-based differentiation, technical SEO foundations, GEO optimization for LLM citation, risk-aware backlink strategy, simplified single-language satellite sites with cross-domain hreflang linking, keyword planning, build-time scorecard generation, content production processes, Jekyll configuration, and supporting tooling. All sites are Jekyll-based, deployed via GitHub Actions CI/CD to AWS S3/CloudFront, and managed within a single multi-site repository.

## Glossary

- **Satellite_Site**: A Jekyll-based website (e.g., perfectsystem.pl, o14.pl) in the multi-site repository that provides high-quality content and strategic backlinks to the Main_Sales_Page. Each satellite site targets a single language and a specific Audience_Segment.
- **Main_Sales_Page**: devopsity.com — the primary commercial website offering cloud migrations, managed cloud services, and GenAI-supported tooling. Has a working multilingual Jekyll hreflang structure (English at root, Polish at /pl/, with /de/ and /es/ planned).
- **Audience_Segment**: A distinct target audience profile assigned to a Satellite_Site (e.g., startups, SMBs, enterprise, specific verticals). Each satellite site focuses on a different segment to ensure genuinely distinct content and identity.
- **Content_Cluster**: A group of related content pieces organized around a Pillar_Page and supporting Cluster_Pages, targeting a specific topic area
- **Pillar_Page**: A comprehensive, long-form page that covers a broad topic and links to all related Cluster_Pages within the same Content_Cluster
- **Cluster_Page**: A focused content piece (blog post, landing page, or informational page) that covers a specific subtopic within a Content_Cluster and links back to the Pillar_Page
- **Content_Type**: A classification of page purpose — one of: blog post, landing page, product page, or informational page — each with its own layout, front matter schema, and URL pattern
- **Keyword_Registry**: A structured YAML file that maps target keywords to Content_Clusters, Satellite_Sites, languages, audience segments, and search intent
- **SEO_Metadata**: The set of HTML meta tags, structured data, and link elements required for search engine optimization on each page (title, description, canonical, Open Graph, Twitter Card, JSON-LD)
- **Structured_Data**: JSON-LD markup embedded in page HTML that provides machine-readable entity and content information to search engines and LLMs
- **GEO_Markup**: Content formatting and structural patterns (clear factual statements, entity definitions, authoritative citations, FAQ sections) designed to increase the likelihood of LLM citation
- **Hreflang_Tag**: An HTML link element that declares the language and geographic targeting of a page and points to equivalent pages on devopsity.com language variants
- **Backlink_Placement**: A contextual hyperlink within Satellite_Site content that points to the Main_Sales_Page, placed within relevant editorial content with natural, varied anchor text
- **Content_Template**: A Jekyll layout and front matter schema that enforces SEO_Metadata, Structured_Data, and GEO_Markup requirements for a specific Content_Type
- **Quality_Gate**: An automated check in the CI/CD pipeline that validates SEO and GEO compliance of content before deployment
- **SEO_Scorecard**: A per-page JSON report generated during build that evaluates compliance with SEO_Metadata, Structured_Data, internal linking, and keyword targeting requirements — consumable by the existing external dashboard
- **GEO_Scorecard**: A per-page JSON report generated during build that evaluates compliance with GEO_Markup requirements (factual statements, entity markup, FAQ presence, citation formatting) — consumable by the existing external dashboard
- **Site_Config**: The `_config.yml` file for a specific Satellite_Site that defines site-wide SEO settings, plugin configuration, default metadata, audience segment, and language
- **Content_Front_Matter**: The YAML front matter block at the top of each content file that defines page-level metadata (title, description, keywords, content type, cluster assignment, language, author, backlink configuration)
- **Sitemap**: An XML file generated during Jekyll build that lists all indexable pages on a Satellite_Site with their last modification dates and change frequencies
- **Robots_Txt**: A text file at the site root that instructs search engine crawlers on which paths to index and references the Sitemap location
- **Canonical_Tag**: An HTML link element that declares the preferred URL for a page, preventing duplicate content issues
- **Internal_Link**: A hyperlink within a Satellite_Site that connects one page to another page on the same site, supporting Content_Cluster structure and SEO link equity distribution
- **Cross_Domain_Link**: A hyperlink that connects content on a Satellite_Site to the appropriate language version of devopsity.com

## Requirements

### Requirement 1: Content Architecture and Topic Clusters

**User Story:** As a content strategist, I want content organized into topic clusters with pillar pages and supporting cluster pages, so that search engines and LLMs recognize topical authority and users find comprehensive coverage of each subject.

#### Acceptance Criteria

1. THE Content_Cluster SHALL consist of exactly one Pillar_Page and one or more Cluster_Pages, where each Cluster_Page links back to the Pillar_Page and the Pillar_Page links to all its Cluster_Pages.
2. WHEN a new content piece is created, THE Content_Front_Matter SHALL declare the Content_Cluster assignment, Content_Type, target keyword from the Keyword_Registry, and language code.
3. THE Pillar_Page SHALL use a dedicated Jekyll layout that renders a table of contents linking to all associated Cluster_Pages within the same Content_Cluster.
4. WHEN a Cluster_Page is added to a Content_Cluster, THE Pillar_Page SHALL automatically include a link to the new Cluster_Page in its table of contents during Jekyll build.
5. IF a content piece references a Content_Cluster that does not exist in the Keyword_Registry, THEN THE Quality_Gate SHALL report a validation error identifying the undefined cluster.

### Requirement 2: Audience-Segment-Based Content Differentiation

**User Story:** As a site owner, I want each satellite site to target a different audience segment with genuinely distinct content and identity, so that the sites are not perceived as duplicates by search engines and each provides unique value to its audience.

#### Acceptance Criteria

1. THE Site_Config SHALL include an `audience_segment` field that defines the target audience for the Satellite_Site (e.g., "startups", "smb", "enterprise", "vertical-fintech").
2. THE sites.yml Site Registry SHALL include an `audience_segment` field for each Satellite_Site entry, matching the value in the corresponding Site_Config.
3. WHEN content is created for a Satellite_Site, THE Content_Front_Matter SHALL reflect the site's Audience_Segment in tone, examples, and use cases appropriate to that segment.
4. THE Keyword_Registry SHALL include an `audience_segment` field per entry, allowing keyword targeting to be scoped by audience segment.
5. IF two Satellite_Sites share the same `audience_segment` value in sites.yml, THEN THE Quality_Gate SHALL report a warning identifying the duplicate audience segments.

### Requirement 3: Flexible URL Structures

**User Story:** As a site owner, I want flexible URL path structures that support blog posts, landing pages, product pages, and informational pages, so that the site can grow beyond a flat blog structure.

#### Acceptance Criteria

1. THE Site_Config SHALL define permalink patterns per Content_Type: blog posts as `/:categories/:title/`, landing pages as `/:title/`, product pages as `/services/:title/`, and informational pages as `/info/:title/`.
2. WHEN a content piece specifies a Content_Type in its Content_Front_Matter, THE Jekyll build SHALL generate the URL using the permalink pattern defined for that Content_Type.
3. THE Site_Config SHALL support custom permalink overrides in Content_Front_Matter, allowing individual pages to define a `permalink` field that takes precedence over the Content_Type default.
4. IF a generated URL conflicts with an existing page URL on the same Satellite_Site, THEN THE Quality_Gate SHALL report a URL collision error identifying both pages.

### Requirement 4: SEO Technical Foundation — Metadata and Tags

**User Story:** As a site owner, I want every page to include complete SEO metadata (title tags, meta descriptions, canonical URLs, Open Graph tags, Twitter Cards), so that search engines and social platforms display content correctly.

#### Acceptance Criteria

1. THE Content_Template SHALL render an HTML `<title>` element containing the page title followed by a separator and the site name, with a total length between 30 and 60 characters.
2. THE Content_Template SHALL render a `<meta name="description">` tag with content between 120 and 160 characters, sourced from the `description` field in Content_Front_Matter.
3. THE Content_Template SHALL render a Canonical_Tag with the full absolute URL of the page, using the site's production domain.
4. THE Content_Template SHALL render Open Graph meta tags (`og:title`, `og:description`, `og:type`, `og:url`, `og:image`, `og:locale`) sourced from Content_Front_Matter and Site_Config defaults.
5. THE Content_Template SHALL render Twitter Card meta tags (`twitter:card`, `twitter:title`, `twitter:description`, `twitter:image`) sourced from Content_Front_Matter and Site_Config defaults.
6. IF a content piece is missing a required SEO_Metadata field (title, description), THEN THE Quality_Gate SHALL report a validation error identifying the page and the missing field.

### Requirement 5: SEO Technical Foundation — Structured Data (JSON-LD)

**User Story:** As a site owner, I want structured data (JSON-LD) embedded in every page, so that search engines understand the content type, authorship, and organization behind the site.

#### Acceptance Criteria

1. THE Content_Template for blog posts SHALL render a JSON-LD `Article` schema including `headline`, `author`, `datePublished`, `dateModified`, `publisher`, `description`, `mainEntityOfPage`, and `image` properties.
2. THE Content_Template for landing pages and product pages SHALL render a JSON-LD `WebPage` schema including `name`, `description`, `url`, and `publisher` properties.
3. THE Content_Template SHALL render a JSON-LD `Organization` schema on the site's home page, including `name`, `url`, `logo`, `sameAs` (social profiles), and `contactPoint` properties.
4. THE Content_Template SHALL render a JSON-LD `BreadcrumbList` schema on all pages except the home page, reflecting the page's position in the site hierarchy.
5. WHEN a content piece includes an FAQ section marked with a `faq` front matter field, THE Content_Template SHALL render a JSON-LD `FAQPage` schema with each question-answer pair.
6. IF the JSON-LD output for a page contains invalid JSON syntax, THEN THE Quality_Gate SHALL report a structured data validation error identifying the page.

### Requirement 6: SEO Technical Foundation — Sitemaps, Robots, and Crawl Directives

**User Story:** As a site owner, I want automatically generated XML sitemaps and robots.txt files, so that search engines can efficiently discover and index all pages.

#### Acceptance Criteria

1. THE Jekyll build SHALL generate an XML Sitemap at `/sitemap.xml` listing all indexable pages on the Satellite_Site with `<lastmod>`, `<changefreq>`, and `<priority>` elements.
2. THE Jekyll build SHALL generate a Robots_Txt file at `/robots.txt` that references the Sitemap URL and allows crawling of all indexable paths.
3. WHEN a content piece sets `noindex: true` in its Content_Front_Matter, THE Jekyll build SHALL exclude that page from the Sitemap and render a `<meta name="robots" content="noindex, follow">` tag.
4. THE Sitemap SHALL include only pages with HTTP 200 status (valid content) and exclude pagination pages, tag pages, and category archive pages unless explicitly configured for indexing.

### Requirement 7: GEO Optimization — Content Structure for LLM Citation

**User Story:** As a content strategist, I want content structured in a way that LLMs can easily parse, cite, and reference, so that the satellite sites appear as authoritative sources in AI-generated responses.

#### Acceptance Criteria

1. THE Content_Template SHALL enforce a content structure that begins with a concise summary paragraph (2-4 sentences) stating the key facts of the page, placed immediately after the H1 heading.
2. THE Content_Template SHALL render content with clear hierarchical headings (H2, H3) where each section begins with a factual topic sentence suitable for LLM extraction.
3. WHEN a content piece includes a `definitions` field in Content_Front_Matter, THE Content_Template SHALL render a definitions section with `<dfn>` HTML elements and corresponding JSON-LD `DefinedTerm` schema markup.
4. THE Content_Template SHALL render an FAQ section at the end of each Pillar_Page and Cluster_Page, using `<details>` and `<summary>` HTML elements and corresponding JSON-LD `FAQPage` schema.
5. WHEN a content piece includes statistical claims or factual assertions, THE Content_Front_Matter SHALL include a `sources` field listing citation URLs, and THE Content_Template SHALL render these as a numbered references section with hyperlinks.
6. THE GEO_Scorecard SHALL verify that each content piece contains a summary paragraph, hierarchical headings, and at least one FAQ entry, reporting non-compliance as a warning during build.

### Requirement 8: Risk-Aware Backlink Strategy — Satellite to Main Sales Page

**User Story:** As a site owner, I want satellite sites to include strategic, contextual backlinks to devopsity.com that feel natural and editorial, so that the main sales page gains domain authority and referral traffic without risking Google penalties.

#### Acceptance Criteria

1. THE Content_Template SHALL render a contextual Backlink_Placement section within the body of each Cluster_Page, containing a relevant editorial paragraph with a hyperlink to a specific page on the Main_Sales_Page.
2. WHEN a content piece specifies a `backlink_target` URL and `backlink_anchor` text in Content_Front_Matter, THE Content_Template SHALL render the Backlink_Placement using the specified target URL and anchor text.
3. THE Content_Template SHALL render a call-to-action block at the end of each blog post and landing page, linking to the Main_Sales_Page with configurable text defined in Site_Config.
4. THE Quality_Gate SHALL verify that each Cluster_Page contains at least one Backlink_Placement to the Main_Sales_Page, reporting missing backlinks as a warning.
5. THE Backlink_Placement SHALL use varied anchor text across pages to avoid over-optimization patterns. Anchor text SHALL NOT repeat the same exact phrase on more than 2 pages within the same Satellite_Site.
6. WHILE the Satellite_Site contains more than five published Cluster_Pages, THE site-wide ratio of pages with Backlink_Placements to total pages SHALL remain between 40% and 80%.
7. THE Backlink_Placement SHALL appear within contextually relevant editorial content (not in sidebars, footers, or boilerplate sections) to maintain a natural, non-spammy link profile.
8. THE Quality_Gate SHALL verify that anchor text across all pages on a Satellite_Site is sufficiently varied, reporting a warning if any single anchor text phrase is used on more than 2 pages.

### Requirement 9: Simplified Multilingual Support — Single-Language Satellites with Cross-Domain Hreflang

**User Story:** As a site owner, I want each satellite site to operate in a single language with hreflang tags pointing to devopsity.com's language variants, so that search engines understand the language relationships across domains without the complexity of per-site multilingual subdirectories.

#### Acceptance Criteria

1. THE Site_Config SHALL define a single `lang` field (e.g., "pl" for Polish satellite sites) that applies site-wide. Satellite sites SHALL NOT have language subdirectories.
2. THE Content_Template SHALL render an `<html lang="xx">` attribute matching the `lang` field in Site_Config.
3. WHEN a content piece specifies a `devopsity_translations` map in Content_Front_Matter (mapping language codes to full URLs on devopsity.com language variants), THE Content_Template SHALL render Hreflang_Tags for each devopsity.com language variant and a self-referencing hreflang for the current page.
4. THE Hreflang_Tags SHALL point to the appropriate language version of devopsity.com (e.g., `https://devopsity.com/` for English, `https://devopsity.com/pl/` for Polish, and future `/de/`, `/es/` variants) where equivalent content exists.
5. THE Sitemap SHALL include `<xhtml:link rel="alternate" hreflang="xx" href="..."/>` entries for each page that has `devopsity_translations` defined in Content_Front_Matter.
6. IF a translation URL specified in `devopsity_translations` is unreachable during build-time validation, THEN THE Quality_Gate SHALL report a warning identifying the broken translation link.

### Requirement 10: Keyword and Content Planning Registry

**User Story:** As a content strategist, I want a structured keyword registry that maps keywords to content clusters, sites, languages, audience segments, and search intent, so that content production is guided by data and gaps are identifiable.

#### Acceptance Criteria

1. THE Keyword_Registry SHALL be a YAML file at the repository root (`keywords.yml`) containing entries with fields: `keyword`, `cluster`, `site_id`, `language`, `audience_segment`, `search_intent` (informational, navigational, transactional, commercial), `target_url` (if published), and `status` (planned, in-progress, published).
2. WHEN a content piece references a keyword in its Content_Front_Matter, THE Quality_Gate SHALL verify that the keyword exists in the Keyword_Registry and that the `site_id`, `language`, and `audience_segment` match.
3. THE Keyword_Registry SHALL allow multiple keywords to map to the same Content_Cluster, enabling long-tail keyword coverage within a single cluster.
4. IF two content pieces on the same Satellite_Site target the same primary keyword, THEN THE Quality_Gate SHALL report a keyword cannibalization warning identifying both pages.
5. WHEN a `keywords.yml` entry has `status: planned` and no `target_url`, THE entry SHALL be treated as a content gap, and a build-time report SHALL list all content gaps grouped by Content_Cluster.

### Requirement 11: Build-Time SEO Scorecard

**User Story:** As a site owner, I want a build-time SEO scorecard that outputs JSON reports consumable by my existing dashboard, so that I can track SEO compliance without building a standalone dashboard.

#### Acceptance Criteria

1. THE Site_Config SHALL include a `tracking` section that configures Google Search Console verification meta tag for each Satellite_Site.
2. WHEN the Jekyll build completes, THE build process SHALL generate an SEO_Scorecard JSON report file listing per-page compliance with SEO_Metadata, Structured_Data, Internal_Link, and keyword targeting requirements.
3. THE SEO_Scorecard SHALL assign each page a compliance score (percentage of passed checks out of total applicable checks) and flag pages scoring below 80% as requiring attention.
4. THE SEO_Scorecard JSON output SHALL follow a consistent schema with fields: `site_id`, `build_timestamp`, `pages` (array of per-page results with `url`, `checks`, `score`, `warnings`), and `summary` (aggregate counts).

### Requirement 12: Build-Time GEO Scorecard

**User Story:** As a site owner, I want a build-time GEO scorecard that outputs JSON reports consumable by my existing dashboard, so that I can track GEO optimization alongside SEO metrics.

#### Acceptance Criteria

1. WHEN the Jekyll build completes, THE build process SHALL generate a GEO_Scorecard JSON report file listing per-page compliance with GEO_Markup requirements (summary paragraph presence, heading hierarchy, FAQ section, entity definitions, source citations).
2. THE GEO_Scorecard SHALL assign each page a GEO readiness score (percentage of passed GEO checks) and flag pages scoring below 70% as requiring GEO optimization.
3. THE GEO_Scorecard JSON output SHALL follow a consistent schema with fields: `site_id`, `build_timestamp`, `pages` (array of per-page results with `url`, `geo_checks`, `geo_score`, `warnings`), and `summary` (aggregate counts).

### Requirement 13: Content Production Process — Templates and Editorial Guidelines

**User Story:** As a content author, I want standardized content templates with clear editorial guidelines, so that every piece of content meets SEO and GEO quality standards from the start.

#### Acceptance Criteria

1. THE repository SHALL provide Content_Template files (Jekyll layouts and includes) for each Content_Type: blog post, landing page, product page, and informational page.
2. THE Content_Template for each Content_Type SHALL include a front matter schema comment block documenting all required and optional fields with their descriptions and validation rules.
3. WHEN a new content file is created using a Content_Template, THE Content_Front_Matter SHALL pre-populate required fields (layout, lang, content_type, cluster, keywords, description, author, date) with placeholder values.
4. THE repository SHALL include an editorial guidelines document (`CONTENT_GUIDELINES.md`) that defines: minimum word count per Content_Type (blog post: 1200 words, pillar page: 2500 words, landing page: 600 words), heading structure rules, image alt text requirements, internal linking minimums (at least 3 Internal_Links per page), and backlink placement guidelines.
5. IF a content piece has a word count below the minimum defined for its Content_Type, THEN THE Quality_Gate SHALL report a content length warning identifying the page and the shortfall.

### Requirement 14: Jekyll Configuration for SEO and GEO Features

**User Story:** As a developer, I want Jekyll sites configured with the necessary plugins, layouts, and includes to support all SEO and GEO features, so that content authors can focus on writing while the build system handles technical optimization.

#### Acceptance Criteria

1. THE Site_Config SHALL include the following Jekyll plugins: `jekyll-seo-tag`, `jekyll-sitemap`, `jekyll-feed`, and `jekyll-paginate`.
2. THE Site_Config SHALL define default SEO_Metadata values (`title`, `description`, `author`, `lang`, `image`) that apply to all pages unless overridden in Content_Front_Matter.
3. THE repository SHALL provide Jekyll `_includes` files for: JSON-LD structured data rendering (`_includes/jsonld.html`), hreflang tag rendering (`_includes/hreflang.html`), breadcrumb navigation (`_includes/breadcrumbs.html`), FAQ section rendering (`_includes/faq.html`), backlink CTA block (`_includes/backlink-cta.html`), and GEO summary block (`_includes/geo-summary.html`).
4. THE repository SHALL provide Jekyll `_layouts` files for each Content_Type: `post.html` (blog posts), `pillar.html` (pillar pages), `landing.html` (landing pages), `product.html` (product pages), and `info.html` (informational pages).
5. WHEN the `jekyll-seo-tag` plugin renders metadata, THE Site_Config SHALL configure it with `title`, `description`, `url`, `author`, `twitter.username`, `facebook.publisher`, `logo`, and `social.links` fields.

### Requirement 15: SEO and GEO Validation Tooling

**User Story:** As a developer, I want automated scripts that validate SEO and GEO compliance during the build process, so that non-compliant content is caught before deployment.

#### Acceptance Criteria

1. THE repository SHALL include a validation script (`scripts/seo-validate.sh`) that checks each built HTML page for: presence of `<title>` tag, `<meta name="description">` tag, Canonical_Tag, Open Graph tags, and at least one JSON-LD script block.
2. THE repository SHALL include a validation script (`scripts/geo-validate.sh`) that checks each built HTML page for: presence of a summary paragraph after the H1, hierarchical heading structure (no skipped heading levels), and presence of at least one FAQ entry (detected via `<details>` elements or JSON-LD `FAQPage` schema).
3. WHEN the CI/CD pipeline runs the Quality_Gate step for a Satellite_Site, THE pipeline SHALL execute both `seo-validate.sh` and `geo-validate.sh` against the site's build output and report results as distinct pipeline checks.
4. THE validation scripts SHALL output results in JSON format listing each page path, checks performed, pass/fail status per check, and a summary count of passed and failed checks. This JSON output serves as the SEO_Scorecard and GEO_Scorecard respectively.
5. IF any page fails a required SEO or GEO validation check, THEN THE Quality_Gate SHALL report a failed pipeline status for the affected Satellite_Site, preventing deployment.

### Requirement 16: Content Auditing and Gap Analysis Tooling

**User Story:** As a content strategist, I want tooling that audits existing content against the Keyword_Registry and identifies content gaps, so that I can prioritize content production effectively.

#### Acceptance Criteria

1. THE repository SHALL include an audit script (`scripts/content-audit.sh`) that cross-references published content (pages with `status: published` in Keyword_Registry) against the Keyword_Registry to produce a report of: covered keywords (published content exists), in-progress keywords (content being written), and gap keywords (planned but no content).
2. WHEN the audit script runs, THE output SHALL include a per-cluster summary showing the number of published, in-progress, and planned content pieces, and the percentage of keyword coverage per Content_Cluster.
3. THE audit script SHALL detect orphaned content (published pages whose target keyword is not in the Keyword_Registry) and report these as requiring Keyword_Registry updates.
4. THE audit script SHALL output results in both human-readable (Markdown table) and machine-readable (JSON) formats.
