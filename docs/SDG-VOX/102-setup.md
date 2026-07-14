# Setup & First Run

## Dependencies

| Component | Arch (pacman) | Debian/Ubuntu (apt) |
|-----------|---------------|---------------------|
| Python bindings | `python-gobject` | `python3-gi` |
| Cairo rendering | `python-cairo` | `python3-cairo` |
| Audio capture | `gst-plugins-base`, `gst-plugins-good` | `gir1.2-gstreamer-1.0`, `gstreamer1.0-plugins-good` |
| Speech-to-text | `whisper-cpp-vulkan` (or compile whisper.cpp) | — |
| Keyboard typing | `ydotool` | `ydotool` |
| Audio server | `pipewire` + `pipewire-pulse` | `pipewire` + `pipewire-pulse` |
| Wayland overlay | `gtk-layer-shell` | `gtk-layer-shell` |
| Terminal | `ghostty` (or your preferred terminal) | `ghostty` |

When installed via sdgpkg, dependencies are installed automatically:

```bash
sdgpkg install sdg-vox
```

## Whisper model

The daemon requires a Whisper model file. The install script auto-downloads `ggml-medium.en.bin` (~1.5 GB) from Hugging Face to `~/.cache/SDG-VOX/models/`.

Manual download:

```bash
curl -# -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin" \
  -o ~/.cache/SDG-VOX/models/ggml-medium.en.bin
```

## Microphone configuration

SDG-VOX captures audio via GStreamer, which uses PipeWire (with PulseAudio fallback). The default source is used — ensure your mic is set up:

```bash
# Check your default audio source
pactl info | grep "Default Source"

# List all sources
pactl list sources short

# Set a specific source as default
pactl set-default-source <source_name>
```

Test that your mic works:

```bash
# Record a 3-second test
parec --rate=16000 --format=s16le --channels=1 | hexdump -C | head
```

## First run

```bash
# 1. Install
sdgpkg install sdg-vox

# 2. (Optional) Open the config GUI to customize commands
sdgvox config

# 3. Start the daemon
sdgvox daemon
```

The daemon will:
1. Launch whisper-server and load the model (~10-60 seconds)
2. Start capturing audio from your default microphone
3. Display a transparent HUD overlay at the top of the screen

## Your first voice command

```bash
# Wait for the daemon to finish loading (you'll see "whisper-server ready" in logs)
# Then say:
"system command, open firefox"
```

The overlay should show the transcription and the matched action. Firefox opens.

## Grace period

After your first command, you have 3 seconds to speak another command without repeating the wake word. The overlay shows "Listening..." during this window.

## Stopping the daemon

Press `Ctrl+C` in the terminal where the daemon is running, or send SIGINT/SIGTERM.
