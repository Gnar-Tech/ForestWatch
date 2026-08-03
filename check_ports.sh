#!/usr/bin/env bash
ADB="/c/Users/admin/AppData/Local/Android/Sdk/platform-tools/adb.exe"
echo "=== adb devices ==="
"$ADB" devices
echo "=== listeners on 5554 / 5555 / 8081 ==="
netstat -ano | grep -E ':5554|:5555|:8081' | head -n 30
echo "=== emulator/qemu processes ==="
tasklist | grep -iE 'qemu|emulator' | head -n 20
