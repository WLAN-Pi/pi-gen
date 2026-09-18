# WLAN Pi OS versioning for Bookworm

Format: `YY.MM[.point][-type.sequence]-CODENAME`

Structure:

- Format: `YY.MM[.point][-type.sequence]-CODENAME`
  - `YY.MM`: Base date
  - `[.point]`: Optional patch release number (1, 2, 3...)
  - `[-type.sequence]`: Optional pre-release type and sequential number (-dev.1, -rc.2, etc.)
  - `-CODENAME`: Coffee-themed codename

## Overview

- Release version format: YY.MM-CODENAME
- Point releases: Rare, using YY.MM.point-CODENAME format
- Codenames: Coffee themed starting with 'Affogato' for releases. Development releases should be using 'theanine' as default codename.
- Pre-release markers: -dev, -rc
- Dev builds: YY.MM-dev.sequence-CODENAME
- Release candidates: YY.MM-rc.sequence-CODENAME
- Development track: Infrequent
- Testing approach: -dev releases until an -rc is cut
- Release cadence: Irregular (as needed)

Precedence clarification:

- 25.07-dev.1-theanine (development)
- 25.07-rc.1-theanine (release candidate)
- 25.07-theanine (final release)
- 25.07.1-theanine (patch release)

Traceability information stored in:

- `/etc/rpi-issue`

Codenames:

- Stored in `/etc/os-release`

Version:

- Stored in `/etc/wlanpi-release`

Examples:

```
25.07-dev.1-theanine  (First development build in July 2025)
25.07-dev.2-theanine  (Second development build same month)
25.07-rc.1-theanine   (First release candidate)
[Testing period]
25.07-theanine        (Final release)
25.07.1-theanine      (Point/patch/hotfix release if needed)
```

## Versioning guidelines

### Version structure examples

- Format: `YY.MM[.point][-type.sequence]-CODENAME`
  - `YY.MM`: 25.07-theanine
  - `.point`: 25.07.1-theanine
  - `-type`: 
    - 25.07-dev.1-theanine
    - 25.07-rc.1-theanine
  - `.sequence`:
    - 25.07-dev.1-theanine
    - 25.07-dev.2-theanine
    - 25.07-dev.3-theanine

### Version type examples

1. Development builds: `YY.MM-dev.sequence-CODENAME`
   - For developer testing and feature development
   - Example: 25.07-dev.1-theanine

2. Release candidates: `YY.MM-rc.sequence-CODENAME`
   - For wider testing before final release
   - Example: 25.07-rc.1-theanine

3. Final releases: `YY.MM-CODENAME`
   - Official stable releases
   - Example: 25.07-theanine

4. Patch releases: `YY.MM.point-CODENAME`
   - For emergency fixes or minor updates
   - Example: 25.07.1-theanine
