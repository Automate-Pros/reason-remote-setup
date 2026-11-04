#!/usr/bin/env bash
# One-line installer for the Automate Pros Reason Remote surfaces on macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/Automate-Pros/reason-remote-setup/main/install.sh | bash
#
# BETA, untested on Mac hardware.
#
# Downloads the latest setup bundle (the same reason-remote-setup.zip that install.ps1 uses)
# and copies the Reason Remote codec and maps into:
#
#   /Library/Application Support/Propellerhead Software/Remote          (needs sudo; skipped otherwise)
#   ~/Library/Application Support/Propellerhead Software/Remote         (enough on its own)
#
# Then prints the two steps that cannot be automated on a Mac: the IAC Driver buses and
# adding the surfaces in Reason. Safe to re-run. Removes the pre-1.1 "Community" surfaces.
#
# Environment (mostly for tests):
#   REASON_REMOTE_BUNDLE  path to a local reason-remote-setup.zip instead of downloading
#   REASON_REMOTE_ROOTS   colon-separated Remote folders to install into
#   REASON_REMOTE_OS      pretend `uname -s` returned this
#
# Works with the bash 3.2 that ships with macOS.

set -eu

ASSET_URL="https://github.com/Automate-Pros/reason-remote-setup/releases/latest/download/reason-remote-setup.zip"
README_URL="https://github.com/Automate-Pros/reason-remote-setup#readme"
MANUFACTURER="Automate Pros"
LEGACY_MANUFACTURER="Community"

say() { printf '%s\n' "$*"; }
die() { printf '\nInstall failed: %s\nYou can install manually instead - see %s\n' "$*" "$README_URL" >&2; exit 1; }

say "Reason Remote - Automate Pros (macOS installer: beta, untested on Mac hardware)"

OS="${REASON_REMOTE_OS:-$(uname -s)}"
case "$OS" in
  Darwin) ;;
  MINGW*|MSYS*|CYGWIN*|Windows*) die "This is the macOS installer. On Windows run install.ps1 in PowerShell 7 (see the README)." ;;
  *) [ -n "${REASON_REMOTE_ROOTS:-}" ] || die "Reason runs on macOS and Windows only (this is $OS)." ;;
esac

for tool in unzip; do
  command -v "$tool" >/dev/null 2>&1 || die "'$tool' is required."
done

WORK="$(mktemp -d "${TMPDIR:-/tmp}/reason-remote-setup.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------- download + check

ZIP="$WORK/reason-remote-setup.zip"
if [ -n "${REASON_REMOTE_BUNDLE:-}" ]; then
  cp "$REASON_REMOTE_BUNDLE" "$ZIP" || die "Cannot read $REASON_REMOTE_BUNDLE"
else
  command -v curl >/dev/null 2>&1 || die "'curl' is required."
  say "Downloading the latest setup bundle..."
  curl -fsSL "$ASSET_URL" -o "$ZIP" || die "Download failed: $ASSET_URL"
fi

# A GitHub error page or a truncated transfer would otherwise fail inside unzip.
size=$(wc -c < "$ZIP" | tr -d ' ')
[ "$size" -ge 10240 ] || die "The download is only $size bytes, which is not the setup bundle. Check $ASSET_URL in a browser."
say "  $((size / 1024)) KB"

unzip -q -o "$ZIP" -d "$WORK/bundle" || die "The bundle is not a valid zip file."

SRC_CODEC="$WORK/bundle/Codecs/Lua Codecs/$MANUFACTURER"
SRC_MAP="$WORK/bundle/Maps/$MANUFACTURER"
for required in \
  "$SRC_CODEC/StreamDeckPlusRemote.lua" "$SRC_CODEC/StreamDeckPlusRemote.luacodec" \
  "$SRC_CODEC/StreamDeckPlusMaster.lua" "$SRC_CODEC/StreamDeckPlusMaster.luacodec" \
  "$SRC_MAP/$MANUFACTURER Stream Deck+ Remote.remotemap" "$SRC_MAP/$MANUFACTURER Stream Deck+ Master.remotemap"; do
  [ -f "$required" ] || die "This is not the setup bundle: ${required#"$WORK/bundle/"} is missing."
