# SDG-VOX Documentation Plan

## Current Status
No documentation exists. Package is a minimal placeholder with a single install.sh that only installs packages using unipkg.

## Docs System (`docs/`)
**Deploy location**: `~/.local/docs/SDG-VOX/`

### Planned Doc Topics
| # | Topic | Description | Priority |
|---|-------|-------------|----------|
| 1 | Voice Control Setup | Prerequisites (voice models, wake word engines, microphone config) | High |
| 2 | Commands Reference | Available voice commands and phrase patterns | High |
| 3 | Wake Word Configuration | Configuring wake word detection | Medium |
| 4 | Integration | How voice commands interact with SDG-MANGO-CORE and DMS | Low |

### Implementation
- Create `docs/SDG-VOX/` directory with markdown files
- Follow SDG-DOCS naming convention
- Register in `install.sh` for deployment to `~/.local/docs/`

## Tips System (`tips/`)
**Deploy location**: `~/.local/tips/SDG-VOX/`

### Planned Tips
| # | Tip | Description | Priority |
|---|-----|-------------|----------|
| 1 | Wake word | Say the configured wake word to activate voice control | High |
| 2 | Voice commands | "open terminal", "lock screen", "increase volume" — natural language | High |
| 3 | Mic setup | Ensure microphone is working for voice control | Medium |

### Implementation
- Create `tips/SDG-VOX/tips.list` with the above tips
- Register in `install.sh` for deployment to `~/.local/tips/`
