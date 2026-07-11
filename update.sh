#!/bin/bash

WORKDIR="$HOME/.cache/SDG-PKG/sdg-vox"

rm -rf "$HOME/.local/SDG-VOX"
cp -r "$WORKDIR/local/"* "$HOME/.local/"

rm -rf "$HOME/.local/docs/SDG-VOX" "$HOME/.local/tips/SDG-VOX"
cp -r "$WORKDIR/docs/"* "$HOME/.local/docs/"
cp -r "$WORKDIR/tips/"* "$HOME/.local/tips/"

sudo ln -sf "$HOME/.local/SDG-VOX/vox.sh" /usr/bin/sdgvox

cp "$WORKDIR/other/vox-config.desktop" "$HOME/.local/share/applications/vox-config.desktop"

# Whisper model — ensure it exists (will survive update since it lives in ~/.cache)
MODELS_DIR="$HOME/.cache/SDG-VOX/models"
mkdir -p "$MODELS_DIR"

if [ ! -f "$MODELS_DIR/ggml-medium.en.bin" ]; then
    echo "Whisper model missing — downloading (~1.5 GB)..."
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
