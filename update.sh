#!/bin/bash

WORKDIR="$HOME/.cache/SDG-PKG/sdg-vox"

rm -rf "$HOME/.local/SDG-VOX"
cp -r "$WORKDIR/local/"* "$HOME/.local/"

rm -rf "$HOME/.local/docs/SDG-VOX" "$HOME/.local/tips/SDG-VOX"
cp -r "$WORKDIR/docs/"* "$HOME/.local/docs/"
cp -r "$WORKDIR/tips/"* "$HOME/.local/tips/"

sudo ln -sf "$HOME/.local/SDG-VOX/vox.sh" /usr/bin/sdgvox

cp "$WORKDIR/other/vox-config.desktop" "$HOME/.local/share/applications/vox-config.desktop"
