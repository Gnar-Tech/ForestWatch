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

# 0. Check Docker & PostGIS database
echo "[0/6] Checking Docker & PostGIS database..."
if ! docker info >/dev/null 2>&1; then
  echo "       WARNING: Docker daemon not running. Start Docker Desktop manually if you need the backend database."
  echo "       Skipping PostGIS startup."
else
  echo "       Docker is running."
  cd "$BACKEND_DIR"
  # Check if the DB container is already running
  DB_RUNNING=$(docker ps --filter "name=forestwatch-db" --filter "status=running" -q 2>/dev/null || true)
  if [ -z "$DB_RUNNING" ]; then
    echo "       Starting PostGIS container..."
    docker compose up -d
    echo "       Waiting for database to be ready..."
    DB_WAIT=0
    while [ $DB_WAIT -lt 15 ]; do
      if docker exec forestwatch-db pg_isready -U forestwatch -d forestwatch >/dev/null 2>&1; then
        echo "       Database is ready!"
        break
      fi
      sleep 2
      DB_WAIT=$((DB_WAIT + 1))
    done
  else
    echo "       PostGIS container already running."
  fi
  cd "$PROJECT_ROOT"
fi
echo ""

# 1. Check if emulator is already running
EMULATOR_RUNNING=$("$ADB" devices 2>/dev/null | grep -c "emulator-5554.*device" || true)

if [ "$EMULATOR_RUNNING" -eq 0 ]; then
  echo "[1/6] Starting emulator (forestwatch)..."
  "$EMULATOR" -avd "$AVD_NAME" -gpu host -no-snapshot -no-boot-anim &
  EMU_PID=$!

  echo "       Waiting for emulator to boot (this can take 60-90s)..."
  "$ADB" wait-for-device
  echo "       Device detected, applying UI settings..."
  # Try to suppress ANR popup as early as possible
  "$ADB" shell settings put secure anr_show_background false 2>/dev/null || true
  echo "       Waiting for boot completion..."

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
  # Give UI time to settle, auto-dismiss any ANR popups
  echo "       Letting UI settle (checking for ANR popups for 20s)..."
  SETTLE_WAIT=0
  while [ $SETTLE_WAIT -lt 10 ]; do
    # Check if an ANR dialog is showing and dismiss it by pressing "Wait" (button 2)
    ANR=$("$ADB" shell dumpsys window 2>/dev/null | grep -i "anr\|not responding\|Application Error" || true)
    if [ -n "$ANR" ]; then
      echo "       ANR dialog detected — auto-dismissing (pressing Wait)..."
      "$ADB" shell input keyevent KEYCODE_DPAD_RIGHT 2>/dev/null
      "$ADB" shell input keyevent KEYCODE_ENTER 2>/dev/null
      sleep 2
    fi
    sleep 2
    SETTLE_WAIT=$((SETTLE_WAIT + 1))
  done
  # Disable animations to speed up UI
  "$ADB" shell settings put global window_animation_scale 0 2>/dev/null || true
  "$ADB" shell settings put global transition_animation_scale 0 2>/dev/null || true
  # Disable bloatware that shows popups/tutorials on boot
  "$ADB" shell pm disable-user com.google.android.apps.photos 2>/dev/null || true
  "$ADB" shell pm disable-user com.google.android.youtube 2>/dev/null || true
  "$ADB" shell pm disable-user com.google.android.apps.youtube.music 2>/dev/null || true
  # Go to home screen
  "$ADB" shell input keyevent KEYCODE_HOME 2>/dev/null
  echo "       UI ready!"
else
  echo "[1/6] Emulator already running."
fi

echo ""

# 2. Set up adb reverse port forwarding
echo "[2/6] Setting up adb reverse (tcp:4000)..."
"$ADB" reverse tcp:4000 tcp:4000
echo "       Done!"

echo ""

# 3. Set mock GPS location (Lake of the Woods Resort, OR)
echo "[3/6] Setting mock GPS to Lake of the Woods Resort, OR..."
"$ADB" emu geo fix -122.212 42.3785
echo "       Done!"

echo ""

# 4. Start backend server
echo "[4/6] Starting backend server..."
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
echo "[5/6] Starting Expo (dev build)..."
cd "$MOBILE_DIR"
npx expo start --dev-client --android

# Cleanup on exit
trap "echo ''; echo 'Shutting down...'; kill $BACKEND_PID 2>/dev/null; echo 'Done.'; exit 0" INT TERM
