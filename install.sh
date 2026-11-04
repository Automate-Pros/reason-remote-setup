#!/usr/bin/env bash
# One-line installer for the Automate Pros Reason Remote surfaces on macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/Automate-Pros/reason-remote-setup/main/install.sh | bash
#
# BETA, untested on Mac hardware.
#
# Downloads one pinned release of the setup bundle (the reason-remote-setup.zip that
# install.ps1 uses), refuses it unless its SHA-256 matches the one below, and copies the
# Reason Remote codec and maps into:
#
#   /Library/Application Support/Propellerhead Software/Remote          (needs sudo; skipped otherwise)
#   ~/Library/Application Support/Propellerhead Software/Remote         (enough on its own)
#
# Then prints the two steps that cannot be automated on a Mac: the IAC Driver buses and
# adding the surfaces in Reason. Safe to re-run. Removes the pre-1.1 "Community" surfaces
# (only their known files; anything else in those folders is left alone).
#
# Why sudo is optional: /Library/... is shared by every user on the Mac and only an admin
# can write there. Reason reads the per-user folder just as well, so plain `| bash` is
# enough for one user. Nothing else in this script needs root.
#
# Nothing runs until the last line, so a download cut off half way does nothing.
#
# Environment (mostly for tests):
#   REASON_REMOTE_BUNDLE         path to a local reason-remote-setup.zip instead of downloading
#   REASON_REMOTE_BUNDLE_SHA256  expected SHA-256 of that local zip (default: the pinned one)
#   REASON_REMOTE_ROOTS          colon-separated Remote folders to install into
#   REASON_REMOTE_OS             pretend `uname -s` returned this
#   REASON_REMOTE_APPS_DIRS      colon-separated folders to look for Reason and Stream Deck in
#
# Works with the bash 3.2 that ships with macOS.

set -eu

# The bundle this script installs. When a new setup bundle is released, update both lines
# together (the digest is on the release page, or: shasum -a 256 reason-remote-setup.zip).
BUNDLE_TAG="v1.3.0"
BUNDLE_SHA256="f73dcfe61b15ba6eff0e4b1819f6fd791d05c66de1da024b3f7ad58fee895c4f"

ASSET_URL="https://github.com/Automate-Pros/reason-remote-setup/releases/download/$BUNDLE_TAG/reason-remote-setup.zip"
README_URL="https://github.com/Automate-Pros/reason-remote-setup#readme"
SYSTEM_ROOT="/Library/Application Support/Propellerhead Software/Remote"
MANUFACTURER="Automate Pros"
LEGACY_MANUFACTURER="Community"

# The files the pre-1.1 releases installed under manufacturer "Community", one per line.
legacy_codec_files() {
  printf '%s\n' StreamDeckPlusRemote.lua StreamDeckPlusRemote.luacodec StreamDeckPlusRemote.png \
    StreamDeckPlusMaster.lua StreamDeckPlusMaster.luacodec StreamDeckPlusMaster.png
}
legacy_map_files() {
  printf '%s\n' "Community Stream Deck+ Remote.remotemap" "Community Stream Deck+ Master.remotemap" \
    batch-scopes.remotemap.fragment document-scope.remotemap.fragment master-section-scope.remotemap.fragment
}

say() { printf '%s\n' "$*"; }
note() { printf 'Note: %s\n' "$*"; }
die() { printf '\nInstall failed: %s\nYou can install manually instead - see %s\n' "$*" "$README_URL" >&2; exit 1; }

sha256_of() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    return 1
  fi
}

