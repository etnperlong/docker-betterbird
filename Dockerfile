#
# betterbird Dockerfile
#
# https://github.com/etnperlong/docker-betterbird
#

# Pull base image.
FROM jlesage/baseimage-gui:debian-13-v4.13.2

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG BETTERBIRD_VERSION=153.1.0esr-bb7
ARG BETTERBIRD_SHA256=119083762fadba6b86681c0373f9ff5c11d87773e1422eed10756932c135307f

# Define software download URLs.
ARG BETTERBIRD_URL=https://www.betterbird.eu/downloads/LinuxArchive/betterbird-${BETTERBIRD_VERSION}.en-US.linux-x86_64.tar.xz

# Define working directory.
WORKDIR /tmp

# Install Betterbird runtime dependencies.
RUN \
    add-pkg \
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
        libxrender1 \
        locales && \
    localedef -i en_US -f UTF-8 en_US.UTF-8

# Download and install the official Betterbird Linux archive.
RUN \
    add-pkg --virtual build-dependencies ca-certificates curl xz-utils && \
    curl -fL -o betterbird.tar.xz "$BETTERBIRD_URL" && \
    echo "$BETTERBIRD_SHA256  betterbird.tar.xz" | sha256sum -c - && \
    tar -xJf betterbird.tar.xz -C /opt && \
    rm betterbird.tar.xz && \
    install_app_icon.sh /opt/betterbird/chrome/icons/default/default256.png && \
    del-pkg build-dependencies

# Install extra packages.
RUN \
    add-pkg \
        # Icons used by folder/file selection window (when saving as).
        adwaita-icon-theme \
        # A font is needed.
        fonts-dejavu

# Add files.
COPY rootfs/ /

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "Betterbird" && \
    set-cont-env APP_VERSION "$BETTERBIRD_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

# Define mountable directories.
VOLUME ["/config"]

# Metadata.
LABEL \
      org.label-schema.name="betterbird" \
      org.label-schema.description="Docker container for Betterbird" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/etnperlong/docker-betterbird" \
      org.label-schema.schema-version="1.0"
