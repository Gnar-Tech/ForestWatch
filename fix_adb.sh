#!/usr/bin/env bash
ADB="/c/Users/admin/AppData/Local/Android/Sdk/platform-tools/adb.exe"
echo ">> adb version:"; "$ADB" version
echo ">> kill-server..."; "$ADB" kill-server
sleep 2
echo ">> start-server..."; "$ADB" start-server
sleep 2
echo ">> reconnect offline..."; "$ADB" reconnect offline 2>&1
sleep 3
echo ">> polling device state (up to ~60s)..."
for i in $(seq 1 20); do
  STATE=$("$ADB" get-state 2>/dev/null | tr -d '\r')
  BOOTED=$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  echo "   try $i: state=$STATE boot_completed=$BOOTED"
  if [ "$BOOTED" = "1" ]; then
    echo ">> DEVICE ONLINE + BOOTED"
    break
  fi
  sleep 3
done
echo "=== final adb devices ==="
"$ADB" devices
