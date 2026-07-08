#!/bin/bash
# ---------------------------------------------------------------------------
# SDG-VOX — uninstall script
#
# Removes all files installed by install.sh and tears down the symlink.
# ---------------------------------------------------------------------------

# Remove the local module directory (Python package + CLI wrapper + models)
rm -rf /home/$(whoami)/.local/SDG-VOX

# Remove the user configuration (command graph tree)
rm -rf /home/$(whoami)/.config/SDG-VOX

# Remove docs and tips shipped with this module
rm -rf /home/$(whoami)/.local/docs/SDG-VOX
rm -rf /home/$(whoami)/.local/tips/SDG-VOX

# Remove the desktop entry
rm -f /home/$(whoami)/.local/share/applications/vox-config.desktop

# Remove the /usr/bin/sdgvox symlink created during install
sudo unlink /usr/bin/sdgvox
