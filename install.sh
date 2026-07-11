#!/bin/bash

### dependencies
unipkg install any python3-gobject
unipkg install any python3-cairo
unipkg install any gst-plugins-base
unipkg install any gst-plugins-good
unipkg install any gtk-layer-shell
unipkg install any pipewire
unipkg install any pipewire-pulse
unipkg install any ydotool

WORKDIR="$HOME/.cache/SDG-PKG/sdg-vox"

cp -r "$WORKDIR/local/"* "$HOME/.local/"
cp -r "$WORKDIR/docs/"* "$HOME/.local/docs/"
cp -r "$WORKDIR/tips/"* "$HOME/.local/tips/"

mkdir -p "$HOME/.config/SDG-VOX"
[ ! -f "$HOME/.config/SDG-VOX/config.json" ] && cp "$WORKDIR/config/SDG-VOX/config.json" "$HOME/.config/SDG-VOX/config.json"

mkdir -p "$HOME/.local/share/applications"
cp "$WORKDIR/other/vox-config.desktop" "$HOME/.local/share/applications/vox-config.desktop"

sudo ln -sf "$HOME/.local/SDG-VOX/vox.sh" /usr/bin/sdgvox

# Whisper model download
MODELS_DIR="$HOME/.cache/SDG-VOX/models"
mkdir -p "$MODELS_DIR"

if [ ! -f "$MODELS_DIR/ggml-medium.en.bin" ]; then
    echo "Downloading Whisper model (~1.5 GB)..."
    if command -v curl &>/dev/null; then
        curl -# -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin" -o "$MODELS_DIR/ggml-medium.en.bin"
    elif command -v wget &>/dev/null; then
        wget --show-progress "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin" -O "$MODELS_DIR/ggml-medium.en.bin"
    else
        echo "Neither curl nor wget available -- download manually:"
        echo "  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin"
        echo "  Place at: $MODELS_DIR/ggml-medium.en.bin"
    fi
fi

which sdgvox || echo "INSTALL FAILED!"
