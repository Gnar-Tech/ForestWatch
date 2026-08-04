#!/usr/bin/env bash

ADB="${ANDROID_HOME:-/c/Users/admin/AppData/Local/Android/Sdk}/platform-tools/adb.exe"

echo "=== ForestWatch Shutdown ==="
echo ""

# Kill Expo / Metro bundler
echo "[1/4] Stopping Expo / Metro..."
taskkill.exe //F //IM node.exe 2>/dev/null && echo "       Node processes killed." || echo "       No node processes found."
echo ""

# Kill backend (runs under node, already killed above, but check for any npm)
echo "[2/4] Stopping backend..."
taskkill.exe //F //IM npm.exe 2>/dev/null && echo "       npm processes killed." || echo "       No npm processes found."
echo ""

# Kill emulator
echo "[3/4] Stopping emulator..."
"$ADB" emu kill 2>/dev/null && echo "       Emulator killed." || echo "       No emulator running or already stopped."
"$ADB" kill-server 2>/dev/null
echo ""

# Stop PostGIS container (leave Docker Desktop running)
echo "[4/4] Stopping PostGIS container..."
docker stop forestwatch-db 2>/dev/null && echo "       Container stopped." || echo "       No container running or Docker not available."
echo ""

echo "=== All ForestWatch processes stopped ==="
