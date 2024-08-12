#!/usr/bin/env bash
set -e

cd /home/sketu/rising

log_file="cloned_repositories.txt"
> "$log_file"
primary_repo_url="https://github.com/RisingOSS-devices/android_device_${BRAND}_${CODENAME}.git"
fallback_repo_url="https://github.com/LineageOS/android_device_${BRAND}_${CODENAME}.git"

function repo_exists {
  local repo_url=$1
  git ls-remote --exit-code "$repo_url" &> /dev/null
  return $?
}

function get_remote_url {
  local remote_name=$1
  local repo=$2

  case $remote_name in
    github)
      echo "https://github.com/$repo.git"
      ;;
    gitlab)
      echo "https://gitlab.com/$repo.git"
      ;;
    gitea)
      echo "https://gitea.com/$repo.git"
      ;;
    bitbucket)
      echo "https://bitbucket.org/$repo.git"
      ;;
    *)
      echo "https://github.com/$repo.git"
      ;;
  esac
}

function find_repo_with_fallback {
  local repo_name=$1
  local username=$2
  local remote_name=$3
  local orgs=("RisingOSS-devices" "LineageOS")
  
  if [[ -n "$username" ]]; then
    repo_url=$(get_remote_url "$remote_name" "$username/$repo_name")
    if repo_exists "$repo_url"; then
      echo "$repo_url"
      return
    fi
  fi

  for org in "${orgs[@]}"; do
    local repo_url=$(get_remote_url "$remote_name" "$org/$repo_name")
    if repo_exists "$repo_url"; then
      echo "$repo_url"
      return
    fi
  done

  echo ""
}

function clone_and_check_dependencies {
  local repo_url=$1
  local dest_dir=$2
  local recursive_flag=$3
  if [[ -d "$dest_dir" ]]; then
    rm -rf "$dest_dir"
  fi
  if [[ "$recursive_flag" == "true" ]]; then
    git clone --recursive "$repo_url" --depth=1 "$dest_dir"
  else
    git clone "$repo_url" --depth=1 "$dest_dir"
  fi
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to clone the repository $repo_url."
    exit 1
  fi
  echo "$dest_dir" >> "$log_file"
  if [[ -f "$dest_dir/vendorsetup.sh" ]]; then
    echo "Error: vendorsetup.sh found in $dest_dir. Please remove it and add to rising.dependencies."
    exit 1
  fi
  local dependencies_file
  if [[ -f "$dest_dir/rising.dependencies" ]]; then
    dependencies_file="$dest_dir/rising.dependencies"
  elif [[ -f "$dest_dir/lineage.dependencies" ]]; then
    dependencies_file="$dest_dir/lineage.dependencies"
  else
    return 0
  fi
  echo "Found dependencies file: $dependencies_file"
  jq -c '.[]' "$dependencies_file" | while read -r dependency; do
    local dependency_repository=$(echo "$dependency" | jq -r '.repository')
    local dependency_branch=$(echo "$dependency" | jq -r '.branch // "fourteen"')
    local dependency_target_path=$(echo "$dependency" | jq -r '.target_path')
    local remote_name=$(echo "$dependency" | jq -r '.remote // "github"')
    local recursive_flag=$(echo "$dependency" | jq -r '.recursive // "false"')
    local username=""
    if [[ "$dependency_repository" == *"/"* ]]; then
      username=$(echo "$dependency_repository" | cut -d'/' -f1)
      dependency_repository=$(echo "$dependency_repository" | cut -d'/' -f2-)
    fi
    local dependency_url=$(find_repo_with_fallback "$dependency_repository" "$username" "$remote_name")
    if [[ -z "$dependency_url" ]]; then
      echo "Warning: Failed to find repository $dependency_repository. Continuing with next dependency."
      continue
    fi
    if ! clone_and_check_dependencies "$dependency_url" "$dependency_target_path" "$recursive_flag"; then
      echo "Warning: Failed to clone dependency $dependency_url. Continuing with next dependency."
    fi
  done
}

if repo_exists "$primary_repo_url"; then
  clone_and_check_dependencies "$primary_repo_url" "device/$BRAND/$CODENAME" "false"
else
  echo "Warning: Device tree not found in RisingOSS-devices ($primary_repo_url). Cloning from LineageOS."
  if repo_exists "$fallback_repo_url"; then
    clone_and_check_dependencies "$fallback_repo_url" "device/$BRAND/$CODENAME" "false"
  else
    echo "Error: Neither the primary nor fallback repository exists."
    exit 1
  fi
fi

echo "Setup completed successfully."