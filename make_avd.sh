#!/usr/bin/env bash
# Creates the ForestWatch AVD (system image already installed).
set -e
export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"
export ANDROID_HOME="${ANDROID_HOME:-/c/Users/admin/AppData/Local/Android/Sdk}"

AVDM="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager.bat"
IMAGE="system-images;android-34;google_apis;x86_64"
AVD_NAME="forestwatch"
DEVICE="pixel_3a"

echo ">> Creating AVD '$AVD_NAME' (device: $DEVICE)..."
echo "no" | "$AVDM" create avd -n "$AVD_NAME" -k "$IMAGE" -d "$DEVICE" --force

echo ">> Available AVDs:"
"$ANDROID_HOME/emulator/emulator.exe" -list-avds
echo ">> If you see 'forestwatch' above, the AVD was created successfully."
