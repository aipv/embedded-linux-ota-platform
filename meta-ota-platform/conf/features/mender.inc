#
# Mender OTA configuration
#

INHERIT += "mender-full"
PREFERRED_VERSION_mender = "5.0.0"
PACKAGECONFIG:remove:pn-mender = "version-inventory-script"
MENDER_BOOT_PART_SIZE_MB = "64"
MENDER_UPDATE_POLL_INTERVAL_SECONDS = "60"
