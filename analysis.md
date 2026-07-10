# SDG-VOX Analysis

## Type
Voice Command System Module

## Description
SDG-VOX is a wake-word activated, fully offline voice command daemon for SDG-OS. It uses `whisper.cpp` for speech-to-text and a tree-based command graph for matching spoken commands to actions (exec, shell_exec, type).

## CLI Entry Points
| Command | Description |
|---------|-------------|
| `sdgvox daemon` | Start voice daemon (always-listening with HUD overlay) |
| `sdgvox daemon --headless` | Start daemon without overlay |
| `sdgvox config` | Open GTK config editor |
| `vox-config.desktop` | Desktop launcher for config GUI |

## Usage
After installation via `sdgpkg install sdg-vox`, the `sdgvox` command becomes available.

### Starting the Daemon
```bash
sdgvox daemon                  # Start with HUD overlay (shows transcriptions)
sdgvox daemon --headless       # Start without overlay
```

The daemon loads `~/.config/SDG-VOX/config.json` and listens continuously. It downloads the Whisper model (~1.5GB) on first run.

### Voice Commands
Say the wake word **"system command"** (or "cmd", "computer", "i cast", "highcast") followed by a command:

| Say this | Result |
|----------|--------|
| "system command launch firefox" | Opens Firefox |
| "system command volume up" | Increases volume by 5% |
| "system command search for hello world" | Opens Google search for "hello world" |
| "system command type hello world" | Types "hello world" via ydotool |
| "system command administrator update" | Runs system update with sudo |
| "system command quit firefox" | Kills Firefox |
| "system command clipboard copy" | Copies selection to clipboard |
| "system command open terminal" | Opens Ghostty terminal |

After saying just the wake word ("system command"), you have a 3-second window to speak a follow-up command without repeating the wake word.

### Prefix/Suffix Modifiers
| Say | Effect |
|-----|--------|
| "**administrator** launch update" | Runs with sudo |
| "**silent** launch firefox" | Runs with setsid (detached) |
| "launch firefox **background**" | Runs in background (&) |
| "launch firefox **detach**" | Fully detached from terminal |

### Immediate Triggers
Say "cancel" at any time to abort the current command.

### Config Editor
```bash
sdgvox config                  # Open GTK GUI editor
```

The config editor lets you:
- View the command graph as a flowchart (Cairo rendering)
- Add/edit/delete nodes (branch, exec, shell_exec, type)
- Drag to create connections between nodes
- Configure terminal, exec prefix, prefix/suffix rules, immediate triggers
- Test commands by typing an utterance and tracing the path through the graph
- Launch/stop the daemon from within the GUI

### Keyboard Shortcuts in Config Editor
| Key | Action |
|-----|--------|
| Delete | Remove selected node |
| Ctrl+C | Copy selected node |
| Ctrl+V | Paste node |
| Ctrl+S | Save config |
| Right-click | Context menu |

## Directory Structure
```
SDG-VOX/
├── README.md                     # Minimal stub
├── .gitignore                    # Ignores models/, *.bin, *.zip, __pycache__/
├── install.sh / update.sh / uninstall.sh
├── config/SDG-VOX/
│   └── config.json               # Default command graph (529 lines, 48 nodes: 1 root + 30 branch + 12 exec + 3 shell_exec + 1 type + 1 special)
├── local/SDG-VOX/
│   ├── vox.sh                    # CLI wrapper (symlinked to /usr/bin/sdgvox)
│   ├── pyproject.toml            # Python package metadata
│   ├── models/
│   │   └── ggml-medium.en.bin    # Whisper model (~1.5GB, gitignored)
│   └── vox/                      # Python package
│       ├── __init__.py           # Version: 0.1.0
│       ├── __main__.py           # python -m vox support
│       ├── cli.py                # CLI argument parser
│       ├── daemon.py             # Main daemon loop (config, hot-reload, watchdog)
│       ├── audio_capture.py      # GStreamer PipeWire capture (16kHz S16LE)
│       ├── whisper_recognizer.py # Whisper STT (VAD, wake-word state machine)
│       ├── recognizer.py         # Legacy Vosk recognizer (dead code)
│       ├── command_tree.py       # Graph matching engine (skip-based)
│       ├── models.py             # Data classes (GraphNode, Config, etc.)
│       ├── executor.py           # Action dispatcher (subprocess/ydotool)
│       ├── config_manager.py     # JSON load/save with migration
│       ├── config_ui.py          # GTK config editor (1229 lines)
│       ├── flowchart_view.py     # Cairo DAG editor (809 lines)
│       └── overlay.py            # GTK-layer-shell HUD overlay
├── docs/
│   ├── README.md                 # Full documentation (258 lines, Vosk version)
│   ├── README-updated.md         # Updated docs (180 lines, Whisper version)
│   ├── CONCEPT.md                # Original concept
│   └── CONCEPT-updated.md        # Updated concept
├── other/vox-config.desktop      # Desktop entry for config GUI
└── tips/placeholder              # Empty placeholder file
```

## Default Command Graph (48 nodes)
| Root | Wake words | Aliases |
|------|------------|---------|
| default | "system command" | "cmd", "computer", "i cast", "highcast" |

### Connections from root
- **launch/open**: Firefox, Chromium, terminal (ghostty), package manager (unipkg)
- **quit**: Firefox, Chromium (pkill)
- **clipboard**: copy (wl-copy), paste (wl-paste)
- **volume**: up (+5%), down (-5%), mute (toggle)
- **search for**: xdg-open google search
- **type**: ydotool type
- **run**: generic exec
- **output**: output mode
- **dictate**: dictation mode
- **execute**: shell exec
- **full/fool**: full system command

### Prefix/Suffix Rules
| Prefix | Effect |
|--------|--------|
| "administrator" | Prepend "sudo" |
| "silent" | Prepend "setsid -w" |
| "background" | Append "&" |
| "detach" | Append "&>/dev/null &" |

## Recognition Pipeline
1. Daemon spawns `whisper-server` as a managed subprocess (port 18081) with 120-second startup wait + health-check/auto-restart watchdog
2. GStreamer capture (PipeWire → 16kHz S16LE mono)
3. VAD segmentation (RMS threshold, silence >0.8s)
4. HTTP POST to whisper-server (port 18081)
5. Wake-word detection → wake state (3-second grace)
6. Command tree matching (skip-based algorithm)

## Required Dependencies
| Dependency | Purpose |
|------------|---------|
| python3 (>=3.10) | Runtime |
| python3-gobject | GTK3 bindings |
| python3-cairo | Cairo rendering |
| gst-plugins-base | GStreamer audio pipeline |
| gst-plugins-good | GStreamer audio pipeline |
| gtk-layer-shell | Wayland overlay layer |
| pipewire | Audio capture |
| pipewire-pulse | PulseAudio compat |
| ydotool | Keyboard typing (Wayland) |
| whisper.cpp (whisper-server) | Speech-to-text engine |

## Optional Dependencies
| Dependency | Purpose |
|------------|---------|
| Vosk | Legacy STT engine (recognizer.py is dead code) |

## Required Dependents
None (user-facing application)

## Optional Dependents
- **SDG-DOCS**: Documents vox commands
- **SDG-MANGO-CORE**: Could bind sdgvox to a key

## Config File
`~/.config/SDG-VOX/config.json` — User-editable JSON command graph with hot-reload (daemon polls mtime every second)
