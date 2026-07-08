#!/usr/bin/env bash
# vox.sh — wrapper that adds the vox package directory to sys.path and
# runs the CLI.  Symlinked to /usr/bin/sdgvox by install.sh.
exec /usr/bin/python3 -c "
import sys
from pathlib import Path
sys.path.insert(0, str(Path.home() / '.local' / 'SDG-VOX'))
from vox.cli import main
main()
" "$@"
