#!/bin/bash
# ---------------------------------------------------------------------------
# SDG-VOX — update script
#
# Redeploys local binaries, docs, tips, and the desktop file from the
# sdgpkg cache.  Skips ~/.config/SDG-VOX/ to preserve the user's
# command graph customisations.
# ---------------------------------------------------------------------------

# --------------------------------------------------------------------------
# 1. Redeploy local binaries / libraries
# --------------------------------------------------------------------------
# Remove the old local copy, then copy fresh from the cache
rm -rf /home/$(whoami)/.local/SDG-VOX
cp -r /home/$(whoami)/.cache/SDG-PKG/sdg-vox/local/* /home/$(whoami)/.local

# Re-apply the symlink (the wrapper script may have changed)
sudo ln -sf /home/$(whoami)/.local/SDG-VOX/vox.sh /usr/bin/sdgvox

# --------------------------------------------------------------------------
# 2. Redeploy docs & tips
# --------------------------------------------------------------------------
rm -rf /home/$(whoami)/.local/docs/SDG-VOX
rm -rf /home/$(whoami)/.local/tips/SDG-VOX
mkdir -p /home/$(whoami)/.local/docs/SDG-VOX /home/$(whoami)/.local/tips/SDG-VOX
cp -r /home/$(whoami)/.cache/SDG-PKG/sdg-vox/docs/* /home/$(whoami)/.local/docs/SDG-VOX
cp -r /home/$(whoami)/.cache/SDG-PKG/sdg-vox/tips/* /home/$(whoami)/.local/tips/SDG-VOX

# --------------------------------------------------------------------------
# 3. Redeploy desktop entry
# --------------------------------------------------------------------------
cp /home/$(whoami)/.cache/SDG-PKG/sdg-vox/other/vox-config.desktop /home/$(whoami)/.local/share/applications/vox-config.desktop

# NOTE: Config (~/.config/SDG-VOX/) is intentionally NOT touched here so
# that the user's command tree and settings survive updates.
