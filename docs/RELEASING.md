# Release a WLAN Pi OS image

This page shows how to build an image release and promote it to stable.

## Goal

Cut a WLAN Pi OS image build, confirm the published release, and promote a
final build to the latest stable release.

## Prerequisites

- Write access to `WLAN-Pi/pi-gen`.
- The build workflow is dispatched on the default branch, `trixie64`, unless
  you deliberately override the guard.
- GitHub Actions is enabled for the repository.

## How releases work

The build workflow runs only from `workflow_dispatch`. A successful run
publishes a GitHub release for the build tag. Every build type publishes as a
pre-release by design, including `final` and `point`. Promoting a build to a
stable, latest release is a manual step.

Releases are immutable, tag-based artifacts. Never create, delete, move, or
retag a release or its tag. There are no release branches.

## Version and codename

Versions follow `YY.MM[.point][-type.sequence]-CODENAME`. See
[VERSIONING.md](VERSIONING.md) for the full scheme.

The git tag is the version with the codename and no `v` prefix, for example
`26.08-Cortado`. The GitHub release title adds the `v` prefix, for example
`v26.08-Cortado`.

## Inputs

[CI.md](CI.md) documents every `workflow_dispatch` input. The inputs you set
most often are:

- `build_type`: `dev`, `rc`, `final`, or `point`.
- `codename`: the coffee-themed codename for the release.
- `base_date`: optional `YY.MM` override to continue versioning for a month.
- `point_base`: required for `build_type=point`, the `YY.MM` to patch.

## Cut a build

1. Confirm the default branch is current:

   ```bash
   git switch trixie64 && git pull --ff-only
   ```

2. Dispatch the build. Choose the form that matches the release you want.

   Development build:

   ```bash
   gh workflow run build.yml --ref trixie64 \
     -f build_type=dev -f codename=theanine
   ```

   Release candidate:

   ```bash
   gh workflow run build.yml --ref trixie64 \
     -f build_type=rc -f codename=cortado
   ```

   Final release:

   ```bash
   gh workflow run build.yml --ref trixie64 \
     -f build_type=final -f codename=cortado
   ```

   Point release:

   ```bash
   gh workflow run build.yml --ref trixie64 \
     -f build_type=point -f point_base=26.08 -f codename=cortado
   ```

   The Actions UI is equivalent: open Actions, select **WLAN Pi OS build &
   release pipeline**, choose **Run workflow**, select the `trixie64` branch,
   fill the inputs, and run it.

3. Watch the run:

   ```bash
   gh run list --workflow build.yml
   gh run watch
   ```

## What CI produces

A successful run on the default branch creates:

- A git tag equal to the full version, for example `26.08-Cortado`.
- A GitHub pre-release titled `v26.08-Cortado`. When `skip_full_image=true`,
  the title ends with `[LITE ONLY]`.
- Assets: `*.img.gz`, `*.sha256`, `*.info`, and `*.sbom.xz`.
- Generated release notes.

Verify the release:

```bash
gh release view 26.08-Cortado
```

Expected output shows the pre-release marker and the uploaded assets.

## Check package status and release contents

The **Package status** workflow reports what is in the packagecloud channels
and what shipped in a release. It is read-only: it never builds, publishes, or
changes a release.

1. Open the repository **Actions** tab.
2. Select **Package status**, then choose **Run workflow**.
3. Set `command`:
   - `status` compares the `wlanpi/main` and `wlanpi/dev` packagecloud
     channels for the image distribution and architecture. Use it to see which
     packages are pending promotion.
   - `show` lists the packages in a release. Set `release` to the release tag,
     for example `26.08-Cortado`, and `image` to `lite`, `full`, or `both`.
4. Read the result in the run summary.

With the GitHub CLI:

```bash
gh workflow run release-info.yml -f command=status
gh workflow run release-info.yml -f command=show -f release=26.08-Cortado
```

The output is tab-separated with a header. For `status` the columns are
`package`, `main`, `dev`, and `status`. The `status` values are:

- `current`: the same version is in both channels.
- `pending`: `dev` is newer, so the package is pending promotion.
- `main-only`: the package is in `main` and not in `dev`.
- `dev-only`: the package is in `dev` and not in `main`.
- `main-newer`: `main` is newer than `dev`.
- `differs`: the host cannot compare the two versions.

For `show` the columns are `image`, `package`, and `version`.

## Promote a build to stable

Promotion is manual. Automated promotion from `-rc` to final is intentionally
not implemented; it was attempted and was not reliable, and may be revisited
later. The `--mode promote` path in `scripts/prepare-release-notes` is not
wired to any workflow.

To promote a build, first cut a `final` build as shown above. CI publishes it
as a pre-release. Then promote that release.

With the GitHub CLI:

```bash
gh release edit 26.08-Cortado --prerelease=false --latest
```

In the GitHub UI:

1. Open the repository **Releases** page.
2. Select the release to promote.
3. Choose **Edit release**.
4. Clear **Set as a pre-release**.
5. Select **Set as the latest release**.
6. Choose **Update release**.

Promotion does not rebuild anything and does not change the tag. It only
changes how GitHub labels the release.

Verify:

```bash
gh release view 26.08-Cortado
```

Expected output no longer shows the pre-release marker and the release is
listed as the latest.

## Override the default-branch guard

The release job normally runs only when the workflow is dispatched on the
default branch. Set `force_release=true` to publish from the dispatched ref:

```bash
gh workflow run build.yml --ref my-branch \
  -f build_type=dev -f codename=theanine -f force_release=true
```

Caveats:

- GitHub only offers `workflow_dispatch` for workflows that exist on the
  default branch. The dispatched ref must already contain the `force_release`
  input, or GitHub rejects the run with an unexpected-input error.
- The override publishes a release from a non-default branch. Use it
  deliberately, and only for a branch you intend to release from.

## Release composition

A release contains the images that were built. See
[CI.md](CI.md#release-composition) for the full matrix.

- Full image: built unless `skip_full_image=true`.
- Lite image: built unless `skip_lite_image=true`.
- Lite A/B image: built only when `ab_partition=true` and the lite image was
  built.

You cannot set both `skip_full_image=true` and `skip_lite_image=true`.

## Gotchas

- `skip_full_image=true` builds the lite image only. The release title ends
  with `[LITE ONLY]`.
- `skip_lite_image=true` builds the full image only. The release title ends
  with `[FULL ONLY]`, and the A/B job is skipped because there is no lite
  image to partition.
- `ab_partition=false` still publishes a release, containing only the images
  that were built. The release notes omit the A/B image.

## Recovery

If a build is bad, cut a new sequence for the same month, or a new point
release. Do not delete, move, or retag the bad release. Releases are
immutable.

## Related

- [CI.md](CI.md): build pipeline and input reference.
- [VERSIONING.md](VERSIONING.md): version scheme.
