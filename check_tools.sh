#!/usr/bin/env bash
SDK="${ANDROID_HOME:-/c/Users/admin/AppData/Local/Android/Sdk}"
echo "=== cmdline-tools/latest/bin ==="
ls -1 "$SDK/cmdline-tools/latest/bin" 2>&1
echo "=== sdkmanager version ==="
"$SDK/cmdline-tools/latest/bin/sdkmanager.bat" --version 2>&1 | head -n 5
echo "=== installed packages (system images / platforms) ==="
"$SDK/cmdline-tools/latest/bin/sdkmanager.bat" --list_installed 2>&1 | head -n 40
