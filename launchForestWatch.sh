#!/usr/bin/env bash

PROJECT_ROOT="/c/data/A-Coding/webdev/ForestWatch"
MOBILE_DIR="$PROJECT_ROOT/mobile"
BACKEND_DIR="$PROJECT_ROOT/backend"
AVD_NAME="forestwatch"
ANDROID_HOME="${ANDROID_HOME:-/c/Users/admin/AppData/Local/Android/Sdk}"
EMULATOR="$ANDROID_HOME/emulator/emulator.exe"
ADB="$ANDROID_HOME/platform-tools/adb.exe"

echo "=== ForestWatch Launcher ==="
echo ""
# Prevent 'set -e' style exits
# Allow grep to return no matches without failing

# 1. Check if emulator is already running
EMULATOR_RUNNING=$("$ADB" devices 2>/dev/null | grep -c "emulator-5554.*device" || true)

if [ "$EMULATOR_RUNNING" -eq 0 ]; then
  echo "[1/5] Starting emulator (forestwatch)..."
  "$EMULATOR" -avd "$AVD_NAME" -gpu host -no-snapshot &
  EMU_PID=$!

  echo "       Waiting for emulator to boot (this can take 60-90s)..."
  "$ADB" wait-for-device
  echo "       Device detected, waiting for boot completion..."

  # Wait for boot completion with timeout (max ~180s)
  BOOT_TIMEOUT=90
  BOOT_COUNT=0
  while [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
    sleep 2
    BOOT_COUNT=$((BOOT_COUNT + 1))
    if [ $BOOT_COUNT -ge $BOOT_TIMEOUT ]; then
      echo "       WARNING: Boot timeout reached. Continuing anyway..."
      break
    fi
  done
  echo "       Emulator booted!"
  # Give UI a few extra seconds to settle
  sleep 5
else
  echo "[1/5] Emulator already running."
fi

echo ""

# 2. Set up adb reverse port forwarding
echo "[2/5] Setting up adb reverse (tcp:4000)..."
"$ADB" reverse tcp:4000 tcp:4000
echo "       Done!"

echo ""

# 3. Set mock GPS location (Lake of the Woods Resort, OR)
echo "[3/5] Setting mock GPS to Lake of the Woods Resort, OR..."
"$ADB" emu geo fix -122.212 42.3785
echo "       Done!"

echo ""

# 4. Start backend server
echo "[4/5] Starting backend server..."
cd "$BACKEND_DIR"
if [ -f "node_modules/.package-lock.json" ]; then
  npm run dev &
  BACKEND_PID=$!
  echo "       Backend started (PID: $BACKEND_PID) - waiting 3s..."
  sleep 3
else
  echo "       WARNING: node_modules not found. Run 'npm install' in backend/ first."
  echo "       Skipping backend start."
fi

echo ""

# 5. Start Expo dev client and launch app on emulator
echo "[5/5] Starting Expo (dev build)..."
cd "$MOBILE_DIR"
npx expo start --dev-client --android

# Cleanup on exit
trap "echo ''; echo 'Shutting down...'; kill $BACKEND_PID 2>/dev/null; echo 'Done.'; exit 0" INT TERM
