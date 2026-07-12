# Commands Reference

## The command graph

The default `config.json` contains 48 nodes forming a directed graph. Each node has a **trigger** (the word(s) spoken to reach it), a **type** (branch/exec/shell_exec/type), and optional **connections** to child nodes.

## Node types

| Type | Behavior |
|------|----------|
| `branch` | Routes to child nodes by matching its trigger against utterance tokens. No action on its own. |
| `exec` | Runs `command` via `subprocess.Popen(cmd, shell=True)`. |
| `shell_exec` | Opens the configured terminal and runs `command` inside via `bash -c`. |
| `type` | Types `command` text via `ydotool type`. |

## Skip-based matching

Non-matching words are silently ignored. Multi-word triggers (e.g. `"search for"`) are matched greedily (longest first).

```
"system command, open the firefox now"       → matches "open" → "firefox"
"system command, hey please launch chromium" → matches "launch" → "chromium"
"system command, search for cute cats online" → captures "cute cats online"
```

## Auto-follow (shared sub-graphs)

A branch node with exactly one connection leading to another branch is auto-followed — the intermediate label acts as an internal router and consumes no tokens. This lets you create shared sub-graphs:

```json
"open":     { "type": "branch", "connections": ["browsers"] },
"launch":   { "type": "branch", "connections": ["browsers"] },
"browsers": { "type": "branch", "connections": ["firefox", "chromium"] }
```

Both `"open firefox"` and `"launch firefox"` work because `"browsers"` is auto-followed.

## Text capture

When `text_capture: true` on an action node, all remaining utterance tokens after the matching keyword are captured and substituted into `{text}` (or `{url_text}` for URL encoding):

```json
"search for": {
  "type": "branch",
  "connections": ["search_exec"]
}
"search_exec": {
  "type": "exec",
  "text_capture": true,
  "command": "xdg-open https://google.com/search?q={url_text}"
}
```

Saying `"system command, search for cats online"` → captures `"cats online"` → runs `xdg-open 'https://google.com/search?q=cats%20online'`.

## Prefixes & suffixes

Prefix/suffix words are detected anywhere in the utterance and modify the final command:

| Rule | Words | Effect |
|------|-------|--------|
| Prefix | `administrator` | Prepends `sudo` to command |
| Prefix | `silent` | Prepends `setsid -w` (runs detached) |
| Suffix | `background` | Appends `&` (runs in background) |
| Suffix | `detach` | Appends `&>/dev/null &` (fully detached) |

- `"administrator open firefox"` → `sudo firefox`
- `"open firefox background"` → `firefox &`
- `"administrator open firefox background"` → `sudo firefox &`
- `"silent open firefox detach"` → `setsid -w firefox &>/dev/null &`

## Immediate triggers

Whole-utterance substring matches that fire before any graph walk:

| Word | Type | Command |
|------|------|---------|
| `cancel` | exec | `true` (aborts current command, resets wake state) |

The `cancel` trigger is checked in both `on_partial` and `on_result` callbacks, so saying "cancel" at any point aborts the current utterance and clears the wake state.

## Full node reference

### Root

| Node | Type | Wake word | Aliases | Connections |
|------|------|-----------|---------|-------------|
| `default` | root | `system command` | `cmd`, `computer`, `i cast`, `highcast` | launch, open, quit, clipboard, volume, search for, type, run, output, dictate, execute, full, fool |

### Launch / Open (browsers, apps)

| Say | Path | Type | Command |
|-----|------|------|---------|
| `launch firefox` / `open firefox` / `launch browser` / `open browser` | launch → firefox_l → launch_firefox_exec | exec | `firefox` |
| `launch chromium` / `open chromium` / `launch browser` / `open browser` | launch → chromium_l → launch_chromium_exec | exec | `chromium` |
| `launch terminal` / `open terminal` / `launch package` / `open package` | launch → terminal → ghostty_exec | exec | `ghostty` |
| `launch package` / `open package` | launch → package → unipkg | shell_exec | `unipkg launch-tui` |
| `launch terminal` / `open terminal` | launch → terminal → run_terminal_exec | shell_exec | `{text}` (text_capture) |

### Quit

| Say | Path | Type | Command |
|-----|------|------|---------|
| `quit firefox` / `quit browser` | quit → firefox_q → quit_firefox_exec | exec | `pkill firefox` |
| `quit chromium` / `quit browser` | quit → chromium_q → quit_chromium_exec | exec | `pkill chromium` |

### Clipboard

| Say | Path | Type | Command |
|-----|------|------|---------|
| `clipboard copy` | clipboard → copy_branch → copy_exec | exec | `wl-copy` |
| `clipboard paste` | clipboard → paste_branch → paste_exec | exec | `wl-paste` |

### Volume

| Say | Path | Type | Command |
|-----|------|------|---------|
| `volume up` | volume → up_branch → up_exec | exec | `pactl set-sink-volume @DEFAULT_SINK@ +5%` |
| `volume down` | volume → down_branch → down_exec | exec | `pactl set-sink-volume @DEFAULT_SINK@ -5%` |
| `volume mute` | volume → mute_branch → mute_exec | exec | `pactl set-sink-mute @DEFAULT_SINK@ toggle` |

### Search

| Say | Path | Type | Command |
|-----|------|------|---------|
| `search for <query>` | search for → search_exec | exec | `xdg-open https://google.com/search?q={url_text}` (text_capture) |

### Type

| Say | Path | Type | Command |
|-----|------|------|---------|
| `type <text>` / `dictate <text>` / `output <text>` | type/dictate/output → type_exec | type | `{text}` (text_capture) |

### Execute / Run

| Say | Path | Type | Command |
|-----|------|------|---------|
| `execute system update` / `full system update` / `fool system update` | execute/full/fool → system → update → full system update | shell_exec | `cachy-update` |
| `execute system upgrade` / `full` / `fool` → system → upgrade → full system update | shell_exec | `cachy-update` |
| `run system update` / `run system upgrade` | run → system → update/upgrade → full system update | shell_exec | `cachy-update` |
| `execute` / `run` + `<command>` → system → update/upgrade | — | — |
| `execute order 66` | execute → order → 66 → play imperial march | exec | `xdg-open 'https://www.youtube.com/watch?v=-bzWSJG93P8'` |

### Hidden

| Say | Path | Type | Command |
|-----|------|------|---------|
| `execute order 66` / `fool` / `full` → various paths → play imperial march | exec | YouTube link |
