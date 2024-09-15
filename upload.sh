#!/usr/bin/env bash
set -e

upload_to_drive() {
    local file="$1"
    rclone copy "$file" rising:Release/$CODENAME -P
    if [ $? -eq 0 ]; then
        echo "Uploaded $file to drive successfully."
    else
        echo "Error: Upload of $file to drive failed."
        return 1
    fi
}

upload_to_sourceforge() {
    local file="$1"
    echo "Attempting to upload $file to SourceForge..."
    sshpass -p "$SF_PASSWORD" rsync -avP -e "ssh -o StrictHostKeyChecking=no" "$file" $SF_USERNAME@$SF_HOST:/home/frs/project/risingos-test/$CODENAME/
    if [ $? -eq 0 ]; then
        echo "Uploaded $file to SourceForge successfully."
    else
        echo "Error: Upload of $file to SourceForge failed."
        return 1
    fi
}

if [ "$#" -gt 1 ]; then
    usage
fi

if [ "$1" == "-sf" ]; then
    DESTINATION="sourceforge"
else
    DESTINATION="drive"
fi

TARGET_DIR="/home/sketu/rising/out/target/product/${CODENAME}"
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory '$TARGET_DIR' does not exist."
    exit 1
fi

cd "$TARGET_DIR"

case "$RELEASE" in
    stable)
        echo "RELEASE is set to 'stable'. Uploading stable build..."
        DESTINATION="drive"
        ;;
    test)
        echo "RELEASE is set to 'test'. Uploading test build..."
        DESTINATION="sourceforge"
        ;;
    *)
        echo "Error: Invalid RELEASE value. Must be 'stable' or 'test'."
        exit 1
        ;;
esac

FILES=(Rising*.zip)
for FILE in "${FILES[@]}"; do
    if [ ! -e "$FILE" ]; then
        echo "Error: File '$FILE' not found in $TARGET_DIR."
        exit 1
    fi
done

case $DESTINATION in
    drive)
        for FILE in "${FILES[@]}"; do
            upload_to_drive "$FILE" || exit 1
        done
        echo "All uploads to drive completed."
        echo "Uploaded to here: https://download-risingos.pages.dev/$CODENAME"
        ;;
    sourceforge)
        for FILE in "${FILES[@]}"; do
            upload_to_sourceforge "$FILE" || exit 1
        done
        echo "All uploads to SourceForge completed."
        echo "Uploaded to here: https://sourceforge.net/projects/risingos-test/files/$CODENAME"
        ;;
    *)
        echo "Error: Invalid destination '$DESTINATION'."
        exit 1
        ;;
esac