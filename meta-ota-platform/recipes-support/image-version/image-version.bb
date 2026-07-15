SUMMARY = "Install image version information"
DESCRIPTION = "Install /etc/image-version with build info from image.conf"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

do_install() {
    install -d ${D}${sysconfdir}

    echo "Project    : ${PROJECT_NAME}" > ${D}${sysconfdir}/image-version
    echo "Image      : ${YOCTO_IMAGE}" >> ${D}${sysconfdir}/image-version
    echo "Release    : ${IMAGE_RELEASE}" >> ${D}${sysconfdir}/image-version
    echo "Build ID   : ${IMAGE_BUILD_ID}" >> ${D}${sysconfdir}/image-version
    echo "Comment    : ${IMAGE_COMMENT}" >> ${D}${sysconfdir}/image-version
    echo "Artifact   : ${MENDER_ARTIFACT_NAME}" >> ${D}${sysconfdir}/image-version

    BUILD_TIME="$(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Build Time : ${BUILD_TIME}" >> ${D}${sysconfdir}/image-version

    chmod 0644 ${D}${sysconfdir}/image-version
}

FILES:${PN} += "${sysconfdir}/image-version"
