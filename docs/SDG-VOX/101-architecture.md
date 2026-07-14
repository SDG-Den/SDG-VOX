# Architecture

> This page describes the internal architecture for developers. For setup instructions and everyday usage, see [Setup & First Run](102-setup.md) or the [Quick Reference](000-quick-reference.md).

## Pipeline overview

Audio capture → VAD segmentation → whisper-server STT → wake word detection → graph matching → action execution → HUD overlay feedback

```
┌──────────────┐    ┌──────────┐    ┌────────────────┐
│ AudioCapture │───▶│ VAD      │───▶│ whisper-server │
│ (GStreamer)  │    │ (RMS)    │    │ (port 18081)   │
└──────────────┘    └──────────┘    └───────┬────────┘
                                            │ text
                                            ▼
┌──────────┐    ┌──────────────┐    ┌───────────────┐
│ Executor │◀───│ command_tree │◀───│ wake detection│
│          │    │ .match()     │    │ (3s timeout)  │
└────┬─────┘    └──────────────┘    └───────────────┘
     │
     ├──▶ subprocess.Popen (exec)
     ├──▶ terminal + bash -c (shell_exec)
     └──▶ ydotool type (type)
```

## Modules

| Module | Responsibility |
|--------|----------------|
| `audio_capture.py` | GStreamer pipeline capturing mic audio, tries `pipewiresrc` first, falls back to `pulsesrc`. Pushes raw PCM bytes to a callback. |
| `whisper_recognizer.py` | Manages whisper-server subprocess. Runs VAD to segment speech, sends WAV segments to whisper-server HTTP API. Produces partial and final transcriptions. Handles wake word detection and wake state timeout. Includes health-check watchdog and auto-restart. |
| `command_tree.py` | Skip-based directed-graph matching engine. Strips wake word, scans for prefix/suffix modifiers, matches immediate triggers, walks the graph from root connections. Returns `MatchResult` objects with action type, command, captured text, and prefix/suffix. |
| `executor.py` | Dispatches matched actions via subprocess, terminal, or ydotool. Substitutes `{text}` and `{url_text}` placeholders. Applies prefix/suffix modifiers. |
| `daemon.py` | Wires everything together in a `GLib.MainLoop`. Starts capture → recognizer → overlay. Polls config for hot-reload. Runs watchdog for whisper-server health. Handles clean shutdown. |
| `overlay.py` | Transparent GTK window in the compositor's `OVERLAY` layer. Shows real-time transcriptions and matched actions. Auto-hides after configurable timeout. |
| `config_manager.py` | Loads/saves `config.json` with migration from old graph format. |
| `config_ui.py` | GTK config editor window with toolbar, node property editor, settings dialog, and test dialog. |
| `flowchart_view.py` | Cairo-rendered interactive DAG viewer/editor. Layered BFS layout, color-coded node types, pan/zoom, drag-to-connect. |
| `cli.py` | Entry point handling daemon and config commands. |
| `models.py` | Dataclasses: `GraphNode`, `Config`, `ImmediateTrigger`, `AffixRule`. |

## Data flow

1. **Audio capture**: `AudioCapture` runs a GStreamer pipeline that captures the default microphone, resamples to 16 kHz mono S16LE, and pushes buffers to an `appsink`.

2. **VAD segmentation**: `WhisperRecognizer.feed_audio()` computes RMS energy per buffer. Above RMS 300 = speech; below = silence. Speech segments are accumulated until 800ms of silence, then finalized and transcribed. Partial transcriptions are triggered every 300ms during active speech.

3. **Transcription**: WAV bytes are sent to whisper-server's HTTP API. The returned text is checked for wake words.

4. **Wake word detection**: If the transcribed text starts with a configured wake word or alias, the remainder is forwarded to the matcher. If only the wake word was spoken (no command yet), a 3-second wake state is entered — subsequent utterances within that window are treated as commands without requiring the wake word again.

5. **Graph matching**: `command_tree.match()` strips punctuation, checks immediate triggers first, then extracts prefix/suffix modifiers from any position in the utterance, then walks the graph by matching node triggers against utterance tokens. Non-matching tokens are silently skipped.

6. **Execution**: `executor.execute()` substitutes `{text}` / `{url_text}`, applies prefix/suffix, then dispatches via subprocess/terminal/ydotool.

7. **Overlay feedback**: The daemon's `on_partial` and `on_result` callbacks update the overlay with live transcription text and the executed action.

## Config hot-reload

The daemon polls `config.json`'s mtime every second. On change, it reloads the full config, rebuilds the root wake word map, and updates the recognizer's root list — no restart needed.

## Watchdog

Every 30 seconds, the daemon checks if whisper-server is still listening on `127.0.0.1:18081`. If unresponsive, it terminates and re-launches the subprocess.
