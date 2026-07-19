#!/bin/bash

LOCALDIR=SDG-VOX
DOCDIR=SDG-VOX
TIPDIR=SDG-VOX
entrypoint=vox.sh
command=sdgvox

WORKDIR=$(pwd)

rm -rf "$HOME/.local/docs/$DOCDIR" "$HOME/.local/tips/$TIPDIR" "$HOME/.local/$LOCALDIR"

mkdir -p "$HOME/.local/$LOCALDIR"
cp -r "$WORKDIR/local/"* "$HOME/.local/"
cp -r "$WORKDIR/docs/"* "$HOME/.local/docs/"
cp -r "$WORKDIR/tips/"* "$HOME/.local/tips/"

mkdir -p "$HOME/.config/SDG-VOX"
[ ! -f "$HOME/.config/SDG-VOX/config.json" ] && cp "$WORKDIR/config/SDG-VOX/config.json" "$HOME/.config/SDG-VOX/config.json"

mkdir -p "$HOME/.local/share/applications"
cp "$WORKDIR/other/vox-config.desktop" "$HOME/.local/share/applications/vox-config.desktop"

sudo ln -sf "$HOME/.local/$LOCALDIR/$entrypoint" /usr/bin/$command

which $command || echo "INSTALL FAILED!"
