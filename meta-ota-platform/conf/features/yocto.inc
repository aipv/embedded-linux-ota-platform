#
# Yocto build configuration
#

# Distribution
DISTRO ?= "poky"

# Shared download and sstate cache
DL_DIR ?= "${TOPDIR}/../../../yocto-cache/downloads"
SSTATE_DIR ?= "${TOPDIR}/../../../yocto-cache/sstate-cache"

# Build options
USER_CLASSES ?= "buildstats"
PATCHRESOLVE = "noop"
