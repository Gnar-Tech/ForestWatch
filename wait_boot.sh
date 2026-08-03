#!/usr/bin/env bash
ADB="/c/Users/admin/AppData/Local/Android/Sdk/platform-tools/adb.exe"
echo ">> Waiting for device to appear..."
"$ADB" wait-for-device
echo ">> Device connected. Waiting for full boot (sys.boot_completed)..."
for i in $(seq 1 60); do
  BOOTED=$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  if [ "$BOOTED" = "1" ]; then
    echo ">> Boot complete!"
    break
  fi
  sleep 3
done
echo "=== adb devices ==="
"$ADB" devices
