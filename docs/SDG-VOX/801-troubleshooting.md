# Troubleshooting

## Daemon won't start

**"Whisper model not found"**

The model file `ggml-medium.en.bin` is missing from `~/.cache/SDG-VOX/models/`.

```bash
./install.sh   # re-downloads the model
```

Or download manually (~1.5 GB):

```bash
curl -# -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin" \
  -o ~/.cache/SDG-VOX/models/ggml-medium.en.bin
```

**"whisper-server failed to start"**

Ensure `whisper-server` (from `whisper.cpp`) is installed:

```bash
which whisper-server
```

On Arch Linux: `sudo pacman -S whisper-cpp-vulkan`
On other distros: compile from https://github.com/ggerganov/whisper.cpp

## No microphone input

**"No audio source available" error**

SDG-VOX tries `pipewiresrc` first, then `pulsesrc`. Ensure PipeWire or PulseAudio is running:

```bash
pactl info
```

If PipeWire is not installed, install: `pipewire` + `pipewire-pulse`.

**Check default source:**

```bash
pactl info | grep "Default Source"
pactl list sources short
```

**Test mic directly:**

```bash
parec --rate=16000 --format=s16le --channels=1 | hexdump -C | head
```

If this produces no output, your mic is not configured at the system level.

## Commands not matching

**Wake word not recognized**

Speak slowly and clearly. The wake word must appear at the beginning of the utterance. Default wake words: `system command`, `cmd`, `computer`, `i cast`, `highcast`.

**"no match" in logs**

The utterance was transcribed but no graph path matched. Check:
- Is the command node connected to the root?
- Are you using the exact trigger words from the config?
- Multi-word triggers are matched greedily (longest first)

**Prefix/suffix not working**

Prefix/suffix words can appear anywhere in the utterance, not just at the start/end. They are case-insensitive.

## Type actions fail

**"ydotool not found"**

The `ydotool` daemon (`ydotoold`) must be running. The daemon auto-starts it, but verify:

```bash
pgrep -x ydotoold
```

Install: `sudo pacman -S ydotool` (Arch) or `sudo apt install ydotool` (Debian).

## Overlay not showing

**On X11 (not Wayland)**

The overlay uses `gtk-layer-shell`, which only works on Wayland compositors that support the `wlr-layer-shell` protocol (sway, Hyprland, river, etc.). On X11, use `--headless` mode.

**Overlay window not visible**

Some compositors block `OVERLAY` layer windows. Try:

```bash
sdgvox daemon --headless
```

## Config GUI issues

**GUI doesn't open**

Ensure GTK 3 and Cairo are installed:

```bash
python3 -c "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk; print('OK')"
python3 -c "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gdk; print('OK')"
```

**"cannot open display"**

The config GUI requires a running X11 or Wayland display. Run from a terminal in your desktop session, not over SSH (unless using X11 forwarding).

## Config corruption

If `config.json` becomes corrupted, delete it and reinstall:

```bash
rm ~/.config/SDG-VOX/config.json
./install.sh   # restores default config
```

## The daemon is not responding

```bash
pkill -x sdgvox    # stop the CLI wrapper
pkill -x python3   # stop Python processes (if needed)
```

## Logs

The daemon logs to stdout/stderr. Run in a terminal to see logs:

```bash
sdgvox daemon 2>&1 | tee ~/vox.log
```

Log lines include timestamps and levels: `[INFO]`, `[WARNING]`, `[ERROR]`, `[DEBUG]`.

## Hot-reload not working

The daemon polls `config.json` mtime every second. If you saved the file but changes aren't picked up:

- Ensure the file path is correct (`~/.config/SDG-VOX/config.json`)
- Check file permissions
- Restart the daemon as a fallback
