# Docker container for Betterbird
[![Release](https://img.shields.io/github/release/etnperlong/docker-betterbird.svg?logo=github&style=for-the-badge)](https://github.com/etnperlong/docker-betterbird/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/etnperlong/betterbird/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/etnperlong/betterbird/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/etnperlong/betterbird?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/etnperlong/betterbird)
[![Docker Stars](https://img.shields.io/docker/stars/etnperlong/betterbird?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/etnperlong/betterbird)
[![Build Status](https://img.shields.io/github/actions/workflow/status/etnperlong/docker-betterbird/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/etnperlong/docker-betterbird/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/etnperlong/docker-betterbird)

> [!IMPORTANT]
> **Fork notice:** This project started from
> [jlesage/docker-thunderbird](https://github.com/jlesage/docker-thunderbird) and
> is now based on the [LinuxServer.io Selkies base
> image](https://github.com/linuxserver/docker-baseimage-selkies)
> (`ghcr.io/linuxserver/baseimage-selkies:debiantrixie`, Debian 13). It replaces
> Thunderbird with Betterbird and source-builds pinned Betterbird packages for
> native `linux/amd64` and `linux/arm64` image builds.

This project provides a lightweight Docker container for
[Betterbird](https://www.betterbird.eu).

Access the application's full graphical interface directly from any modern web
browser — no downloads, installs, or setup required on the client side. The
Selkies web client adds audio playback, seamless clipboard sharing (text and
images), file upload/download, multiple monitors, touch and on-screen keyboard
input, and installation as a web app (PWA).

> [!NOTE]
> This Docker container is entirely unofficial and not made by the creators of
> Betterbird.

---

[![Betterbird logo](https://images.weserv.nl/?url=www.betterbird.eu/media/img/betterbird-256.png&w=110)](https://www.betterbird.eu)[![Betterbird](https://images.placeholders.dev/?width=352&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=Betterbird&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://www.betterbird.eu)

Betterbird is a fine-tuned soft fork of Mozilla Thunderbird with additional
features and bug fixes.

## Supported Architectures

The image supports `linux/amd64` and `linux/arm64`. Betterbird packages for
both architectures are built from the same pinned Thunderbird source and
Betterbird patch revision on native GitHub Actions runners.

These packages are unofficial builds produced by this project. Their archives,
SHA-256 checksums, and build provenance are passed between workflow jobs as
GitHub Actions artifacts.

---

## Table of Contents

   * [Quick Start](#quick-start)
   * [Build Pipeline](#build-pipeline)
   * [Docker Compose File](#docker-compose-file)
   * [Environment Variables](#environment-variables)
   * [Data Volumes](#data-volumes)
   * [Ports](#ports)
   * [Security](#security)
   * [Reverse Proxy](#reverse-proxy)
      * [Routing Based on Hostname](#routing-based-on-hostname)
      * [Routing Based on URL Path](#routing-based-on-url-path)
   * [Input Methods and Fonts](#input-methods-and-fonts)
   * [GPU Acceleration](#gpu-acceleration)
   * [Dark Mode](#dark-mode)
   * [Logs](#logs)
   * [Shell Access](#shell-access)
   * [Migrating from the jlesage-based Image](#migrating-from-the-jlesage-based-image)
   * [Docker Image Versioning and Tags](#docker-image-versioning-and-tags)
   * [Docker Image Update](#docker-image-update)
   * [Licensing](#licensing)
   * [Support or Contact](#support-or-contact)

## Quick Start

> [!IMPORTANT]
> The Docker command provided in this quick start is an example, and parameters
> should be adjusted to suit your needs.

> [!IMPORTANT]
> `--shm-size=1gb` is required. The session uses shared memory for its
> compositor and audio, and the Docker default of 64 MB can crash the web
> client.

> [!NOTE]
> Docker automatically selects the native `linux/amd64` or `linux/arm64` image
> for the host platform.

Launch the Betterbird docker container with the following command:

```shell
docker run -d \
    --name=betterbird \
    --shm-size=1gb \
    -p 3001:3001 \
    -v /docker/appdata/betterbird:/config:rw \
    etnperlong/betterbird
```

Where:

  - `/docker/appdata/betterbird`: Stores the application's configuration,
    profile, logs, and any files requiring persistency.

Access the Betterbird GUI by browsing to `https://your-host-ip:3001/`. The
container serves HTTPS with a self-signed certificate generated on first start,
so the browser shows a certificate warning until you install your own
certificate (see [Security](#security)).

## Build Pipeline

The GitHub Actions workflow builds the application and container in two native
architecture matrices:

1. `ubuntu-24.04` and `ubuntu-24.04-arm` compile Betterbird from the pinned
   inputs in `build/betterbird.env`.
2. Each package job uploads its tarball, SHA-256 checksum, and provenance file
   as a workflow artifact.
3. Native image jobs download the matching artifact and provide it to the
   Docker build context. The Dockerfile does not download application binaries.
4. Release builds push each platform by digest and merge both digests into the
   final multi-platform manifest.

The current package is Betterbird `153.6.0esr-bb12`, built from Mozilla's
[Thunderbird 153.6.0esr build1 candidate source archive](https://archive.mozilla.org/pub/thunderbird/candidates/153.6.0esr-candidates/build1/source/thunderbird-153.6.0esr.source.tar.xz)
(SHA-256 `5fabe3918c8d34b2c4892745a16e83b3a94314ff2831aee03c0d5f7b5c632ba6`)
with the [stable Betterbird 153.6.0esr-bb12 patch revision](https://github.com/Betterbird/thunderbird-patches/tree/153.6.0esr-bb12),
pinned to commit `b3bf122cf8f2deea3b89979a42e0809ce4a53b13`. See the
[Betterbird downloads](https://www.betterbird.eu/downloads/) and
[release notes](https://www.betterbird.eu/releasenotes/) for upstream release
information.

The project's `SOURCE_DATE_EPOCH` is set from that stable patch commit's
timestamp (`2026-10-27T09:53:32Z`) for reproducible builds; it is not the
official binary build date.

Package artifacts are temporary workflow data. Published container images do
not depend on an artifact remaining available after the workflow completes.

## Docker Compose File

Below is an example `docker-compose.yml` file for use with
[Docker Compose](https://docs.docker.com/compose/overview/). Adjust the
configuration to suit your needs.

```yaml
services:
  betterbird:
    image: etnperlong/betterbird
    container_name: betterbird
    restart: unless-stopped
    shm_size: 1gb
    ports:
      - "3001:3001"
    volumes:
      - "/docker/appdata/betterbird:/config:rw"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      # - PASSWORD=change-me
```

## Environment Variables

To customize the container's behavior, pass environment variables using the
`-e` parameter in the format `<VARIABLE_NAME>=<VALUE>`. All variables are
optional; the defaults below are baked into the image.

| Variable                    | Description                                                                                                                       | Default |
|-----------------------------|-----------------------------------------------------------------------------------------------------------------------------------|---------|
|`PUID`| User ID the session and Betterbird run as, and owner of `/config`. Matches the previous image's default so existing volumes keep their ownership. | `1000` |
|`PGID`| Group ID for the same user.                                                                                                       | `1000` |
|`TZ`| Timezone used by the container.                                                                                                   | `Etc/UTC` |
|`LC_ALL`| Session locale, for example `de_DE.UTF-8` or `zh_CN.UTF-8`. All locales are prebuilt.                                             | (unset) |
|`PASSWORD`| HTTP basic-auth password for the web interface. **Unset means no authentication at all.** See [Security](#security).             | (unset) |
|`CUSTOM_USER`| Basic-auth username used together with `PASSWORD`.                                                                                | `abc` |
|`SUBFOLDER`| Path prefix when the container is served from a subfolder. Both slashes are required, e.g. `/betterbird/`.                        | `/` |
|`TITLE`| Browser tab title and PWA application name.                                                                                       | `Betterbird` |
|`PIXELFLUX_WAYLAND`| `true` runs the labwc Wayland session; `false` switches to the X11/Openbox stack.                                                 | `true` |
|`RESTART_APP`| Restarts Betterbird automatically when it exits.                                                                                  | `true` |
|`SELKIES_ENCODER`| Video encoders offered in the sidebar menu. Narrow it to one value, e.g. `h264enc`, to force it.                                  | `h264enc,h265enc,vp8enc,vp9enc,av1enc,jpeg` |
|`SELKIES_FRAMERATE`| Frame-rate range offered in the sidebar; the session starts at 60 fps.                                                            | `8-240` |
|`SELKIES_AUDIO_ENABLED`| Streams session audio to the browser.                                                                                             | `true` |
|`SELKIES_MICROPHONE_ENABLED`| Lets the browser send a microphone feed into the session.                                                                         | `false` |
|`SELKIES_ENABLE_CLIPBOARD`| Clipboard policy: `true`, `in`, `out`, or `false`.                                                                                | `true` |
|`SELKIES_FILE_TRANSFERS`| Allowed file-transfer directions: `upload,download`, `upload`, `download`, or `""` to disable.                                     | `upload,download` |
|`FILE_MANAGER_PATH`| Directory exposed to uploads and the Files panel.                                                                                 | `~/Desktop` (`/config/Desktop`) |
|`SELKIES_ENABLE_SHARING`| Unauthenticated sharing and collaboration links.                                                                                  | `false` |
|`HARDEN_DESKTOP`| `true` disables terminals, passwordless `sudo`, open-with helpers, file transfers, and printing, for a locked-down session.        | (unset) |
|`DRINODE`| Render node (EGL/3D) to use, e.g. `/dev/dri/renderD128`. Defaults to auto-selection.                                              | (unset) |
|`DRI_NODE`| Encode node used for hardware video encoding. The single underscore is intentional and differs from `DRINODE`.                    | (unset) |
|`NO_DECOR`| `true` hides window decorations. Can also be toggled in the session with `Ctrl+Shift+D`.                                          | (unset) |
|`NO_FULL`| `true` stops the Betterbird window from being maximized on launch.                                                                | (unset) |

The complete, much longer list of Selkies and LinuxServer.io variables is
documented at
<https://docs.linuxserver.io/selkies/user-guide/configuration/>.

## Data Volumes

Volume mappings are set using the `-v` parameter with a value in the format
`<HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]`.

| Container path  | Permissions | Description |
|-----------------|-------------|-------------|
|`/config`| rw | Stores the application's profile, configuration, state, logs, and any files requiring persistency. It is the home directory of the container user. |

Nothing outside `/config` survives a container update. Inside `/config`:

  - `profile/`: Betterbird profile (accounts, mail, settings).
  - `log/betterbird/`: application logs, see [Logs](#logs).
  - `Desktop/`: default upload and download location.
  - `ssl/`: certificate used for HTTPS.

## Ports

When using the default bridge network, ports are published with the `-p`
parameter using the format `<HOST_PORT>:<CONTAINER_PORT>`. See the Docker
[container networking](https://docs.docker.com/config/containers/container-networking)
documentation for details.

| Port | Protocol | Mapping to Host | Description |
|------|----------|-----------------|-------------|
| 3001 | TCP | Required | HTTPS web interface. Browse the GUI here. |
| 3000 | TCP | Optional | Plain HTTP. Only a target for a reverse proxy; opening it directly in a browser yields a broken client because the video decoder and clipboard require a secure context. |

## Security

  - **HTTPS is mandatory.** The session uses WebCodecs for video/audio and
    `navigator.clipboard` for clipboard sync; both only work in a secure
    context. Always use `https://host:3001/` (or a TLS-terminating reverse
    proxy).
  - **A self-signed certificate is generated on first start** at
    `/config/ssl/cert.pem` and `/config/ssl/cert.key`. Replace both files with
    your own certificate chain and key (same names, PEM format) and restart the
    container. A browser-trusted certificate is also required to install the
    interface as a PWA.
  - **There is no authentication by default.** Setting `PASSWORD` (and
    optionally `CUSTOM_USER`, default `abc`) enables HTTP basic auth at the
    bundled NGINX. This is a single shared credential with no session handling;
    for anything reachable from the internet, terminate at a reverse proxy with
    real authentication (Authelia, Authentik, SWAG, or similar).
  - **Sharing links are disabled** (`SELKIES_ENABLE_SHARING=false`). If you
    enable them, anyone with the link gets the full session without logging in.
  - **The session is root-equivalent inside the container.** `HARDEN_DESKTOP=true`
    removes terminals, `sudo`, file transfers, and printing from the session.
  - The inner Docker daemon is disabled (`START_DOCKER=false`); do not add
    `--privileged` or a Docker socket unless you accept the increased blast
    radius.

## Reverse Proxy

A reverse proxy can route requests by hostname or URL path. Proxy to the
container's plain HTTP port **3000**, terminate TLS at the proxy, and pass the
WebSocket upgrade through. Without the upgrade headers the client loads but
the screen stays black.

Settings that matter:

  - `Upgrade` and `Connection` headers (WebSocket transport).
  - `proxy_buffering off`.
  - Read and send timeouts of at least 3600 seconds.
  - `client_max_body_size 0` so large mail attachments can be uploaded.

### Routing Based on Hostname

Each hostname is routed to a different application or container. If the reverse
proxy runs on the same machine as this container, it proxies all requests for
`betterbird.domain.tld` to the container at `127.0.0.1:3000`.

```nginx
map $http_upgrade $connection_upgrade {
	default upgrade;
	''      close;
}

upstream docker-betterbird {
	# If the reverse proxy server is not running on the same machine as the
	# Docker container, use the IP of the Docker host here.
	# Make sure to adjust the port according to how port 3000 of the
	# container has been mapped on the host.
	server 127.0.0.1:3000;
}

server {
	[...]

	server_name betterbird.domain.tld;

	location / {
		proxy_pass http://docker-betterbird;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection $connection_upgrade;
		proxy_set_header Host $host;
		proxy_buffering off;
		proxy_read_timeout 3600s;
		proxy_send_timeout 3600s;
		client_max_body_size 0;
	}
}
```

### Routing Based on URL Path

The same hostname is used, but different URL paths route to different
applications. For example, all requests for
`server.domain.tld/betterbird/` go to this container.

Set `SUBFOLDER=/betterbird/` on the container (both slashes are required) and
proxy the same path:

```nginx
map $http_upgrade $connection_upgrade {
	default upgrade;
	''      close;
}

upstream docker-betterbird {
	server 127.0.0.1:3000;
}

server {
	[...]

	location = /betterbird {return 301 $scheme://$http_host/betterbird/;}
	location /betterbird/ {
		proxy_pass http://docker-betterbird/;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection $connection_upgrade;
		proxy_set_header Host $host;
		proxy_buffering off;
		proxy_read_timeout 3600s;
		proxy_send_timeout 3600s;
		client_max_body_size 0;
	}
}
```

## Input Methods and Fonts

Input methods are handled entirely by the browser. Composition events from a
system or on-screen keyboard are streamed to the session as committed text, so
no `fcitx`, `ibus`, or `im-config` is installed or needed in the container, and
there is no environment variable to set. The client's keyboard layout is
applied automatically; `LC_ALL` only changes the application language, not the
layout.

Noto CJK, Noto Core, and Noto Color Emoji fonts are part of the base image, so
Chinese, Japanese, and Korean text renders without installing extra packages.

## GPU Acceleration

Expose the host GPU render device to the container:

```shell
docker run --device /dev/dri ...
```

Rendering (EGL/3D) and video encoding are then wired automatically. For
multi-GPU hosts, pin the devices explicitly: `DRINODE` selects the render node,
`DRI_NODE` the encode node. Host-side drivers are required, e.g. `amdgpu`,
`i915`, or `nouveau`; NVIDIA needs the container toolkit runtime.

## Dark Mode

There is no `DARK_MODE` switch. Set the GTK theme instead:

```shell
-e GTK_THEME=Adwaita:dark
```

Alternatively, create `/config/.config/gtk-3.0/settings.ini` with
`gtk-application-prefer-dark-theme=1`.

## Logs

Betterbird output is redirected to two files:

  - `/config/log/betterbird/output.log`
  - `/config/log/betterbird/error.log`

Each file is truncated at startup once it exceeds 1 MiB. Container init
messages, NGINX, the session, and anything written to stdout before the
redirect are visible with:

```shell
docker logs betterbird
```

## Shell Access

To access the shell of a running container:

```shell
docker exec -it betterbird bash
```

The session user is `abc` (ID `PUID`/`PGID`); `sudo` is available without a
password inside the container.

## Migrating from the jlesage-based Image

The base image changed from `jlesage/baseimage-gui` to
`ghcr.io/linuxserver/baseimage-selkies`, which is a deliberate breaking change:
the old network services are gone, there is no compatibility shim, and several
variables were renamed or removed. The table below is the complete mapping for
user-facing settings.

| Previous image | This image |
|----------------|------------|
| `USER_ID` / `GROUP_ID` (`1000`) | `PUID` / `PGID`, still `1000` by default here |
| `-p 5800:5800`, `http://host:5800` | `-p 3001:3001`, `https://host:3001` |
| `-p 5900:5900`, any VNC client | No VNC server; the GUI is HTML/WebCodecs on port 3001 |
| `VNC_PASSWORD`, `/config/.vncpass` | Removed together with the VNC server |
| `SECURE_CONNECTION`, `SECURE_CONNECTION_VNC_METHOD` | TLS on port 3001 is always on with a generated self-signed certificate |
| `WEB_AUTHENTICATION`, `WEB_AUTHENTICATION_USERNAME`, `WEB_AUTHENTICATION_PASSWORD` | `CUSTOM_USER` and `PASSWORD` (HTTP basic auth, no session tokens) |
| `WEB_LISTENING_PORT` / `VNC_LISTENING_PORT` | `CUSTOM_PORT` (3000) / `CUSTOM_HTTPS_PORT` (3001) |
| `WEB_LOCALHOST_ONLY` / `VNC_LOCALHOST_ONLY` | No equivalent |
| `WEB_AUDIO=1` | Audio is on by default (`SELKIES_AUDIO_ENABLED=true`) |
| `WEB_MICROPHONE=1` | `SELKIES_MICROPHONE_ENABLED=true` |
| `WEB_HOST_CLIPBOARD_SYNC` | `SELKIES_ENABLE_CLIPBOARD` and `SELKIES_ENABLE_BINARY_CLIPBOARD` |
| `WEB_FILE_MANAGER=1` | File transfers are on by default (`SELKIES_FILE_TRANSFERS=upload,download`) |
| `WEB_FILE_MANAGER_ALLOWED_PATHS` / `_DENIED_PATHS` | Only `FILE_MANAGER_PATH` is exposed; there are no per-path allow/deny lists |
| `WEB_NOTIFICATION=1` | No equivalent; there is no notification bridge, Betterbird popups stay in the session |
| `WEB_TERMINAL=1` | No web terminal; use `docker exec` |
| `KEEP_APP_RUNNING=1` | `RESTART_APP=true` (default) |
| `DARK_MODE=1` | No equivalent; use `GTK_THEME=Adwaita:dark` |
| `ENABLE_CJK_FONT=1` | Not needed; Noto CJK fonts are included |
| `DISPLAY_WIDTH` / `DISPLAY_HEIGHT` | `SELKIES_MANUAL_WIDTH` / `SELKIES_MANUAL_HEIGHT` (X11 mode only) |
| `INSTALL_PACKAGES` | `DOCKER_MODS=linuxserver/mods:universal-package-install` with `INSTALL_PACKAGES` |

What carries over and what to check:

  - The `/config` volume is reused as-is. The profile at `/config/profile`,
    including accounts, local mail, and settings, is opened unchanged, and the
    default `1000` IDs keep the existing file ownership working.
  - If you used a custom certificate with the old image, copy it to
    `/config/ssl/cert.pem` and `/config/ssl/cert.key`.
  - `/config/.config/labwc/autostart` and `/config/.config/openbox/autostart`
    are copied from the image only on first run. Delete them to pick up changes
    from a newer image.
  - Replace the published port in your scripts, compose files, and reverse
    proxy configuration before restarting. There is no working plain-HTTP view
    to fall back to.
  - Expect a fresh first start to build the desktop config and certificate;
    give it a few seconds before the page becomes usable.

## Docker Image Versioning and Tags

Each release of a Docker image is versioned, and each version has its own image
tag. Before October 2022, the versioning scheme followed
[semantic versioning](https://semver.org).

Since then, the versioning scheme has shifted to
[calendar versioning](https://calver.org) with the format `YY.MM.SEQUENCE`,
where:
  - `YY` is the zero-padded year (relative to year 2000).
  - `MM` is the zero-padded month.
  - `SEQUENCE` is the incremental release number within the month (first release
    is 1, second is 2, etc).

View all available tags on [Docker Hub] or check the [Releases] page for version
details.

[Releases]: https://github.com/etnperlong/docker-betterbird/releases
[Docker Hub]: https://hub.docker.com/r/etnperlong/betterbird/tags

## Docker Image Update

The Docker image is regularly updated to incorporate new features, fix issues,
or integrate newer versions of the containerized application. If your system
provides a built-in method for updating containers, use it. Alternatively,
[Watchtower] can automate updates.

To manually update:

  1. Fetch the latest image:
```shell
docker pull etnperlong/betterbird
```

  2. Stop the container:
```shell
docker stop betterbird
```

  3. Remove the container:
```shell
docker rm betterbird
```

  4. Recreate and start the container using the `docker run` command, with the
     same parameters used during initial deployment.

[Watchtower]: https://github.com/containrrr/watchtower

> [!NOTE]
> Since all application data is saved under the `/config` container folder,
> destroying and recreating the container does not result in data loss, and the
> application resumes with the same state, provided the `/config` folder
> mapping remains unchanged.

## Licensing

The container is built on the LinuxServer.io Selkies base image, which is
licensed under the **GPL-3.0**. The Selkies streaming server and its components
(pixelflux, pcmflux) are licensed under the **MPL-2.0**. Betterbird itself
follows Thunderbird's Mozilla Public License. These are runtime dependencies of
this image; see the respective upstream repositories for the full texts.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/etnperlong/docker-betterbird/issues).
