#!/usr/bin/env bash

if [[ "${OTA_PLATFORM_ENV:-0}" != "1" ]]; then
    echo "Please run:"
    echo "  source setup-environment"
    exit 1
fi

bitbake "${YOCTO_IMAGE}"
