# Developer Guide

## Repository structure

```
SDG-VOX/
├── config/
│   └── SDG-VOX/
│       └── config.json          # Default command graph
├── docs/SDG-VOX/                 # Documentation (deployed to ~/.local/docs/)
├── tips/SDG-VOX/                 # Tips (deployed to ~/.local/tips/)
├── local/SDG-VOX/
│   ├── vox.sh                    # CLI wrapper shell script
│   ├── pyproject.toml            # Python package metadata
│   ├── models/                   # Whisper model files (~1.5 GB, gitignored)
│   └── vox/                      # Python source package
│       ├── __init__.py           # Version: 0.1.0
│       ├── __main__.py           # python -m vox entry point
│       ├── cli.py                # Argument parser
│       ├── daemon.py             # Main loop
│       ├── audio_capture.py      # GStreamer mic capture
│       ├── whisper_recognizer.py # whisper-server STT + VAD
│       ├── command_tree.py       # Graph matching engine
│       ├── executor.py           # Action dispatcher
│       ├── overlay.py            # HUD overlay (gtk-layer-shell)
│       ├── config_manager.py     # JSON load/save/migration
│       ├── config_ui.py          # GTK config editor
│       ├── flowchart_view.py     # Cairo graph renderer
│       └── models.py             # Dataclasses
├── install.sh
├── update.sh
├── uninstall.sh
├── other/
│   └── vox-config.desktop        # Desktop entry
├── README.md                     # Project stub
├── info.md                       # SDG-OS package metadata
├── CHANGELOG.md
└── analysis.md                   # Technical analysis
```

## Building from source

```bash
# Clone or copy, then install:
./install.sh
```

This copies files to `~/.local/`, handles symlinks, and downloads the Whisper model.

## Adding commands to the graph

Commands are defined in `config/SDG-VOX/config.json` as a flat map of named nodes:

```json
"my_command": {
  "type": "exec",
  "trigger": "my command",
  "command": "echo hello",
  "text_capture": false,
  "connections": []
}
```

Add the new node name to an existing node's `connections` array to make it reachable.

### Node types

| Type | When to use |
|------|-------------|
| `branch` | Routing/menu node — connects to child nodes, no action |
| `exec` | Run a command in the background |
| `shell_exec` | Run a command in a visible terminal window |
| `type` | Type text via ydotool |

### Text capture

Set `text_capture: true` on any action node to capture the remaining utterance tokens. Use `{text}` (plain) or `{url_text}` (URL-encoded) in the command template.

### Shared sub-graphs

Create a branch node with trigger text and one connection, then point multiple parent nodes at it. The intermediate node is auto-followed (no token consumed).

## Code conventions

- Python 3.10+ with `from __future__ import annotations`
- GTK 3 via `PyGObject` (`gi.repository`)
- Type hints on all public function signatures
- Dataclasses for data models (`models.py`)
- GLib main loop for async (no asyncio)
- Logging via the `vox` logger

## Extending

### Adding a new node type

1. Add the type string to `ACTION_TYPES` in `command_tree.py` if it's an action type
2. Handle the new type in `executor.py:execute()`
3. Add the type to the `type` field enum in `config_ui.py` (node editor dropdown)
4. Add color mapping in `flowchart_view.py`

### Adding a new config field

1. Add field to the `Config` dataclass in `models.py`
2. Add migration logic in `config_manager.py` if needed
3. Add UI in `config_ui.py` Settings dialog
4. Add help text in the `_help_texts` dictionary in `config_ui.py`

## Testing

There is no dedicated test framework yet. Manual testing:

- Run `vox daemon --headless` (no overlay) and watch logs
- Use `vox config` to open the GUI and validate the graph
- Check `sdgvox daemon` output in terminal for transcription logs
