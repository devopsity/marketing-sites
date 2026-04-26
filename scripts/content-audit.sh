#!/usr/bin/env bash
# content-audit.sh — Content audit script that cross-references published content
# against the keyword registry and reports coverage, gaps, orphaned content, and
# keyword cannibalization. Outputs content-audit.json (machine-readable) and
# content-audit.md (human-readable Markdown table).
#
# Dependencies: yq (mikefarah/yq), jq, grep (standard POSIX + yq + jq)
# Compatible with bash 4+ (uses arrays)
#
# Usage:
#   content-audit.sh <keywords_yml_path> <site_source_dir>
#
# Arguments:
#   keywords_yml_path  Path to the keywords.yml registry file
#   site_source_dir    Path to the site source directory (e.g., sites/perfectsystem)
#
# Output:
#   content-audit.json  Machine-readable audit report
#   content-audit.md    Human-readable Markdown table
#
# Exit codes:
#   0  Audit completed successfully
#   2  Usage error or missing dependencies

set -euo pipefail

###############################################################################
# Usage
###############################################################################
usage() {
  echo "Usage: $0 <keywords_yml_path> <site_source_dir>" >&2
  echo "  keywords_yml_path  Path to the keywords.yml registry file" >&2
  echo "  site_source_dir    Path to the site source directory (e.g., sites/perfectsystem)" >&2
  exit 2
}

