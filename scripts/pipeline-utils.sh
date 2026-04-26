#!/usr/bin/env bash
# pipeline-utils.sh — Extracted, testable shell functions for the multi-site CI/CD pipeline.
# Source this file to use the functions; it does not auto-execute anything.
#
# Dependencies: yq (YAML parser), jq (JSON processor)
# Compatible with bash 3.2+ (no associative arrays)

###############################################################################
# validate_registry
#
# Parses sites.yml, checks for unique id values, verifies required fields are
# present, and verifies source_dir paths exist.
# Exits non-zero with error details on failure.
#
# Usage:
#   validate_registry <sites_yml_path>
###############################################################################
validate_registry() {
  local sites_yml="${1:?Usage: validate_registry <sites_yml_path>}"
  local error_count=0
  local error_messages=""

  if [[ ! -f "$sites_yml" ]]; then
    echo "ERROR: sites.yml not found at '$sites_yml'" >&2
    return 1
  fi

  local site_count
  site_count=$(yq -r '.sites | length' "$sites_yml")

  if [[ "$site_count" -eq 0 ]]; then
    echo "ERROR: No sites defined in '$sites_yml'" >&2
    return 1
  fi

  # --- Check required fields ---------------------------------------------------
  local required_fields="id source_dir domain preview_bucket production_bucket cloudfront_distribution_id"

  local i field value site_id_hint
  for (( i=0; i<site_count; i++ )); do
    for field in $required_fields; do
      value=$(yq -r ".sites[$i].$field // \"\"" "$sites_yml")
      if [[ -z "$value" ]]; then
        site_id_hint=$(yq -r ".sites[$i].id // \"(index $i)\"" "$sites_yml")
        error_messages="${error_messages}  - Site '$site_id_hint' is missing required field '$field'"$'\n'
        error_count=$((error_count + 1))
      fi
    done
  done

  # --- Check unique ids --------------------------------------------------------
  local all_ids
  all_ids=$(yq -r '.sites[].id' "$sites_yml")

  local seen_ids="" id
  while IFS= read -r id; do
    if echo "$seen_ids" | grep -qx "$id"; then
      error_messages="${error_messages}  - Duplicate site id: '$id'"$'\n'
      error_count=$((error_count + 1))
    fi
    seen_ids="${seen_ids}${id}"$'\n'
  done <<< "$all_ids"

  # --- Check source_dir paths exist --------------------------------------------
  local repo_root
  repo_root=$(dirname "$sites_yml")
  if [[ "$repo_root" == "." || "$repo_root" == "" ]]; then
    repo_root="."
  fi

  local source_dir full_path site_id
  for (( i=0; i<site_count; i++ )); do
    source_dir=$(yq -r ".sites[$i].source_dir // \"\"" "$sites_yml")
    if [[ -n "$source_dir" ]]; then
      full_path="$repo_root/$source_dir"
      if [[ ! -d "$full_path" ]]; then
        site_id=$(yq -r ".sites[$i].id // \"(index $i)\"" "$sites_yml")
        error_messages="${error_messages}  - Site '$site_id': source_dir '$source_dir' does not exist (checked '$full_path')"$'\n'
        error_count=$((error_count + 1))
      fi
    fi
  done

  # --- Report results ----------------------------------------------------------
  if [[ $error_count -gt 0 ]]; then
    echo "ERROR: Site registry validation failed with $error_count error(s):" >&2
    echo -n "$error_messages" >&2
    return 1
  fi

  echo "Site registry validation passed ($site_count site(s))."
  return 0
}


