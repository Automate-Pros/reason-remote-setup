# Reason Remote — Setup Guide

This makes your Stream Deck + follow whatever device you select in Reason. Select a Thor,
the deck shows Thor's controls. Select a SubTractor, it switches. No button presses, no
manual profile switching.

Get the Windows plugin here:
[**Reason Remote on the Elgato Marketplace**](https://marketplace.elgato.com/product/reason-remote-e601aff3-8dcc-49c8-a978-e3b86b73bb10).
There is also a free **[Reason Remote Lite](https://marketplace.elgato.com/product/reason-remote-lite-14ff1e75-a9a5-49cf-a7fd-1f77a9946b22)** —
see [The two versions](#the-two-versions).

**The plugin on its own does nothing.** It listens for MIDI from a Remote codec that has to
be installed into Reason, over virtual MIDI ports that have to be created first. On Windows
the installer in Step 2 does nearly all of that itself — loopMIDI, the four ports, the
Reason surfaces. What's left by hand is a Reason restart and one locking step. After that
it just works.

> Not affiliated with, or endorsed by, Reason Studios AB or Elgato. Reason and all Reason
> device names are trademarks of their respective owners.

---

## The two versions

Two Stream Deck plugins, same setup. The only difference is how many Reason devices the deck
follows — every step in this guide applies to both, unchanged.

| | **Reason Remote** | **Reason Remote Lite** |
| --- | --- | --- |
| Price | Paid | Free |
| Instruments | Every device listed in Step 1b | SubTractor, ReDrum, Europa, Radical Keys |
| Document page (track navigation) | Yes | Yes, identical |
| Master Section page (mixing) | Yes | Yes, identical |
| Reason codec, MIDI ports, surfaces | Shared | Shared |

Select a device Lite doesn't cover and the deck shows a page naming that device and what the
full version adds — that is not a fault.

Because the codec, the MIDI ports and the Reason surfaces are shared, buying the full version
later means installing one Stream Deck plugin and redoing nothing else — just **uninstall Lite
first** (Step 1a).

---

## Quick start

| # | Do this |
| --- | --- |
| 1 | Install **[Reason Remote](https://marketplace.elgato.com/product/reason-remote-e601aff3-8dcc-49c8-a978-e3b86b73bb10)** (or **Reason Remote Lite**) and accept the AutoInstall profile prompts |
| 2 | Close Reason, then run the one-liner in Step 2. On Windows it installs the codec/maps, sets up loopMIDI and the four ports, and registers both surfaces in Reason. On Mac, create the IAC buses first (Step 3) |
| 3 | **Fully quit and restart Reason** |
| 4 | **Lock Master** to the Master Section (Step 4c). If the installer said a step needs doing by hand, Steps 3 and 4a–4b have the details |
| 5 | Focus a SubTractor — the deck should switch; turn a dial; then try Thor and **Mix** |

Details for each step are below.

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
is easy to miss, covered in Step 4c.

You can set up the auto-follow surface alone if you don't need the mixer, in which case you
only need ports 1 and 2.

---

## What you need

| | |
| --- | --- |
| Stream Deck + | The profiles are built for the Stream Deck + (dials + touch strip) |
| Stream Deck software | 6.9 or newer |
| Reason | Reason 12 or newer, or Reason Recon |
| PowerShell 7 | Windows: [install pwsh](https://aka.ms/powershell) if you don't have it. macOS: `brew install --cask powershell` |
| Virtual MIDI ports | Windows: [loopMIDI](https://www.tobias-erichsen.de/software/loopmidi.html) — the installer offers to download it for you. macOS: the built-in IAC Driver |

Step 2 fetches the Reason codec and maps for you — there is nothing else to download by hand.

**No other Stream Deck plugin is needed.** The dials, the touch strip and the mixer keys are
all Reason Remote's own actions, in both versions. Earlier releases required a separate paid
MIDI plugin for the dials; that dependency is gone. If you installed one for this, you can
leave it or remove it — Reason Remote does not use it either way.

> **Windows and macOS.** The codec and both surfaces install on either. The **Auto-Follow
> Stream Deck plugin is Windows-only** — on macOS you get working Reason surfaces that you
> drive from a manually imported Stream Deck profile, but not automatic profile switching.

---

## Step 1 — Install the Stream Deck plugin (Windows)

### 1a — Reason Remote, or Reason Remote Lite

Install **[Reason Remote](https://marketplace.elgato.com/product/reason-remote-e601aff3-8dcc-49c8-a978-e3b86b73bb10)**
from the Elgato Marketplace — or **[Reason Remote Lite](https://marketplace.elgato.com/product/reason-remote-lite-14ff1e75-a9a5-49cf-a7fd-1f77a9946b22)**
if you want the free version first. Everything from here on is identical for both.

> **Sent a `.streamDeckPlugin` file directly?** Double-click it instead, accept the
> AutoInstall prompts, and carry on from Step 2 — the rest of this guide is the same. Note
> that Stream Deck does not auto-update a plugin installed this way: new versions arrive as
> a new file, not as an update prompt.

> **Do not run Lite and the full version at the same time.** Both listen on the same
> feedback MIDI port and both switch profiles, so they fight over the deck and it flickers
> between them. Uninstall one before installing the other. Nothing else changes — the codec,
> the MIDI ports and the Reason surfaces are shared, so you keep your existing setup.

### 1b — The bundled profiles

When Stream Deck prompts, **accept AutoInstall** for the bundled profiles. They install
automatically and stay idle until Reason tells the plugin a device was selected.

**Reason Remote** installs nine:

| Profile | Covers |
| --- | --- |
| `Reason - Core (Auto-Follow)` | SubTractor, Friktion, Thor, Fury |
| `RSN-Objekt,Octo,NN19,ID8,Parsec (Auto Follow)` | Objekt, Dr. Octo Rex, NN-19, ID8, Parsec |
| `RSN-Kong,Redrum,Europa,Malstrom,NNXT (Auto Follow)` | Kong, Redrum, Europa, Malström, NN-XT |
| `RSN-Mimic,Grain,Complex1,Polytone,Monotone (Auto Follow)` | Mimic, Grain, Complex-1, Polytone, Monotone |
| `RSN-RadPiano,RadKeys,Algoritm (Auto Follow)` | Radical Piano, Radical Keys, Algoritm |
| `RSN-Humana,Klang,Pangea (Auto Follow)` | Humana, Klang, Pangea |
| `RSN-UmpfClub,UmpfRetro (Auto Follow)` | Umpf Club, Umpf Retro |
| `Reason - Document (Global)` | Track navigation and document-level controls |
| `Reason - Master (Global)` | Master Section mixing (the locked surface) |

**Reason Remote Lite** installs three instead:

| Profile | Covers |
| --- | --- |
| `Reason Lite (Auto-Follow)` | SubTractor, ReDrum, Europa, Radical Keys, plus a page naming whatever else you select |
| `Reason Lite - Document (Global)` | Track navigation and document-level controls |
| `Reason Lite - Master (Global)` | Master Section mixing (the locked surface) |

---

## Step 2 — Run the installer

**Close Reason first** — the installer can only register the surfaces while Reason is not
running. On macOS, create the IAC buses first (Step 3). Then open **PowerShell 7**
(`pwsh` — not Windows PowerShell) and run:

```powershell
irm https://raw.githubusercontent.com/Automate-Pros/reason-remote-setup/main/install.ps1 | iex
```

That downloads the latest setup bundle and installs it. Same line on Windows and macOS.

On Windows it does more than copy files:

- Checks for **loopMIDI**. If it's missing, it asks before downloading the official
  installer from tobias-erichsen.de (the download's signature is verified) and running it.
- Creates the four `loopMIDI Port` ports and turns Autostart on.
- Registers both Automate Pros surfaces in Reason's preferences, on the right ports with
  Easy MIDI off. Works with Reason 13 and newer; a timestamped backup of each preferences
  file is written next to it first. Reason 12 or anything the installer doesn't recognise
  is left alone — it prints the manual steps (4a–4b) instead.

It ends with a summary saying what it did and what, if anything, is still yours to do.
Set `REASON_REMOTE_SETUP_MANUAL=1` before running to skip all of that and only copy files.

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
> need to re-add the surfaces in Step 4 — Reason won't carry the old ones over.

---

## Step 3 — The virtual MIDI ports (manual and macOS)

Reason and the Stream Deck talk over virtual MIDI cables. You need **four** for both
surfaces (or just the first two if you're skipping the mixer).

**On Windows, Step 2 already did this.** Do it by hand only if the installer's summary said
it couldn't, or you're setting up without the installer. On macOS it's always manual.

### Windows — loopMIDI

1. Install **[loopMIDI](https://www.tobias-erichsen.de/software/loopmidi.html)** and launch it.
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

> **Upgrading from a version before 2026-08-24?** The Remote surface definition changed so the
> deck can send notes. **Delete and re-add** the Stream Deck+ Remote surface in Reason
> Preferences after installing — re-adding is not optional, and the old registration will not
> pick up the change. Leave **Master Keyboard** ticked for it if you want the piano to play the
> selected track.

## Step 4 — Add both surfaces in Reason

**Fully quit Reason and restart it.** Reason only reads Remote maps at startup, so this is
mandatory — it's the single most common reason setup appears not to work.

**On Windows the installer normally registers both surfaces for you** — check its summary.
If it did, skip to 4c; only 4c can't be automated. Do 4a and 4b by hand when the summary
told you to (Reason 12, macOS, an unrecognised preferences file, or Reason was running).

### 4a — The auto-follow surface

<img width="521" height="449" alt="Reason Add Manually dialog for Automate Pros Stream Deck+ Remote" src="https://github.com/user-attachments/assets/8bae85f0-85dc-4b97-849d-edceee6ee225" />

1. **Preferences → Control Surfaces → Add Manually**
2. **Manufacturer:** `Automate Pros`
3. **Model:** `Stream Deck+ Remote`
4. **Input Port:** port 1 · **Output Port:** port 2
5. Turn **off** Easy MIDI for both, or Reason handles every message twice

### 4b — The Master surface

<img width="525" height="444" alt="Reason Add Manually dialog for Automate Pros Stream Deck+ Master" src="https://github.com/user-attachments/assets/2b3f4620-6928-48c3-9e13-b5df08141ea7" />

1. **Add Manually** again
2. **Manufacturer:** `Automate Pros`
3. **Model:** `Stream Deck+ Master`
4. **Input Port:** port 3 · **Output Port:** port 4
5. Turn **off** Easy MIDI for both

### 4c — Lock the Master surface to the Master Section

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

**The lock is saved in the song, not in Reason's preferences** — which is why the installer
can't set it, and why a new song comes up unlocked. To stop redoing it: set the lock in an
empty song, save that song somewhere permanent, then **Preferences → General → Default
Song → Custom** and point it at that file. Every new song starts locked from then on.

If `Automate Pros` doesn't appear in the Add Manually list, the codec didn't land in the
right folder or Reason wasn't fully restarted. Recheck Step 2 and restart again.

---

## Step 5 — Try it

1. loopMIDI (or IAC) running, Reason open, Stream Deck software running.
2. Click a **SubTractor** in the rack so it has focus.
3. The deck should switch to the SubTractor layout within a moment.
4. Turn a dial — the parameter should move in Reason.
5. Click a **Thor**. The deck should follow.
6. With the instrument still focused, press **Mix** to reach the Master Section, and confirm
   the faders drive the main mixer.
7. **Press and hold anywhere on the touch strip.** The deck jumps to the Document page —
   transport, undo, loop, click. Hold again to go back to the instrument you were on.
8. From Document, press **Piano**. Hold a key and it plays the selected track for as long as
   you hold it; tap the touch strip for a chromatic octave. Turn dial 1 to transpose, and press
   the bottom-right key to switch the seven keys between notes and chords. Hold the strip to
   go back to the instrument.

If nothing switches, drop a **Reason Remote Status** action on any profile first — see
Troubleshooting.

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

**Start with the Status key.**
Drop a **Reason Remote Status** action onto any profile. It shows what the plugin last
received and which profile it switched to — faster than guessing which step failed.

**The deck never switches.**
If Status stays blank, no MIDI is arriving: check loopMIDI is running, the port is named
`loopMIDI Port 2`, and Reason's auto-follow surface **output** is set to that port.

**A key shows a yellow warning triangle.**
That means the plugin process isn't running, not that the key is misconfigured. Reinstall
the plugin and check for a `node.exe` process for `com.automate-pros.reason-remote`.

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
`Master Section (Master Section)`. See Step 4c.

**The surface or the Master Section isn't in the Surface Locking dropdowns.**
Check you completed Step 4b — the surface has to exist in Preferences before it can be
locked — and that a song is open when you open the dialog.

**Dials move the wrong parameter.**
The deck is on a profile for a different device. Check the Status key — if it disagrees with
Reason, click the device in the rack again to re-send its identity.

**Dials do nothing, but the page still switches.**
Profile switching arrives on Port 2 (Reason to deck); dials go out on Port 1 (deck to Reason),
so this means Port 1 isn't getting through. Check the auto-follow surface's **Input Port** in
Reason is `loopMIDI Port 1`, that the port exists in loopMIDI, and that Easy MIDI is off.

**It worked, then stopped after a reboot.**
loopMIDI didn't start. Enable **Autostart** in its options.

**Where are the logs?**
`%APPDATA%\Elgato\StreamDeck\Plugins\com.automate-pros.reason-remote.sdPlugin\logs\`

---

## Uninstalling

1. Remove the plugin from Stream Deck (right-click → Uninstall). Its profiles go with it.
2. Delete the `Automate Pros` folders from `Codecs/Lua Codecs/` and `Maps/` in both Remote
   locations listed in Step 2.
3. Remove both control surfaces in Reason's Preferences.
4. Delete the virtual MIDI ports if nothing else uses them.

**Moving from Lite to the full version?** Only step 1 applies — uninstall the Lite plugin,
then install the full one. Leave the codec, maps, MIDI ports and Reason surfaces exactly as
they are; both versions use the same ones.

---

## Support

Please use GitHub — Marketplace comments are easy to miss.

| | |
| --- | --- |
| **Bugs, crashes, broken installs** | [GitHub Issues](https://github.com/Automate-Pros/reason-remote-setup/issues) |
| **Questions, how-to, instrument requests** | [GitHub Discussions](https://github.com/Automate-Pros/reason-remote-setup/discussions) |
| **Website** | [automate-pros.com](https://automate-pros.com) |
