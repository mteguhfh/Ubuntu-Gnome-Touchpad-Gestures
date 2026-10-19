#!/usr/bin/env bash
#
# Remove Touchpad Gesture Customization and clean up the enabled-extensions list.
#
set -euo pipefail

UUID="touchpad-gesture-customization@coooolapps.com"

if [ -t 1 ]; then
    B='\033[1;34m'; N='\033[0m'
else
    B=''; N=''
fi
log() { printf "${B}==>${N} %s\n" "$*"; }

gnome-extensions disable "$UUID" 2>/dev/null || true

python3 - "$UUID" <<'PY'
import ast
import subprocess
import sys

uuid = sys.argv[1]
raw = subprocess.run(
    ["gsettings", "get", "org.gnome.shell", "enabled-extensions"],
    capture_output=True, text=True, check=True,
).stdout.strip()

enabled = [item for item in ast.literal_eval(raw) if item != uuid]
value = "[" + ", ".join("'%s'" % item for item in enabled) + "]"
subprocess.run(
    ["gsettings", "set", "org.gnome.shell", "enabled-extensions", value],
    check=True,
)
print("removed from enabled-extensions")
PY

if gnome-extensions list | grep -qx "$UUID"; then
    log "Uninstalling ${UUID}..."
    gnome-extensions uninstall "$UUID"
else
    log "Extension is not installed; nothing to uninstall."
fi

log "Done. Log out and back in to fully unload it from the running shell."
