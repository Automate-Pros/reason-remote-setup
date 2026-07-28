# Reason Remote Auto-Follow — Setup Guide

This makes your Stream Deck + follow whatever device you select in Reason. Select a Thor,
the deck shows Thor's controls. Select a SubTractor, it switches. No button presses, no
manual profile switching.

**The plugin on its own does nothing.** It listens for MIDI from a Remote codec that has to
be installed into Reason, over virtual MIDI ports that have to be created first. Budget
about 20 minutes for the one-time setup. After that it just works.

> Not affiliated with, or endorsed by, Reason Studios AB or Elgato. Reason and all Reason
> device names are trademarks of their respective owners.

---

## The two control surfaces

This installs **two** Reason control surfaces, both under manufacturer **Automate Pros**.
They do different jobs and need their own MIDI port pair each.

| Surface | Model | Ports (in / out) | What it does |
| --- | --- | --- | --- |
| **Auto-follow** | `Stream Deck+ Remote` | 1 / 2 | Instrument pages and the Document (track navigation) page. This is the surface that follows your selection in Reason. |
| **Master** | `Stream Deck+ Master` | 3 / 4 | Master Section mixing. **Locked** to the Master Section, so it keeps working while an instrument is focused. |

The Master surface is what lets you mix without losing your instrument page — that only
works because it is **surface locked** to the Master Section — a manual step in Reason that
is easy to miss, covered in Step 3c.

You can set up the auto-follow surface alone if you don't need the mixer, in which case you
only need ports 1 and 2.

---

## What you need

