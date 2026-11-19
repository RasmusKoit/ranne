#!/usr/bin/env bash
# Collect watch-side evidence for a Ranne test session into one zip.
# Usage: scripts/collect-logs.sh [-s SERIAL] [-p PACKAGE] [-o OUTPUT_DIR] [-n NOTE]
set -euo pipefail

PACKAGE="dev.koit.ranne"
SERIAL=""
OUT_DIR="."
NOTE=""

usage() {
  cat <<USAGE
Collect watch-side logs and device state for a Ranne test session.

Usage: $(basename "$0") [options]

Options:
  -s SERIAL   adb device serial or ip:port (default: the only connected device)
  -p PACKAGE  watch app package (default: ${PACKAGE})
  -o DIR      directory to write the zip into (default: current directory)
  -n NOTE     free-text note stored with the logs, e.g. "after overnight test"
  -h, --help  show this help

Connect to the watch first:
  adb pair <ip:pairing-port>     # once, code from the Wireless debugging screen
  adb connect <ip:port>

Collected: device properties, app version and permissions, battery-optimisation
exemption, Bluetooth bond state, Doze state, the app's logcat, and a full logcat.
The zip can contain notification text and Bluetooth addresses. Read it before
attaching it to a public issue.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -s) SERIAL="${2:?-s needs a value}"; shift 2 ;;
    -p) PACKAGE="${2:?-p needs a value}"; shift 2 ;;
    -o) OUT_DIR="${2:?-o needs a value}"; shift 2 ;;
    -n) NOTE="${2:?-n needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

command -v adb >/dev/null 2>&1 || { echo "adb not found. Install Android platform-tools." >&2; exit 1; }
command -v zip >/dev/null 2>&1 || { echo "zip not found." >&2; exit 1; }

ADB=(adb)
[ -n "$SERIAL" ] && ADB=(adb -s "$SERIAL")

if ! "${ADB[@]}" get-state >/dev/null 2>&1; then
  echo "No watch reachable over adb. Run 'adb devices' and connect first (see --help)." >&2
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
DEST="$WORK/ranne-logs-$STAMP"
mkdir -p "$DEST"

# Run a device command, keep going if it fails, and record the failure in the file.
capture() {
  local file="$1"; shift
  if ! "${ADB[@]}" shell "$@" >"$DEST/$file" 2>&1; then
    echo "[collect-logs] command failed: $*" >>"$DEST/$file"
  fi
}

{
  echo "collected_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "package=$PACKAGE"
  echo "note=$NOTE"
  echo "host=$(uname -sr)"
} >"$DEST/session.txt"

echo "Collecting device properties..."
{
  for prop in ro.product.manufacturer ro.product.model ro.product.device \
              ro.build.display.id ro.build.version.release ro.build.version.sdk \
              ro.build.version.security_patch ro.build.fingerprint; do
    printf '%s=%s\n' "$prop" "$("${ADB[@]}" shell getprop "$prop" 2>/dev/null | tr -d '\r')"
  done
} >"$DEST/device-props.txt"

echo "Collecting app state..."
capture app-package.txt dumpsys package "$PACKAGE"
capture battery-exemption.txt dumpsys deviceidle whitelist
capture deviceidle.txt dumpsys deviceidle
capture battery.txt dumpsys battery
capture bluetooth.txt dumpsys bluetooth_manager
capture app-services.txt dumpsys activity services "$PACKAGE"
capture companion-associations.txt dumpsys companiondevice

if grep -q "$PACKAGE" "$DEST/battery-exemption.txt" 2>/dev/null; then
  echo "battery_optimisation_exempt=yes" >>"$DEST/session.txt"
else
  echo "battery_optimisation_exempt=no" >>"$DEST/session.txt"
fi

echo "Collecting logcat..."
APP_PID="$("${ADB[@]}" shell pidof "$PACKAGE" 2>/dev/null | tr -d '\r' || true)"
echo "app_pid=${APP_PID:-not-running}" >>"$DEST/session.txt"
if [ -n "$APP_PID" ]; then
  "${ADB[@]}" logcat -d -v threadtime --pid="$APP_PID" >"$DEST/logcat-app.txt" 2>&1 || true
else
  echo "App process not running; no per-process logcat." >"$DEST/logcat-app.txt"
fi
"${ADB[@]}" logcat -d -v threadtime >"$DEST/logcat-full.txt" 2>&1 || true
grep -E 'Bluetooth|bt_|BtGatt|bond|SMP|CompanionDevice' "$DEST/logcat-full.txt" \
  >"$DEST/logcat-bluetooth.txt" 2>/dev/null || true

mkdir -p "$OUT_DIR"
ZIP_PATH="$(cd "$OUT_DIR" && pwd)/ranne-logs-$STAMP.zip"
(cd "$WORK" && zip -qr "$ZIP_PATH" "ranne-logs-$STAMP")

echo "Wrote $ZIP_PATH"
echo "It can contain notification text and Bluetooth addresses. Read it before sharing."
