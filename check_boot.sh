#!/usr/bin/env bash
ADB="/c/Users/admin/AppData/Local/Android/Sdk/platform-tools/adb.exe"
echo "=== adb devices ==="
"$ADB" devices
echo "=== sys.boot_completed ==="
"$ADB" -s emulator-5554 shell getprop sys.boot_completed 2>&1 | tr -d '\r'
echo "=== bootanim ==="
"$ADB" -s emulator-5554 shell getprop init.svc.bootanim 2>&1 | tr -d '\r'
