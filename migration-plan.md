# SDG-VOX Migration Plan

## 1. Implement Root-Level Lifecycle Scripts

All four root-level lifecycle scripts are **empty stubs** — must be implemented:

| Script | Purpose |
|--------|---------|
| `install.sh` | Deploy `local/SDG-VOX/` → `~/.local/share/sdgos/vox/` or `~/.config/sdgos/vox/`, install Python package, create `/usr/local/bin/vox` symlink, deploy `config/SDG-VOX/config.json` → `~/.config/sdgos/vox/config.json`, install desktop file, download ML model |
| `uninstall.sh` | Remove all vox files, remove symlink, remove desktop file, remove models |
| `update.sh` | Re-deploy scripts, re-install Python package |
| `detect.sh` | Check for Python3, GTK3, GStreamer, PipeWire |

## 2. Note: Internal Install Script
`local/install.sh` is a **comprehensive install script** (280 lines) that handles:
- Python detection
- System package detection (pacman/apt/dnf)
- System dependency installation
- Desktop file deployment
- ML model download (Whisper, ~1.5GB)
- Verification of all dependencies

**Migration decision:** Either:
1. **From-scratch**: Move logic from `local/install.sh` into the root `install.sh` and reference `local/install.sh` as a sub-script.
2. **Wrapper**: Have root `install.sh` simply call `local/install.sh` (after copying files to the right place).

Recommend option 2 for simplicity, but the root lifecycle scripts still need to handle the **deployment** of files to `~/.config/sdgos/vox/` before running `local/install.sh`.

## 3. Path Audit

### 3.1 `local/SDG-VOX/vox.sh` (CLI wrapper)
- Line 7: `Path.home() / '.config' / 'sdgos' / 'vox'` — Python path to the vox package directory. This is where the Python code should be deployed.
- Line 4: `exec /usr/bin/python3 -c "..."` — uses hardcoded `/usr/bin/python3`.

### 3.2 `local/SDG-VOX/vox/config_manager.py`
- Line 8: `INSTALL_DIR = Path.home() / ".config" / "sdgos" / "vox"` — config root.
- Line 12: `return INSTALL_DIR / "config.json"` — config file path.
- Line 16: `d = INSTALL_DIR / "models"` — model directory.

### 3.3 `local/install.sh`
- Line 148: `$SCRIPT_DIR/vox-config.desktop` — uses the repo-relative path during dev.
- Line 158: `models_dir="${XDG_CONFIG_HOME:-$HOME/.config}/sdgos/vox/models"` — model install path.

### 3.4 No hardcoded `/home/$(whoami)/` found — good.

## 4. Deploy Path Map

| Source | Destination | Notes |
|--------|-------------|-------|
| `local/SDG-VOX/vox/` (Python package) | `~/.config/sdgos/vox/vox/` | Python package directory |
| `local/SDG-VOX/vox.sh` | `~/.config/sdgos/vox/vox.sh` (or `/usr/local/bin/vox`) | CLI wrapper |
| `local/SDG-VOX/pyproject.toml` | `~/.config/sdgos/vox/pyproject.toml` | For pip install |
| `local/SDG-VOX/models/*` | `~/.config/sdgos/vox/models/` | ML models (large files) |
| `config/SDG-VOX/config.json` | `~/.config/sdgos/vox/config.json` | User config |
| `other/vox-config.desktop` | `~/.local/share/applications/vox-config.desktop` | Desktop entry |
| `docs/README.md` etc. | — | Already in repo docs |

## 5. Model Files
- `local/SDG-VOX/models/` contains large ML model files:
  - `ggml-medium.en.bin` (~1.5GB)
  - `ggml-base.en.bin` (~150MB)
  - `vosk-model-en-us-0.22-lgraph/` (directory, ~50MB)
  - `vosk-model-small-en-us-0.15/` (directory, ~40MB)
  - `vosk-model-en-us-0.22-lgraph.zip`
- **Consideration:** These are large binaries. Options:
  1. Keep in Git (bloats repo, needs LFS).
  2. Download at install time (already supported by `local/install.sh` lines 155-187).
  3. Keep only the small models, download large ones on demand.
- Recommend option 2: the install script already handles this. Add `.gitignore` for model files.

## 6. Cross-module References

### 6.1 Binds from SDG-MANGO-CORE
- `binds.conf` line 79: `SUPER+SHIFT+M` → `~/.config/sdgos/tuis/documentation.sh` (SDG-UTIL-SCRIPTS, not vox directly).

### 6.2 VOX is self-contained
- VOX doesn't reference other SDG modules in its code — it only depends on system packages.
- The config references `mmsg dispatch spawn_shell,` as `exec_prefix` — depends on mangoWM being installed.

## 7. Modular Tips/Help Contribution

### 7.1 Tips
- Add tips about voice commands, available wake words, configuration UI.
- Create `tips/` directory with entries.

### 7.2 Help system
- Contribute a help topic about vox usage and command tree editing.
- Document the available voice commands and command tree structure.

## 8. Empty Directory Cleanup

| Directory | Status |
|-----------|--------|
| `cache/` | Empty — remove |
| `tips/` | Empty — add tips or remove |

## 9. `.pyc` Cache Files
- `local/SDG-VOX/vox/__pycache__/` contains compiled Python bytecode files.
- Add to `.gitignore`: `**/__pycache__/`.

## 10. VOX Config Desktop Entry
- `other/vox-config.desktop` — verify it correctly references the vox installation path after deployment.
