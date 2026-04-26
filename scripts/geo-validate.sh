#!/usr/bin/env bash
# geo-validate.sh — GEO validation script that checks built HTML pages for GEO
# (Generative Engine Optimization) compliance and outputs a geo-scorecard.json
# report consumable by the external dashboard.
#
# Dependencies: grep, jq, sed, awk (standard POSIX + jq)
# Compatible with bash 4+ (uses arrays)
#
# Usage:
#   geo-validate.sh <site_directory> [site_id]
#
# Arguments:
#   site_directory  Path to the built _site/ directory
#   site_id         Optional site identifier (defaults to directory basename)
#
# Output:
#   geo-scorecard.json in the current working directory
#
# Exit codes:
#   0  All required checks passed
#   1  One or more required GEO checks failed
#   2  Usage error or missing dependencies

set -euo pipefail

###############################################################################
# Constants
###############################################################################
GEO_SCORE_THRESHOLD=70

# Word count minimums per content type
WC_MIN_POST=1200
WC_MIN_PILLAR=2500
WC_MIN_LANDING=600
WC_MIN_PRODUCT=600
# info pages have no minimum

###############################################################################
# Usage
###############################################################################
usage() {
  echo "Usage: $0 <site_directory> [site_id]" >&2
  echo "  site_directory  Path to the built _site/ directory" >&2
  echo "  site_id         Optional site identifier (defaults to directory basename)" >&2
  exit 2
}

###############################################################################
# Dependency check
###############################################################################
check_deps() {
  local missing=0
  for cmd in grep jq sed awk; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "ERROR: Required command '$cmd' not found in PATH" >&2
      missing=1
    fi
  done
  if [[ $missing -ne 0 ]]; then
    exit 2
  fi
}

###############################################################################
# get_relative_url — Convert file path to URL path relative to site root
###############################################################################
get_relative_url() {
  local file="$1"
  local site_dir="$2"
  local rel="${file#"$site_dir"}"
  # Remove trailing index.html
  rel="${rel%index.html}"
  # Ensure leading slash
  if [[ "$rel" != /* ]]; then
    rel="/$rel"
  fi
  echo "$rel"
}

###############################################################################
# detect_content_type — Detect content type from HTML body class or structure
# Returns: post, pillar, landing, product, info, or unknown
###############################################################################
detect_content_type() {
  local file="$1"

  # Check body class for layout hints (e.g., layout-post, layout-pillar)
  local body_class
  body_class=$(grep -oi '<body[^>]*class=["\x27][^"\x27]*["\x27]' "$file" 2>/dev/null \
    | head -1 \
    | sed -E 's/.*class=["\x27]([^"\x27]*)["\x27].*/\1/' \
    || echo "")

  if [[ -n "$body_class" ]]; then
    if echo "$body_class" | grep -qi 'layout-post\|post-layout'; then
      echo "post"; return
    elif echo "$body_class" | grep -qi 'layout-pillar\|pillar-layout'; then
      echo "pillar"; return
    elif echo "$body_class" | grep -qi 'layout-landing\|landing-layout'; then
      echo "landing"; return
    elif echo "$body_class" | grep -qi 'layout-product\|product-layout'; then
      echo "product"; return
    elif echo "$body_class" | grep -qi 'layout-info\|info-layout'; then
      echo "info"; return
    fi
  fi

  # Check for article class names (e.g., post-content, pillar-content)
  if grep -qi 'class=["\x27][^"\x27]*post-content' "$file" 2>/dev/null; then
    echo "post"; return
  elif grep -qi 'class=["\x27][^"\x27]*pillar-content' "$file" 2>/dev/null; then
    echo "pillar"; return
  elif grep -qi 'class=["\x27][^"\x27]*landing-content' "$file" 2>/dev/null; then
    echo "landing"; return
  elif grep -qi 'class=["\x27][^"\x27]*product-content' "$file" 2>/dev/null; then
    echo "product"; return
  elif grep -qi 'class=["\x27][^"\x27]*info-content' "$file" 2>/dev/null; then
    echo "info"; return
  fi

  # Fallback: check for layout meta tag or data attribute
  local layout_meta
  layout_meta=$(grep -oi 'data-layout=["\x27][^"\x27]*["\x27]' "$file" 2>/dev/null \
    | head -1 \
    | sed -E 's/.*data-layout=["\x27]([^"\x27]*)["\x27].*/\1/' \
    || echo "")

  if [[ -n "$layout_meta" ]]; then
    case "$layout_meta" in
      post) echo "post"; return ;;
      pillar) echo "pillar"; return ;;
      landing) echo "landing"; return ;;
      product) echo "product"; return ;;
      info) echo "info"; return ;;
    esac
  fi

  echo "unknown"
}