# Under `sudo`, the user who ran sudo; empty otherwise.
sudo_owner() {
  if [ "$(id -u)" = "0" ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    printf '%s\n' "$SUDO_USER"
  fi
}

# The home folder of the person installing: the sudo user's own home under sudo (whether or
# not sudo kept HOME), $HOME otherwise.
user_home() {
  local owner home=""
  owner="$(sudo_owner)"
  if [ -n "$owner" ] && command -v dscl >/dev/null 2>&1; then
    home="$(dscl . -read "/Users/$owner" NFSHomeDirectory 2>/dev/null | sed -n 's/^NFSHomeDirectory: //p')"
  fi
  if [ -n "$home" ] && [ -d "$home" ]; then printf '%s\n' "$home"; else printf '%s\n' "$HOME"; fi
}

# mkdir -p, and when owner is set, hand every folder this call created to that user.
make_dirs() {
  local owner="$1" dir top probe
  shift
  for dir in "$@"; do
    top=""
    probe="$dir"
    while [ ! -e "$probe" ]; do top="$probe"; probe="$(dirname "$probe")"; done
    mkdir -p "$dir" 2>/dev/null || return 1
    if [ -n "$owner" ] && [ -n "$top" ]; then
      chown -R "$owner:$(id -g "$owner")" "$top" || return 1
    fi
  done
}

# Remove the known pre-1.1 files from one Community folder, then the folder if it is empty.
remove_legacy() {
  local dir="$1" names="$2" name removed=0
  [ -d "$dir" ] || return 0
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    if [ -f "$dir/$name" ]; then rm -f "$dir/$name"; removed=1; fi
  done <<EOF
$names
EOF
  # Early releases also left an empty src folder next to the codec.
  if [ -d "$dir/src" ]; then rmdir "$dir/src" 2>/dev/null || true; fi
  if rmdir "$dir" 2>/dev/null; then
    say "  removed old $LEGACY_MANUFACTURER surface from $dir"
  elif [ "$removed" = "1" ]; then
    say "  removed the old Stream Deck+ files from $dir (other files there were left alone)"
  fi
}

# First match of any glob pattern under any of the colon-separated folders.
find_app() {
  local rest="$1:" dir pattern path
  # Glob the patterns unquoted but never split them: app names contain spaces.
  local IFS='
'
  shift
  while [ -n "$rest" ]; do
    dir="${rest%%:*}"
    rest="${rest#*:}"
    [ -n "$dir" ] || continue
    for pattern in "$@"; do
      for path in "$dir"/$pattern; do
        if [ -d "$path" ]; then printf '%s\n' "$path"; return 0; fi
      done
    done
  done
  return 1
}

check_apps() {
  local os="$1" home="$2" dirs
  dirs="${REASON_REMOTE_APPS_DIRS:-/Applications:$home/Applications}"
  if ! find_app "$dirs" "Reason*.app" "Reason*/Reason*.app" >/dev/null; then
    note "Reason was not found in /Applications. The files are installed anyway, and Reason 12 or"
    say "      newer picks them up when it starts. Install Reason before Step 2 below."
  fi
  if ! find_app "$dirs" "Elgato Stream Deck.app" "*Stream Deck*.app" >/dev/null; then
    note "the Stream Deck app was not found in /Applications. Reason Remote is a Stream Deck"
    say "      plugin, so it needs the Stream Deck app (6.9 or newer, macOS 13 or newer) and a"
    say "      Stream Deck +. See Requirements in $README_URL"
  fi
  if [ "$os" = "Darwin" ] && pgrep -f '/Reason[^/]*\.app/Contents/MacOS/' >/dev/null 2>&1; then
    note "Reason is running. Quit it fully and start it again: it reads these files only at startup."
  fi
}

main() {
  local os home owner work zip size expected actual src_codec src_map roots root
  local dst_codec dst_map root_owner installed=0 skipped=0 required old_ifs

  say "Reason Remote - Automate Pros (macOS installer: beta, untested on Mac hardware)"

  os="${REASON_REMOTE_OS:-$(uname -s)}"
  case "$os" in
    Darwin) ;;
    MINGW*|MSYS*|CYGWIN*|Windows*) die "This is the macOS installer. On Windows run install.ps1 in PowerShell 7 (see the README)." ;;
    *) [ -n "${REASON_REMOTE_ROOTS:-}" ] || die "Reason runs on macOS and Windows only (this is $os)." ;;
  esac

  command -v unzip >/dev/null 2>&1 || die "'unzip' is required."
  sha256_of /dev/null >/dev/null || die "'shasum' (or 'sha256sum') is required to check the download."

  owner="$(sudo_owner)"
  home="$(user_home)"
  check_apps "$os" "$home"

  work="$(mktemp -d "${TMPDIR:-/tmp}/reason-remote-setup.XXXXXX")"
  # shellcheck disable=SC2064 # expand now: $work is local to main
  trap "rm -rf '$work'" EXIT

  # -------------------------------------------------------------- download + check

  zip="$work/reason-remote-setup.zip"
  if [ -n "${REASON_REMOTE_BUNDLE:-}" ]; then
    cp "$REASON_REMOTE_BUNDLE" "$zip" || die "Cannot read $REASON_REMOTE_BUNDLE"
    expected="${REASON_REMOTE_BUNDLE_SHA256:-$BUNDLE_SHA256}"
  else
    command -v curl >/dev/null 2>&1 || die "'curl' is required."
    say "Downloading setup bundle $BUNDLE_TAG..."
    curl -fsSL --proto '=https' "$ASSET_URL" -o "$zip" || die "Download failed: $ASSET_URL"
    expected="$BUNDLE_SHA256"
  fi

  # A GitHub error page or a truncated transfer would otherwise fail inside unzip.
  size=$(wc -c < "$zip" | tr -d ' ')
  [ "$size" -ge 10240 ] || die "The download is only $size bytes, which is not the setup bundle. Check $ASSET_URL in a browser."

  actual="$(sha256_of "$zip")"
  [ "$actual" = "$expected" ] || die "The bundle's SHA-256 is $actual, expected $expected. Nothing was installed."
  say "  $((size / 1024)) KB, SHA-256 verified"

  unzip -q -o "$zip" -d "$work/bundle" || die "The bundle is not a valid zip file."

  src_codec="$work/bundle/Codecs/Lua Codecs/$MANUFACTURER"
  src_map="$work/bundle/Maps/$MANUFACTURER"
  for required in \
    "$src_codec/StreamDeckPlusRemote.lua" "$src_codec/StreamDeckPlusRemote.luacodec" \
    "$src_codec/StreamDeckPlusMaster.lua" "$src_codec/StreamDeckPlusMaster.luacodec" \
    "$src_map/$MANUFACTURER Stream Deck+ Remote.remotemap" "$src_map/$MANUFACTURER Stream Deck+ Master.remotemap"; do
    [ -f "$required" ] || die "This is not the setup bundle: ${required#"$work/bundle/"} is missing."
  done

  # -------------------------------------------------------------- copy

  roots="${REASON_REMOTE_ROOTS:-$SYSTEM_ROOT:$home/Library/Application Support/Propellerhead Software/Remote}"
  old_ifs="$IFS"
  IFS=':'
  # shellcheck disable=SC2086 # split on ':' only
  set -- $roots
  IFS="$old_ifs"

  for root in "$@"; do
    [ -n "$root" ] || continue
    dst_codec="$root/Codecs/Lua Codecs/$MANUFACTURER"
    dst_map="$root/Maps/$MANUFACTURER"
    # Under sudo the per-user copy, and any folder created for it, belongs to the user who
    # ran sudo, not root. The system location stays root's.
    root_owner=""
    [ "$root" = "$SYSTEM_ROOT" ] || root_owner="$owner"
    if ! { make_dirs "$root_owner" "$dst_codec" "$dst_map" && [ -w "$dst_codec" ] && [ -w "$dst_map" ]; }; then
      say "Skipped $root (no write access)"
      skipped=$((skipped + 1))
      continue
    fi
    cp -f "$src_codec"/* "$dst_codec/"
    cp -f "$src_map"/* "$dst_map/"
    remove_legacy "$root/Codecs/Lua Codecs/$LEGACY_MANUFACTURER" "$(legacy_codec_files)"
    remove_legacy "$root/Maps/$LEGACY_MANUFACTURER" "$(legacy_map_files)"
    if [ -n "$root_owner" ]; then
      chown -R "$root_owner:$(id -g "$root_owner")" "$dst_codec" "$dst_map" || die "Could not give $root back to $root_owner."
    fi
    say "Installed to $root"
    installed=$((installed + 1))
  done

  [ "$installed" -gt 0 ] || die "Could not install to any Reason Remote location."
  if [ "$skipped" -gt 0 ]; then
    say ""
    say "Note: the system-wide location was skipped. Reason reads your user location just as well."
    say "To install for every user on this Mac too (needs an admin password):"
    say "  curl -fsSL https://raw.githubusercontent.com/Automate-Pros/reason-remote-setup/main/install.sh | sudo bash"
  fi

  # -------------------------------------------------------------- next steps

  cat <<EOF

Next steps:
  1. Create four virtual MIDI buses (once):
     open -a "Audio MIDI Setup"   then Window -> Show MIDI Studio -> double-click IAC Driver,
     tick "Device is online", add buses until there are four: Bus 1, Bus 2, Bus 3, Bus 4,
     then click Apply. Keep the default names - the plugin looks for "IAC Driver Bus 1" to "IAC Driver Bus 4".
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

To uninstall, see "Uninstalling" in the guide.
Full guide: $README_URL
EOF
}

main "$@"
