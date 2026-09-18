# Build system

1. Build system:

   - Use current ISO 8601 date (YYYY.MM.DD) for the base version separated by periods.
   - Track and increment sequence numbers for same-day builds through git tags.
   - Apply correct image type marker based on build intention.

2. Release promotion path:

   - Development → RC → Final Release
   - Final RC build should be promotable to final release without rebuild
   - No mechanism to promote from -dev to -rc. 
   - Promotion mechanism is for -rc to final only. -rc may remain in the filenames.
   - Mechanism to strip -rc marker when promoting to release
   - Workflow allows current ISO 8601 date (YYYY.MM.DD) for base version by default, but allows a different base date which enables promoting an -rc to release from any date to maintain the same versioning structure and format.

3. File naming convention: `wlanpi-os-VERSION-TYPE.img`
  
   - Example: wlanpi-os-2025.04.19-rc.1-lite.img
   - Example: wlanpi-os-2025.04.19-rc.1-full.img

4. Others

   - Release files include info showing what is installed, sbom, and digests including sha256 checksums of image files.
