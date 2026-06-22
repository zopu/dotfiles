#!/usr/bin/env bash
# Install (or reinstall) the kanata LaunchDaemon so kanata runs as root at boot.
#
#   sudo ./install.sh
#
# kanata must run as root on macOS: the Karabiner-DriverKit-VirtualHIDDevice
# output socket lives in a root-only directory
# (/Library/Application Support/org.pqrs/tmp/rootonly/vhidd_server), so a
# user-context LaunchAgent cannot reach it. Hence a LaunchDaemon.
set -euo pipefail

LABEL="com.kanata"
PLIST_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/com.kanata.plist"
PLIST_DST="/Library/LaunchDaemons/${LABEL}.plist"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

mkdir -p /Library/Logs/Kanata
install -m 644 -o root -g wheel "$PLIST_SRC" "$PLIST_DST"

# Reload cleanly if already loaded.
launchctl bootout system "$PLIST_DST" 2>/dev/null || true
launchctl bootstrap system "$PLIST_DST"
launchctl enable "system/${LABEL}"

echo "Installed ${LABEL}."
echo
echo "NEXT (required the first time):"
echo "  1. System Settings > Privacy & Security > Input Monitoring"
echo "     -> add /opt/homebrew/bin/kanata (Cmd+Shift+G to type the path) and toggle ON"
echo "  2. REBOOT — daemon TCC grants only take effect on a clean boot."
echo
echo "Verify after reboot:"
echo "  sudo tail -f /Library/Logs/Kanata/kanata.out.log   # expect 'driver connected: true'"
