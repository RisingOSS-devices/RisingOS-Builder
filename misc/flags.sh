#!/bin/bash

if [ -z "$VARIANT" ]; then
    echo "VARIANT environment variable is not set. Please set it to one of: VANILLA, CORE, GAPPS."
    exit 1
fi

value=$(echo "$VARIANT" | tr '[:lower:]' '[:upper:]')

if [[ "$value" != "VANILLA" && "$value" != "CORE" && "$value" != "GAPPS" ]]; then
    exit 1
fi

process_file() {
    local file="$1"
    local value="$2"
    tmp_file=$(mktemp)
    WITH_GMS_handled=false
    TARGET_CORE_GMS_handled=false
    
    while IFS= read -r line; do
        if [[ "$line" =~ WITH_GMS ]]; then
            WITH_GMS_handled=true
            case $value in
                VANILLA)
                    line="${line/true/false}"
                    ;;
                CORE)
                    if [[ "$line" == *"false"* ]]; then
                        line="${line/false/true}"
                    fi
                    ;;
                GAPPS)
                    line="${line/false/true}"
                    ;;
            esac
        fi

        if [[ "$value" == "CORE" && "$line" =~ TARGET_CORE_GMS ]]; then
            TARGET_CORE_GMS_handled=true
            line="TARGET_CORE_GMS := true"
        fi

        if [[ "$value" == "GAPPS" && "$line" =~ TARGET_CORE_GMS && "$line" == *"true"* ]]; then
            line="TARGET_CORE_GMS := false"
        fi

        echo "$line" >> "$tmp_file"
    done < "$file"
    if [[ "$value" == "VANILLA" && "$WITH_GMS_handled" == "false" ]]; then
        rm "$tmp_file"
        return
    fi
    mv "$tmp_file" "$file"
}

files=$(find device/$BRAND/$CODENAME -name 'lineage_$CODENAME.mk')

if [[ -z "$files" ]]; then
    exit 1
fi

for file in $files; do
    process_file "$file" "$value"
done