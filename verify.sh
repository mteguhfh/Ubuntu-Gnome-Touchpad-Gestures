#!/usr/bin/env bash
#
# Diagnose the touchpad gesture setup on Ubuntu 26.10+ / GNOME 45-51.
#
set -euo pipefail

UUID="touchpad-gesture-customization@coooolapps.com"
SCHEMA="org.gnome.shell.extensions.touchpad-gesture-customization"
EXT_DIR="${HOME}/.local/share/gnome-shell/extensions/${UUID}"

if [ -t 1 ]; then
    B='\033[1;34m'; G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; N='\033[0m'
else
    B=''; G=''; Y=''; R=''; N=''
fi

ok()   { printf "${G}[ok]${N}   %s\n" "$*"; }
bad()  { printf "${R}[fail]${N} %s\n" "$*"; }
warn() { printf "${Y}[warn]${N} %s\n" "$*"; }
info() { printf "${B}[info]${N} %s\n" "$*"; }

printf '\n%s\n\n' "Touchpad gesture check"

# --- baseline ---------------------------------------------------------------

if command -v gnome-shell >/dev/null 2>&1; then
    info "GNOME Shell: $(gnome-shell --version)"
else
    bad "gnome-shell not found"
fi

info "Session type: ${XDG_SESSION_TYPE:-unknown}"
if [ "${XDG_SESSION_TYPE:-}" != "wayland" ]; then
    warn "Extension is Wayland-only. Log in with 'Ubuntu on Wayland'."
fi

if [ -d "$EXT_DIR" ]; then
    ok "Installed at $EXT_DIR"
else
    bad "Not installed. Run ./install.sh"
fi

# --- extension state --------------------------------------------------------

state="$(gnome-extensions info "$UUID" 2>/dev/null | awk -F': ' '/State:/ {print $2}' || true)"
version="$(gnome-extensions info "$UUID" 2>/dev/null | awk -F': ' '/Version:/ {print $2}' || true)"

if [ "$state" = "ACTIVE" ]; then
    ok "State: ACTIVE (version ${version})"
elif [ -n "$state" ]; then
    bad "State: ${state}"
    printf '       Check logs with:\n'
    printf '       journalctl --user -b --no-pager | grep -i gesture | tail -20\n'
else
    bad "Extension is not known to the running shell."
    printf '       Log out and log back in, then rerun this script.\n'
fi

# --- enabled list -----------------------------------------------------------

if gsettings get org.gnome.shell enabled-extensions | grep -q "$UUID"; then
    ok "Listed in enabled-extensions"
else
    bad "Missing from org.gnome.shell enabled-extensions (rerun ./install.sh)"
fi

if [ "$(gsettings get org.gnome.shell disable-user-extensions)" = "false" ]; then
    ok "User extensions are not disabled"
else
    bad "User extensions are globally disabled"
fi

# --- touchpad ---------------------------------------------------------------

send_events="$(gsettings get org.gnome.desktop.peripherals.touchpad send-events | tr -d "'")"
if [ "$send_events" = "disabled-on-external-mouse" ]; then
    warn "Touchpad is disabled when an external mouse is connected."
    printf '       Fix: gsettings set org.gnome.desktop.peripherals.touchpad send-events enabled\n'
elif [ "$send_events" = "disabled" ]; then
    bad "Touchpad is disabled entirely."
    printf '       Fix: gsettings set org.gnome.desktop.peripherals.touchpad send-events enabled\n'
else
    ok "Touchpad send-events: ${send_events}"
fi

# --- leftovers from dead extensions ----------------------------------------

for stale in touchpad_window_switcher@gonza.com; do
    if [ -d "${HOME}/.local/share/gnome-shell/extensions/${stale}" ]; then
        warn "Dead X11-era extension still installed: ${stale}"
        printf '       Remove it: gnome-extensions uninstall %s\n' "$stale"
    fi
done

# --- effective gesture mapping ---------------------------------------------

printf '\n'
if [ -d "$EXT_DIR/schemas" ] && [ -f "$EXT_DIR/schemas/gschemas.compiled" ]; then
    info "Gesture mapping"
    for key in \
        horizontal-swipe-3-fingers-gesture \
        vertical-swipe-3-fingers-gesture \
        horizontal-swipe-4-fingers-gesture \
        vertical-swipe-4-fingers-gesture \
        tap-3-finger-gesture
    do
        value="$(GSETTINGS_SCHEMA_DIR="$EXT_DIR/schemas" \
            gsettings get "$SCHEMA" "$key" 2>/dev/null | tr -d "'" || true)"
        printf '       %-38s %s\n' "$key" "${value:-unavailable}"
    done
    printf '\n       Change these in: gnome-extensions prefs %s\n' "$UUID"
else
    warn "Compiled settings schema not found; open the extension preferences once."
fi

printf '\n'
