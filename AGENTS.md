# Guidance for coding agents

Read this first. [CI](docs/CI.md) covers the build pipeline,
[versioning](docs/VERSIONING.md) covers version numbers, and
[releasing](docs/RELEASING.md) covers how releases are cut and promoted.

## Repo model

- This repo builds WLAN Pi OS images from the `wlanpi1-lite` and
  `wlanpi2-full` stages. There are no upstream `stage0-5` stages.
- The default branch is `trixie64`, the living builder for the current
  Debian release, continuing the `bullseye64` and `bookworm64` line. PRs
  target the default branch; there is no `main`.
- One concern per PR. Size is a soft target: above 500 changed lines, add a
  `Review order` section to the description; above 1,000 is fine when the
  change is cohesive. Split only at real seams, never to hit a number. Put
  moves and formatting in separate commits from behavioral changes. Full policy:
  [developer guide](https://github.com/WLAN-Pi/developers/blob/main/CONTRIBUTING.md#pr-size-and-scope).
- Upstream (`RPi-Distro/pi-gen`) changes are audited and cherry-picked.
  The trees have diverged (no `stage0-5` here), so never merge upstream
  wholesale.

## Release engineering

- Releases are immutable, tag-based artifacts. Never create, delete,
  move, or retag a release or its tag.
- You may convert a mistaken or test-only pre-release to a draft with
  `gh release edit <tag> --draft`; this preserves its tag and artifacts.
- There are no release branches. Versions are build inputs, not branch
  properties. See [versioning](docs/VERSIONING.md).
- Releases are produced only by `.github/workflows/build.yml` through
  `workflow_dispatch`, normally dispatched on the default branch. The
  `force_release` input overrides the default-branch guard and is
  human-only; agents must not use it.
- Every build type (`dev`, `rc`, `final`, `point`) publishes as a GitHub
  pre-release by design. Promoting a build to a stable, latest release
  is a manual step. See [releasing](docs/RELEASING.md).
- Promotion from `-rc` to final is intentionally not automated.
- Docs-only, CI-only, or workflow-only changes do not create releases.

## Before you write

Reuse first, write second:

- Grep `scripts/`, `export-image/`, and the existing stage directories
  before adding a stage step or helper; follow the `NN-name` stage
  convention.
- Check `depends` and `depends-arm64` before assuming a host tool exists
  in the build environment.

## Cost and scope

- Smallest diff that fixes the issue. No speculative abstraction, no
  config for a value that never changes, no helper with one caller.
- Delete over add; boring over clever.
- Mark deliberate simplifications that cut a real corner with a
  `# shortcut:` comment naming the ceiling and the upgrade path.
- Be terse. Prefer `grep` and targeted reads over dumping whole files.
  Run the real gates once, not ad-hoc exploratory commands.
- Stop and ask the human before restructuring a stage, adding a new
  workflow, or when scope is ambiguous.

## Verify before committing

```bash
{ git ls-files '*.sh'
  git ls-files -s | awk '$1 == "100755" {print $4}' | xargs -r grep -l '^#!.*sh'
} | sort -u | xargs -r shellcheck -S warning
```

All tracked `*.sh` files plus executable scripts without a `.sh` suffix
must pass shellcheck at warning severity. CI enforces this
(`.github/workflows/lint.yml`).

## Documentation

Write technical documentation using Diátaxis: tutorials teach, how-to
guides solve a task, reference documents the interface, and explanations
provide conceptual context. Choose one primary type per page.

Use clear, direct, task-oriented prose. Verify all technical statements
against the repository. Include prerequisites, exact commands or complete
examples, and a way to verify success where applicable. Do not invent
behavior or duplicate canonical reference material.

### House style

- Address the reader as "you."
- Use present tense and active voice.
- Start task pages with the goal and prerequisites.
- Use numbered steps for ordered actions and bullets for unordered facts.
- Put commands in fenced code blocks; put expected output immediately
  after.
- Use literal spelling for commands, paths, flags, config keys, and
  values.
- Use one canonical term for each concept.
- Never use emdashes; use commas or parentheses, or rewrite the sentence.
- Avoid filler such as "simply," "just," "obviously," and "easy."
- Warn immediately before destructive, privileged, costly, or
  production-impacting steps.
- Link to the canonical reference instead of duplicating option details.
