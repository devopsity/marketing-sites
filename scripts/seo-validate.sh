#!/usr/bin/env bash
# seo-validate.sh — SEO validation script that checks built HTML pages for SEO compliance
# and outputs an seo-scorecard.json report consumable by the external dashboard.
#
# Dependencies: grep, jq, sed, awk (standard POSIX + jq)
# Compatible with bash 4+ (uses arrays)
#
# Usage:
#   seo-validate.sh <site_directory> [site_id]
#
# Arguments:
#   site_directory  Path to the built _site/ directory
#   site_id         Optional site identifier (defaults to directory basename)
#
# Output:
#   seo-scorecard.json in the current working directory
#
# Exit codes:
#   0  All required checks passed
#   1  One or more required checks failed (missing title, missing description, invalid JSON-LD)
#   2  Usage error or missing dependencies

set -euo pipefail

###############################################################################
# Constants
###############################################################################
TITLE_MIN=30
TITLE_MAX=60
DESC_MIN=120
DESC_MAX=160
SCORE_THRESHOLD=80
BACKLINK_RATIO_MIN=40
BACKLINK_RATIO_MAX=80
ANCHOR_MAX_REPEAT=2

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
# extract_title — Extract <title> tag content from an HTML file
# Returns empty string if not found
###############################################################################
extract_title() {
  local file="$1"
  # Handle multi-line title tags; grab content between <title> and </title>
  sed -n '/<title>/,/<\/title>/p' "$file" \
    | tr '\n' ' ' \
    | sed -E 's/.*<title[^>]*>//; s/<\/title>.*//' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | sed 's/[[:space:]]\+/ /g'
}

###############################################################################
# extract_meta_description — Extract meta description content
###############################################################################
extract_meta_description() {
  local file="$1"
  grep -oi '<meta[^>]*name=["\x27]description["\x27][^>]*>' "$file" 2>/dev/null \
    | head -1 \
    | sed -E 's/.*content=["\x27]([^"\x27]*)["\x27].*/\1/' \
    || echo ""
}

###############################################################################
# check_canonical — Check if canonical link tag is present
###############################################################################
check_canonical() {
  local file="$1"
  grep -qi '<link[^>]*rel=["\x27]canonical["\x27]' "$file" 2>/dev/null
}

###############################################################################
# check_og_tags — Check if all required OG tags are present
# Required: og:title, og:description, og:type, og:url
###############################################################################
check_og_tags() {
  local file="$1"
  local all_present=true
  for tag in "og:title" "og:description" "og:type" "og:url"; do
    if ! grep -qi "property=[\"']${tag}[\"']" "$file" 2>/dev/null; then
      all_present=false
      break
    fi
  done
  $all_present
}

###############################################################################
# check_twitter_tags — Check if Twitter Card tags are present
###############################################################################
check_twitter_tags() {
  local file="$1"
  grep -qi 'name=["\x27]twitter:card["\x27]' "$file" 2>/dev/null
}

###############################################################################
# extract_jsonld — Extract JSON-LD blocks from an HTML file
# Outputs each block on a separate line
###############################################################################
extract_jsonld() {
  local file="$1"
  # Use awk to extract content between <script type="application/ld+json"> and </script>
  awk '
    BEGIN { capture=0; buf="" }
    /<script[^>]*type=["\x27]application\/ld\+json["\x27][^>]*>/ {
      capture=1
      # Get content after the opening tag on the same line
      sub(/.*<script[^>]*type=["\x27]application\/ld\+json["\x27][^>]*>/, "")
      if (/<\/script>/) {
        sub(/<\/script>.*/, "")
        print
        capture=0
        next
      }
      buf=$0
      next
    }
    capture && /<\/script>/ {
      sub(/<\/script>.*/, "")
      buf=buf " " $0
      print buf
      buf=""
      capture=0
      next
    }
    capture { buf=buf " " $0 }
  ' "$file"
}

###############################################################################
# count_internal_links — Count internal links (href starting with / but not //)
###############################################################################
count_internal_links() {
  local file="$1"
  grep -oiE 'href=["\x27](/[^"\x27/][^"\x27]*)["\x27]' "$file" 2>/dev/null | wc -l | tr -d ' '
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
  # Ensure trailing slash for directories
  if [[ "$rel" != */ ]]; then
    rel="$rel"
  fi
  echo "$rel"
}

