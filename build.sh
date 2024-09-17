#!/bin/bash bash
set -e
cd /home/sketu/rising

source build/envsetup.sh

export BUILD_USERNAME=${GIT_USER}
export BUILD_HOSTNAME=risingos-ci

riseup ${CODENAME} ${TYPE}

if [ "$SIGNING" == "normal" ]; then
    rise b
elif [ "$SIGNING" == "normal-fastboot" ]; then
    rise fb
elif [ "$SIGNING" == "full" ]; then
    rise sb
fi
