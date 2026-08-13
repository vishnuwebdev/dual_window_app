#!/usr/bin/env bash
#
# Installs a freshly-built app bundle onto this kiosk unit, replacing
# whatever is currently running, WITHOUT touching this unit's own
# config.json/db.json (admin/drop-off PINs, locker mapping, etc. — see
# lib/core/config/config_service.dart, which reads/writes those two files
# relative to the app's working directory, not from inside the bundle).
#
# Run this ON THE CLIENT'S UNIT, after copying a freshly built release
# bundle onto it (USB drive, scp, whatever transfer method you're already
# using). This script never touches git and never needs the source repo
# to be present on this unit — that's the whole point: the unit only ever
# ends up with this one compiled bundle, never the source.
#
# The bundle you pass in is whatever
#   flutter build linux --release
# produced on the BUILD machine (not this unit) — i.e. the contents of
# build/linux/<arch>/release/bundle/.
#
# Usage:
#   ./deploy_bundle.sh /path/to/new/bundle

set -euo pipefail

# Everything for this app lives under here on this unit: the persistent
# config.json/db.json, and the swappable `bundle/` folder holding the
# compiled app. Override with INSTALL_DIR=... if you install elsewhere.
INSTALL_DIR="${INSTALL_DIR:-$HOME/locker-app}"
APP_NAME="cnc_dual_screen"

new_bundle="${1:-}"
if [ -z "$new_bundle" ] || [ ! -d "$new_bundle" ]; then
  echo "Usage: $0 /path/to/new/bundle"
  echo "  (the folder containing the '$APP_NAME' executable, e.g. build/linux/arm64/release/bundle)"
  exit 1
fi

if [ ! -x "$new_bundle/$APP_NAME" ]; then
  echo "Error: '$new_bundle' doesn't contain a '$APP_NAME' executable — is this the right folder?"
  exit 1
fi

mkdir -p "$INSTALL_DIR"

# --- 1. Stop the currently running app, if any --------------------------
# Reuses this repo's own stop script (kill_app.sh) when it's sitting next
# to this one, since it already knows to kill every window's process, not
# just one — desktop_multi_window spawns each secondary window (e.g. the
# Admin window) as its own OS process re-launching the same binary.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -x "$script_dir/kill_app.sh" ]; then
  "$script_dir/kill_app.sh"
else
  pids=$(pgrep -f "$APP_NAME" || true)
  if [ -n "$pids" ]; then
    echo "Stopping $APP_NAME (pid(s): $pids)..."
    kill $pids 2>/dev/null || true
    sleep 2
    kill -9 $(pgrep -f "$APP_NAME" || true) 2>/dev/null || true
  fi
fi

# --- 2. Keep the old bundle around, just in case -------------------------
if [ -d "$INSTALL_DIR/bundle" ]; then
  rm -rf "$INSTALL_DIR/bundle.previous"
  mv "$INSTALL_DIR/bundle" "$INSTALL_DIR/bundle.previous"
  echo "Previous bundle kept at $INSTALL_DIR/bundle.previous (for rollback)."
fi

# --- 3. Install the new bundle -------------------------------------------
cp -r "$new_bundle" "$INSTALL_DIR/bundle"
echo "New bundle installed at $INSTALL_DIR/bundle."

# --- 4. Leave config.json / db.json alone ---------------------------------
# These live directly in $INSTALL_DIR (the app's working directory, see
# above), not inside bundle/, so replacing bundle/ above never touches
# them. Only exception: first install ever on this unit, when there's no
# existing config.json/db.json yet — seed them from the bundle then.
for f in config.json db.json; do
  if [ ! -f "$INSTALL_DIR/$f" ] && [ -f "$INSTALL_DIR/bundle/$f" ]; then
    cp "$INSTALL_DIR/bundle/$f" "$INSTALL_DIR/$f"
    echo "Seeded $f from the bundle (first install on this unit)."
  fi
done

# --- 5. Launch the app from $INSTALL_DIR ----------------------------------
# Launching from here (rather than from inside bundle/) is what makes the
# app find config.json/db.json next to it instead of starting fresh.
cd "$INSTALL_DIR"
nohup "$INSTALL_DIR/bundle/$APP_NAME" > "$INSTALL_DIR/app.log" 2>&1 &
disown
echo "$APP_NAME started (pid $!). Logs: $INSTALL_DIR/app.log"
