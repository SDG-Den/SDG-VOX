# SDG-VOX Documentation Plan

## Current Status
Four doc files exist — but two have outdated `-updated.md` duplicates that need merging. Zero tips exist.

## Source-Verified Inventory
**Components:**
- Voice control system using whisper-server (NOT Vosk — the original README.md is outdated)
- Architecture: daemon mode (always-listening) + config GUI mode
- Wake word detection with 3-second WAKE_TIMEOUT
- Command graph with skip-based matching algorithm
- Node types: branch, exec, shell_exec, type
- Prefix/suffix modifiers: sudo (`administrator`), setsid (`silent`, `background`), & (`detach`)
- GTK config GUI with Cairo flowchart view, node editor, settings dialog
- Headless mode (`--headless` flag)
- Dependencies: ghostty (not gnome-terminal), gtk-layer-shell, whistle-server model (ggml-medium.en.bin, ~1.5GB)

### Outdated Files to Merge
| Outdated File | New Content to Merge |
|--------------|---------------------|
| `README.md` (Vosk, gnome-terminal) | `README-updated.md` (whisper-server, ghostty, gtk-layer-shell) |
| `CONCEPT.md` (old notes) | `CONCEPT-updated.md` (updated concept with whisper-server) |

## Docs System (`docs/`)
**Deploy location**: `~/.local/docs/SDG-VOX/`

### Planned Doc Topics
| # | Topic | Description | Priority |
|---|-------|-------------|----------|
| 1 | Voice Control Setup | Installation, dependencies (whisper model ~1.5GB), mic config, first run | High |
| 2 | Commands Reference | Command graph, skip-based matching, node types, shared sub-graphs, prefixes/suffixes | High |
| 3 | Wake Word Configuration | Wake words (from config.json:127-132), 3-second timeout, hotword sensitivity | High |
| 4 | Integration | config GUI, daemon overlay, headless mode, config.json format, keybinds | Medium |

### Existing Content
| File | Notes |
|------|-------|
| `README.md` | 258 lines — thorough but references Vosk (DEPRECATED) |
| `README-updated.md` | 180 lines — updated to whisper-server. Merge into README.md |
| `CONCEPT.md` | 15 lines — early concept notes |
| `CONCEPT-updated.md` | 20 lines — updated concept. Merge into CONCEPT.md |

## Tips System (`tips/`)
**Deploy location**: `~/.local/tips/SDG-VOX/`

### Planned Tips
| # | Tip | Priority |
|---|-----|----------|
| 1 | Activate wake word to start voice commands | High |
| 2 | Use `administrator` prefix for sudo commands | High |
| 3 | Open the config GUI to manage voice profiles | Medium |
| 4 | Use headless mode for background operation | Low |

## Implementation Notes
- CRITICAL: Merge `README-updated.md` → `README.md` (adopt whisper-server, ghostty, gtk-layer-shell) then delete `README-updated.md`
- Merge `CONCEPT-updated.md` → `CONCEPT.md` then delete `CONCEPT-updated.md`
- Tips in `tips/SDG-VOX/tips.list`
- Source code for command reference is in `config/SDG-VOX/config.json` and `local/SDG-VOX/` Python files
