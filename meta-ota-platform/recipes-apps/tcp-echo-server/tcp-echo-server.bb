SUMMARY = "TCP Echo Server"
DESCRIPTION = "A simple TCP echo server that echoes back received data"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${THISDIR}/LICENSE;md5=df91d3c006831f6a500cdcff355b065a"

SRC_URI = "git://github.com/aipv/tcp_echo_server.git;branch=main;protocol=https"

SRCREV = "d337ab78c880e2d6b3c695a43657df91daf393f2"

S = "${WORKDIR}/git"

inherit systemd

SYSTEMD_SERVICE:${PN} = "tcp-echo-server.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_compile() {
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 tcp_echo_server ${D}${bindir}

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/git/tcp-echo-server.service \
        ${D}${systemd_system_unitdir}
}

FILES:${PN} += "${systemd_system_unitdir}/tcp-echo-server.service"
