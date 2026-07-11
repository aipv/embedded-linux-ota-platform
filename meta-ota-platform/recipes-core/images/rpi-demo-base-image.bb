SUMMARY = "Raspberry Pi demo base image"

require recipes-core/images/core-image-minimal.bb

IMAGE_INSTALL:append = " \
    tree \
    openssh \
    openssh-sshd \
    kernel-image \
    kernel-devicetree \
    mender-server-cert-config \
    image-version \
    systemd-analyze \
"

IMAGE_FSTYPES:remove = " rpi-sdimg"
SDIMG_ROOTFS_TYPE = "ext4"
EXTRA_IMAGE_FEATURES += "debug-tweaks"

ROOTFS_POSTPROCESS_COMMAND += "add_mender_demo_hosts;"

add_mender_demo_hosts() {
    echo "192.168.0.88 docker.mender.io s3.docker.mender.io" \
        >> ${IMAGE_ROOTFS}${sysconfdir}/hosts
}
