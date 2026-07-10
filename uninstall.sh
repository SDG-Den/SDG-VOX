#!/bin/bash
# ---------------------------------------------------------------------------
# SDG-VOX — uninstall script
#
# Removes all files installed by install.sh and tears down the symlink.
# ---------------------------------------------------------------------------

# Remove the local module directory (Python package + CLI wrapper + models)
rm -rf $HOME/.local/SDG-VOX

# Remove the user configuration (command graph tree)
rm -rf $HOME/.config/SDG-VOX

# Remove docs and tips shipped with this module
rm -rf $HOME/.local/docs/SDG-VOX
rm -rf $HOME/.local/tips/SDG-VOX

# Remove the desktop entry
rm -f $HOME/.local/share/applications/vox-config.desktop

# Remove the /usr/bin/sdgvox symlink created during install
sudo unlink /usr/bin/sdgvox
