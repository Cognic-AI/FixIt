@echo off
REM Script to run Flutter app with verbose logging on Windows
REM Save this as run_with_logs.bat

echo 🚀 Starting Flutter app with verbose logging...
echo 📱 Make sure your device/emulator is connected
echo.

echo 📋 To see logs, you can also run in another terminal:
echo    flutter logs
echo    or
echo    adb logcat ^| findstr "flutter"
echo.

REM Run Flutter with verbose output
flutter run --verbose

REM Alternative commands you can use:
REM flutter run --debug
REM flutter run --verbose --target=lib/main.dart
