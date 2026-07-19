# Enable container runtime support.
DISTRO_FEATURES:append = " virtualization"

# Docker Engine and Docker Compose V2.
IMAGE_INSTALL:append = " \
    docker-moby \
    docker-compose \
"
