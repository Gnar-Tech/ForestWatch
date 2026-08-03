#!/usr/bin/env bash

ADB="${ANDROID_HOME:-/c/Users/admin/AppData/Local/Android/Sdk}/platform-tools/adb.exe"

echo "=== ForestWatch Shutdown ==="
echo ""

# Kill Expo / Metro bundler
echo "[1/3] Stopping Expo / Metro..."
taskkill.exe //F //IM node.exe 2>/dev/null && echo "       Node processes killed." || echo "       No node processes found."
echo ""

# Kill backend (runs under node, already killed above, but check for any npm)
echo "[2/3] Stopping backend..."
taskkill.exe //F //IM npm.exe 2>/dev/null && echo "       npm processes killed." || echo "       No npm processes found."
echo ""

# Kill emulator
echo "[3/3] Stopping emulator..."
"$ADB" emu kill 2>/dev/null && echo "       Emulator killed." || echo "       No emulator running or already stopped."
"$ADB" kill-server 2>/dev/null
echo ""

echo "=== All ForestWatch processes stopped ==="
