# SDG-VOX Repository Analysis

## Overview

SDG-VOX is a wake-word activated, offline voice-to-commands daemon. Transcribes speech locally via whisper-server (whisper.cpp), walks a directed graph of command bindings, and ships a GTK configuration editor with a Cairo-rendered flowchart. Part of the SDG-OS ecosystem; installed via `sdgpkg install sdg-vox`.

---

## 1. Directory Structure

```
SDG-VOX/
├── install.sh                  # Root lifecycle: dependencies, deploy, symlink, model download
├── uninstall.sh                # Reverse of install
├── update.sh                   # Redeploy files, skip user config
├── README.md                   # Stub — "# SDG-VOX" only (2 lines)
├── migration-plan.md           # Outdated plan for old → sdgos path migration
├── TESTCOMPLETE.md             # Empty (0 bytes)
├── .gitignore                  # Ignores models/, *.bin, *.zip, __pycache__, *.pyc
├── config/
│   └── SDG-VOX/
│       └── config.json         # 529-line command graph (trigger-on-node format)
├── docs/
│   ├── CONCEPT.md              # Original concept (Vosk era)
│   ├── CONCEPT-updated.md      # Updated concept (whisper-server era)
│   ├── README.md               # Old README (Vosk, shell_exec, etc.)
│   └── README-updated.md       # Updated README (whisper-server, gtk-layer-shell)
├── local/
│   └── SDG-VOX/
│       ├── vox.sh              # CLI wrapper — adds vox/ to sys.path
│       ├── pyproject.toml      # Package metadata (non-standard build backend)
│       └── vox/                # Python package (14 files, ~3,971 lines total)
│           ├── __init__.py
│           ├── __main__.py
│           ├── cli.py
│           ├── config_manager.py
│           ├── models.py
│           ├── command_tree.py
│           ├── audio_capture.py
│           ├── recognizer.py           # ⚠ DEAD CODE — Vosk, not imported
│           ├── whisper_recognizer.py   # Active — whisper.cpp STT
│           ├── daemon.py
│           ├── executor.py
│           ├── overlay.py
│           ├── flowchart_view.py
│           └── config_ui.py
├── tips/
│   └── placeholder            # Empty file (0 bytes)
└── other/
    └── vox-config.desktop      # Desktop entry → Exec=sdgvox config
```

**Total: ~4,000+ lines across 24 files (excluding `.git`).**

---

## 2. Function — File-by-File

### 2.1 Root Lifecycle Scripts

#### `install.sh` (115 lines)
- **Function**: Full deployment for sdgpkg-managed install.
- **Flow**: Install deps via `unipkg` → copy config → copy Python package + wrapper → copy docs/tips → install desktop file → create `/usr/bin/sdgvox` symlink → download Whisper model (~1.5 GB ggml-medium.en.bin).
- **Key paths** (all hardcoded `/home/$(whoami)/`):
  - Source working dir: `/home/$(whoami)/.cache/SDG-PKG/sdg-vox` (line 41)
  - Config: `/home/$(whoami)/.config/SDG-VOX/config.json` (line 50)
  - Local: `/home/$(whoami)/.local/SDG-VOX/vox/` (line 60), `vox.sh` (line 61), `pyproject.toml` (line 62)
  - Docs: `/home/$(whoami)/.local/docs/SDG-VOX/` (line 72)
  - Tips: `/home/$(whoami)/.local/tips/SDG-VOX/` (line 73)
  - Symlink: `/usr/bin/sdgvox` → `~/.local/SDG-VOX/vox.sh` (line 88)
  - Models: `/home/$(whoami)/.local/SDG-VOX/models/` (line 96)

#### `uninstall.sh` (22 lines)
- **Function**: Removes everything install.sh created.
- **Removes**: `~/.local/SDG-VOX`, `~/.config/SDG-VOX`, `~/.local/docs/SDG-VOX`, `~/.local/tips/SDG-VOX`, desktop entry, `/usr/bin/sdgvox` symlink.