###############################################################################
# extract_backlink_anchors — Extract anchor text of external links to
# devopsity.com from within <article> or <main> elements
###############################################################################
extract_backlink_anchors_in_context() {
  local file="$1"
  # Extract content within <article> or <main> tags, then find devopsity links
  awk '
    BEGIN { capture=0 }
    /<(article|main)[^>]*>/ { capture=1 }
    /<\/(article|main)>/ { capture=0 }
    capture { print }
  ' "$file" \
    | grep -oiE '<a[^>]*href=["\x27][^"\x27]*devopsity\.com[^"\x27]*["\x27][^>]*>[^<]*</a>' 2>/dev/null \
    | sed -E 's/<a[^>]*>//g; s/<\/a>//g' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    || true
}

###############################################################################
# check_backlink_in_bad_context — Check if devopsity backlinks appear in
# <aside>, <footer>, or <nav> elements (bad placement)
###############################################################################
check_backlink_in_bad_context() {
  local file="$1"
  local bad_found=false
  for tag in aside footer nav; do
    local content
    content=$(awk -v tag="$tag" '
      BEGIN { capture=0 }
      $0 ~ "<" tag "[^>]*>" { capture=1 }
      $0 ~ "</" tag ">" { capture=0 }
      capture { print }
    ' "$file" 2>/dev/null || true)
    if echo "$content" | grep -qi 'devopsity\.com' 2>/dev/null; then
      bad_found=true
      break
    fi
  done
  $bad_found
}

###############################################################################
# has_backlink — Check if page has any link to devopsity.com
###############################################################################
has_backlink() {
  local file="$1"
  grep -qi 'href=["\x27][^"\x27]*devopsity\.com' "$file" 2>/dev/null
}

###############################################################################
# validate_page — Run all SEO checks on a single HTML page
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

  # --- Check 1: Title present ---
  local title
  title=$(extract_title "$file")
  local title_present=false
  if [[ -n "$title" ]]; then
    title_present=true
    passed_checks=$((passed_checks + 1))
  else
    has_required_failure=true
    warnings_json=$(echo "$warnings_json" | jq '. + ["Missing <title> tag"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 2: Title length ---
  local title_len=0
  local title_length_pass=false
  if [[ -n "$title" ]]; then
    title_len=${#title}
    if [[ $title_len -ge $TITLE_MIN && $title_len -le $TITLE_MAX ]]; then
      title_length_pass=true
      passed_checks=$((passed_checks + 1))
    else
      warnings_json=$(echo "$warnings_json" | jq --arg msg "Title length $title_len outside ${TITLE_MIN}-${TITLE_MAX} range" '. + [$msg]')
    fi
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["Title length check skipped — no title"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 3: Meta description present ---
  local desc
  desc=$(extract_meta_description "$file")
  local desc_present=false
  if [[ -n "$desc" ]]; then
    desc_present=true
    passed_checks=$((passed_checks + 1))
  else
    has_required_failure=true
    warnings_json=$(echo "$warnings_json" | jq '. + ["Missing <meta name=\"description\"> tag"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 4: Description length ---
  local desc_len=0
  local desc_length_pass=false
  if [[ -n "$desc" ]]; then
    desc_len=${#desc}
    if [[ $desc_len -ge $DESC_MIN && $desc_len -le $DESC_MAX ]]; then
      desc_length_pass=true
      passed_checks=$((passed_checks + 1))
    else
      warnings_json=$(echo "$warnings_json" | jq --arg msg "Description length $desc_len outside ${DESC_MIN}-${DESC_MAX} range" '. + [$msg]')
    fi
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["Description length check skipped — no description"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 5: Canonical tag ---
  local canonical_present=false
  if check_canonical "$file"; then
    canonical_present=true
    passed_checks=$((passed_checks + 1))
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["Missing canonical tag"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 6: OG tags ---
  local og_present=false
  if check_og_tags "$file"; then
    og_present=true
    passed_checks=$((passed_checks + 1))
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["Missing one or more Open Graph tags (og:title, og:description, og:type, og:url)"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 7: Twitter Card tags ---
  local twitter_present=false
  if check_twitter_tags "$file"; then
    twitter_present=true
    passed_checks=$((passed_checks + 1))
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["Missing Twitter Card tags"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 8: JSON-LD present ---
  local jsonld_blocks
  jsonld_blocks=$(extract_jsonld "$file")
  local jsonld_present=false
  if [[ -n "$jsonld_blocks" ]]; then
    jsonld_present=true
    passed_checks=$((passed_checks + 1))
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["Missing JSON-LD structured data"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 9: JSON-LD valid JSON ---
  local jsonld_valid=false
  if [[ -n "$jsonld_blocks" ]]; then
    local all_valid=true
    while IFS= read -r block; do
      [[ -z "$block" ]] && continue
      if ! echo "$block" | jq . &>/dev/null; then
        all_valid=false
        has_required_failure=true
        warnings_json=$(echo "$warnings_json" | jq '. + ["Invalid JSON-LD syntax"]')
        break
      fi
    done <<< "$jsonld_blocks"
    if $all_valid; then
      jsonld_valid=true
      passed_checks=$((passed_checks + 1))
    fi
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["JSON-LD validity check skipped — no JSON-LD found"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Check 10: Internal link count ---
  local link_count
  link_count=$(count_internal_links "$file")
  local links_pass=false
  if [[ "$link_count" -ge 1 ]]; then
    links_pass=true
    passed_checks=$((passed_checks + 1))
  else
    warnings_json=$(echo "$warnings_json" | jq '. + ["No internal links found"]')
  fi
  total_checks=$((total_checks + 1))

  # --- Compute score ---
  local score=0
  if [[ $total_checks -gt 0 ]]; then
    score=$(awk "BEGIN { printf \"%.0f\", ($passed_checks / $total_checks) * 100 }")
  fi

  # --- Build JSON output ---
  jq -n \
    --arg url "$url" \
    --argjson title_present "$title_present" \
    --argjson title_length_pass "$title_length_pass" \
    --argjson title_len "$title_len" \
    --argjson desc_present "$desc_present" \
    --argjson desc_length_pass "$desc_length_pass" \
    --argjson desc_len "$desc_len" \
    --argjson canonical_present "$canonical_present" \
    --argjson og_present "$og_present" \
    --argjson twitter_present "$twitter_present" \
    --argjson jsonld_present "$jsonld_present" \
    --argjson jsonld_valid "$jsonld_valid" \
    --argjson links_pass "$links_pass" \
    --argjson link_count "$link_count" \
    --argjson score "$score" \
    --argjson warnings "$warnings_json" \
    '{
      url: $url,
      checks: {
        title_present: $title_present,
        title_length: { pass: $title_length_pass, value: $title_len },
        meta_description_present: $desc_present,
        meta_description_length: { pass: $desc_length_pass, value: $desc_len },
        canonical_present: $canonical_present,
        og_tags_present: $og_present,
        twitter_tags_present: $twitter_present,
        jsonld_present: $jsonld_present,
        jsonld_valid: $jsonld_valid,
        internal_links_count: { pass: $links_pass, value: $link_count }
      },
      score: $score,
      warnings: $warnings
    }'

  # Return non-zero if required checks failed (caller captures via $?)
  if $has_required_failure; then
    return 1
  fi
  return 0
}

###############################################################################
# validate_backlinks — Site-wide backlink checks
# Checks anchor text variety, ratio, and placement
# Outputs warnings as JSON array
###############################################################################
validate_backlinks() {
  local site_dir="$1"
  shift
  local html_files=("$@")

  local total_pages=${#html_files[@]}
  local pages_with_backlinks=0
  local backlink_warnings="[]"

  # Collect all anchor texts across the site and track per-page backlink presence
  local all_anchors=""
  local bad_placement_pages=""

  for file in "${html_files[@]}"; do
    local url
    url=$(get_relative_url "$file" "$site_dir")

    # Check if page has any backlink to devopsity.com
    if has_backlink "$file"; then
      pages_with_backlinks=$((pages_with_backlinks + 1))
    fi

    # Collect anchor texts from valid context (article/main)
    local anchors
    anchors=$(extract_backlink_anchors_in_context "$file")
    if [[ -n "$anchors" ]]; then
      while IFS= read -r anchor; do
        [[ -z "$anchor" ]] && continue
        all_anchors="${all_anchors}${anchor}"$'\n'
      done <<< "$anchors"
    fi

    # Check for bad placement (aside, footer, nav)
    if check_backlink_in_bad_context "$file"; then
      bad_placement_pages="${bad_placement_pages}${url}"$'\n'
    fi
  done

  # --- Anchor text variety check ---
  if [[ -n "$all_anchors" ]]; then
    # Count occurrences of each anchor text (case-insensitive)
    local repeated
    repeated=$(echo "$all_anchors" | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -rn \
      | awk -v max="$ANCHOR_MAX_REPEAT" '$1 > max { $1=""; sub(/^[[:space:]]+/, ""); print }')
    if [[ -n "$repeated" ]]; then
      while IFS= read -r phrase; do
        [[ -z "$phrase" ]] && continue
        backlink_warnings=$(echo "$backlink_warnings" | jq --arg msg "Anchor text repeated >$ANCHOR_MAX_REPEAT times: \"$phrase\"" '. + [$msg]')
      done <<< "$repeated"
    fi
  fi

  # --- Backlink ratio check ---
  if [[ $total_pages -gt 5 ]]; then
    local ratio=0
    if [[ $total_pages -gt 0 ]]; then
      ratio=$(awk "BEGIN { printf \"%.0f\", ($pages_with_backlinks / $total_pages) * 100 }")
    fi
    if [[ $ratio -lt $BACKLINK_RATIO_MIN || $ratio -gt $BACKLINK_RATIO_MAX ]]; then
      backlink_warnings=$(echo "$backlink_warnings" | jq --arg msg "Backlink ratio ${ratio}% outside ${BACKLINK_RATIO_MIN}-${BACKLINK_RATIO_MAX}% range ($pages_with_backlinks of $total_pages pages)" '. + [$msg]')
    fi
  fi

  # --- Bad placement check ---
  if [[ -n "$bad_placement_pages" ]]; then
    while IFS= read -r page_url; do
      [[ -z "$page_url" ]] && continue
      backlink_warnings=$(echo "$backlink_warnings" | jq --arg msg "Backlink in <aside>/<footer>/<nav> on $page_url" '. + [$msg]')
    done <<< "$bad_placement_pages"
  fi

  echo "$backlink_warnings"
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
          pages_warning: 0,
          average_score: 0
        }
      }' > seo-scorecard.json
    echo "SEO scorecard written to seo-scorecard.json (0 pages)"
    exit 0
  fi

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Validate each page
  local pages_json="[]"
  local any_required_failure=false
  local total_score=0
  local pages_passing=0
  local pages_warning=0

  for file in "${html_files[@]}"; do
    local page_json
    local page_failed=false

    page_json=$(validate_page "$file" "$site_dir") || page_failed=true

    if $page_failed; then
      any_required_failure=true
    fi

    # Extract score for summary
    local page_score
    page_score=$(echo "$page_json" | jq '.score')
    total_score=$((total_score + page_score))

    if [[ $page_score -ge $SCORE_THRESHOLD ]]; then
      pages_passing=$((pages_passing + 1))
    else
      pages_warning=$((pages_warning + 1))
    fi

    pages_json=$(echo "$pages_json" | jq --argjson page "$page_json" '. + [$page]')
  done

  # Run site-wide backlink validation
  local backlink_warnings
  backlink_warnings=$(validate_backlinks "$site_dir" "${html_files[@]}")

  # Compute summary
  local total_pages=${#html_files[@]}
  local average_score=0
  if [[ $total_pages -gt 0 ]]; then
    average_score=$(awk "BEGIN { printf \"%.1f\", $total_score / $total_pages }")
  fi

  # Build final scorecard JSON
  jq -n \
    --arg site_id "$site_id" \
    --arg ts "$timestamp" \
    --argjson pages "$pages_json" \
    --argjson total "$total_pages" \
    --argjson passing "$pages_passing" \
    --argjson warning "$pages_warning" \
    --argjson avg "$average_score" \
    --argjson backlink_warnings "$backlink_warnings" \
    '{
      site_id: $site_id,
      build_timestamp: $ts,
      pages: $pages,
      backlink_warnings: $backlink_warnings,
      summary: {
        total_pages: $total,
        pages_passing: $passing,
        pages_warning: $warning,
        average_score: $avg
      }
    }' > seo-scorecard.json

  # Report results
  echo "SEO Scorecard: $total_pages pages analyzed"
  echo "  Passing (>=${SCORE_THRESHOLD}%): $pages_passing"
  echo "  Warning (<${SCORE_THRESHOLD}%):  $pages_warning"
  echo "  Average score: ${average_score}%"

  if [[ $(echo "$backlink_warnings" | jq 'length') -gt 0 ]]; then
    echo "  Backlink warnings:"
    echo "$backlink_warnings" | jq -r '.[] | "    - " + .'
  fi

  echo "Scorecard written to seo-scorecard.json"

  # Exit non-zero if any required check failed
  if $any_required_failure; then
    echo "ERROR: One or more required SEO checks failed (missing title, missing description, or invalid JSON-LD)" >&2
    exit 1
  fi

  exit 0
}

main "$@"
