#!/bin/bash
# ---------------------------------------------------------------------------
# SDG-VOX — install script
#
# Wake-word activated, offline voice-to-commands daemon with a GTK config
# editor.  Transcribes speech locally via Vosk/Whisper and walks a directed
# graph of command bindings.
#
# Ships a Python package (vox/), a CLI wrapper (vox.sh), configuration,
# documentation, and tips.
#
# The source lives in ~/.cache/SDG-PKG/sdg-vox (the sdgpkg cache).
# This script installs dependencies, copies files to XDG-style paths,
# creates a /usr/bin/sdgvox symlink, and downloads the Whisper model.
# ---------------------------------------------------------------------------

# --------------------------------------------------------------------------
# 0. Dependencies — installed via unipkg (distro-agnostic package helper)
# --------------------------------------------------------------------------
# Python GTK/Cairo bindings for the config editor and overlay UI
unipkg install any python3-gobject
unipkg install any python3-cairo

# GStreamer base + good plugins for microphone audio capture
unipkg install any gst-plugins-base
unipkg install any gst-plugins-good

# GTK layer shell — allows the overlay window to render as a Wayland layer
unipkg install any gtk-layer-shell

# Audio server — required for mic capture in the daemon
unipkg install any pipewire
unipkg install any pipewire-pulse

# ydotool — types text into the focused window (Wayland & X11)
unipkg install any ydotool

# --------------------------------------------------------------------------
# Source directory: sdgpkg clones the repo here before calling install
# --------------------------------------------------------------------------
WORKDIR=/home/$(whoami)/.cache/SDG-PKG/sdg-vox

# --------------------------------------------------------------------------
# 1. Configuration
# --------------------------------------------------------------------------
# Deploy the default command graph config.json to ~/.config/SDG-VOX/.
# This file is the user's voice command tree — it is NOT overwritten on
# update (update.sh skips config to preserve customisations).
mkdir -p /home/$(whoami)/.config/SDG-VOX
cp $WORKDIR/config/SDG-VOX/config.json /home/$(whoami)/.config/SDG-VOX/config.json

# --------------------------------------------------------------------------
# 2. Local binaries / libraries
# --------------------------------------------------------------------------
# Copy the Python package (vox/) and the CLI wrapper (vox.sh) to
# ~/.local/SDG-VOX/.  The wrapper adds this directory to sys.path so
# that `import vox.cli` resolves correctly without pip install.
# pyproject.toml is included for reference but vox.sh manages the path.
mkdir -p /home/$(whoami)/.local/SDG-VOX
cp -r $WORKDIR/local/SDG-VOX/vox /home/$(whoami)/.local/SDG-VOX/
cp $WORKDIR/local/SDG-VOX/vox.sh /home/$(whoami)/.local/SDG-VOX/vox.sh
cp $WORKDIR/local/SDG-VOX/pyproject.toml /home/$(whoami)/.local/SDG-VOX/pyproject.toml
chmod a+x /home/$(whoami)/.local/SDG-VOX/vox.sh

# --------------------------------------------------------------------------
# 3. Modular docs & tips
# --------------------------------------------------------------------------
# Docs and tips are deployed to versioned subdirectories under
# ~/.local/docs/ and ~/.local/tips/ so they don't collide with other
# SDG modules.
mkdir -p /home/$(whoami)/.local/docs/SDG-VOX /home/$(whoami)/.local/tips/SDG-VOX
cp -r $WORKDIR/docs/* /home/$(whoami)/.local/docs/SDG-VOX
cp -r $WORKDIR/tips/* /home/$(whoami)/.local/tips/SDG-VOX

# --------------------------------------------------------------------------
# 4. Desktop entry
# --------------------------------------------------------------------------
# Install the desktop file so the config GUI can be launched from
# an application launcher (rofi, wofi, etc.).
mkdir -p /home/$(whoami)/.local/share/applications
cp $WORKDIR/other/vox-config.desktop /home/$(whoami)/.local/share/applications/vox-config.desktop

# --------------------------------------------------------------------------
# 5. Symlink entrypoint
# --------------------------------------------------------------------------
# /usr/bin/sdgvox is referenced by the desktop file and by users on the
# command line.  The symlink points to the installed CLI wrapper.
sudo ln -sf /home/$(whoami)/.local/SDG-VOX/vox.sh /usr/bin/sdgvox

# --------------------------------------------------------------------------
# 6. Speech model download
# --------------------------------------------------------------------------
# Whisper model files (~1.5 GB) are fetched from Hugging Face on demand
# rather than stored in the repo.  The daemon expects them under
# ~/.local/SDG-VOX/models/ (config_manager.py models_dir()).
MODELS_DIR=/home/$(whoami)/.local/SDG-VOX/models
mkdir -p "$MODELS_DIR"

if [ ! -f "$MODELS_DIR/ggml-medium.en.bin" ]; then
    echo "Downloading Whisper model (~1.5 GB)..."
    if command -v curl &>/dev/null; then
        curl -# -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin" -o "$MODELS_DIR/ggml-medium.en.bin"
    elif command -v wget &>/dev/null; then
        wget --show-progress "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin" -O "$MODELS_DIR/ggml-medium.en.bin"
    else
        echo "Neither curl nor wget available — download manually:"
        echo "  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin"
        echo "  Place at: $MODELS_DIR/ggml-medium.en.bin"
    fi
fi

# --------------------------------------------------------------------------
# 7. Verify
# --------------------------------------------------------------------------
which sdgvox || echo "INSTALL FAILED!"
