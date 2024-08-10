#!/bin/bash

WORK_DIR="/home/sketu/rising"

update_repo_tool() {
    cd "$WORK_DIR/.repo/repo"
    git pull -r
    cd -
}

delete_failing_repos() {
    while IFS= read -r repo_info; do
        repo_path=$(dirname "$repo_info")
        repo_name=$(basename "$repo_info")
        echo "Deleted repository: $repo_info" | tee -a "$WORK_DIR/deleted_repositories.txt"
        rm -rf "$WORK_DIR/$repo_path/$repo_name"
        rm -rf "$WORK_DIR/.repo/project/$repo_path/$repo_name"/*.git
    done <<< "$(awk '/Failing repos:/ {flag=1; next} /Try/ {flag=0} flag' /tmp/output.txt)"
}

delete_repos_with_uncommitted_changes() {
    grep 'uncommitted changes are present' /tmp/output.txt | while IFS= read -r line; do
        repo_info=$(echo "$line" | awk -F': ' '{print $2}')
        repo_path=$(dirname "$repo_info")
        repo_name=$(basename "$repo_info")
        echo "Deleted repository: $repo_info" | tee -a "$WORK_DIR/deleted_repositories.txt"
        rm -rf "$WORK_DIR/$repo_path/$repo_name"
        rm -rf "$WORK_DIR/.repo/project/$repo_path/$repo_name"/*.git
    done
}

sync_repos() {
    find "$WORK_DIR/.repo" -name '*.lock' -delete
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags --prune 2>&1 | tee /tmp/output.txt
}

init_repo() {
    repo init -u https://github.com/RisingOS-staging/android -b fourteen --git-lfs --depth=1
}

main() {
    cd "$WORK_DIR" || exit 1

    update_repo_tool

    sync_repos

    if ! grep -qe "Failing repos:\|uncommitted changes are present" /tmp/output.txt; then
        echo "All repositories synchronized successfully."
        rm -f "$WORK_DIR/deleted_repositories.txt"
        exit 0
    fi

    rm -f "$WORK_DIR/deleted_repositories.txt"

    if grep -q "Failing repos:" /tmp/output.txt; then
        echo "Deleting failing repositories..."
        delete_failing_repos
    fi

    if grep -q "uncommitted changes are present" /tmp/output.txt; then
        echo "Deleting repositories with uncommitted changes..."
        delete_repos_with_uncommitted_changes
    fi

    echo "Initializing and re-syncing all repositories..."
    init_repo
    sync_repos

    rm -f "$WORK_DIR/deleted_repositories.txt"
}

main "$@"