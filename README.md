<h1 align="center">
  cozzite
</h1>

<h2 align="center">
Bazzite + COSMIC
</h2>

[![build](https://github.com/jechton/cozzite/actions/workflows/build.yml/badge.svg)](https://github.com/jechton/cozzite/actions/workflows/build.yml)

## Changes

Cozzite builds off of bazzite-gnome, and leaves Gnome available since COSMIC is in an alpha state.

It also includes some personal changes:

- Add VS Code

Cozzite also includes many security changes from [secureblue](https://github.com/secureblue/secureblue):

- Add per-network MAC randomization
- Blocklist unused kernel modules
- Brute force protection by locking user accounts for 24 hours after 50 failed login attempts, hardened password encryption and password quality suggestions
- Configure chronyd to use Network Time Security (NTS)
- Disable core dumps
- Disable VS Code telemetry settings
- Remove unmaintained fuse
- Set various hardened sysctl values

## Installation

To rebase an existing atomic Fedora installation:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/jechton/cozzite:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jechton/cozzite:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

### After installation

Enroll the secureboot key: `ujust enroll-secure-boot-key`

Set kargs: `ujust set-kargs-hardening`

## ISO

ISOs cannot be distributed on GitHub due to file size restrictions. You can generate an offline ISO (`deploy.iso`) using `podman`:

```
sudo podman run --rm --privileged --volume .:/build-container-installer/build \
      ghcr.io/jasonn3/build-container-installer:latest \
      IMAGE_REPO=ghcr.io/jechton \
      IMAGE_NAME=cozzite \
      IMAGE_TAG=latest \
      VARIANT=Silverblue
```

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/jechton/cozzite
```
