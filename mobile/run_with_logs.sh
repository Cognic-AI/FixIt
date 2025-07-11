#!/bin/bash
# Script to run Flutter app with verbose logging
# Save this as run_with_logs.sh and make it executable with: chmod +x run_with_logs.sh

echo "🚀 Starting Flutter app with verbose logging..."
echo "📱 Make sure your device/emulator is connected"
echo ""

# For Android
echo "📋 To see logs, you can also run in another terminal:"
echo "   flutter logs"
echo "   or"
echo "   adb logcat | grep -E '(flutter|FIXITMAIN|LOGIN|AUTH)'"
echo ""

# Run Flutter with verbose output
flutter run --verbose

# Alternative commands you can use:
# flutter run --debug
# flutter run --verbose --target=lib/main.dart
