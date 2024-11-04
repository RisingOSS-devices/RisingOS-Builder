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
    if [ -d "$WORKDIR/.repo/repo" ]; then
        (cd "$WORKDIR/.repo/repo" && git pull -r) >> "$OUTPUT_FILE" 2>&1 || log "Warning: Failed to update repo tool"
    else
        log "Warning: .repo/repo directory not found. Skipping update."
    fi
}

init_repo() {
    local init_url="$STABLE_REPO_URL"
    
    if [[ "${STAGING:-false}" == "true" && "${RELEASE:-}" != "stable" ]]; then
        init_url="$STAGING_REPO_URL"
        log "Cloning staging source"
    else
        log "Cloning stable source"
    fi

    repo init -u "$init_url" -b fifteen --git-lfs --depth=1 >> "$OUTPUT_FILE" 2>&1 || {
        log "Error: repo init failed. Check $OUTPUT_FILE for details."
        exit 1
    }
}

sync_repos() {
    log "Syncing repositories..."
    find "$WORKDIR/.repo" -name '*.lock' -delete
    repo sync -c -j"$(nproc --all)" --force-sync --no-clone-bundle --no-tags --prune
    log "repo sync completed successfully"
}

delete_failing_repos() {
    log "Checking for failing repositories..."
    local failing_repos=$(awk '/^error: .+ checkout .+:$/{print $2}' "$OUTPUT_FILE")
    if [ -n "$failing_repos" ]; then
        log "Deleting failing repositories:"
        echo "$failing_repos" | while read -r repo; do
            log "Deleting repository: $repo"
            echo "$repo" >> "$DELETED_REPOS_FILE"
            rm -rf "$WORKDIR/$repo" "$WORKDIR/.repo/projects/$repo.git"
        done
    else
        log "No failing repositories found"
    fi
}

perform_sync() {
    if ! sync_repos; then
        delete_failing_repos
        log "Re-attempting sync after deleting failing repositories"
        if ! sync_repos; then
            log "Error: repo sync failed even after deleting failing repositories"
            exit 1
        fi
    fi
}

main() {
    cd "$WORKDIR" || exit 1
    
    : > "$OUTPUT_FILE"
    rm -f "$DELETED_REPOS_FILE"

    update_repo_tool
    init_repo
    perform_sync

    if [ -f "$DELETED_REPOS_FILE" ]; then
        log "The following repositories were deleted:"
        cat "$DELETED_REPOS_FILE" | tee -a "$OUTPUT_FILE"
    fi
}

main "$@"