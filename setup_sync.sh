#!/usr/bin/env bash
ADB="/c/Users/admin/AppData/Local/Android/Sdk/platform-tools/adb.exe"
MOBILE_ENV="/c/data/A-Coding/webdev/ForestWatch/mobile/.env"

echo ">> Writing $MOBILE_ENV"
echo "EXPO_PUBLIC_API_URL=http://localhost:4000" > "$MOBILE_ENV"
cat "$MOBILE_ENV"

echo ">> adb devices:"
"$ADB" devices

echo ">> Setting up adb reverse tunnels (device localhost -> PC)..."
"$ADB" reverse tcp:8081 tcp:8081
"$ADB" reverse tcp:4000 tcp:4000
echo ">> Active reverse tunnels:"
"$ADB" reverse --list
