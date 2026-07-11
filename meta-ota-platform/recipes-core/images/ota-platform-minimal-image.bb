SUMMARY = "Embedded Linux OTA Platform Minimal Image"

require recipes-core/images/core-image-minimal.bb

IMAGE_INSTALL:append = " \
    openssh \
    openssh-sshd \
    kernel-image \
    kernel-devicetree \
"

IMAGE_FSTYPES:remove = " rpi-sdimg"
SDIMG_ROOTFS_TYPE = "ext4"
EXTRA_IMAGE_FEATURES += "debug-tweaks"
