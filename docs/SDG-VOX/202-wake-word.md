# Wake Word Configuration

## Default wake words

The default config defines one root node with:

| Field | Value |
|-------|-------|
| **Primary wake word** | `system command` |
| **Aliases** | `cmd`, `computer`, `i cast`, `highcast` |

The wake word must be spoken at the **beginning** of an utterance. The daemon checks if the transcribed text starts with any configured wake word or alias.

## How it works

1. The `WhisperRecognizer` transcribes audio continuously via whisper-server
2. Each transcription is checked against all root nodes' wake words and aliases
3. If a match is found, the wake word is stripped and the remainder is passed to the graph matcher
4. If only the wake word was spoken (no command), a 3-second **wake state** is entered — subsequent utterances within that window are treated as commands without requiring the wake word again

## 3-second grace period

When you speak just the wake word (e.g. "system command"), the daemon enters a wake state for 3 seconds:

- The overlay shows "Listening..."
- Any utterance within 3 seconds is treated as a command
- Saying the wake word again resets the timer
- The state is consumed on the first complete command match
- Saying "cancel" immediately exits the wake state

This allows natural interaction like:
1. "System command" → "Listening..."
2. "Open firefox" → Firefox opens (no wake word needed)
3. "Volume up" → Volume increases (still within grace period)

## Customizing wake words

### Via config GUI

1. Run `sdgvox config`
2. Click the **Settings** toolbar button
3. Go to the **Wake Word** tab
4. Edit the wake phrase and aliases (one per line)
5. Click Save

### Via config.json

Edit `~/.config/SDG-VOX/config.json`. The root node has these fields:

```json
{
  "default": {
    "type": "root",
    "wake_word": "system command",
    "aliases": ["cmd", "computer", "i cast", "highcast"],
    "connections": ["launch", "open", "quit", ...]
  }
}
```

- `wake_word`: The primary phrase that activates voice control
- `aliases`: Alternative phrases (case-insensitive)
- Multiple root nodes are supported (each can have its own wake word)

## What makes a good wake word

| Do | Don't |
|----|-------|
| Use 2-3 syllable phrases | Single words that appear in normal speech |
| Distinct from common conversation | Words that sound similar to commands |
| Easy to pronounce clearly | Complex phrases with uncommon words |

## Wake word is not recognized

- Speak clearly and at a moderate pace
- Ensure the wake word is at the **start** of your utterance
- The wake word is case-insensitive
- Background noise can affect recognition quality
- The whisper model works best with clear, close-mic audio
