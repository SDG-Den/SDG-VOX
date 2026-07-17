Package Name: sdg-vox
Descriptive Name: SDG Voice Command System
Source: https://github.com/SDG-Den/SDG-VOX
Maintainer: SDGDen
Version:0.2.2

Dependencies: 
python, python-gobject, python-cairo, gst-plugins-base, gst-plugins-good, gtk-layer-shell, pipewire, pipewire-pulse, ydotool, whisper.cpp (whisper-server)

Description: 
Wake-word activated, fully offline voice command daemon using whisper.cpp for speech-to-text. Features a tree-based command graph supporting exec, shell_exec, and type actions. GTK3 config editor with Cairo flowchart view. Default wake word is "system command" (aliases: cmd, computer, i cast, highcast). Supports prefix/suffix modifiers (administrator→sudo, silent→setsid, background→&, detach).