#### `update.sh` (35 lines)
- **Function**: Redeploys local files, docs, tips, desktop file from cache. Skips config.
- **Note**: Also hardcoded paths throughout.

### 2.2 Python Package (`vox/`)

#### `cli.py` (38 lines)
- **Function**: Argument parser — subcommands `daemon` (with `--headless`) and `config`.
- **Config path**: Uses `default_config_path()` from config_manager.
- **Dispatch**: `daemon` → `run_daemon()`; `config` → `run_config_ui()`.

#### `config_manager.py` (216 lines)
- **Constants** (lines 8-9):
  - `LOCAL_DIR = Path.home() / ".local" / "SDG-VOX"` — where Python package + models live
  - `CONFIG_DIR = Path.home() / ".config" / "SDG-VOX"` — where `config.json` lives
- **Functions**: `default_config_path()`, `models_dir()`, `load_config()`, `save_config()`, `_parse_node()`, `_serialize_node()`, `_parse_affix_rules()`, `_parse_triggers()`, `_migrate_old_format()`, `_parse_config()`, `_serialize_config()`.
- **Migration** (lines 92-175): Detects old-format config (edge-based connections, pre-trigger format) and converts to trigger-on-node format.

#### `models.py` (68 lines)
- **Dataclasses**: `GraphNode` (type, trigger, wake_word, aliases, command, text_capture, connections, pos_x/y), `ImmediateTrigger` (word, type, command), `AffixRule` (words, prepend, append), `Config` (terminal, exec_prefix, prefixes, suffixes, immediate_triggers, tree).

#### `command_tree.py` (226 lines)
- **Function**: Skip-based directed-graph matching engine.
- **Key functions**: `strip_punctuation()`, `strip_wake_word()`, `match()`, `trace_path()`, `_walk_graph()`.
- **Algorithm**: Multi-word triggers matched greedily (longest-first). Non-matching tokens silently skipped. Immediate triggers scanned anywhere in utterance. Auto-follow for branch nodes with single connection.

#### `audio_capture.py` (100 lines)
- **Function**: GStreamer mic capture.
- **Pipeline**: `pipewiresrc` → `pulsesrc` fallback → `audioconvert` → `audioresample` → `capsfilter` (16 kHz S16LE mono) → `appsink`.
- **Callback**: Raw PCM bytes to `on_audio`.

#### `recognizer.py` (126 lines) ⚠ DEAD CODE
- **Function**: Vosk-based STT with wake-word detection.
- **Import**: `from vosk import Model, KaldiRecognizer` (line 16).
- **Status**: NOT imported by any other module. `daemon.py` imports `WhisperRecognizer` from `whisper_recognizer.py`. The docs/README-updated.md line 173 explicitly marks it as "Legacy Vosk recognizer (dead code, kept for reference)."

#### `whisper_recognizer.py` (314 lines)
- **Function**: Whisper.cpp STT via whisper-server subprocess with VAD.
- **Key**: Launches `whisper-server` on port 18081, sends audio via HTTP multipart POST to `/inference`. VAD with RMS threshold, silence detection, partial transcription every 0.3s during speech. Wake state with 3-second timeout.
- **Methods**: `start()`, `feed_audio()`, `_process_vad()`, `_finalize_segment()`, `_transcribe()`, `_check_wake_word()`, `health_check()`, `restart()`, `stop()`.

#### `daemon.py` (166 lines)
- **Function**: Main loop — wires `AudioCapture` → `WhisperRecognizer` → `match()` → `execute()` → `Overlay`.
- **Features**: Config hot-reload (1-second poll), whisper-server health watchdog (30s), SIGINT/SIGTERM graceful shutdown.
- **Imports recognizer**: `from .whisper_recognizer import WhisperRecognizer` (line 18).

#### `executor.py` (60 lines)
- **Function**: Dispatches matched actions: `exec` (subprocess.Popen shell=True), `shell_exec` (terminal + bash -c), `type` (ydotool type).
- **Text substitution**: `{text}` → plain, `{url_text}` → percent-encoded.
- **Prefix/suffix**: Prepended/appended after substitution.

