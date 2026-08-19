#
# betterbird Dockerfile
#
# https://github.com/etnperlong/docker-betterbird
#

# Pull base image.
FROM jlesage/baseimage-gui:debian-13-v4.13.2

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software build metadata.
ARG BETTERBIRD_VERSION=unknown
ARG BETTERBIRD_PATCH_REVISION=unknown
ARG TARGETARCH

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

# Install the native Betterbird package produced by the package build jobs.
COPY build/betterbird/ /tmp/betterbird/
RUN \
    add-pkg --virtual build-dependencies file xz-utils && \
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
    install_app_icon.sh /opt/betterbird/chrome/icons/default/default256.png && \
    cd /tmp && \
    rm -rf /tmp/betterbird && \
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
    set-cont-env BETTERBIRD_PATCH_REVISION "$BETTERBIRD_PATCH_REVISION" && \
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
      io.github.etnperlong.betterbird.patch-revision="${BETTERBIRD_PATCH_REVISION}" \
      org.label-schema.schema-version="1.0"