done

# ---------------------------------------------------------------- copy

if [ -n "${REASON_REMOTE_ROOTS:-}" ]; then
  ROOTS="$REASON_REMOTE_ROOTS"
else
  ROOTS="/Library/Application Support/Propellerhead Software/Remote:$HOME/Library/Application Support/Propellerhead Software/Remote"
fi

installed=0
skipped=0
OLD_IFS="$IFS"
IFS=':'
# shellcheck disable=SC2086 # split on ':' only
set -- $ROOTS
IFS="$OLD_IFS"

for root in "$@"; do
  [ -n "$root" ] || continue
  dst_codec="$root/Codecs/Lua Codecs/$MANUFACTURER"
  dst_map="$root/Maps/$MANUFACTURER"
  if ! { mkdir -p "$dst_codec" "$dst_map" 2>/dev/null && [ -w "$dst_codec" ] && [ -w "$dst_map" ]; }; then
    say "Skipped $root (no write access)"
    skipped=$((skipped + 1))
    continue
  fi
  cp -f "$SRC_CODEC"/* "$dst_codec/"
  cp -f "$SRC_MAP"/* "$dst_map/"
  for legacy in "$root/Codecs/Lua Codecs/$LEGACY_MANUFACTURER" "$root/Maps/$LEGACY_MANUFACTURER"; do
    if [ -d "$legacy" ]; then
      rm -rf "$legacy" && say "  removed old $LEGACY_MANUFACTURER surface from $legacy"
    fi
  done
  # Under `sudo bash`, macOS keeps HOME, so the per-user copy would be owned by root. Hand
  # it back to the user who ran sudo; the system location stays root's.
  if [ "$(id -u)" = "0" ] && [ -n "${SUDO_USER:-}" ] && [ "$root" != "/Library/Application Support/Propellerhead Software/Remote" ]; then
    chown -R "$SUDO_USER" "$dst_codec" "$dst_map" 2>/dev/null || true
  fi
  say "Installed to $root"
  installed=$((installed + 1))
done

[ "$installed" -gt 0 ] || die "Could not install to any Reason Remote location."
if [ "$skipped" -gt 0 ]; then
  say ""
  say "Note: the system-wide location was skipped. Reason reads your user location just as well."
  say "To install for every user too:"
  say "  curl -fsSL https://raw.githubusercontent.com/Automate-Pros/reason-remote-setup/main/install.sh | sudo bash"
fi

# ---------------------------------------------------------------- next steps

cat <<EOF

Next steps:
  1. Create four virtual MIDI buses (once):
     open -a "Audio MIDI Setup"   then Window -> Show MIDI Studio -> double-click IAC Driver,
     tick "Device is online", and add buses until there are four: Bus 1, Bus 2, Bus 3, Bus 4.
     Keep the default names - the plugin looks for "IAC Driver Bus 1" to "IAC Driver Bus 4".
  2. Fully quit and restart Reason. Maps are only read at startup.
  3. Preferences -> Control Surfaces -> Add Manually, twice:

     Auto-follow surface (instruments + Document)
       Manufacturer: $MANUFACTURER
       Model:        Stream Deck+ Remote
       Input Port:   IAC Driver Bus 1
       Output Port:  IAC Driver Bus 2

     Master Section surface (mixing)
       Manufacturer: $MANUFACTURER
       Model:        Stream Deck+ Master
       Input Port:   IAC Driver Bus 3
       Output Port:  IAC Driver Bus 4

  4. Options -> Remote and Keyboard Control -> Surface Locking...:
     lock "Automate Pros Stream Deck+ Master" to the Master Section.
  5. Turn Easy MIDI off for all four buses (or Reason handles everything twice).

Full guide: $README_URL
EOF
