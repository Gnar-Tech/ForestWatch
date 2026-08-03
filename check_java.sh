#!/usr/bin/env bash
echo "current JAVA_HOME=$JAVA_HOME"
echo "=== Android Studio dir ==="
ls -1 "/c/Program Files/Android/Android Studio" 2>&1
echo "=== jbr present? ==="
ls -1 "/c/Program Files/Android/Android Studio/jbr/bin/java.exe" 2>&1
echo "=== jbr java version ==="
"/c/Program Files/Android/Android Studio/jbr/bin/java.exe" -version 2>&1
