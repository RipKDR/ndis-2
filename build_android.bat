@echo off
echo Building NDIS Connect for Android...
echo.

cd "c:\Users\H\ndis 2\ndis_connect"

echo Cleaning previous builds...
flutter clean
echo.

echo Getting dependencies...
flutter pub get
echo.

echo Checking Flutter Doctor...
flutter doctor
echo.

echo Building APK for Android...
flutter build apk --release
echo.

echo Build complete! APK location:
echo %cd%\build\app\outputs\flutter-apk\app-release.apk
echo.

echo To install on Android device:
echo 1. Enable Developer Options and USB Debugging on your Android device
echo 2. Connect your device via USB
echo 3. Run: flutter install
echo.

pause