| | |
| --- | --- |
| Stream Deck + | The profiles are built for the Stream Deck + (dials + touch strip) |
| Stream Deck software | 6.9 or newer |
| Reason | Reason 12 or newer, or Reason Recon |
| **MIDI plugin by Trevliga Spel** | **Required — paid.** [Get it on Marketplace](https://marketplace.elgato.com/@trevliga-spel). See below. |
| PowerShell 7 | Windows: [install pwsh](https://aka.ms/powershell) if you don't have it. macOS: `brew install --cask powershell` |
| Virtual MIDI ports | Windows: [loopMIDI](https://www.tobias-erichsen.de/software/loopmidi.html). macOS: the built-in IAC Driver |

Step 2 fetches everything else for you — there is nothing to download by hand.

> ### The Trevliga Spel MIDI plugin is required
>
> Every **dial** and every **mixer key** in the bundled profiles is driven by the
> [MIDI plugin from Trevliga Spel](https://marketplace.elgato.com/@trevliga-spel). This
> plugin handles auto-follow — switching the deck to the right page as you select devices
> in Reason — but it does not send the parameter MIDI itself.
>
> Without it installed, the deck still follows your selection and page navigation still
> works, but **the dials will not control anything**.
>
> That plugin moved from free to paid in March 2026. If you already own it you were
> grandfathered in and will not be charged again.

> **Windows and macOS.** The codec and both surfaces install on either. The **Auto-Follow
> Stream Deck plugin is Windows-only** — on macOS you get working Reason surfaces that you
> drive from a manually imported Stream Deck profile, but not automatic profile switching.

---

## Step 1 — Create the virtual MIDI ports

Reason and the Stream Deck talk over virtual MIDI cables. You need **four** for both
surfaces (or just the first two if you're skipping the mixer).

### Windows — loopMIDI

1. Install and launch **loopMIDI**.
2. In the box at the bottom left, type a name and click **+**. Create all four:
   `loopMIDI Port 1`, `loopMIDI Port 2`, `loopMIDI Port 3`, `loopMIDI Port 4`.
3. Tick **Autostart** in loopMIDI's options so the ports return after a reboot.

Names must match exactly — the plugin looks for `loopMIDI Port 2` by default. (You can
change that in the plugin's settings if you need different names.)

### macOS — IAC Driver

1. Open **Audio MIDI Setup** → **Window** → **Show MIDI Studio**.
2. Double-click **IAC Driver** and tick **Device is online**.
3. Add four buses with the **+** button under Ports.

### What each pair carries

| Port | Direction |
| --- | --- |
| 1 | Stream Deck → Reason — knob turns and key presses (auto-follow surface) |
| 2 | Reason → Stream Deck — parameter feedback and the device-changed signal |
| 3 | Stream Deck → Reason (Master surface) |
| 4 | Reason → Stream Deck (Master surface) |

Never use one port for both directions — it feeds back on itself.

---

## Step 2 — Install the codec and maps

Open **PowerShell 7** (`pwsh` — not Windows PowerShell) and run:

```powershell
irm https://raw.githubusercontent.com/Automate-Pros/reason-remote-setup/main/install.ps1 | iex
```

That downloads the latest setup bundle and installs it. Same line on Windows and macOS.

On macOS the system-wide location needs `sudo`, but you don't need it — without it the
files go to your user location, which Reason reads perfectly well. To install for every
user instead:

```bash
sudo pwsh -c "irm https://raw.githubusercontent.com/Automate-Pros/reason-remote-setup/main/install.ps1 | iex"
```

> That one-liner runs a script straight off the internet. If you'd rather read it first,
> drop the `| iex` — `irm <url>` on its own just prints it. Or use the manual route below.

### Manual install

If you prefer not to pipe a script, or you're installing somewhere without internet:

1. Download **`reason-remote-setup.zip`** from the
   [latest release](https://github.com/Automate-Pros/reason-remote-setup/releases/latest).
2. Unzip it.
3. From inside that folder, run `pwsh ./install-remote.ps1` (Windows: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\install-remote.ps1`).

Either route copies into Reason's Remote folders:

| OS | Locations |
| --- | --- |
| Windows | `%PROGRAMDATA%\Propellerhead Software\Remote\` and `%APPDATA%\Propellerhead Software\Remote\` |
| macOS | `/Library/Application Support/Propellerhead Software/Remote/` and `~/Library/Application Support/Propellerhead Software/Remote/` |

Within each: codec files (`.lua`, `.luacodec`, `.png`) go to `Codecs/Lua Codecs/Automate Pros/`
and the `.remotemap` files to `Maps/Automate Pros/`. You can copy them by hand instead if
you prefer.

> Upgrading from a version before 1.1? These surfaces used to ship under manufacturer
> **Community**. The installer deletes those folders so Reason doesn't list both. You will
> need to re-add the surfaces in Step 3 — Reason won't carry the old ones over.

---

## Step 3 — Add both surfaces in Reason

**Fully quit Reason and restart it.** Reason only reads Remote maps at startup, so this is
mandatory — it's the single most common reason setup appears not to work.

### 3a — The auto-follow surface

<img width="521" height="449" alt="Reason Add Manually dialog for Automate Pros Stream Deck+ Remote" src="https://github.com/user-attachments/assets/8bae85f0-85dc-4b97-849d-edceee6ee225" />

1. **Preferences → Control Surfaces → Add Manually**
2. **Manufacturer:** `Automate Pros`
3. **Model:** `Stream Deck+ Remote`
4. **Input Port:** port 1 · **Output Port:** port 2
5. Turn **off** Easy MIDI for both, or Reason handles every message twice

### 3b — The Master surface

<img width="525" height="444" alt="Reason Add Manually dialog for Automate Pros Stream Deck+ Master" src="https://github.com/user-attachments/assets/2b3f4620-6928-48c3-9e13-b5df08141ea7" />

1. **Add Manually** again
2. **Manufacturer:** `Automate Pros`
3. **Model:** `Stream Deck+ Master`
4. **Input Port:** port 3 · **Output Port:** port 4
5. Turn **off** Easy MIDI for both

### 3c — Lock the Master surface to the Master Section

**Don't skip this.** Until you do it, the Master surface follows your selection like any
other surface — so it stops being a dedicated mixer the moment you click an instrument,
which defeats the point of having it.

1. In Reason's menu bar: **Options → Remote and Keyboard Control → Surface Locking…**

<!-- IMAGE SLOT: Options > Remote and Keyboard Control menu, Surface Locking highlighted -->

2. **Surface:** choose `Automate Pros Stream Deck+ Master`
3. **Lock to Device:** choose `Master Section (Master Section)`
4. Close the dialog.

<!-- IMAGE SLOT: Surface Locking dialog showing Stream Deck+ Master locked to Master Section -->


The dialog shows the surface's own setup notes once selected, which is a quick way to
confirm you picked the right one — it should mention Ports 3 and 4. Leave **Always Use
Mapping** alone; it stays greyed out for this surface.

Only the Master surface gets locked. Leave `Stream Deck+ Remote` unlocked — following your
selection is exactly what it's for.

If `Automate Pros` doesn't appear in the Add Manually list, the codec didn't land in the
right folder or Reason wasn't fully restarted. Recheck Step 2 and restart again.

---

## Step 4 — Install the plugin (Windows)

Install **Reason Remote Auto-Follow** from the Elgato Marketplace, or double-click the
`.streamDeckPlugin` file.

It brings its own profiles and installs them automatically:

| Profile | Covers |
| --- | --- |
| `Reason - Core` | SubTractor, Friktion, Thor, Fury |
| `Reason - RSN-P1` … `P4` | The remaining stock Reason devices |
| `Reason - Document` | Track navigation and document-level controls |
| `Reason - Master` | Master Section mixing (the locked surface) |

They're set not to auto-switch on install, so nothing changes until Reason tells the plugin
a device was selected.

---

## Step 5 — Try it

1. loopMIDI (or IAC) running, Reason open.
2. Click a **SubTractor** in the rack so it has focus.
3. The deck should switch to the SubTractor layout within a moment.
4. Turn a dial — the parameter should move in Reason.
5. Click a **Thor**. The deck should follow.
6. With the instrument still focused, press **Mix** to reach the Master Section, and confirm
   the faders drive the main mixer.

---

## Actions you can add to your own profiles

| Action | What it does |
| --- | --- |
| **Reason Remote Status** | The last device the plugin saw and which profile it switched to. The best troubleshooting key. |
| **Open Document** / **Return from Document** | Jump to track navigation and back |
| **Open Master** / **Return from Master** | Jump to Master Section mixing and back |
| **Current Instrument** | Shows the device you're browsing; press to open its page |
| **Track Previous** / **Track Next** | Step through tracks while browsing |

---

## Troubleshooting

**The deck never switches.**
Drop a **Reason Remote Status** key onto any profile — it shows what the plugin last
received. If it stays blank, no MIDI is arriving: check loopMIDI is running, the port is
named `loopMIDI Port 2`, and Reason's auto-follow surface output is set to that port.

**A key shows a yellow warning triangle.**
That means the plugin process isn't running, not that the key is misconfigured. Reinstall
the plugin and check for a `node.exe` process for `com.automate-pros.reason.remote`.

**`Automate Pros` isn't in Reason's Add Manually list.**
The codec isn't installed, or Reason wasn't fully quit. Re-run the installer and restart
Reason completely — closing the song isn't enough.

**Both `Community` and `Automate Pros` appear.**
An old install is still present. Re-run the installer, which removes the `Community`
folders, then restart Reason.

**Everything happens twice.**
Easy MIDI is still on for one of the ports. Turn it off for all four.

**The Master surface follows my instrument selection.**
It isn't locked. **Options → Remote and Keyboard Control → Surface Locking…**, pick
`Automate Pros Stream Deck+ Master`, and set **Lock to Device** to
`Master Section (Master Section)`. See Step 3c.

**The surface or the Master Section isn't in the Surface Locking dropdowns.**
Check you completed Step 3b — the surface has to exist in Preferences before it can be
locked — and that a song is open when you open the dialog.

**Dials move the wrong parameter.**
The deck is on a profile for a different device. Check the Status key — if it disagrees with
Reason, click the device in the rack again to re-send its identity.

**It worked, then stopped after a reboot.**
loopMIDI didn't start. Enable **Autostart** in its options.

**Where are the logs?**
`%APPDATA%\Elgato\StreamDeck\Plugins\com.automate-pros.reason.remote.sdPlugin\logs\`

---

## Uninstalling

1. Remove the plugin from Stream Deck (right-click → Uninstall).
2. Delete the `Automate Pros` folders from `Codecs/Lua Codecs/` and `Maps/` in both Remote
   locations listed in Step 2.
3. Remove both control surfaces in Reason's Preferences.
4. Delete the virtual MIDI ports if nothing else uses them.

---

## Support

Issues and questions: <https://github.com/Automate-Pros/reason-remote-setup/issues>
More: <https://automate-pros.com>