###############################################################################
# Dependency check
###############################################################################
check_deps() {
  local missing=0
  for cmd in yq jq grep; do
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
# derive_site_id — Derive site_id from the source directory path
# e.g., sites/perfectsystem -> perfectsystem, sites/o14 -> o14
###############################################################################
derive_site_id() {
  local site_dir="$1"
  basename "$site_dir"
}

###############################################################################
# extract_front_matter_field — Extract a YAML front matter field from a
# markdown file. Returns the raw value (or empty string if not found).
###############################################################################
extract_front_matter_field() {
  local file="$1"
  local field="$2"
  # Extract YAML front matter between --- delimiters, then query with yq
  sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d' | yq -r ".$field // \"\"" 2>/dev/null || echo ""
}

###############################################################################
# extract_front_matter_keywords — Extract the keywords array from front matter
# Returns one keyword per line
###############################################################################
extract_front_matter_keywords() {
  local file="$1"
  sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d' | yq -r '.keywords[]? // empty' 2>/dev/null || true
}

###############################################################################
# extract_front_matter_title — Extract the title from front matter
###############################################################################
extract_front_matter_title() {
  local file="$1"
  extract_front_matter_field "$file" "title"
}

###############################################################################
# extract_front_matter_permalink — Extract permalink or derive URL from file
###############################################################################
extract_page_url() {
  local file="$1"
  local site_dir="$2"

  # Check for explicit permalink in front matter
  local permalink
  permalink=$(extract_front_matter_field "$file" "permalink")
  if [[ -n "$permalink" ]]; then
    echo "$permalink"
    return
  fi

  # Derive URL from file path relative to site source dir
  local rel="${file#"$site_dir"/}"

  # Handle _posts: YYYY-MM-DD-slug.md -> /slug/
  if [[ "$rel" == _posts/* ]]; then
    local filename
    filename=$(basename "$rel" .md)
    # Strip date prefix (YYYY-MM-DD-)
    local slug="${filename#????-??-??-}"
    echo "/$slug/"
    return
  fi

  # Handle other collections (_pillars, _landing, etc.): _collection/slug.md -> /slug/
  if [[ "$rel" == _*/* ]]; then
    local slug
    slug=$(basename "$rel" .md)
    echo "/$slug/"
    return
  fi

  # Handle _pages: slug.md -> /slug/
  if [[ "$rel" == _pages/* ]]; then
    local slug
    slug=$(basename "$rel" .md)
    echo "/$slug/"
    return
  fi

  # Default: strip .md extension and add slashes
  local slug
  slug=$(echo "$rel" | sed 's/\.md$//')
  echo "/$slug/"
}

###############################################################################
# Main
###############################################################################
main() {
  check_deps

  if [[ $# -lt 2 ]]; then
    usage
  fi

  local keywords_yml="$1"
  local site_dir="${2%/}"

  # Validate inputs
  if [[ ! -f "$keywords_yml" ]]; then
    echo "ERROR: Keywords file '$keywords_yml' does not exist" >&2
    exit 2
  fi

  if [[ ! -d "$site_dir" ]]; then
    echo "ERROR: Site source directory '$site_dir' does not exist" >&2
    exit 2
  fi

  local site_id
  site_id=$(derive_site_id "$site_dir")

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  #############################################################################
  # Step 1: Parse keyword registry — filter entries for this site
  #############################################################################
  local kw_count
  kw_count=$(yq -r '.keywords | length' "$keywords_yml")

  # Build arrays of keyword data for this site
  local kw_keywords=()
  local kw_clusters=()
  local kw_statuses=()
  local kw_target_urls=()

  local i
  for (( i=0; i<kw_count; i++ )); do
    local entry_site_id
    entry_site_id=$(yq -r ".keywords[$i].site_id // \"\"" "$keywords_yml")
    if [[ "$entry_site_id" != "$site_id" ]]; then
      continue
    fi

    kw_keywords+=("$(yq -r ".keywords[$i].keyword // \"\"" "$keywords_yml")")
    kw_clusters+=("$(yq -r ".keywords[$i].cluster // \"\"" "$keywords_yml")")
    kw_statuses+=("$(yq -r ".keywords[$i].status // \"planned\"" "$keywords_yml")")
    kw_target_urls+=("$(yq -r ".keywords[$i].target_url // \"\"" "$keywords_yml")")
  done

  local site_kw_count=${#kw_keywords[@]}

  #############################################################################
  # Step 2: Compute per-cluster summary
  #############################################################################
  # Collect unique clusters
  local clusters_unique=()
  local c
  for c in "${kw_clusters[@]+"${kw_clusters[@]}"}"; do
    local found=false
    local existing
    for existing in "${clusters_unique[@]+"${clusters_unique[@]}"}"; do
      if [[ "$existing" == "$c" ]]; then
        found=true
        break
      fi
    done
    if ! $found; then
      clusters_unique+=("$c")
    fi
  done

  local clusters_json="{}"
  local cluster
  for cluster in "${clusters_unique[@]+"${clusters_unique[@]}"}"; do
    local pub=0 inprog=0 planned=0 total=0
    for (( i=0; i<site_kw_count; i++ )); do
      if [[ "${kw_clusters[$i]}" == "$cluster" ]]; then
        total=$((total + 1))
        case "${kw_statuses[$i]}" in
          published)   pub=$((pub + 1)) ;;
          in-progress) inprog=$((inprog + 1)) ;;
          planned)     planned=$((planned + 1)) ;;
        esac
      fi
    done

    local coverage=0
    if [[ $total -gt 0 ]]; then
      coverage=$(awk "BEGIN { printf \"%.0f\", ($pub / $total) * 100 }")
    fi

    clusters_json=$(echo "$clusters_json" | jq \
      --arg cl "$cluster" \
      --argjson pub "$pub" \
      --argjson inprog "$inprog" \
      --argjson planned "$planned" \
      --argjson cov "$coverage" \
      '. + { ($cl): { published: $pub, in_progress: $inprog, planned: $planned, coverage_percent: $cov } }')
  done

  #############################################################################
  # Step 3: Detect content gaps (planned keywords with no target_url)
  #############################################################################
  local gaps_json="[]"
  for (( i=0; i<site_kw_count; i++ )); do
    if [[ "${kw_statuses[$i]}" == "planned" && -z "${kw_target_urls[$i]}" ]]; then
      gaps_json=$(echo "$gaps_json" | jq \
        --arg kw "${kw_keywords[$i]}" \
        --arg cl "${kw_clusters[$i]}" \
        --arg st "${kw_statuses[$i]}" \
        '. + [{ keyword: $kw, cluster: $cl, status: $st }]')
    fi
  done

  #############################################################################
  # Step 4: Scan site source for markdown files and collect page keywords
  #############################################################################
  local md_files=()
  while IFS= read -r -d '' file; do
    md_files+=("$file")
  done < <(find "$site_dir" -name '*.md' -type f -print0 2>/dev/null | sort -z)

  # Build arrays: page_url, page_title, page_primary_keyword (first keyword)
  local page_urls=()
  local page_titles=()
  local page_primary_keywords=()

  for file in "${md_files[@]+"${md_files[@]}"}"; do
    local keywords_list
    keywords_list=$(extract_front_matter_keywords "$file")

    # Skip files with no keywords front matter
    if [[ -z "$keywords_list" ]]; then
      continue
    fi

    local url
    url=$(extract_page_url "$file" "$site_dir")
    local title
    title=$(extract_front_matter_title "$file")
    local primary_kw
    primary_kw=$(echo "$keywords_list" | head -1)

    page_urls+=("$url")
    page_titles+=("$title")
    page_primary_keywords+=("$primary_kw")
  done

  local page_count=${#page_urls[@]}

  #############################################################################
  # Step 5: Detect orphaned content (pages whose primary keyword is not in registry)
  #############################################################################
  local orphaned_json="[]"
  local p
  for (( p=0; p<page_count; p++ )); do
    local pk="${page_primary_keywords[$p]}"
    local found_in_registry=false
    for (( i=0; i<site_kw_count; i++ )); do
      if [[ "${kw_keywords[$i]}" == "$pk" ]]; then
        found_in_registry=true
        break
      fi
    done
    if ! $found_in_registry; then
      orphaned_json=$(echo "$orphaned_json" | jq \
        --arg url "${page_urls[$p]}" \
        --arg title "${page_titles[$p]}" \
        '. + [{ url: $url, title: $title }]')
    fi
  done

  #############################################################################
  # Step 6: Detect keyword cannibalization (two pages targeting same primary keyword)
  #############################################################################
  local cannibalization_json="[]"

  # Build a map of primary_keyword -> list of page URLs
  # Use a simple approach: for each unique primary keyword, collect all pages
  local checked_keywords=()
  for (( p=0; p<page_count; p++ )); do
    local pk="${page_primary_keywords[$p]}"

    # Skip if already checked
    local already_checked=false
    local ck
    for ck in "${checked_keywords[@]+"${checked_keywords[@]}"}"; do
      if [[ "$ck" == "$pk" ]]; then
        already_checked=true
        break
      fi
    done
    if $already_checked; then
      continue
    fi
    checked_keywords+=("$pk")

    # Collect all pages with this primary keyword
    local matching_pages=()
    local q
    for (( q=0; q<page_count; q++ )); do
      if [[ "${page_primary_keywords[$q]}" == "$pk" ]]; then
        matching_pages+=("${page_urls[$q]}")
      fi
    done

    # If more than one page targets the same keyword, it's cannibalization
    if [[ ${#matching_pages[@]} -gt 1 ]]; then
      local pages_array
      pages_array=$(printf '%s\n' "${matching_pages[@]}" | jq -R . | jq -s .)
      cannibalization_json=$(echo "$cannibalization_json" | jq \
        --arg kw "$pk" \
        --argjson pages "$pages_array" \
        '. + [{ keyword: $kw, pages: $pages }]')
    fi
  done

  #############################################################################
  # Step 7: Build and write content-audit.json
  #############################################################################
  jq -n \
    --arg site_id "$site_id" \
    --arg ts "$timestamp" \
    --argjson clusters "$clusters_json" \
    --argjson gaps "$gaps_json" \
    --argjson orphaned "$orphaned_json" \
    --argjson cannibalization "$cannibalization_json" \
    '{
      site_id: $site_id,
      audit_timestamp: $ts,
      clusters: $clusters,
      gaps: $gaps,
      orphaned: $orphaned,
      cannibalization: $cannibalization
    }' > content-audit.json

  #############################################################################
  # Step 8: Build and write content-audit.md
  #############################################################################
  {
    echo "# Content Audit Report"
    echo ""
    echo "**Site:** $site_id"
    echo "**Timestamp:** $timestamp"
    echo ""

    # Cluster summary table
    echo "## Cluster Summary"
    echo ""
    echo "| Cluster | Published | In Progress | Planned | Coverage |"
    echo "|---------|-----------|-------------|---------|----------|"
    for cluster in "${clusters_unique[@]+"${clusters_unique[@]}"}"; do
      local pub inprog planned cov
      pub=$(echo "$clusters_json" | jq -r --arg c "$cluster" '.[$c].published')
      inprog=$(echo "$clusters_json" | jq -r --arg c "$cluster" '.[$c].in_progress')
      planned=$(echo "$clusters_json" | jq -r --arg c "$cluster" '.[$c].planned')
      cov=$(echo "$clusters_json" | jq -r --arg c "$cluster" '.[$c].coverage_percent')
      echo "| $cluster | $pub | $inprog | $planned | ${cov}% |"
    done
    echo ""

    # Content gaps
    local gap_count
    gap_count=$(echo "$gaps_json" | jq 'length')
    echo "## Content Gaps ($gap_count)"
    echo ""
    if [[ "$gap_count" -gt 0 ]]; then
      echo "| Keyword | Cluster | Status |"
      echo "|---------|---------|--------|"
      echo "$gaps_json" | jq -r '.[] | "| \(.keyword) | \(.cluster) | \(.status) |"'
    else
      echo "No content gaps detected."
    fi
    echo ""

    # Orphaned content
    local orphan_count
    orphan_count=$(echo "$orphaned_json" | jq 'length')
    echo "## Orphaned Content ($orphan_count)"
    echo ""
    if [[ "$orphan_count" -gt 0 ]]; then
      echo "| URL | Title |"
      echo "|-----|-------|"
      echo "$orphaned_json" | jq -r '.[] | "| \(.url) | \(.title) |"'
    else
      echo "No orphaned content detected."
    fi
    echo ""

    # Cannibalization
    local cannibal_count
    cannibal_count=$(echo "$cannibalization_json" | jq 'length')
    echo "## Keyword Cannibalization ($cannibal_count)"
    echo ""
    if [[ "$cannibal_count" -gt 0 ]]; then
      echo "| Keyword | Pages |"
      echo "|---------|-------|"
      echo "$cannibalization_json" | jq -r '.[] | "| \(.keyword) | \(.pages | join(", ")) |"'
    else
      echo "No keyword cannibalization detected."
    fi
    echo ""
  } > content-audit.md

  #############################################################################
  # Report results to stdout
  #############################################################################
  local total_gaps
  total_gaps=$(echo "$gaps_json" | jq 'length')
  local total_orphaned
  total_orphaned=$(echo "$orphaned_json" | jq 'length')
  local total_cannibalization
  total_cannibalization=$(echo "$cannibalization_json" | jq 'length')

  echo "Content Audit: site=$site_id"
  echo "  Clusters: ${#clusters_unique[@]}"
  echo "  Keywords (this site): $site_kw_count"
  echo "  Content gaps: $total_gaps"
  echo "  Orphaned content: $total_orphaned"
  echo "  Cannibalization issues: $total_cannibalization"
  echo "Reports written to content-audit.json and content-audit.md"

  exit 0
}

main "$@"
