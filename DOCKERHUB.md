# Docker container for Betterbird
[![Release](https://img.shields.io/github/release/etnperlong/docker-betterbird.svg?logo=github&style=for-the-badge)](https://github.com/etnperlong/docker-betterbird/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/etnperlong/betterbird/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/etnperlong/betterbird/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/etnperlong/betterbird?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/etnperlong/betterbird)
[![Docker Stars](https://img.shields.io/docker/stars/etnperlong/betterbird?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/etnperlong/betterbird)
[![Build Status](https://img.shields.io/github/actions/workflow/status/etnperlong/docker-betterbird/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/etnperlong/docker-betterbird/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/etnperlong/docker-betterbird)

This project provides a lightweight Docker container for
[Betterbird](https://www.betterbird.eu), based on the
[LinuxServer.io Selkies base image](https://github.com/linuxserver/docker-baseimage-selkies).

The full graphical application is available from any modern web browser, with
audio playback, seamless clipboard sharing, file upload/download, and PWA
installation provided by the Selkies web client.

> [!NOTE]
> This Docker container is entirely unofficial and not made by the creators of
> Betterbird.

## Quick Start

`--shm-size=1gb` is required.

```shell
docker run -d \
    --name=betterbird \
    --shm-size=1gb \
    -p 3001:3001 \
    -v /docker/appdata/betterbird:/config:rw \
    etnperlong/betterbird
```

Browse to `https://your-host-ip:3001/`. The container serves HTTPS with a
self-signed certificate generated on first start; replace
`/config/ssl/cert.pem` and `/config/ssl/cert.key` to use your own.

| Port | Description |
|------|-------------|
| 3001 | HTTPS web interface. |
| 3000 | Plain HTTP for a reverse proxy only; not usable directly in a browser. |

| Volume | Description |
|--------|-------------|
| `/config` | Profile, settings, logs, and persistent files. |

Common environment variables: `PUID`/`PGID` (default `1000`), `TZ`,
`LC_ALL`, `PASSWORD` (no authentication at all when unset), `CUSTOM_USER`
(default `abc`), `SUBFOLDER`, `GTK_THEME=Adwaita:dark` for dark mode.

## Documentation

Full documentation, including environment variables, reverse proxy examples,
GPU acceleration, logs, and migration notes, is available at
https://github.com/etnperlong/docker-betterbird#readme.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/etnperlong/docker-betterbird/issues).
