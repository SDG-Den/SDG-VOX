# Test Checklist — SDG-VOX

## Core
- [ ] Launch via `sdgvox`
- [ ] Wake word detection works (default wake word)
- [ ] Speak a command — executes
- [ ] Command tree: nested commands work ("open terminal", "open browser")

## UI
- [ ] GTK HUD overlay shows transcription
- [ ] `sdgvox-config` opens GTK config editor
- [ ] Config editor shows flowchart of command tree
- [ ] Node positions editable in config editor

## Daemon
- [ ] Daemon mode: `sdgvox --daemon` — runs in background
- [ ] Daemon responds to wake word while backgrounded
- [ ] Audio device hotplug — handled gracefully (no crash)
- [ ] Stop daemon — clean shutdown

## Offline
- [ ] Fully offline (disable network — still works)
