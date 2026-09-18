# Guidance for coding agents

Read this first. [CI](docs/CI.md) covers the build pipeline and
[versioning](docs/VERSIONING.md) covers releases.

## Repo model

- This repo builds WLAN Pi OS images from the `wlanpi1-lite` and
  `wlanpi2-full` stages. There are no upstream `stage0-5` stages.
- PRs target the default branch, which is the living current-distro
  builder. Released states are annotated git tags, not branch merges.
- One concern per PR. No mixed move-plus-change diffs. Soft cap ~400
  changed lines.
- CI-only, docs-only, or workflow-only changes do not create releases.
  Releases are cut by the build workflow and recorded as tags.
- Upstream (`RPi-Distro/pi-gen`) changes are audited and cherry-picked.
  The trees have diverged (no `stage0-5` here), so never merge upstream
  wholesale.

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
git ls-files '*.sh' | xargs -r shellcheck -S warning
```

All tracked shell scripts must pass shellcheck at warning severity. CI
enforces this (`.github/workflows/lint.yml`).

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
