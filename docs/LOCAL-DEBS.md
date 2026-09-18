# Local debs and building images

> **Branch note:** this branch installs all wlanpi app packages
> (wlanpi-core, wlanpi-common, wlanpi-webui, wlanpi-fpms, ...) straight from
> packagecloud — the explicit per-package sideloading that the `trixie`
> branch carries has been removed. The only local deb left is the custom
> kernel, via the generic `local-debs/` mechanism below.
>
> **Caveat:** packages that ship a Python virtualenv (wlanpi-core,
> wlanpi-webui, wlanpi-fpms) must be **Trixie builds** to work: a Bookworm
> build embeds `/opt/<pkg>/lib/python3.11/` with cp311 extensions but its
> `bin/python3` resolves to the system Python 3.13, so the service fails at
> import time even though the package installs cleanly. Until Trixie builds
> are published to packagecloud for builds of those packages, images from this
> branch will install them but the services will not start.

## The `local-debs/` directory

Any `.deb` dropped into `local-debs/` at the repo root is installed by the
`04-local-debs` sub-stage in both variants. Good for standalone packages with
no dependencies on other wlanpi packages (currently: the custom kernel, which
has no packagecloud counterpart — only Bookworm kernels are published).

**Ordering caveat:** sub-stages run alphabetically within a stage.

- `wlanpi1-lite`: `04-local-debs` runs **before** `08-install-wlanpi-packages`
- `wlanpi2-full`: `04-install-wlanpi-packages` runs **before** `04-local-debs`

In the lite build, a deb in `local-debs/` that depends on another wlanpi
package (e.g. webui depends on wlanpi-core) installs before that dependency
exists, so apt satisfies it from packagecloud. Debs with wlanpi dependencies
should not go in `local-debs/` — on this branch, let packagecloud supply
them (or use the `trixie` branch, which sideloads them dependency-ordered).

## Triggering builds

Native arm64 build (this host), must run as root:

```bash
cd ~/source/pi-gen-bookworm
sudo ./build-arm64.sh
```

- Settings come from `config` (release=trixie, both variants via
  `STAGE_LIST="wlanpi1-lite wlanpi2-full"`, apt-cacher-ng proxy on
  localhost:3142).
- Useful overrides (export before running, or put in a `-c extra-config`):
  - `CLEAN=1` — delete each stage's rootfs and rebuild from scratch
  - `SKIP_FULL_IMAGE=true` — build the lite variant only
  - `WLANPI_VERSION` / `WLANPI_CODENAME` — override date-based versioning
- Without `CLEAN=1` the build is **incremental**: it re-runs every sub-stage
  against the existing rootfs under `work/wlanpi-os/<variant>/rootfs/`. Much
  faster, but see the gotcha below.
- Logs: pi-gen writes `work/wlanpi-os/build.log`; a failed run prints a
  Build FAILED banner with timestamps.
- Output lands in `deploy/`: compressed images (`.img.gz`), package manifests
  (`.info`), and checksums.

There is also `build-docker.sh` for containerized builds (used by CI;
`config` auto-detects the container and moves `WORK_DIR` to `/tmp`).

## Verifying the result

Check the manifest for expected package versions:

```bash
grep wlanpi-webui deploy/wlanpi-os-*-lite.info
```

Or query the work rootfs directly:

```bash
sudo chroot work/wlanpi-os/wlanpi2-full/rootfs \
  dpkg-query -W wlanpi-core wlanpi-common wlanpi-webui wlanpi-fpms
```

## Gotcha: apt "downgrade" errors on incremental rebuilds

Trixie's apt 3.x treats installing a local `.deb` whose version **equals** the
installed version as a downgrade *when the same version also exists in a
configured repo* (the resolver prefers the repo origin, so switching to the
local file counts as a downgrade). On an incremental rebuild the local
package is already installed, so a plain `apt-get install -y /tmp/<pkg>.deb`
fails with:

```
E: Packages were downgraded and -y was used without --allow-downgrades.
```

All local-deb installs in this repo therefore use
`apt-get install -y --reinstall --allow-downgrades`. `--allow-downgrades`
guarantees the local deb wins over a same-version repo package. `--reinstall`
covers a deb **rebuilt without a version bump** (same filename, new content):
without it, an incremental rebuild sees the version already installed in the
work rootfs, reports "already the newest version", and silently keeps the
stale files from the previous build.
