#!/bin/bash

VARIANT=$(echo "$VARIANT" | tr '[:lower:]' '[:upper:]')
update_flag() {
    local flag="$1"
    local value="$2"
    local line="$flag := $value"
    if ! grep -q "$flag" "$tmp_file"; then
        echo "$line" >> "$tmp_file"
        changes_made=true
    elif ! grep -q "$line" "$tmp_file"; then
        sed -i "s/^$flag :=.*/$line/" "$tmp_file"
        changes_made=true
    fi
}

process_file() {
    local file="$1"
    local tmp_file=$(mktemp)
    local changes_made=false

    cp "$file" "$tmp_file"

    case "$VARIANT" in
        VANILLA)
            update_flag "WITH_GMS" "false"
            update_flag "TARGET_CORE_GMS" "false"
            update_flag "TARGET_DEFAULT_PIXEL_LAUNCHER" "false"
            ;;
        CORE)
            update_flag "WITH_GMS" "true"
            update_flag "TARGET_CORE_GMS" "true"
            ;;
        GAPPS)
            update_flag "WITH_GMS" "true"
            update_flag "TARGET_CORE_GMS" "false"
            ;;
    esac

    if [ "$changes_made" = true ]; then
        mv "$tmp_file" "$file"
        echo "Modified: $file"
        echo "  - Updated flags for $VARIANT Build"
    else
        rm "$tmp_file"
        echo "No changes needed for: $file"
    fi
}

find "/home/sketu/rising/device/$BRAND/$CODENAME" -name "lineage_$CODENAME.mk" | while read -r file; do
    process_file "$file"
done