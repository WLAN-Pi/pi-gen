# WLAN Pi OS versioning

This scheme applies to the current builder branch, `trixie64`.

Format: `YY.MM[.point][-type.sequence]-CODENAME`

- `YY.MM`: base month.
- `.point`: optional patch number.
- `-type.sequence`: optional pre-release type and sequence number.
- `-CODENAME`: coffee-themed codename.

## Build types

| Type | Format | Purpose |
|---|---|---|
| `dev` | `YY.MM-dev.N-CODENAME` | Development builds. Default codename `theanine`. |
| `rc` | `YY.MM-rc.N-CODENAME` | Release candidates for wider testing. |
| `final` | `YY.MM-CODENAME` | Stable release. |
| `point` | `YY.MM.N-CODENAME` | Patch release for an existing month. |

The sequence number `N` increments from the existing git tags for the same
base and type. A point release takes its base from the `point_base` input and
increments from the existing tags under that base. See [CI.md](CI.md) for how
the pipeline computes this.

## Precedence

```
25.07-dev.1-theanine   (development)
25.07-rc.1-theanine    (release candidate)
25.07-theanine         (final release)
25.07.1-theanine       (patch release)
```

## Codenames

Release codenames are coffee themed and use TitleCase, for example
`Affogato`, `Breve`, and `Cortado`. Development builds default to
`theanine`.

## Tags and release titles

The git tag is the full version with no `v` prefix, for example
`26.08-Cortado`. The GitHub release title adds the `v` prefix, for example
`v26.08-Cortado`. Every build publishes as a pre-release; promotion to a
stable, latest release is manual. See [RELEASING.md](RELEASING.md).

## Traceability

The image records the version and the codename on separate lines in
`/etc/wlanpi-release`. `VERSION` never includes the codename:

```
VERSION=26.08
CODENAME=Cortado
```

`scripts/common:update_issue` also writes a version string to
`/etc/rpi-issue`, which becomes the `Version` field in the release `.info`
file. Release candidates write the base version `YY.MM`, stripping the
`-rc.sequence` and codename. Dev, final, and point builds write the full
`YY.MM[-type.sequence]-CODENAME`.

- `26.10-rc.1-Cortado` writes `Version 26.10`.
- `26.10-Cortado` writes `Version 26.10-Cortado`.

## Related

- [CI.md](CI.md): build pipeline and input reference.
- [RELEASING.md](RELEASING.md): how to cut and promote a release.