###############################################################################
# detect_changes
#
# Takes sites.yml path and a list of changed files (newline-separated string
# or file path prefixed with @). Returns a JSON array of affected site objects.
#
# Returns all sites if shared files changed, only matching sites if changes are
# site-specific, empty array if no sites affected.
#
# Shared file detection: Any file not under a site's source_dir and not in the
# ignore list is considered shared. The sites.yml file itself triggers all sites.
# Infrastructure files (infrastructure/) log a notice but continue.
#
# Usage:
#   detect_changes <sites_yml_path> <changed_files_string>
#   detect_changes <sites_yml_path> @<changed_files_file>
###############################################################################
detect_changes() {
  local sites_yml="${1:?Usage: detect_changes <sites_yml_path> <changed_files>}"
  local changed_input="${2:-}"

  if [[ ! -f "$sites_yml" ]]; then
    echo "ERROR: sites.yml not found at '$sites_yml'" >&2
    return 1
  fi

  # Read changed files — from file (@path) or inline string
  local changed_files=""
  if [[ "$changed_input" == @* ]]; then
    local file_path="${changed_input#@}"
    if [[ ! -f "$file_path" ]]; then
      echo "ERROR: Changed files list not found at '$file_path'" >&2
      return 1
    fi
    changed_files=$(cat "$file_path")
  else
    changed_files="$changed_input"
  fi

  # If no changed files, return empty array
  if [[ -z "$changed_files" ]]; then
    echo "[]"
    return 0
  fi

  # Files to ignore when determining shared vs site-specific changes
  local ignore_list="README.md
.gitignore
LICENSE.txt
changelog.md
docker-compose.yml
favicon.ico"

  # Collect all source_dir values
  local site_count
  site_count=$(yq -r '.sites | length' "$sites_yml")

  local source_dirs=""
  local i
  for (( i=0; i<site_count; i++ )); do
    local sd
    sd=$(yq -r ".sites[$i].source_dir" "$sites_yml")
    source_dirs="${source_dirs}${sd}"$'\n'
  done

  # Classify each changed file
  local shared_detected=false
  local infra_detected=false
  local affected_indices=""  # newline-separated list of indices

  local file
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    # Check if this is the sites.yml file itself — triggers all sites
    local sites_yml_basename
    sites_yml_basename=$(basename "$sites_yml")
    if [[ "$file" == "$sites_yml_basename" || "$file" == "$sites_yml" ]]; then
      shared_detected=true
      continue
    fi

    # Check if file is in the ignore list
    if echo "$ignore_list" | grep -qx "$file"; then
      continue
    fi

    # Check if file is under infrastructure/
    if [[ "$file" == infrastructure/* ]]; then
      infra_detected=true
      continue
    fi

    # Check if file falls under any site's source_dir
    local matched_site=false
    for (( i=0; i<site_count; i++ )); do
      local sd
      sd=$(echo "$source_dirs" | sed -n "$((i+1))p")
      if [[ "$file" == "${sd}"/* ]]; then
        # Add index if not already present
        if ! echo "$affected_indices" | grep -qx "$i"; then
          affected_indices="${affected_indices}${i}"$'\n'
        fi
        matched_site=true
        break
      fi
    done

    # If file is not under any site's source_dir and not ignored, it's shared
    if ! $matched_site; then
      shared_detected=true
    fi
  done <<< "$changed_files"

  # Log infrastructure notice
  if $infra_detected; then
    echo "NOTICE: Infrastructure files changed — flagged for review." >&2
  fi

  # Build output JSON array
  if $shared_detected; then
    yq -o=json -I=0 '.sites' "$sites_yml"
  elif [[ -n "$(echo "$affected_indices" | tr -d '[:space:]')" ]]; then
    local filter="["
    local first=true
    local idx
    for idx in $(echo "$affected_indices" | sort -n -u | tr -s '\n'); do
      [[ -z "$idx" ]] && continue
      if $first; then
        first=false
      else
        filter+=","
      fi
      filter+=".sites[$idx]"
    done
    filter+="]"
    yq -o=json -I=0 "$filter" "$sites_yml"
  else
    echo "[]"
  fi

  return 0
}


###############################################################################
# build_preview_url
#
# Takes preview_bucket, region, and pr_number. Returns the preview URL.
#
# Usage:
#   build_preview_url <preview_bucket> <region> <pr_number>
###############################################################################
build_preview_url() {
  local preview_bucket="${1:?Usage: build_preview_url <preview_bucket> <region> <pr_number>}"
  local region="${2:?Usage: build_preview_url <preview_bucket> <region> <pr_number>}"
  local pr_number="${3:?Usage: build_preview_url <preview_bucket> <region> <pr_number>}"

  echo "http://${preview_bucket}.s3-website-${region}.amazonaws.com/pr-${pr_number}/"
}

###############################################################################
# build_check_name
#
# Takes stage and site_id. Returns the GitHub Actions check name.
#
# Usage:
#   build_check_name <stage> <site_id>
###############################################################################
build_check_name() {
  local stage="${1:?Usage: build_check_name <stage> <site_id>}"
  local site_id="${2:?Usage: build_check_name <stage> <site_id>}"

  echo "${stage}/${site_id}"
}
