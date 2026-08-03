#!/usr/bin/env bash
SDK="${ANDROID_HOME:-/c/Users/admin/AppData/Local/Android/Sdk}"
echo "SDK=$SDK"
echo "=== emulator binary ==="
ls -la "$SDK/emulator/emulator.exe" 2>&1 || echo MISSING_EMULATOR
echo "=== list AVDs ==="
"$SDK/emulator/emulator.exe" -list-avds 2>&1
echo "=== adb binary ==="
ls -la "$SDK/platform-tools/adb.exe" 2>&1 || echo MISSING_ADB
echo "=== adb devices ==="
"$SDK/platform-tools/adb.exe" devices 2>&1
echo "=== avd dir ==="
ls -1 "$HOME/.android/avd" 2>&1 || echo NO_AVD_DIR
echo "=== system-images ==="
ls -1 "$SDK/system-images" 2>&1 || echo NO_SYSTEM_IMAGES
