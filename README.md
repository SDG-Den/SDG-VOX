# SDG-VOX

Voice command system for SDG-OS — wake-word activated, fully offline voice control.

## Description

SDG-VOX uses `whisper.cpp` for speech-to-text and a tree-based command graph to match spoken commands to actions. It runs as a background daemon with optional HUD overlay and a GTK config editor with flowchart visualization.

## Features

- **Wake-word activation** — "system command", "cmd", "computer", "i cast", "highcast"
- **3-second grace** — speak follow-up commands without repeating wake word
- **48-node command graph** — launch/open, quit, clipboard, volume, search, type, run, execute, dictate
- **Prefix/suffix modifiers** — "administrator" (sudo), "silent" (detached), "background" (&), "detach"
- **HUD overlay** — transparent GTK overlay showing transcriptions
- **Config editor** — GTK GUI with flowchart view, drag-to-connect nodes, command testing
- **Hot-reload** — daemon polls config every second for changes
- **Whisper server** — managed subprocess with health-check and auto-restart

## CLI Usage

```bash
sdgvox daemon              # Start with HUD overlay
sdgvox daemon --headless   # Start without overlay
sdgvox config              # Open GTK config editor
```

## Voice Commands

| Say | Result |
|-----|--------|
| "system command launch firefox" | Opens Firefox |
| "system command volume up" | Volume +5% |
| "system command open terminal" | Opens Ghostty |
| "system command type hello" | Types "hello" via ydotool |
| "system command quit firefox" | Kills Firefox |
| "system command administrator update" | sudo system update |

## Installation

```bash
sdgpkg install sdg-vox
```

## Dependencies

- `python3` (>=3.10), `python3-gobject`, `python3-cairo`
- `gst-plugins-base`, `gst-plugins-good` — audio capture
- `gtk-layer-shell` — Wayland overlay
- `pipewire`, `pipewire-pulse` — audio
- `whisper.cpp` (whisper-server) — speech-to-text
- `ydotool` — keystroke injection

## Related Packages

- **SDG-MANGO-CORE** — could bind sdgvox to a key
