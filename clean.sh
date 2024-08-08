#!/usr/bin/env bash
set -e

cd /home/sketu/rising

rm -rf build.log
rm -rf out/target/*

rm -rf .repo/local_manifests
rm -rf .repo/projects/device/$BRAND
rm -rf .repo/projects/vendor/$BRAND
rm -rf .repo/projects/kernel/$BRAND
rm -rf .repo/projects/hardware
rm -rf /home/sketu/rising/vendor/lineage-priv/keys/

clean_dependencies() {
    local dependencies_file=$1

    if [[ -f "$dependencies_file" ]]; then
        echo "Cleaning dependencies from: $dependencies_file"
        jq -c '.[]' "$dependencies_file" | while read -r dependency; do
            local dependency_target_path
            dependency_target_path=$(echo "$dependency" | jq -r '.target_path')
            echo "Checking target path: $dependency_target_path"
            if [[ -d "$dependency_target_path" ]]; then
                echo "Removing directory: $dependency_target_path"
                rm -rf "$dependency_target_path"
            else
                echo "Directory does not exist: $dependency_target_path"
            fi
            local rising_dependencies="$dependency_target_path/rising.dependencies"
            local lineage_dependencies="$dependency_target_path/lineage.dependencies"
            if [[ -f "$rising_dependencies" ]]; then
                echo "Found rising.dependencies in: $dependency_target_path"
                clean_dependencies "$rising_dependencies"
            fi

            if [[ -f "$lineage_dependencies" ]]; then
                echo "Found lineage.dependencies in: $dependency_target_path"
                clean_dependencies "$lineage_dependencies"
            fi
        done
    fi
}

primary_dependencies="device/$BRAND/$CODENAME/rising.dependencies"
fallback_dependencies="device/$BRAND/$CODENAME/lineage.dependencies"

if [[ -f "$primary_dependencies" ]]; then
    echo "Cleaning dependencies from: $primary_dependencies"
    clean_dependencies "$primary_dependencies"
elif [[ -f "$fallback_dependencies" ]]; then
    echo "Cleaning dependencies from: $fallback_dependencies"
    clean_dependencies "$fallback_dependencies"
else
    echo "No dependency files found for device: $BRAND/$CODENAME"
fi

rm -rf device/$BRAND