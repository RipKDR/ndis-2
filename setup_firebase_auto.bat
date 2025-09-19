@echo off
echo ========================================
echo   NDIS Connect Firebase Auto-Setup
echo ========================================
echo.

cd "c:\Users\H\ndis 2\ndis_connect"

echo Installing FlutterFire CLI...
dart pub global activate flutterfire_cli
echo.

echo Adding FlutterFire CLI to PATH for this session...
set PATH=%PATH%;%USERPROFILE%\AppData\Local\Pub\Cache\bin
echo.

echo Running FlutterFire configure...
echo This will:
echo - Connect to your Firebase project
echo - Generate proper firebase_options.dart
echo - Download google-services.json
echo.

echo Please make sure you're logged into Firebase CLI first:
echo firebase login
echo.

pause

echo Configuring Firebase for your project...
flutterfire configure ^
  --project=ndis-connect-prod ^
  --out=lib/firebase_options.dart ^
  --ios-bundle-id=au.ndis.connect ^
  --android-package-name=au.ndis.connect.ndis_connect

echo.
echo ========================================
echo Firebase configuration complete!
echo.
echo Next steps:
echo 1. Add Google Maps API key to AndroidManifest.xml
echo 2. Run: validate_android_setup.bat
echo 3. Run: build_android.bat
echo ========================================

pause