#### `overlay.py` (107 lines)
- **Function**: Transparent GTK HUD using `GtkLayerShell` OVERLAY layer.
- **Features**: Auto-hide timeout, centered text, size auto-calculated from text length.

#### `flowchart_view.py` (809 lines)
- **Function**: Cairo-rendered interactive DAG editor. draw.io-style.
- **Interactions**: Drag nodes, drag from right port to connect, pan empty space, scroll zoom, right-click context menu.
- **Layout**: BFS layered auto-layout with barycenter ordering for sort within layers.
- **Drawing**: Rounded rect nodes with colour-coded types, bezier edges with arrowheads, port circles, type badges.

#### `config_ui.py` (1229 lines)
- **Function**: GTK config editor with flowchart view + property panel + toolbar.
- **Features**:
  - Toolbar: Save, Settings, New Node, Validate, Auto-layout, Test, Help, Daemon toggle
  - Settings dialog: 4 tabs (Terminal, Filters, Triggers) — NOTE: no Wake Word tab despite HELP_TEXTS listing one
  - Node editor: Trigger, Name, Type combo, Wake word, Aliases (root only), Command/S string
  - Copy/paste nodes
  - String tester dialog with `trace_path` highlighting
  - Daemon launch/stop via `vox daemon` / `pkill whisper-server`
- **Node type logic**: `root` gets wake word + aliases; `branch` gets trigger; `exec/shell_exec/type` gets name + command.

### 2.3 Configuration

#### `config/SDG-VOX/config.json` (529 lines)
- **Format**: trigger-on-node (flat dict of named nodes).
- **Nodes**: 32 nodes — 1 root ("system command" with aliases: cmd, computer, i cast, highcast), 15 branches, 9 exec, 2 shell_exec, 1 type, 4 unnamed.
- **Commands**: firefox/chromium launch/quit, wl-copy/wl-paste, pactl volume control, ghostty, unipkg, cachy-update, ydotool type.
- **exec_prefix**: `"mmsg dispatch spawn_shell,"` — dependency on mangoWM.

### 2.4 Documentation Files

#### `docs/README.md` — OLD (Vosk era)
- Mentions Vosk STT (line 7, 28, 233, 244, 251)
- References pip-installable vosk (line 17)
- File structure lists recognizer.py without "dead code" annotation

#### `docs/README-updated.md` — CURRENT (whisper-server era)
- Mentions whisper-server STT (line 8, 28, 150, 172)
- Explicitly marks recognizer.py as "dead code, kept for reference" (line 173)
- Adds gtk-layer-shell dependency (line 153)
- File structure lists whisper_recognizer.py as main, recognizer.py as legacy

#### `docs/CONCEPT.md` — OLD
- No whisper-server mention
- Vosk-era design doc

#### `docs/CONCEPT-updated.md` — CURRENT
- Mentions "whisper-server (whisper.cpp) for offline speech-to-text" (line 19-20)

---

## 3. Dependencies

### Runtime Python (3.10+)
| Module | Imports |
|--------|---------|
| `audio_capture.py` | `gi.repository.Gst, GLib` |
| `cli.py` | `argparse`, `pathlib` |
| `command_tree.py` | stdlib only |
| `config_manager.py` | `json`, `pathlib` |
| `config_ui.py` | `gi.repository.Gtk, Gdk, GLib, Pango` |
| `daemon.py` | `gi.repository.Gst, GLib`, `logging`, `signal`, `pathlib` |
| `executor.py` | `subprocess`, `shlex`, `shutil`, `urllib.parse` |
| `flowchart_view.py` | `gi.repository.Gtk, Gdk, PangoCairo`, `cairo`, `math`, `collections`, `enum` |
| `models.py` | `dataclasses`, `typing` |
| `overlay.py` | `gi.repository.Gtk, Gdk, GLib, GtkLayerShell` |
| `recognizer.py` ⚠ DEAD | `vosk`, `json`, `urllib`, `zipfile` |
| `whisper_recognizer.py` | `gi.repository.GLib`, `socket`, `subprocess`, `json`, `tempfile`, `wave`, `urllib` |

