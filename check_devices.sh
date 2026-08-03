#!/usr/bin/env bash
export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"
export ANDROID_HOME="${ANDROID_HOME:-/c/Users/admin/AppData/Local/Android/Sdk}"
AVDM="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager.bat"

echo "=== installed system images ==="
ls -1 "$ANDROID_HOME/system-images" 2>&1
ls -1R "$ANDROID_HOME/system-images/android-34" 2>&1 | head -n 20

echo "=== avdmanager device profiles (filtered) ==="
"$AVDM" list device 2>/dev/null | grep -Ei 'id:|Name:' | head -n 60
