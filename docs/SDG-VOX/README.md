# vox — voice-to-commands

Wake-word activated, fully offline voice commands with a flat directed-graph binding engine. No cloud APIs, no data leaving your machine.

- **Daemon mode** — always-listening background service with a transparent HUD overlay
- **Config mode** — GTK graph editor with a Cairo-rendered flowchart (DAG layout, pan/zoom)
- **Offline STT** — whisper-server (whisper.cpp), runs locally
- **Three action types** — `exec`, `shell_exec`, `type`

## Quick start

```sh
# Install system + Python dependencies (detects package manager)
./install.sh

# Open the configuration GUI to build your command graph
vox config

# Start the daemon (speak "system command" + your command)
vox daemon
```

## How it works

You speak a **wake word** (default: `"system command"`) followed by a command, e.g. `"system command, open firefox"`. The daemon transcribes continuously via whisper-server, detects the wake word, strips it, then walks the command graph to find a matching action.

### Matching algorithm — skip-based

The graph matcher is *skip-based*: non-matching words are silently ignored rather than causing the match to fail:

```
"system command, open the firefox now"       → matches "open" → "firefox"
"system command, hey please launch chromium" → matches "launch" → "chromium"
"system command, search for cute cats online" → captures "cute cats online"
```

### Command graph

Each node is an independent entity with a *name* (the spoken keyword), a *type*, and *connections* to other nodes. Multiple nodes can share the same downstream node. Nodes with exactly one connection to another branch node are *auto-followed* — the intermediate label is silently traversed without consuming a token.

```
system command
  ├─ open     ──→ browsers    (auto-follow; "open" consumes 1 token then jumps to "browsers")
  ├─ launch   ──→ browsers
  ├─ browsers
  │   ├─ firefox   → exec firefox
  │   ├─ chromium  → exec chromium
  │   └─ brave     → exec brave-browser
  ├─ clipboard
  │   ├─ copy      → exec wl-copy
  │   └─ paste     → exec wl-paste
  ├─ search for        → exec (text_capture) xdg-open '...?q={text}'
  ├─ type              → type (text_capture) {text}
  ├─ run in terminal   → shell_exec (text_capture) {text}
  └─ volume
       ├─ up    → pactl set-sink-volume @DEFAULT_SINK@ +5%
       ├─ down  → pactl set-sink-volume @DEFAULT_SINK@ -5%
       └─ mute  → pactl set-sink-mute @DEFAULT_SINK@ toggle
```

### Node types

| Type | Behaviour |
|---|---|
| `branch` | Routes speech to connected child nodes (no action on its own) |
| `exec` | Runs `command` via `subprocess.Popen(cmd, shell=True)` |
| `shell_exec` | Opens the configured terminal and runs `command` inside |
| `type` | Types `command` text via `ydotool type` (Wayland + X11) |

### Text capture

When `text_capture` is `true` on an action node, all remaining utterance tokens after the matching keyword are captured and substituted into `{text}`:

```json
"search for": {
  "type": "exec",
  "text_capture": true,
  "command": "xdg-open 'https://google.com/search?q={text}'"
}
```

Saying `"system command, search for cats online"` → captures `"cats online"` → runs `xdg-open 'https://google.com/search?q=cats%20online'`.

### Shared sub-graphs (auto-follow)

A branch node with exactly **one** connection leading to another branch is auto-followed — the intermediate label acts as an internal router and consumes no tokens. This lets you create shared sub-graphs:

```json
{
  "tree": {
    "root": ["open", "launch", "browsers"],
    "nodes": {
      "open":     { "type": "branch", "connections": ["browsers"] },
      "launch":   { "type": "branch", "connections": ["browsers"] },
      "browsers": { "type": "branch", "connections": ["firefox", "chromium", "brave"] },
      "firefox":  { "type": "exec",   "command": "firefox" },
      "chromium": { "type": "exec",   "command": "chromium" }
    }
  }
}
```

Both `"open firefox"` and `"launch firefox"` work. `"browsers firefox"` also works because "browsers" is a root connection.

### Prefixes & suffixes

Prefix/suffix words are detected **anywhere** in the utterance — they are not stripped, but their `prepend`/`append` string is applied to the matched command:

```json
{
  "prefixes": [
    { "words": ["administrator"], "prepend": "sudo" }
  ],
  "suffixes": [
    { "words": ["background"], "append": "&" }
  ]
}
```

- `"administrator open firefox"` → `sudo firefox` (prefix word anywhere)
- `"open firefox background"` → `firefox &` (suffix word anywhere)
- `"administrator open firefox background"` → `sudo firefox &`

### Immediate triggers

Whole-utterance matches that fire before any graph walk:

```json
{
  "immediate_triggers": [
    { "word": "stop listening", "type": "exec", "command": "pkill -STOP vox" }
  ]
}
```

## Configuration GUI

```
vox config
```

Opens a GTK window with:

- **Flowchart view** (left panel) — Cairo-rendered, left-to-right directed graph with:
  - Layered DAG layout (BFS layering from root)
  - Colour-coded node types (exec = green, type = blue, shell_exec = orange, branch = grey)
  - Type badges and command previews on each node
  - Shared nodes (multiple inbound edges) rendered once
  - **Pan** by click-dragging empty space
  - **Zoom** with mouse scroll wheel (0.2×–3.0×)
  - Curved edges showing connections between nodes
  - Click to select, right-click for context menu