### System Packages (installed by install.sh via unipkg)
- `python3-gobject` — GTK bindings
- `python3-cairo` — Cairo bindings
- `gst-plugins-base`, `gst-plugins-good` — GStreamer audio
- `gtk-layer-shell` — Wayland overlay
- `pipewire`, `pipewire-pulse` — Audio server
- `ydotool` — Keyboard typing
- whisper-server (whisper.cpp) — STT engine (not installed by install.sh; expected manually)
- Model: `ggml-medium.en.bin` (~1.5 GB, auto-downloaded from HuggingFace)

### Python Package Metadata (`pyproject.toml`)
- Uses `setuptools.backends._legacy:_Backend` (non-standard, deprecated in favour of `setuptools.build_meta`).
- Entry point: `vox = "vox.cli:main"` — but the actual runtime uses `vox.sh` wrapper + `/usr/bin/sdgvox` symlink, not pip-installed.

---

## 4. Dependents (Cross-Module References)

### SDG-OS-META
- `install.sh:13` — `sdgpkg install sdg-vox`

### SDG-REPO / SDG-REPO-OLD
- `SDGOS.repo:7` — Registry entry: `sdg-vox|https://git.sdgcloud.nl/SDGDen/SDG-VOX`

### SDG-DOCS
| File | Line | Reference |
|------|------|-----------|
| `03-automation-integration.md` | 14, 23, 55 | `~/.config/SDG-VOX/config.json`, MODULE="SDG-VOX", `sdgpkg install sdg-vox` |
| `02-tips-and-docs-api.md` | 68 | Reads `~/.config/SDG-VOX/config.json` |
| `01-path-conventions.md` | 51, 62 | `~/.config/SDG-VOX/config.json`, `sdgvox` command |
| `04-sdgpkg-reference.md` | 29-77 | Full sdg-vox install/update lifecycle |
| `01-architecture-overview.md` | 14, 25, 31 | Application listing, repo URL, install flow |
| `02-configuring-modules.md` | 14, 44 | Path docs, `sdgvox-config` |
| `01-module-layout.md` | 36 | Notes SDG-VOX as self-contained |
| `04-common-workflows.md` | 9, 44 | Install command, config path |

### GLOBAL-MIGRATION-GUIDE.md
- Lines 25, 47, 69, 303-308: Documents migration from `~/.config/sdgos/vox/` to `~/.config/SDG-VOX/`.

---

## 5. Use / Configuration

### Installation Paths (hardcoded in shell scripts)
```
~/.cache/SDG-PKG/sdg-vox/           # Source (sdgpkg clone cache)
~/.config/SDG-VOX/config.json       # User command graph (preserved on update)
~/.local/SDG-VOX/vox/               # Python package
~/.local/SDG-VOX/vox.sh             # CLI wrapper (symlinked to /usr/bin/sdgvox)
~/.local/SDG-VOX/pyproject.toml     # Package metadata (reference only)
~/.local/SDG-VOX/models/            # Whisper model files
~/.local/docs/SDG-VOX/              # Documentation
~/.local/tips/SDG-VOX/              # Tips
~/.local/share/applications/vox-config.desktop  # Desktop entry
```

### CLI Usage
```sh
sdgvox daemon          # Start daemon with overlay
sdgvox daemon --headless  # No overlay
sdgvox config          # Open GTK config editor
```

### Config Format (`config.json`)
- **Root node**: `type: "root"` with `wake_word` + `aliases`.
- **Branch nodes**: `type: "branch"` with `trigger` (spoken keyword) + `connections`.
- **Action nodes**: `type: "exec"|"shell_exec"|"type"` with `command` + optional `text_capture`.
- **Prefixes/Suffixes**: Words detected anywhere in utterance; `prepend`/`append` applied to final command.
- **Immediate triggers**: Whole-utterance matches that fire before graph walk.

