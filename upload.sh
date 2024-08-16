#!/usr/bin/env bash
set -e

TARGET_DIR="/home/sketu/rising/out/target/product/${CODENAME}"
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory '$TARGET_DIR' does not exist."
    exit 1
fi

cd "$TARGET_DIR"

if [ -z "$RELEASE" ]; then
    echo "Error: The RELEASE environment variable is not set."
fi

case "$RELEASE" in
    stable)
        echo "RELEASE is set to 'stable'. Uploading stable build to drive..."
        upload RisingOS-*.zip boot.img recovery.img
        ;;
    test)
        echo "RELEASE is set to 'test'. Uploading test build to sourceforge..."
        upload -sf RisingOS-*.zip boot.img recovery.img
        ;;
    *)
        echo "Error: The RELEASE environment variable is not set."
        exit 1
        ;;
esac