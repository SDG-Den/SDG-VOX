# Integration

## Headless mode

Run the daemon without the HUD overlay:

```bash
sdgvox daemon --headless
# or
vox daemon --headless
```

Useful for:
- Servers or machines without a display
- Running as a systemd user service
- Minimal-resource environments

Without `--headless`, a transparent GTK overlay window appears at the top of the screen showing partial transcriptions and matched actions.

## HUD overlay

The overlay is a GTK window in the compositor's `OVERLAY` layer (via `gtk-layer-shell`):

- Always-on-top, never tiled or obscured
- Semi-transparent, borderless
- Anchored to the top of the screen with a 12px margin
- Maximum 60 character width, auto-sizing
- Shows partial transcriptions in real-time
- Shows the matched action on execution (with 3-second auto-hide)
- Hidden automatically after timeout, or immediately on "cancel"

## Configuration file format

Location: `~/.config/SDG-VOX/config.json`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `terminal` | string | `"ghostty -e"` | Terminal command for `shell_exec` actions |
| `exec_prefix` | string | `""` | Prefix prepended to all exec commands |
| `prefixes` | array | `[]` | `AffixRule` objects: words detected anywhere that prepend to command |
| `suffixes` | array | `[]` | `AffixRule` objects: words detected anywhere that append to command |
| `immediate_triggers` | array | `[]` | `ImmediateTrigger` objects: whole-utterance matches |
| `tree.nodes` | object | `{}` | Flat map of named `GraphNode` objects |

### GraphNode

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `type` | string | `"branch"` | `"branch"`, `"exec"`, `"shell_exec"`, `"type"` |
| `trigger` | string | `""` | Spoken word(s) to reach this node |
| `command` | string | `""` | Shell command (action types only); `{text}` substituted |
| `text_capture` | bool | `false` | Capture remaining utterance tokens into `{text}` |
| `connections` | array of strings | `[]` | Names of downstream nodes |
| `pos_x` | float or null | `null` | Canvas X position |
| `pos_y` | float or null | `null` | Canvas Y position |

Root nodes also have:
- `wake_word` — the wake phrase
- `aliases` — alternative wake phrases

### AffixRule

| Field | Type | Description |
|-------|------|-------------|
| `words` | array of strings | Trigger words (case-insensitive, anywhere in utterance) |
| `prepend` | string | Prepended to final command |
| `append` | string | Appended to final command |

### ImmediateTrigger

| Field | Type | Description |
|-------|------|-------------|
| `word` | string | Exact utterance to match (after wake-word stripping) |
| `type` | string | `"exec"`, `"shell_exec"`, or `"type"` |
| `command` | string | The command to run |

## Desktop entry

Installed to `~/.local/share/applications/vox-config.desktop`. Launches the config GUI from your application menu.

## Keybinds

SDG-VOX does not include a built-in keybinding system. Integrate with your window manager or DE:

```ini
# Example Hyprland bind
bind = SUPER+V, exec, sdgvox daemon --headless
```

## SDG-MANGO-CORE integration

SDG-MANGO-CORE can trigger `sdgvox` daemon start/stop. Suggested bindings:

| Action | Command |
|--------|---------|
| Start daemon | `sdgvox daemon --headless` |
| Open config | `sdgvox config` |
| Toggle listening | The `cancel` immediate trigger aborts current command |

## File structure

```
~/.config/SDG-VOX/
└── config.json              # User command graph

~/.local/SDG-VOX/
├── vox.sh                   # CLI wrapper
├── pyproject.toml
└── vox/                     # Python package
    ├── __init__.py
    ├── __main__.py
    ├── cli.py
    ├── daemon.py
    ├── audio_capture.py
    ├── whisper_recognizer.py
    ├── command_tree.py
    ├── executor.py
    ├── overlay.py
    ├── config_manager.py
    ├── config_ui.py
    ├── flowchart_view.py
    └── models.py

~/.cache/SDG-VOX/models/
└── ggml-medium.en.bin       # Whisper model (~1.5 GB)

~/.local/docs/SDG-VOX/      # Documentation
~/.local/tips/SDG-VOX/      # Tips
```
