#!/bin/bash

set -euo pipefail

WORKDIR="/home/sketu/rising"
OUTPUT_FILE="/tmp/repo_sync_output.txt"
DELETED_REPOS_FILE="$WORKDIR/deleted_repositories.txt"
STABLE_REPO_URL="https://github.com/RisingTechOSS/android"
STAGING_REPO_URL="https://github.com/RisingOS-staging/android"

log() {
    echo "$1" | tee -a "$OUTPUT_FILE"
}

update_repo_tool() {
    log "Updating repo tool..."
    (cd "$WORKDIR/.repo/repo" && git pull -r) >/dev/null 2>&1
}

delete_repo() {
    local repo_info="$1"
    local repo_path=$(dirname "$repo_info")
    local repo_name=$(basename "$repo_info")
    log "Deleting repository: $repo_info"
    echo "$repo_info" >> "$DELETED_REPOS_FILE"
    rm -rf "$WORKDIR/$repo_path/$repo_name" "$WORKDIR/.repo/projects/$repo_path/$repo_name"/*.git
}

delete_failing_repos() {
    log "Deleting failing repositories..."
    awk '/Failing repos:/{flag=1; next} /Try/{flag=0} flag' "$OUTPUT_FILE" | while read -r repo_info; do
        delete_repo "$repo_info"
    done
}

sync_repos() {
    log "Syncing repositories..."
    find "$WORKDIR/.repo" -name '*.lock' -delete
    repo sync -c -j"$(nproc --all)" --force-sync --no-clone-bundle --no-tags --prune | tee -a "$OUTPUT_FILE"
}

init_repo() {
    local init_url="$STABLE_REPO_URL"
    if [[ "${STAGING:-false}" == "true" && "${RELEASE:-}" != "stable" ]]; then
        init_url="$STAGING_REPO_URL"
        log "Initializing repo with the Staging Source"
    else
        log "Initializing repo with the Stable Source"
    fi

    log "Running repo init with URL: $init_url"
    repo init -u "$init_url" -b fourteen --git-lfs --depth=1 2>&1 | tee -a "$OUTPUT_FILE"
}

main() {
    cd "$WORKDIR" || exit 1
    : > "$OUTPUT_FILE"
    rm -f "$DELETED_REPOS_FILE"

    update_repo_tool
    sync_repos

    if ! grep -q "Failing repos:" "$OUTPUT_FILE"; then
        log "All repositories synchronized successfully."
        exit 0
    fi

    delete_failing_repos

    log "Reinitializing and re-syncing all repositories..."
    init_repo
    sync_repos

    if [[ -f "$DELETED_REPOS_FILE" ]]; then
        log "The following repositories were deleted:"
        cat "$DELETED_REPOS_FILE"
    else
        log "No repositories were deleted during this sync."
    fi
}

main "$@"