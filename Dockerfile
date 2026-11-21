#
# betterbird Dockerfile
#
# https://github.com/etnperlong/docker-betterbird
#

# Pull base image. Base images have no `latest` tag; pin a versioned tag.
FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie-f7632021-ls153

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software build metadata.
ARG BETTERBIRD_VERSION=unknown
ARG BETTERBIRD_PATCH_REVISION=unknown
ARG TARGETARCH

# Install Betterbird runtime dependencies.
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        # Icons used by folder/file selection window (when saving as).
        adwaita-icon-theme \
        libasound2t64 \
        libatk1.0-0t64 \
        libcairo-gobject2 \
        libcairo2 \
        libdbus-1-3 \
        libfontconfig1 \
        libfreetype6 \
        libgdk-pixbuf-2.0-0 \
        libglib2.0-0t64 \
        libgtk-3-0t64 \
        libpango-1.0-0 \
        libstdc++6 \
        libx11-6 \
        libx11-xcb1 \
        libxcb-shm0 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 && \
    rm -rf /var/lib/apt/lists/*

# Install the native Betterbird package produced by the package build jobs.
COPY build/betterbird/ /tmp/betterbird/
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends file xz-utils && \
    cd /tmp/betterbird && \
    sha256sum -c betterbird.tar.xz.sha256 && \
    tar -xJf betterbird.tar.xz -C /opt && \
    test -x /opt/betterbird/betterbird-bin && \
    case "$TARGETARCH" in \
        amd64) expected_architecture="x86-64" ;; \
        arm64) expected_architecture="ARM aarch64" ;; \
        *) echo "Unsupported target architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    file /opt/betterbird/betterbird-bin | grep -F "$expected_architecture" && \
    install -Dm644 provenance.json /usr/share/doc/betterbird/build-provenance.json && \
    # Favicon and PWA icon of the web client.
    install -Dm644 /opt/betterbird/chrome/icons/default/default256.png /usr/share/selkies/www/icon.png && \
    cd / && \
    apt-get autoclean && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# Add files.
COPY rootfs/ /

# Single-app defaults: Wayland session, restart Betterbird when it exits, keep
# the UID/GID of volumes created by the previous jlesage-based image, and turn
# off base features a mail client does not use (inner Docker, gamepads, Steam
# shim, virtual webcam, unauthenticated sharing links).
ENV TITLE=Betterbird \
    PIXELFLUX_WAYLAND=true \
    RESTART_APP=true \
    PUID=1000 \
    PGID=1000 \
    START_DOCKER=false \
    NO_GAMEPAD=true \
    NO_STEAM=true \
    NO_WEBCAM=true \
    SELKIES_ENABLE_SHARING=false

# Ports and volumes.
EXPOSE 3000 3001
VOLUME ["/config"]

# Metadata.
LABEL \
      org.label-schema.name="betterbird" \
      org.label-schema.description="Docker container for Betterbird" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/etnperlong/docker-betterbird" \
      io.github.etnperlong.betterbird.version="${BETTERBIRD_VERSION}" \
      io.github.etnperlong.betterbird.patch-revision="${BETTERBIRD_PATCH_REVISION}" \
      org.label-schema.schema-version="1.0"
