#!/usr/bin/env bash
set -e

REPO=${REPO:-"https://github.com/FayazK/ascia_ui.git"}
TARGET=/config/custom_frontend

echo "[*] Downloading build..."
rm -rf "$TARGET"
git clone --depth=1 "$REPO" "$TARGET"

echo "[*] Patching configuration.yaml..."
CONFIG=/config/configuration.yaml
grep -q "frontend:" "$CONFIG" || echo "frontend:" >> "$CONFIG"
if grep -q "development_repo:" "$CONFIG"; then
  sed -i "s|development_repo:.*|development_repo: $TARGET|" "$CONFIG"
else
  sed -i "/frontend:/a\  development_repo: $TARGET" "$CONFIG"
fi

echo "[*] Restarting Home Assistant Core..."
ha core restart

echo "[+] Done.  Custom UI in place."
exit 0
