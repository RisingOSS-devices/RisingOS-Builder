#!/bin/bash

VARIANT=$(echo "$VARIANT" | tr '[:lower:]' '[:upper:]')
process_file() {
    local file="$1"
    local tmp_file=$(mktemp)
    local with_gms_found=false
    local target_core_gms_found=false
    local target_default_pixel_launcher_found=false
    local changes_made=false

    while IFS= read -r line; do
        if [[ "$line" =~ WITH_GMS ]]; then
            with_gms_found=true
            new_line="WITH_GMS := $([ "$VARIANT" != "VANILLA" ] && echo "true" || echo "false")"
            if [ "$line" != "$new_line" ]; then
                line="$new_line"
                changes_made=true
            fi
        elif [[ "$line" =~ TARGET_CORE_GMS ]]; then
            target_core_gms_found=true
            new_line="TARGET_CORE_GMS := $([ "$VARIANT" == "CORE" ] && echo "true" || echo "false")"
            if [ "$line" != "$new_line" ]; then
                line="$new_line"
                changes_made=true
            fi
        elif [[ "$line" =~ TARGET_DEFAULT_PIXEL_LAUNCHER ]]; then
            target_default_pixel_launcher_found=true
            if [ "$VARIANT" == "VANILLA" ]; then
                new_line="TARGET_DEFAULT_PIXEL_LAUNCHER := false"
                if [ "$line" != "$new_line" ]; then
                    line="$new_line"
                    changes_made=true
                fi
            fi
        fi
        echo "$line" >> "$tmp_file"
    done < "$file"

    if [ "$VARIANT" == "CORE" ]; then
        if [ "$with_gms_found" = false ]; then
            echo "WITH_GMS := true" >> "$tmp_file"
            changes_made=true
        fi
        if [ "$target_core_gms_found" = false ]; then
            echo "TARGET_CORE_GMS := true" >> "$tmp_file"
            changes_made=true
        fi
    elif [ "$VARIANT" == "GAPPS" ] && [ "$with_gms_found" = false ]; then
        echo "WITH_GMS := true" >> "$tmp_file"
        changes_made=true
    fi

    if [ "$changes_made" = true ]; then
        mv "$tmp_file" "$file"
        echo "Modified: $file"
        echo "  - Updated flags for $VARIANT Build"
    else
        rm "$tmp_file"
        echo "No changes needed for: $file"
    fi
}

find "/home/sketu/test/device/$BRAND/$CODENAME" -name "lineage_$CODENAME.mk" | while read -r file; do
    process_file "$file"
done