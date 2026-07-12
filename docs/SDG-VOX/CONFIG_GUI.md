# Config GUI Guide

Launch the configuration editor:

```bash
sdgvox config
# or
vox config
# or with a custom config path:
vox --config /path/to/config.json config
```

## Window layout

The GUI is a GTK window split into two panels:

### Left panel — Flowchart view

A Cairo-rendered interactive directed graph showing all nodes and their connections:

- **Layout**: Layered DAG layout (BFS layering from root, left-to-right)
- **Color coding**:
  - Green — `exec` nodes
  - Blue — `type` nodes
  - Orange — `shell_exec` nodes
  - Grey — `branch` nodes
- **Type badges** and command previews shown on each node
- **Shared nodes** (multiple inbound edges) rendered once

#### Interaction

| Action | Effect |
|--------|--------|
| Click empty space + drag | **Pan** the canvas |
| Mouse scroll wheel | **Zoom** in/out (0.2×–3.0× range) |
| Click a node | Select it — properties appear in the right panel |
| Right-click a node | Context menu: Add child node, Delete node |
| Drag from a node's edge | Create a connection to another node (drag-to-connect) |

Connections are drawn as curved edges with arrowheads. Selected nodes are highlighted.

### Right panel — Node editor

When a node is selected, its properties are shown:

| Field | Description |
|-------|-------------|
| **Name** | Internal node name (unique identifier) |
| **Type** | `branch`, `exec`, `shell_exec`, or `type` |
| **Command** | Shell command (only for action types). Use `{text}` for text capture substitution. |
| **Text capture** | Toggle — when on, remaining utterance tokens after the trigger are captured into `{text}` |
| **Connections** | Comma-separated list of child node names |

At the bottom of the right panel:

- **Root connections** — list of entrypoint node names that the wake word routes to

A `?` help button appears next to every setting, explaining what it does.

### Toolbar

| Button | Action |
|--------|--------|
| **Save** | Writes the current graph to `config.json` |
| **Settings** | Opens the Settings dialog (4 tabs, see below) |
| **New node** | Adds a new branch node at a default position |
| **Validate** | Checks the graph for errors (missing connections, invalid names, etc.) |
| **Help** | Opens a help dialog explaining the GUI |
| **Daemon** | Starts/stops the voice daemon directly from the GUI |

### Right-click context menu

- **Add node** — creates a new child branch node connected to the right-clicked node
- **Delete node** — removes the node and its connections

## Settings dialog

A four-tab modal dialog for global configuration:

### Tab 1 — Wake Word

| Field | Description |
|-------|-------------|
| **Wake phrase** | The main wake word (default: `system command`) |
| **Aliases** | Alternative wake phrases (one per line). Default: `cmd`, `computer`, `i cast`, `highcast` |

### Tab 2 — Terminal

| Field | Description |
|-------|-------------|
| **Terminal command** | Terminal emulator used for `shell_exec` actions (default: `ghostty -e`) |

### Tab 3 — Filters

Inline-editable tables for prefix and suffix rules:

| Column | Description |
|--------|-------------|
| **Words** | Trigger words (comma-separated) |
| **Prepend** | String prepended to the matched command |
| **Append** | String appended to the matched command |

### Tab 4 — Triggers

Immediate trigger table:

| Column | Description |
|--------|-------------|
| **Word** | Exact utterance to match (after wake-word stripping) |
| **Type** | One of `exec`, `shell_exec`, `type` |
| **Command** | The command to run |

## Help dialogs

Contextual `?` buttons throughout the GUI open `Gtk.MessageDialog` popups explaining:

| Topic | Content |
|-------|---------|
| Node types | `branch`, `exec`, `shell_exec`, `type` behaviors |
| Text capture | How `{text}` substitution works |
| Prefixes | How prefix rules modify commands |
| Suffixes | How suffix rules modify commands |
| Triggers | Immediate triggers that fire before graph walk |
| Terminal | Terminal emulator configuration |
| Flowchart | Visual graph editor instructions |

## Test dialog

Allows simulating a voice command against the current graph without running the daemon. Enter text and see which path is walked and what action would execute.

## Hot-reload

Changes saved via the GUI are picked up by a running daemon within ~1 second (config mtime polling) — no restart needed.
