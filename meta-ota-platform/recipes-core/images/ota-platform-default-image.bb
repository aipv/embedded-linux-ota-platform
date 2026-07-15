SUMMARY = "Embedded Linux OTA Platform Default Image"

require recipes-core/images/core-image-minimal.bb

IMAGE_INSTALL:append = " \
    openssh \
    openssh-sshd \
    kernel-image \
    kernel-devicetree \
    mender-cert-config \
"

IMAGE_FSTYPES:remove = " rpi-sdimg"
SDIMG_ROOTFS_TYPE = "ext4"
EXTRA_IMAGE_FEATURES += "debug-tweaks"

ROOTFS_POSTPROCESS_COMMAND += "add_ota_platform_hosts;"

add_ota_platform_hosts() {
    echo "${PROJECT_MENDER_SERVER_HOST_IP} ${PROJECT_MENDER_SERVER_HOST} s3.${PROJECT_MENDER_SERVER_HOST}" \
        >> ${IMAGE_ROOTFS}${sysconfdir}/hosts
}
