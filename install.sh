#!/usr/bin/env bash
#
# Install Touchpad Gesture Customization on Ubuntu 26.10+ / GNOME 45-51 (Wayland).
# The extension itself is a third-party project, not bundled here:
#   https://github.com/HieuTNg/touchpad-gesture-customization
#
set -euo pipefail

UUID="touchpad-gesture-customization@coooolapps.com"
UPSTREAM="https://github.com/HieuTNg/touchpad-gesture-customization"
DRY_RUN=0

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            printf 'Usage: %s [--dry-run]\n' "$0"
            exit 0
            ;;
        *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
    esac
done

if [ -t 1 ]; then
    B='\033[1;34m'; Y='\033[1;33m'; R='\033[1;31m'; N='\033[0m'
else
    B=''; Y=''; R=''; N=''
fi

log()  { printf "${B}==>${N} %s\n" "$*"; }
warn() { printf "${Y}[!]${N} %s\n" "$*" >&2; }
die()  { printf "${R}[x]${N} %s\n" "$*" >&2; exit 1; }

need() {
    command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"
}

need curl
need jq
need python3
need gnome-extensions
need gnome-shell

# --- environment checks -----------------------------------------------------

session="${XDG_SESSION_TYPE:-unknown}"
if [ "$session" != "wayland" ]; then
    die "This extension only supports Wayland. Current session: $session.
     Log out and pick 'Ubuntu on Wayland' on the login screen."
fi

shell_version="$(gnome-shell --version | awk '{print $3}' | cut -d. -f1)"
case "$shell_version" in
    ''|*[!0-9]*) die "Could not detect GNOME Shell version." ;;
esac
log "GNOME Shell ${shell_version} on Wayland"

if [ "$shell_version" -lt 45 ]; then
    die "GNOME ${shell_version} is too old. This guide targets GNOME 45-51."
fi

# --- resolve the version that matches this shell ----------------------------

log "Resolving extension version for GNOME ${shell_version}..."
info="$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=${UUID}&shell_version=${shell_version}")" \
    || die "Could not reach extensions.gnome.org."

pk="$(jq -r --arg v "$shell_version" '.shell_version_map[$v].pk // empty' <<<"$info")"
ext_version="$(jq -r --arg v "$shell_version" '.shell_version_map[$v].version // empty' <<<"$info")"

if [ -z "$pk" ]; then
    die "No build of ${UUID} for GNOME ${shell_version} yet.
     Check ${UPSTREAM} for progress."
fi
log "Found version ${ext_version} (build ${pk})"

if [ "$DRY_RUN" -eq 1 ]; then
    log "Dry run: would install ${UUID} v${ext_version} and register it for auto-enable."
    exit 0
fi

# --- download and install ---------------------------------------------------

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

log "Downloading..."
curl -fsSL -o "${tmpdir}/extension.zip" \
    "https://extensions.gnome.org/download-extension/${UUID}.shell-extension.zip?version_tag=${pk}"

log "Installing to ~/.local/share/gnome-shell/extensions/${UUID}..."
gnome-extensions install --force "${tmpdir}/extension.zip"

# --- register for auto-enable ----------------------------------------------

log "Registering for auto-enable..."
python3 - "$UUID" <<'PY'
import ast
import subprocess
import sys

uuid = sys.argv[1]
raw = subprocess.run(
    ["gsettings", "get", "org.gnome.shell", "enabled-extensions"],
    capture_output=True, text=True, check=True,
).stdout.strip()

enabled = ast.literal_eval(raw)
if uuid in enabled:
    print("already registered")
else:
    enabled.append(uuid)
    value = "[" + ", ".join("'%s'" % item for item in enabled) + "]"
    subprocess.run(
        ["gsettings", "set", "org.gnome.shell", "enabled-extensions", value],
        check=True,
    )
    print("registered")
PY

# --- next step --------------------------------------------------------------

state="$(gnome-extensions info "$UUID" 2>/dev/null | awk -F': ' '/State:/ {print $2}' || true)"
if [ "$state" = "ACTIVE" ]; then
    log "Extension is ACTIVE. Swipe with three fingers and you are done."
else
    cat <<EOF

${B}==>${N} Installed. One more step: log out and log back in.

    GNOME Shell only scans extensions at session start, and on Wayland
    the shell cannot be restarted without killing the session.

    After logging back in, verify with:

        ./verify.sh
EOF
fi