###############################################################################
# get_word_count_min — Get minimum word count for a content type
# Returns the minimum or -1 if no minimum applies
###############################################################################
get_word_count_min() {
  local content_type="$1"
  case "$content_type" in
    post)    echo "$WC_MIN_POST" ;;
    pillar)  echo "$WC_MIN_PILLAR" ;;
    landing) echo "$WC_MIN_LANDING" ;;
    product) echo "$WC_MIN_PRODUCT" ;;
    info)    echo "-1" ;;
    *)       echo "-1" ;;
  esac
}

###############################################################################
# check_summary_paragraph — Check for <div class="geo-summary"> after H1
###############################################################################
check_summary_paragraph() {
  local file="$1"
  grep -qi '<div[^>]*class=["\x27][^"\x27]*geo-summary' "$file" 2>/dev/null
}

###############################################################################
# check_heading_hierarchy — Check that heading levels are not skipped
# Returns 0 if hierarchy is valid, 1 if skipped levels found
###############################################################################
check_heading_hierarchy() {
  local file="$1"

  # Extract all heading tags (H1-H6) in order
  local headings
  headings=$(grep -oiE '<h[1-6][^>]*>' "$file" 2>/dev/null \
    | sed -E 's/.*<[hH]([1-6]).*/\1/' \
    || echo "")

  if [[ -z "$headings" ]]; then
    # No headings at all — consider valid (nothing to skip)
    return 0
  fi

  local prev_level=0
  local level
  while IFS= read -r level; do
    [[ -z "$level" ]] && continue
    if [[ $prev_level -gt 0 && $level -gt $((prev_level + 1)) ]]; then
      # Skipped a level (e.g., H1 -> H3 without H2)
      return 1
    fi
    prev_level=$level
  done <<< "$headings"

  return 0
}

###############################################################################
# check_faq_present — Check for FAQ via <details> elements or JSON-LD FAQPage
###############################################################################
check_faq_present() {
  local file="$1"

  # Check for <details> elements (HTML FAQ)
  if grep -qi '<details' "$file" 2>/dev/null; then
    return 0
  fi

  # Check for JSON-LD FAQPage schema
  if grep -qi '"FAQPage"' "$file" 2>/dev/null; then
    return 0
  fi

  return 1
}

###############################################################################
# check_definitions_present — Check for <dfn> elements
###############################################################################
check_definitions_present() {
  local file="$1"
  grep -qi '<dfn' "$file" 2>/dev/null
}

###############################################################################
# check_sources_present — Check for a sources/references section
# Looks for a numbered references list or a section with citation links
###############################################################################
check_sources_present() {
  local file="$1"

  # Check for a sources/references section heading
  if grep -qiE '<h[2-6][^>]*>[^<]*(sources|references|citations|źródła)[^<]*</h[2-6]>' "$file" 2>/dev/null; then
    return 0
  fi

  # Check for an ordered list with external links (common citation pattern)
  if grep -qi 'class=["\x27][^"\x27]*sources\|class=["\x27][^"\x27]*references' "$file" 2>/dev/null; then
    return 0
  fi

  return 1
}

