# Docker container for Betterbird
[![Release](https://img.shields.io/github/release/etnperlong/docker-betterbird.svg?logo=github&style=for-the-badge)](https://github.com/etnperlong/docker-betterbird/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/etnperlong/betterbird/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/etnperlong/betterbird/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/etnperlong/betterbird?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/etnperlong/betterbird)
[![Docker Stars](https://img.shields.io/docker/stars/etnperlong/betterbird?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/etnperlong/betterbird)
[![Build Status](https://img.shields.io/github/actions/workflow/status/etnperlong/docker-betterbird/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/etnperlong/docker-betterbird/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/etnperlong/docker-betterbird)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This project provides a lightweight and secure Docker container for
[Betterbird](https://www.betterbird.eu).

Access the application's full graphical interface directly from any modern web
browser - no downloads, installs, or setup required on the client side - or
connect with any VNC client.

The web interface also offers audio playback, seamless clipboard sharing, an
integrated file manager and terminal for accessing the container's files and
shell, desktop notifications, and more.

> [!NOTE]
> This Docker container is entirely unofficial and not made by the creators of
> Betterbird.

---

[![Betterbird logo](https://images.weserv.nl/?url=www.betterbird.eu/media/img/betterbird-256.png&w=110)](https://www.betterbird.eu)[![Betterbird](https://images.placeholders.dev/?width=352&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=Betterbird&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://www.betterbird.eu)

Betterbird is a fine-tuned soft fork of Mozilla Thunderbird with additional
features and bug fixes.

---

## Quick Start

**NOTE**:
    The Docker command provided in this quick start is an example, and parameters
    should be adjusted to suit your needs.

**NOTE**:
    The official Betterbird Linux archive is currently available only for
    x86-64, so this image supports `linux/amd64` only.

Launch the Betterbird docker container with the following command:
```shell
docker run -d \
    --name=betterbird \
    -p 5800:5800 \
    -v /docker/appdata/betterbird:/config:rw \
    etnperlong/betterbird
```

Where:

  - `/docker/appdata/betterbird`: Stores the application's configuration, state, logs, and any files requiring persistency.

Access the Betterbird GUI by browsing to `http://your-host-ip:5800`.

## Documentation

Full documentation is available at https://github.com/etnperlong/docker-betterbird.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/etnperlong/docker-betterbird/issues).

For other Dockerized applications, visit https://jlesage.github.io/docker-apps.