- **Node editor** (right panel) — edit name, type, command, text-capture, and connection list
- **Root connections editor** — list of entrypoint node names at the bottom of the right panel
- **Toolbar** — Save, Settings (global config), New node, Validate, Help, Daemon toggle
- **Help buttons** (`?`) next to every setting explaining what it does
- **Right-click context menu** — Add node, Delete node

### Settings dialog

Four-tab modal dialog:

| Tab | Fields |
|---|---|
| **Wake Word** | Wake phrase + aliases (one per line) |
| **Terminal** | Terminal command for `shell_exec` actions |
| **Filters** | Inline-editable prefix and suffix rule tables |
| **Triggers** | Immediate trigger table (word, type, command) |

## Daemon overlay

```
vox daemon           # with transparent HUD overlay
vox daemon --headless  # no overlay
```

The overlay is a borderless, always-on-top, semi-transparent GTK window at the top of the screen. It shows:

- Partial transcriptions in real-time
- The final matched action on execution (with a 3-second timeout)

## Configuration file

Location: `<install_dir>/config.json` (this directory — symlinked to `~/.config/sdgos/vox`)

All fields:

| Key | Type | Default | Description |
|---|---|---|---|
| `wake_word` | string | `"system command"` | Wake phrase to trigger command processing |
| `wake_word_aliases` | array of strings | `[]` | Alternative wake phrases (e.g. `"cmd"`, `"computer"`) |
| `terminal` | string | `"ghostty"` | Terminal for `shell_exec` actions |
| `prefixes` | array of `AffixRule` | `[]` | Words that prepend to the matched command (detected anywhere) |
| `suffixes` | array of `AffixRule` | `[]` | Words that append to the matched command (detected anywhere) |
| `immediate_triggers` | array of `Trigger` | `[]` | Whole-utterance commands (no graph walk) |
| `tree.root` | array of strings | `[]` | Root entrypoint node names |
| `tree.nodes` | object | `{}` | Flat map of named `GraphNode` objects |

### GraphNode

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | string | `"branch"` | `"branch"`, `"exec"`, `"shell_exec"`, or `"type"` |
| `command` | string | `""` | Shell command (for action types); `{text}` is substituted |
| `text_capture` | bool | `false` | Capture remaining utterance tokens into `{text}` |
| `connections` | array of strings | `[]` | Names of downstream nodes (edges) |

### AffixRule

| Field | Type | Description |
|---|---|---|
| `words` | array of strings | Trigger words (matched case-insensitively anywhere in utterance) |
| `prepend` | string | String prepended to the final command (default `""`) |
| `append` | string | String appended to the final command (default `""`) |

### ImmediateTrigger

| Field | Type | Description |
|---|---|---|
| `word` | string | Exact utterance to match (after wake-word stripping) |
| `type` | string | One of `"exec"`, `"shell_exec"`, `"type"` |
| `command` | string | The command to run |

## Dependencies

| Component | Dependency | Arch (pacman) | Debian/Ubuntu (apt) |
|---|---|---|---|
| Python bindings | `PyGObject` | `python-gobject` | `python3-gi` |
| Audio capture | `GStreamer` | `gst-plugins-base`, `gst-plugins-good` | `gir1.2-gstreamer-1.0`, `gstreamer1.0-plugins-good` |
| Speech-to-text | whisper-server (whisper.cpp) | `whisper-cpp-vulkan` or `gst-plugin-whisper` | — |
| Keyboard typing | `ydotool` | `ydotool` | `ydotool` |
| Audio server | `pipewire` (or `pulseaudio`) | `pipewire` + `pipewire-pulse` | `pipewire` + `pipewire-pulse` |
| Wayland overlay | `gtk-layer-shell` | `gtk-layer-shell` | `gtk-layer-shell` |

A whisper model (`ggml-medium.en.bin`, ~1.5 GB) is auto-downloaded on first
`vox daemon` from Hugging Face (ggerganov/whisper.cpp).

## File structure

```
~/.config/sdgos/vox/
├── install.sh           # Setup script
├── config.json          # User command graph (flat node map)
├── pyproject.toml       # Python package config
├── models/              # Whisper model files (auto-downloaded)
└── vox/
    ├── __init__.py      # Package version
    ├── __main__.py      # Entry point for `python -m vox`
    ├── cli.py           # Argument parser (vox daemon / vox config)
    ├── daemon.py        # Main loop — wires capture → recognizer → matcher → executor → overlay
    ├── audio_capture.py # GStreamer mic capture (pipewire / pulseaudio)
    ├── whisper_recognizer.py # Whisper-server STT + wake word detection
├── recognizer.py       # Legacy Vosk recognizer (dead code, kept for reference)
    ├── command_tree.py  # Skip-based directed-graph matching engine with auto-follow
    ├── executor.py      # exec / shell_exec / type action dispatcher
    ├── overlay.py       # Transparent GTK HUD overlay
    ├── flowchart_view.py# Cairo-rendered interactive DAG (layered layout, pan/zoom)
    ├── config_ui.py     # GTK config editor (window, settings dialog, daemon launch)
    └── config_manager.py# JSON load / save with graph ↔ dataclass conversion
```