###############################################################################
# count_words — Count words in the main content area, stripping HTML tags
# Looks for content within <article>, <main>, or falls back to <body>
###############################################################################
count_words() {
  local file="$1"

  # Try to extract content from <article> or <main> first
  local content
  content=$(awk '
    BEGIN { capture=0 }
    /<(article|main)[^>]*>/ { capture=1; next }
    /<\/(article|main)>/ { capture=0; next }
    capture { print }
  ' "$file" 2>/dev/null)

  # Fallback to <body> if no article/main found
  if [[ -z "$content" ]]; then
    content=$(awk '
      BEGIN { capture=0 }
      /<body[^>]*>/ { capture=1; next }
      /<\/body>/ { capture=0; next }
      capture { print }
    ' "$file" 2>/dev/null)
  fi

  if [[ -z "$content" ]]; then
    echo "0"
    return
  fi

  # Strip HTML tags, decode common entities, and count words
  echo "$content" \
    | sed 's/<script[^>]*>.*<\/script>//gi' \
    | sed 's/<style[^>]*>.*<\/style>//gi' \
    | sed 's/<[^>]*>//g' \
    | sed 's/&nbsp;/ /g; s/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&quot;/"/g' \
    | tr -s '[:space:]' '\n' \
    | grep -c '[[:alnum:]]' \
    || echo "0"
}

###############################################################################
# validate_page — Run all GEO checks on a single HTML page
# Outputs a JSON object with check results
###############################################################################
validate_page() {
  local file="$1"
  local site_dir="$2"
  local url
  url=$(get_relative_url "$file" "$site_dir")

  local warnings_json="[]"
  local has_required_failure=false
  local total_checks=0
  local passed_checks=0

  # --- Check 1: Summary paragraph present (geo-summary div) ---
  local summary_present=false
  if check_summary_paragraph "$file"; then
    summary_present=true
    passed_checks=$((passed_checks + 1))
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["No GEO summary paragraph found (missing <div class=\"geo-summary\">)"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 2: Heading hierarchy (no skipped levels) ---
  local heading_hierarchy=false
  if check_heading_hierarchy "$file"; then
    heading_hierarchy=true
    passed_checks=$((passed_checks + 1))
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["Heading hierarchy has skipped levels (e.g., H1 followed by H3 without H2)"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 3: FAQ present ---
  local faq_present=false
  if check_faq_present "$file"; then
    faq_present=true
    passed_checks=$((passed_checks + 1))
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["No FAQ section found (no <details> elements or JSON-LD FAQPage)"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 4: Definitions present ---
  local definitions_present=false
  if check_definitions_present "$file"; then
    definitions_present=true
    passed_checks=$((passed_checks + 1))
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["No definitions section found (no <dfn> elements)"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 5: Sources present ---
  local sources_present=false
  if check_sources_present "$file"; then
    sources_present=true
    passed_checks=$((passed_checks + 1))
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["No sources/references section found"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 6: Word count ---
  local content_type
  content_type=$(detect_content_type "$file")
  local wc_min
  wc_min=$(get_word_count_min "$content_type")
  local word_count
  word_count=$(count_words "$file")

  local wc_pass=true
  if [[ "$wc_min" -gt 0 ]]; then
    if [[ "$word_count" -lt "$wc_min" ]]; then
      wc_pass=false
      warnings_json=$(echo "$warnings_json" | jq --arg msg "Word count $word_count below minimum $wc_min for content type '$content_type'" '. + [$msg]')
    fi
    total_checks=$((total_checks + 1))
    if [[ "$wc_pass" == "true" ]]; then
      passed_checks=$((passed_checks + 1))
    fi
  fi
  # If wc_min is -1 (info or unknown), skip word count check entirely

  # --- Compute GEO score ---
  local geo_score=0
  if [[ $total_checks -gt 0 ]]; then
    geo_score=$(awk "BEGIN { printf \"%.0f\", ($passed_checks / $total_checks) * 100 }")
  fi

  # --- Flag pages below threshold ---
  if [[ $geo_score -lt $GEO_SCORE_THRESHOLD ]]; then
    has_required_failure=true
  fi

  # --- Build word_count check object ---
  local wc_check_json
  if [[ "$wc_min" -gt 0 ]]; then
    wc_check_json=$(jq -n --argjson pass "$wc_pass" --argjson val "$word_count" '{ pass: $pass, value: $val }')
  else
    # No word count check applicable — report value but mark as pass
    wc_check_json=$(jq -n --argjson val "$word_count" '{ pass: true, value: $val }')
  fi

  # --- Build JSON output ---
  jq -n \
    --arg url "$url" \
    --argjson summary_present "$summary_present" \
    --argjson heading_hierarchy "$heading_hierarchy" \
    --argjson faq_present "$faq_present" \
    --argjson definitions_present "$definitions_present" \
    --argjson sources_present "$sources_present" \
    --argjson word_count "$wc_check_json" \
    --argjson geo_score "$geo_score" \
    --argjson warnings "$warnings_json" \
    '{
      url: $url,
      geo_checks: {
        summary_paragraph: $summary_present,
        heading_hierarchy: $heading_hierarchy,
        faq_present: $faq_present,
        definitions_present: $definitions_present,
        sources_present: $sources_present,
        word_count: $word_count
      },
      geo_score: $geo_score,
      warnings: $warnings
    }'

  # Return non-zero if page scored below threshold
  if $has_required_failure; then
    return 1
  fi
  return 0
}

###############################################################################
# Main
###############################################################################
main() {
  check_deps

  if [[ $# -lt 1 ]]; then
    usage
  fi

  local site_dir="${1%/}"
  local site_id="${2:-$(basename "$site_dir")}"

  # Validate input directory
  if [[ ! -d "$site_dir" ]]; then
    echo "ERROR: Site directory '$site_dir' does not exist" >&2
    exit 2
  fi

  # Find all HTML files
  local html_files=()
  while IFS= read -r -d '' file; do
    html_files+=("$file")
  done < <(find "$site_dir" -name '*.html' -type f -print0 2>/dev/null | sort -z)

  if [[ ${#html_files[@]} -eq 0 ]]; then
    echo "WARNING: No HTML files found in '$site_dir'" >&2
    # Output empty scorecard
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq -n \
      --arg site_id "$site_id" \
      --arg ts "$timestamp" \
      '{
        site_id: $site_id,
        build_timestamp: $ts,
        pages: [],
        summary: {
          total_pages: 0,
          pages_passing: 0,
          pages_needing_optimization: 0,
          average_geo_score: 0
        }
      }' > geo-scorecard.json
    echo "GEO scorecard written to geo-scorecard.json (0 pages)"
    exit 0
  fi

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Validate each page
  local pages_json="[]"
  local any_required_failure=false
  local total_score=0
  local pages_passing=0
  local pages_needing_optimization=0

  for file in "${html_files[@]}"; do
    local page_json
    local page_failed=false

    page_json=$(validate_page "$file" "$site_dir") || page_failed=true

    if $page_failed; then
      any_required_failure=true
    fi

    # Extract score for summary
    local page_score
    page_score=$(echo "$page_json" | jq '.geo_score')
    total_score=$((total_score + page_score))

    if [[ $page_score -ge $GEO_SCORE_THRESHOLD ]]; then
      pages_passing=$((pages_passing + 1))
    else
      pages_needing_optimization=$((pages_needing_optimization + 1))
    fi

    pages_json=$(echo "$pages_json" | jq --argjson page "$page_json" '. + [$page]')
  done

  # Compute summary
  local total_pages=${#html_files[@]}
  local average_geo_score=0
  if [[ $total_pages -gt 0 ]]; then
    average_geo_score=$(awk "BEGIN { printf \"%.1f\", $total_score / $total_pages }")
  fi

  # Build final scorecard JSON
  jq -n \
    --arg site_id "$site_id" \
    --arg ts "$timestamp" \
    --argjson pages "$pages_json" \
    --argjson total "$total_pages" \
    --argjson passing "$pages_passing" \
    --argjson needing "$pages_needing_optimization" \
    --argjson avg "$average_geo_score" \
    '{
      site_id: $site_id,
      build_timestamp: $ts,
      pages: $pages,
      summary: {
        total_pages: $total,
        pages_passing: $passing,
        pages_needing_optimization: $needing,
        average_geo_score: $avg
      }
    }' > geo-scorecard.json

  # Report results
  echo "GEO Scorecard: $total_pages pages analyzed"
  echo "  Passing (>=${GEO_SCORE_THRESHOLD}%): $pages_passing"
  echo "  Needing optimization (<${GEO_SCORE_THRESHOLD}%): $pages_needing_optimization"
  echo "  Average GEO score: ${average_geo_score}%"
  echo "Scorecard written to geo-scorecard.json"

  # Exit non-zero if any page failed GEO checks
  if $any_required_failure; then
    echo "WARNING: One or more pages scored below ${GEO_SCORE_THRESHOLD}% GEO threshold" >&2
    exit 1
  fi

  exit 0
}

main "$@"
