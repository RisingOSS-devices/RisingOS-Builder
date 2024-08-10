#!/usr/bin/env bash
set -e

cd /home/sketu/rising

rm -rf out/error*.log
rm -rf out/target/product/$CODENAME
rm -rf .repo/local_manifests
rm -rf .repo/projects/device/$BRAND
rm -rf .repo/projects/vendor/$BRAND
rm -rf .repo/projects/kernel/$BRAND
rm -rf vendor/lineage-priv/keys/

wipe_cloned_repositories() {
    local repositories_file="cloned_repositories.txt"

    if [[ -f "$repositories_file" ]]; then
        echo "Wiping directories listed in: $repositories_file"
        while IFS= read -r path; do
            if [[ -d "$path" ]]; then
                echo "Removing directory: $path"
                rm -rf "$path"
            else
                echo "Directory does not exist: $path"
            fi
        done < "$repositories_file"
    else
        echo "No cloned_repositories.txt file found."
    fi
}

wipe_cloned_repositories
rm -rf cloned_repositories.txt