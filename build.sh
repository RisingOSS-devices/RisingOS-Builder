#!/bin/bash bash
set -e
USE_CCACHE=0
cd /home/sketu/rising
. build/envsetup.sh
riseup ${CODENAME} ${TYPE}

if [ "$SIGNING" == "normal" ]; then
    rise b | tee build.log
elif [ "$SIGNING" == "full" ]; then
    rise sb | tee build.log
elif [ "$SIGNING" == "normal-fastboot" ]; then
    rise fb | tee build.log
fi
