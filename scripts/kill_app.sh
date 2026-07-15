#!/usr/bin/env bash
#
# Stops the multi_window_app kiosk on Linux (Raspberry Pi/arm64 or any
# Linux desktop build). Matches by process name rather than PID file since
# the `desktop_multi_window` plugin spawns each secondary window (e.g. the
# Admin window) as its own OS process, re-launching the same binary with
# extra arguments — a single `kill <one pid>` would leave those running.
#
# Usage:
#   ./scripts/stop_app.sh
#
# Tries a graceful SIGTERM first (lets the app finish any in-flight
# config.json/db.json writes and close its gRPC channel cleanly), then
# force-kills anything still alive after a few seconds.

set -uo pipefail

APP_NAME="multi_window_app"

pids=$(pgrep -f "$APP_NAME" || true)

if [ -z "$pids" ]; then
  echo "No running $APP_NAME process found."
  exit 0
fi

echo "Stopping $APP_NAME (pid(s): $pids)..."
kill $pids 2>/dev/null

# Wait up to 5s for a clean exit before forcing it.
for _ in $(seq 1 10); do
  sleep 0.5
  pids=$(pgrep -f "$APP_NAME" || true)
  [ -z "$pids" ] && break
done

pids=$(pgrep -f "$APP_NAME" || true)
if [ -n "$pids" ]; then
  echo "Still running after graceful stop — force killing: $pids"
  kill -9 $pids 2>/dev/null
fi

echo "$APP_NAME stopped."
