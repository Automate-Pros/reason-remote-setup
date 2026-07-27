# Reason Remote Auto-Follow — Setup Guide

This Stream Deck plugin makes your Stream Deck + follow whatever device you select in
Reason. Select a Thor, the deck shows Thor's controls. Select a SubTractor, it switches
to SubTractor. No button presses, no manual profile switching.

**The plugin on its own does nothing.** It listens for MIDI from a Remote codec that has
to be installed into Reason, over virtual MIDI ports that have to be created first. Budget
about 15 minutes for the one-time setup below. After that it just works.

> Windows only. macOS is not supported yet — the virtual MIDI setup and the codec
> installer are Windows-specific.

> Not affiliated with, or endorsed by, Reason Studios AB or Elgato. Reason and all Reason
> device names are trademarks of their respective owners.

---

## What you need

| | |
| --- | --- |
| Stream Deck + | The plugin ships profiles for the Stream Deck + (dials + touch strip) only |
| Stream Deck software | 6.9 or newer |
| Reason | Reason 12 or newer, or Reason Recon |
| loopMIDI | Free, from [Tobias Erichsen](https://www.tobias-erichsen.de/software/loopmidi.html) |
| The companion download | `Reason-StreamDeck-Remote.zip` — link on the Marketplace listing and on the [Releases page](https://github.com/Automate-Pros/reason-remote-setup/releases/latest) |

---

## Step 1 — Create the virtual MIDI ports

Reason and the Stream Deck talk to each other over virtual MIDI cables. loopMIDI creates
them.

1. Install and launch **loopMIDI**.
2. In the box at the bottom left, type a port name and click **+**. Create these two:
   - `loopMIDI Port 1`
   - `loopMIDI Port 2`
3. If you also want the **Master Section** profile on a second Stream Deck, add
   `loopMIDI Port 3` and `loopMIDI Port 4` as well.
4. Tick **Autostart** in loopMIDI's options so the ports come back after a reboot.

The names must match exactly — the plugin looks for `loopMIDI Port 2` by default. (You can
change the port name later in the plugin's settings if you need different names.)

| Port | Carries |
| --- | --- |
| `loopMIDI Port 1` | Stream Deck → Reason (your knob turns and key presses) |
| `loopMIDI Port 2` | Reason → Stream Deck (parameter feedback and the device-changed signal) |
| `loopMIDI Port 3` / `4` | The same pair again, for the optional Master Section surface |

Never use one port for both directions — it feeds back on itself.

---

## Step 2 — Install the Remote codec into Reason

Download and unzip `Reason-StreamDeck-Remote.zip`, then from that folder run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-remote.ps1
```

That copies the Lua codec and the Remote map into both of Reason's Remote folders:

```
%PROGRAMDATA%\Propellerhead Software\Remote\Codecs\Lua Codecs\Community\
%PROGRAMDATA%\Propellerhead Software\Remote\Maps\Community\
%APPDATA%\Propellerhead Software\Remote\Codecs\Lua Codecs\Community\
%APPDATA%\Propellerhead Software\Remote\Maps\Community\
```

If you'd rather copy them by hand, those are the four destinations — the codec files
(`.lua`, `.luacodec`, `.png`) go in the `Codecs\Lua Codecs\Community` folders and the
`.remotemap` goes in the `Maps\Community` folders.

---

## Step 3 — Add the control surface in Reason

**Fully quit Reason and restart it.** Reason only reads Remote maps at startup, so a
restart is mandatory — this is the single most common reason setup appears not to work.

Then:

1. **Preferences → Control Surfaces → Add Manually**
2. **Manufacturer:** `Community`
3. **Model:** `Stream Deck+ Remote`
4. **Input Port:** `loopMIDI Port 1`
5. **Output Port:** `loopMIDI Port 2`
6. Turn **off** Easy MIDI / "Use with Easy MIDI" for both ports, or Reason will handle
   every message twice.

If Manufacturer `Community` doesn't appear in the list, the codec didn't land in the right
folder or Reason wasn't fully restarted. Check Step 2 and restart again.

---

## Step 4 — Install the plugin

Install **Reason Remote Auto-Follow** from the Elgato Marketplace (or double-click the
`.streamDeckPlugin` file).

The plugin brings its own profiles and installs them automatically. You'll see these
appear in your Stream Deck profile list:

| Profile | What it covers |
| --- | --- |
| `Reason - Core` | SubTractor, Friktion, Thor |
| `Reason - RSN-P1` … `P4` | The remaining stock Reason devices |
| `Reason - Fury` | Fury |
| `Reason - Document` | Track navigation and document-level controls |
| `Reason - Master` | Master Section mixing (second surface) |

They are set not to auto-switch on install, so nothing changes until Reason tells the
plugin a device was selected.

---

## Step 5 — Try it

1. Make sure loopMIDI is running and Reason is open.
2. In Reason, click on a **SubTractor** in the rack (open the device so it has focus).
3. Your Stream Deck + should switch to the SubTractor layout within a moment.
4. Turn a dial — the SubTractor's parameter should move in Reason.
5. Click a **Thor** instead. The deck should follow.

---

## Actions you can add to your own profiles

| Action | What it does |
| --- | --- |
| **Reason Remote Status** | Shows the last device the plugin saw, and which profile it switched to. The best troubleshooting key. |
| **Open Document** / **Return from Document** | Jump to the document/track-navigation profile and back |
| **Open Master** / **Return from Master** | Jump to the Master Section profile and back |
| **Current Instrument** | Shows the device you're browsing; press to open its page |
| **Track Previous** / **Track Next** | Step through tracks while in document browse mode |

---

## Troubleshooting

**The deck never switches.**
Drop a **Reason Remote Status** key onto any profile. It shows what the plugin last
received. If it stays blank, no MIDI is arriving — check loopMIDI is running, the port is
named `loopMIDI Port 2`, and that Reason's control surface output is set to that port.

**Manufacturer "Community" isn't in Reason's Add Manually list.**
The codec isn't installed, or Reason wasn't fully quit. Re-run `install-remote.ps1` and
restart Reason completely (not just close the song).

**Everything happens twice.**
Easy MIDI is still enabled on one of the loopMIDI ports. Turn it off for both in
Reason's Preferences.

**Dials move the wrong parameter.**
The deck is on a profile for a different device. Check the Status key — if it disagrees
with what's selected in Reason, click the device in the rack again to re-send its identity.

**It worked, then stopped after a reboot.**
loopMIDI didn't start. Enable **Autostart** in loopMIDI's options.

**Where are the logs?**
`%APPDATA%\Elgato\StreamDeck\Plugins\com.automate-pros.reason.remote.sdPlugin\logs\`

---

## Uninstalling

1. Remove the plugin from Stream Deck (right-click it in the store list → Uninstall).
2. Delete the `Community` folders from the four Remote paths listed in Step 2.
3. Remove the control surface in Reason's Preferences.
4. Delete the loopMIDI ports if nothing else uses them.

---

## Support

Issues and questions: <https://github.com/Automate-Pros/reason-remote-setup/issues>
More: <https://automate-pros.com>
