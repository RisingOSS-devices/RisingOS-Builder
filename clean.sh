#!/usr/bin/env bash
set -e

cd /home/sketu/rising

remove_directories() {
    local dirs=(
        ".repo/local_manifests"
        ".repo/projects/device/$BRAND"
        ".repo/projects/vendor/$BRAND"
        ".repo/projects/vendor/risingOTA.git"
        ".repo/projects/kernel/$BRAND"
        "out/error*.log"
        "out/target/product/$CODENAME"
        "vendor/risingOTA"
        "vendor/lineage-priv/keys/"
    )

    for dir in "${dirs[@]}"; do
        rm -rf "$dir"
    done
}

wipe_cloned_repositories() {
    local repositories_file="cloned_repositories.txt"

    if [[ -f "$repositories_file" ]]; then
        echo "Wiping directories listed in: $repositories_file"
        while IFS= read -r path; do
            if [[ -d "$path" ]]; then
                echo "Removing directory: $path"
                rm -rf "$path"
                repo_path=".repo/project/$(basename "$path").git"
                [[ -d "$repo_path" ]] && rm -rf "$repo_path"
            else
                echo "Directory does not exist: $path"
            fi
        done < "$repositories_file"
    else
        echo "No cloned_repositories.txt file found."
    fi
}

remove_directories
wipe_cloned_repositories
rm -rf cloned_repositories.txt