### Node Types
| Type | Behaviour |
|------|-----------|
| `root` | Defines wake word + aliases + root connections |
| `branch` | Routes to child nodes via trigger matching |
| `exec` | Runs `command` via `subprocess.Popen(cmd, shell=True)` |
| `shell_exec` | Opens configured terminal and runs command |
| `type` | Types text via `ydotool type` |

---

## 6. ⚠ Critical Issues

### 6.1 `recognizer.py` — Dead Code
**File**: `local/SDG-VOX/vox/recognizer.py` (126 lines)
- Imports `vosk` (line 16) — Vosk is NOT a dependency listed in install.sh or used at runtime.
- NOT imported by any other module. `daemon.py` imports `WhisperRecognizer` from `whisper_recognizer.py`.
- `docs/README-updated.md:173` explicitly flags it as "Legacy Vosk recognizer (dead code, kept for reference)."
- **Action**: Can be safely removed. If kept, annotate with `# DEPRECATED — Vosk, not used` at module level.

### 6.2 Dual Stale/Current Doc Files
**Directory**: `docs/`
- `README.md` and `CONCEPT.md` are OLD (Vosk era). `README-updated.md` and `CONCEPT-updated.md` are CURRENT (whisper-server era).
- The stale docs still mention Vosk installation (`sudo pacman -S vosk-api python-vosk`) and reference the old recognizer.
- `README.md` at repo root is a 2-line stub — useless for users.
- **Action**: Purge stale doc files; rename `*-updated.md` → `*.md`; fill root README.md.

### 6.3 `migration-plan.md` Describes Non-Existent Code State
**File**: `migration-plan.md` (102 lines)
Planned an `sdgos/` path layout that was never implemented. Multiple inaccuracies:

| Claim in migration-plan.md | Actual code |
|---------------------------|-------------|
| Section 3.1: vox.sh line 7 uses `Path.home() / '.config' / 'sdgos' / 'vox'` | vox.sh line 7 uses `Path.home() / '.local' / 'SDG-VOX'` |
| Section 3.2: config_manager.py line 8 `INSTALL_DIR = Path.home() / ".config" / "sdgos" / "vox"` | config_manager.py lines 8-9: `LOCAL_DIR = ... / ".local" / "SDG-VOX"`, `CONFIG_DIR = ... / ".config" / "SDG-VOX"` |
| Section 3.4: "No hardcoded /home/$(whoami)/ found — good" | All shell scripts (install.sh, uninstall.sh, update.sh) hardcode `/home/$(whoami)/` |
| Section 4: Deploy to `~/.config/sdgos/vox/` | Actual deploy: `~/.config/SDG-VOX/` and `~/.local/SDG-VOX/` |
| Section 5: `local/SDG-VOX/models/` contains model files | Models are gitignored, not in repo; downloaded at install time |
| Section 5: Mentions `vosk-model-*` files | Currently Whisper-only (Vosk is dead code) |
| Section 8: `cache/` is empty — remove | Directory `cache/` does not exist |
| Section 9: `__pycache__/` in repo | `.gitignore` already covers it (line 7) |

- **Action**: Rewrite or delete migration-plan.md. It misleads anyone reading it as a source of truth.

### 6.4 Hardcoded `/home/$(whoami)/` in Shell Scripts
All three scripts use `/home/$(whoami)/` instead of `$HOME`:

| Script | Lines with hardcoded paths |
|--------|---------------------------|
| `install.sh` | 41, 49, 50, 59, 60, 61, 62, 71, 72, 73, 80, 88, 96, 97, 100, 102, 104, 107, 108 |
| `uninstall.sh` | 9, 12, 15, 16, 19, 22 |
| `update.sh` | 14, 15, 18, 23, 24, 25, 26, 27, 32 |

