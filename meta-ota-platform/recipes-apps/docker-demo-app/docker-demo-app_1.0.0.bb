SUMMARY = "Docker Demo App container image and startup service"
DESCRIPTION = "Installs the Docker Demo App ARM64 image and starts it automatically"
LICENSE = "CLOSED"

SRC_URI = " \
    file://docker-demo-app-1.0.0-arm64.tar;unpack=0 \
    file://docker-demo-app-start.sh \
    file://docker-demo-app.service \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "docker-demo-app.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN} += " \
    docker \
"

do_install() {
    # Docker image archive
    install -d ${D}${datadir}/docker-images
    install -m 0644 \
        ${WORKDIR}/docker-demo-app-1.0.0-arm64.tar \
        ${D}${datadir}/docker-images/docker-demo-app-1.0.0-arm64.tar

    # Startup script
    install -d ${D}${sbindir}
    install -m 0755 \
        ${WORKDIR}/docker-demo-app-start.sh \
        ${D}${sbindir}/docker-demo-app-start

    # systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 \
        ${WORKDIR}/docker-demo-app.service \
        ${D}${systemd_system_unitdir}/docker-demo-app.service
}

FILES:${PN} += " \
    ${datadir}/docker-images/docker-demo-app-1.0.0-arm64.tar \
    ${sbindir}/docker-demo-app-start \
    ${systemd_system_unitdir}/docker-demo-app.service \
"
