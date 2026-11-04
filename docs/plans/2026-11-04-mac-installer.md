# Plan: macOS installer (beta)

Date: 2026-11-04 · Branch: `claude/mac-installer`
Companion to Automate-Pros/reason-streamdeck-remote `docs/plans/2026-11-04-mac-support.md`.

## What

`install.sh`: a bash one-liner installer for macOS, so Mac users do not need PowerShell 7.

```bash
curl -fsSL https://raw.githubusercontent.com/Automate-Pros/reason-remote-setup/main/install.sh | bash
```

It downloads the same release asset as `install.ps1` (`reason-remote-setup.zip`), checks it,
and copies the codec and maps into both Reason Remote folders. The system folder is skipped
without write access. It removes the pre-1.1 `Community` surfaces, then prints the IAC
Driver and Reason steps.

It works against the bundle as it is published today. No bundle or release change is needed.

## How it is checked

`node --test`. The tests build a small bundle zip, point the installer at it with
`REASON_REMOTE_BUNDLE`, and redirect the Remote folders with `REASON_REMOTE_ROOTS`. Linux
stands in for macOS via `REASON_REMOTE_OS=Darwin`. The installer is also run once against
the real latest release asset. It is not run on a Mac.

## Will not do

- Change existing README copy, the Windows path or `install.ps1`.
- Automate IAC bus creation (no public API) or Reason surface registration on macOS
  (preferences location and format are unverified).
- Ask the telemetry question. Telemetry stays off (opt-in), as the pwsh installer leaves it
  on macOS.

## README

Add one new section, marked **beta, untested on hardware**. Nothing else changes.
