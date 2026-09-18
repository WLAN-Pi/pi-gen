# Migration plan: pi-gen-bookworm moves into pi-gen

This repo builds trixie images even though its name and its Dockerfile
default still say bullseye. The goal of this migration is for
`WLAN-Pi/pi-gen` to become the single repo that owns WLAN Pi OS image
builds. This document records the agreed plan.

## Background and branch model

The model follows upstream `RPi-Distro/pi-gen`:

- The default branch is the living, current-distro builder, named for the
  distro: `trixie/release`. There is no `main` branch.
- When the next Debian release lands, freeze `trixie/release` (it stays
  so you can rebuild old images), create `<distro>/release`, and move the
  content there.
- Image versions (`YY.MM`-`codename`) are build inputs (`base_date`,
  `codename`, `repos`, `build_type` in the build workflow), not branch
  properties. Released states are recorded as annotated git tags whose
  message carries those build inputs. A tag alone does not reproduce a
  build; the SBOM artifacts published with each release capture
  provenance.
- Releases are published by the build workflow to GitHub Releases.
- Upstream sync is a manual audit. This tree drops upstream `stage0-5`,
  so changes from `RPi-Distro/pi-gen` upstream are cherry-picked after
  review, not merged wholesale.

## Phase 1: pi-gen-bookworm prep (branch `arm64`)

1. `Dockerfile`: default `BASE_IMAGE` changes from `debian:bullseye` to
   `debian:trixie`. `build-docker.sh` already passes trixie, so this
   aligns the fallback.
2. README becomes a hybrid: a short pointer at the top directs
   non-developers to [Releases](../../releases) for downloads; below
   that, developer build instructions verified against this tree. The
   upstream README (`PI-GEN.md`) is demoted to an upstream reference
   link.
3. `AGENTS.md` is added, adapted from `wlanpi-core`'s `AGENTS.md`
   (branch/PR rules for this repo, reuse-first, cost and scope rules,
   the shellcheck verify gate, and the documentation house style).
4. `.github/workflows/lint.yml` adds a shellcheck gate at warning
   severity over all tracked shell scripts.
5. Shellcheck cleanup of the 16 existing warning-level findings:
   quoting fixes in `build-docker.sh` and `local-dev-ab-partition.sh`,
   and disable directives where the flagged code is intentional
   (upstream parity in `export-image/prerun.sh`, protocol field
   documentation in `go-hw-machine-id.sh`).
6. Commit and push.

## Phase 2: migrate to pi-gen

7. In `WLAN-Pi/pi-gen`, create `trixie/release` off `bullseye64` and
   copy this repo's tracked tree wholesale. Git history is preserved
   underneath; `deploy/` and `work/` are gitignored and do not move.
8. Verify the `SLACK_WEBHOOK_URL` secret exists on `WLAN-Pi/pi-gen`
   (the build workflow posts a Slack status).
9. Push the branch and run a validation CI build (`repos=both`,
   `build_type=dev`). The dev pre-release it publishes is what makes the
   README Releases link truthful in the new repo.

## Phase 3: default and retire

10. Set the `WLAN-Pi/pi-gen` default branch to `trixie/release`.
11. Archive `WLAN-Pi/pi-gen-bookworm`.
12. The first release tag is deferred until the codename is decided.
    When it is, create an annotated tag whose message records
    `base_date`, `codename`, `repos`, and `build_type`.

## Going forward

- Add an `upstream` remote (`https://github.com/RPi-Distro/pi-gen.git`)
  for the occasional manual audit sync.
- Legacy branches (`bullseye64`, `bookworm64`, and the rest) stay as-is
  for rebuilding old images.
