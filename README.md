# WLAN Pi OS builder

Tools to build WLAN Pi OS images, based on
[upstream pi-gen](PI-GEN.md).

## Get the images

You do not need to build anything. Download ready-made images from
[Releases](../../releases): choose the newest non-pre-release for stable
use, and verify your download against the published `.sha256` file.

## Build images yourself

Prerequisites:

- A Debian-based Linux host with root privileges. The reference build
  environment is an `ubuntu-24.04-arm` runner (see [CI](docs/CI.md)).
- Host packages from `depends` (or `depends-arm64` on arm64 hosts).
- For native builds, `apt-cacher-ng` running on `localhost:3142` (the
  checked-in `config` routes apt through it). To use another proxy, set
  `APT_PROXY=<url>`; to build without a proxy, set `APT_PROXY=` (empty).

The repo ships a checked-in `config` that builds both images
(`STAGE_LIST="wlanpi1-lite wlanpi2-full"`).

Native build (requires an arm64 host, such as an arm64 Linux machine or
the `ubuntu-24.04-arm` CI runner):

```bash
sudo -E ./build.sh
```

`-E` preserves your environment so overrides such as `WLANPI_CODENAME`
reach the build (CI uses the same form). `build.sh` verifies native
arm64 execution with `arch-test` and exits with an error on other hosts.

Docker build (works on other host architectures, such as x86_64, through
`qemu-user-static` emulation in the build container; slower than a
native build):

```bash
./build-docker.sh
```

Verify success: finished images appear in `deploy/` as `.img.gz` files
with matching `.sha256` checksums.

Builds are incremental: stage state persists under `work/wlanpi-os/`
and re-runs reuse it. If a stage edit appears to do nothing, remove the
`work/` directory to force a full rebuild.

On Fedora hosts, `export-image` prints SELinux and lowercase-label mount
warnings; both are benign.

## How this repo works

- Branches: `trixie64` is the default branch, the living builder for the
  current Debian release, continuing the `bullseye64` and `bookworm64`
  line. When WLAN Pi OS moves to the next Debian release, `trixie64`
  freezes (it stays so you can rebuild old images) and a new distro
  branch becomes the default. PRs target the default branch; there is no
  `main`.
- [Versioning](docs/VERSIONING.md): image versions (`YY.MM` plus codename)
  are build inputs, not branch properties.
- [CI](docs/CI.md): the build and release pipeline.
- [Local debs](docs/LOCAL-DEBS.md): inject locally built packages.
- [Partitions](docs/PARTITIONS.md): A/B partition layout.
- [Product requirements](docs/PRDs.md).
- [Upstream README](PI-GEN.md): reference for the base tool. Its stage
  layout (`stage0-5`) differs from this repo (`wlanpi1-lite`,
  `wlanpi2-full`).
