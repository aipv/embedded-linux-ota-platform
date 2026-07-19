#!/bin/sh

set -eu

APP_NAME="docker-demo-app"
IMAGE_NAME="docker-demo-app:1.0.0-arm64"
IMAGE_ARCHIVE="/usr/share/docker-images/docker-demo-app-1.0.0-arm64.tar"

HOST_PORT="${HOST_PORT:-8080}"
CONTAINER_PORT="8080"

log()
{
    echo "[docker-demo-app] $*"
}

# Make sure Docker is available.
if ! docker info >/dev/null 2>&1; then
    log "Docker daemon is not available"
    exit 1
fi

# Load the image only when it is not already present.
if ! docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
    if [ ! -f "${IMAGE_ARCHIVE}" ]; then
        log "Image archive not found: ${IMAGE_ARCHIVE}"
        exit 1
    fi

    log "Loading Docker image from ${IMAGE_ARCHIVE}"
    docker load -i "${IMAGE_ARCHIVE}"
else
    log "Docker image already loaded: ${IMAGE_NAME}"
fi

# If the container already exists, start it when necessary.
if docker container inspect "${APP_NAME}" >/dev/null 2>&1; then
    RUNNING="$(docker container inspect \
        --format '{{.State.Running}}' \
        "${APP_NAME}")"

    if [ "${RUNNING}" = "true" ]; then
        log "Container is already running"
    else
        log "Starting existing container"
        docker start "${APP_NAME}"
    fi

    exit 0
fi

# Create and start the container.
log "Creating container ${APP_NAME}"

docker run -d \
    --name "${APP_NAME}" \
    --restart unless-stopped \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    -e APP_NAME="Docker Demo App" \
    -e APP_VERSION="1.0.0" \
    "${IMAGE_NAME}"

log "Container started successfully"

