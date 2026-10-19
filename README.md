# Touchpad Gestures for Ubuntu 26.10+ (GNOME 51, Wayland)

Three-finger touchpad gestures that feel like Windows, on modern Ubuntu.

This repo is not a new GNOME extension. It installs and configures the
maintained upstream extension [Touchpad Gesture
Customization](https://github.com/HieuTNg/touchpad-gesture-customization),
picks the build that matches your GNOME Shell version, and checks that it
actually loaded.

Tested on **Ubuntu 26.10, GNOME Shell 51.0, Wayland**.

## Quick start

```bash
git clone https://github.com/mteguhfh/Ubuntu-Gnome-Touchpad-Gestures.git
cd ubuntu-gnome-touchpad-gestures
./install.sh
```

Then **log out and log back in**. GNOME Shell only scans extensions at
session start, and on Wayland the shell cannot be restarted without ending
the session.

Verify afterwards:

```bash
./verify.sh
```

## Gestures

Defaults after install:

| Gesture | Action |
| --- | --- |
| 3 fingers left/right | Switch windows (Alt+Tab) |
| 3 fingers up/down | Overview / Task View |
| 4 fingers left/right | Switch workspaces |
| 3 or 4 finger pinch | Show desktop |
| 3 finger tap | Unassigned (optional) |

Change them with:

```bash
gnome-extensions prefs touchpad-gesture-customization@coooolapps.com
```

Or through the Extension Manager app.

## Requirements

- GNOME Shell **45-51** on **Wayland**
- `curl`, `jq`, `python3`, `unzip`
- An internet connection (the extension is downloaded from
  extensions.gnome.org)

Ubuntu 26.10 ships all of these by default.

## Why not the old extension?

The commonly shared
[`gonzaarcr/touchpad-window-switcher-gnome-ext`](https://github.com/gonzaarcr/touchpad-window-switcher-gnome-ext)
targets GNOME Shell **3.32-3.38** and was written before GNOME 45 changed
the extension API to ES modules. It does not load on GNOME 45+, and there is
no amount of metadata patching that makes it work.

X11 gesture tools such as `touchegg` and `libinput-gestures` are also not an
option on Ubuntu's default Wayland session.

The upstream extension used here is actively maintained: GNOME 51 support
was merged in October 2026.

## Manual install

If you prefer not to run the script:

```bash
# 1. Find the build for your shell version (example: 51)
curl -s 'https://extensions.gnome.org/extension-info/?uuid=touchpad-gesture-customization@coooolapps.com&shell_version=51'

# 2. Download it with the pk from shell_version_map
curl -L -o gesture.zip \
  'https://extensions.gnome.org/download-extension/touchpad-gesture-customization@coooolapps.com.shell-extension.zip?version_tag=<pk>'

# 3. Install
gnome-extensions install --force gesture.zip

# 4. Register for auto-enable, then log out and back in
```

## Troubleshooting

Check the current state first:

```bash
./verify.sh
```

**Extension is installed but not active.** Log out and back in. The
`ReloadExtension` D-Bus method is deprecated and returns
`org.freedesktop.DBus.Error.NotSupported` on GNOME 51.

**Extension crashed at startup.** Read the log:

```bash
journalctl --user -b --no-pager | grep -i gesture | tail -20
```

**Gestures stop working when a mouse is plugged in.**
The touchpad may be set to turn off when an external mouse is present:

```bash
gsettings set org.gnome.desktop.peripherals.touchpad send-events enabled
```

**Nothing happens on the lock screen or in some apps.** Gestures belong to
the GNOME Shell session, not to individual applications.

**On X11.** This extension does not support X11. Log in with
"Ubuntu on Wayland".

## Uninstall

```bash
./uninstall.sh
```

## Credits

- [HieuTNg/touchpad-gesture-customization](https://github.com/HieuTNg/touchpad-gesture-customization) -
  the actual extension (GPL-3.0), a maintained fork of
  [gnome-gesture-improvements](https://github.com/harshadgavali/gnome-gesture-improvements)
- [extensions.gnome.org](https://extensions.gnome.org) - official extension
  distribution

This repository only contains install and diagnostic scripts. It is not
affiliated with the upstream project.

## License

MIT, for the scripts in this repository. The extension downloaded at install
time is licensed separately under GPL-3.0.
