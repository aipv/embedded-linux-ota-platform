#
# Yocto build configuration
#

# Distribution
DISTRO ?= "poky"

# Shared download and sstate cache
DL_DIR ?= "${TOPDIR}/downloads"
SSTATE_DIR ?= "${TOPDIR}/sstate-cache"

# Build options
USER_CLASSES ?= "buildstats"
PATCHRESOLVE = "noop"
