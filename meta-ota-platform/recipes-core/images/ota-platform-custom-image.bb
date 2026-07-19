SUMMARY = "Embedded Linux OTA Platform Custom Image"

require recipes-core/images/ota-platform-default-image.bb

IMAGE_INSTALL:append = " \
    tree \
    systemd-analyze \
    image-version \
    tcp-echo-server \
    docker-demo-app \
"

IMAGE_INSTALL:append = " packagegroup-ota-platform-tools"