- **Problem**: Breaks on systems where `$HOME` != `/home/$USER` (e.g., NixOS, macOS, custom mounts).
- **Fix**: Replace with `$HOME` or `~` throughout.

### 6.5 Missing `detect.sh`
- `migration-plan.md:12` lists `detect.sh` as a planned root lifecycle script for health/dependency checks.
- **Status**: Not created. No equivalent file exists.

### 6.6 `pyproject.toml` Non-Standard Build Backend
**File**: `local/SDG-VOX/pyproject.toml:13-14`
```toml
requires = ["setuptools>=64"]
build-backend = "setuptools.backends._legacy:_Backend"
```
- `_legacy:_Backend` is a private/internal setuptools symbol, not a public API. Use `setuptools.build_meta` instead. However, this is irrelevant in practice since the package is never pip-installed (vox.sh manages sys.path manually).

### 6.7 `vox.sh` Hardcoded Python Path
**File**: `local/SDG-VOX/vox.sh:4`
```bash
exec /usr/bin/python3 -c "..."
```
- Uses absolute `/usr/bin/python3`. Should use `exec python3` or `/usr/bin/env python3` for portability.

### 6.8 Config Editor Settings Dialog Missing Wake Word Tab
**File**: `config_ui.py`
- The `HELP_TEXTS` dict (lines 25-65) lists a "Wake Word" tab but `SettingsDialog.__init__` (lines 68-202) only creates three tabs: Terminal, Filters, Triggers.
- Wake word/aliases are edited per-root-node in the main editor panel, not in settings.

### 6.9 `config.json` Default Uses `ghostty` Terminal
- `config.json` line 2: `"terminal": "ghostty -e"` — ghostty is a niche terminal. The `models.py` default (line 63) also defaults to `"ghostty -e"`. Most users will need to change this.

### 6.10 `tips/` Directory Contains Only Empty Placeholder
- `tips/placeholder` (0 bytes) — no actual tips content.

### 6.11 `TESTCOMPLETE.md` Is Empty
- 0-byte file. No test results documented.

---

## 7. Minor Observations

- **Config hot-reload**: daemon.py lines 99-116 — polls `config.json` mtime every second and reloads. Updates `recognizer.roots` dynamically.
- **Daemon watchdog**: daemon.py lines 136-145 — checks whisper-server health every 30s, auto-restarts on failure.
- **Wake state**: whisper_recognizer.py lines 260-274 — after hearing wake word alone, enters a 3-second "wake state" where subsequent utterances are forwarded without requiring the wake word again.
- **Auto-follow**: command_tree.py — branch nodes with single connection to another branch are silently traversed, keyword consumes no tokens.
- **Immediate triggers**: `{ "word": "cancel", "type": "exec", "command": "true" }` is the only trigger in default config.
- **Migration from old format**: config_manager.py `_migrate_old_format` (lines 92-175) handles two obsolete config formats.
- **Cross-module dep on mangoWM**: `exec_prefix: "mmsg dispatch spawn_shell,"` — the config assumes mangoWM's `mmsg` is available.

---

## 8. Summary of Recommended Actions

| Priority | Issue | Suggested Action |
|----------|-------|-----------------|
| **HIGH** | `recognizer.py` dead code | Remove or mark unambiguously |
| **HIGH** | `migration-plan.md` inaccurate | Rewrite or delete |
| **HIGH** | Dual stale/current doc files | Purge stale, rename current → canonical |
| **HIGH** | Hardcoded `/home/$(whoami)/` | Replace with `$HOME` in all shell scripts |
| **HIGH** | Missing `detect.sh` | Create dependency detection script |
| **MEDIUM** | Root `README.md` is a stub | Write proper README |
| **MEDIUM** | `vox.sh` hardcoded `/usr/bin/python3` | Use `python3` (via PATH) |
| **LOW** | `pyproject.toml` non-standard backend | Fix to `setuptools.build_meta` |
| **LOW** | `tips/` empty | Add tips content |
| **LOW** | `TESTCOMPLETE.md` empty | Populate or remove |
