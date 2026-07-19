SUMMARY = "Common tools for OTA platform"
LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = " \
    util-linux-lsblk \
    util-linux-fdisk \
"
