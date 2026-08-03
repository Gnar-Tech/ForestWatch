#!/usr/bin/env bash
# ForestWatch — one-time Android emulator setup (Git Bash on Windows).
# Fixes JAVA_HOME, installs a system image, and creates an AVD for Expo.
set -e

# 1) Correct Java (Android Studio ships JDK 21 as "jbr", not "jre").
export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"
export ANDROID_HOME="${ANDROID_HOME:-/c/Users/admin/AppData/Local/Android/Sdk}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

SDKM="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager.bat"
AVDM="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager.bat"
IMAGE="system-images;android-34;google_apis;x86_64"
AVD_NAME="forestwatch"
DEVICE="pixel_7"

echo ">> Using JAVA_HOME=$JAVA_HOME"
echo ">> Using ANDROID_HOME=$ANDROID_HOME"

echo ">> Accepting SDK licenses..."
yes | "$SDKM" --licenses >/dev/null || true

echo ">> Installing platform-tools, emulator, platform 34, and system image (this downloads ~1GB)..."
"$SDKM" "platform-tools" "emulator" "platforms;android-34" "$IMAGE"

echo ">> Creating AVD '$AVD_NAME' (device: $DEVICE)..."
echo "no" | "$AVDM" create avd -n "$AVD_NAME" -k "$IMAGE" -d "$DEVICE" --force

echo ">> Available AVDs:"
"$ANDROID_HOME/emulator/emulator.exe" -list-avds

echo ""
echo ">> DONE. To launch the emulator:"
echo "     \"$ANDROID_HOME/emulator/emulator.exe\" -avd $AVD_NAME &"
echo ">> Then, in the mobile/ folder:  npx expo start --android"
