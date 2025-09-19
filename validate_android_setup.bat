@echo off
echo ========================================
echo   NDIS Connect Android Setup Validator
echo ========================================
echo.

cd "c:\Users\H\ndis 2\ndis_connect"

echo [1/6] Checking Flutter installation...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter not found in PATH
    echo    Please install Flutter and add to PATH
    goto :error
) else (
    echo ✅ Flutter found
)
echo.

echo [2/6] Checking google-services.json...
if exist "android\app\google-services.json" (
    echo ✅ google-services.json found
) else (
    echo ❌ google-services.json missing
    echo    Download from Firebase Console and place in android/app/
)
echo.

echo [3/6] Checking Firebase configuration...
findstr /C:"your-android-api-key" lib\firebase_options.dart >nul 2>&1
if %errorlevel% equ 0 (
    echo ❌ Firebase API keys are still placeholders
    echo    Update lib/firebase_options.dart with real Firebase keys
) else (
    echo ✅ Firebase API keys appear to be configured
)
echo.

echo [4/6] Checking Google Maps API key...
findstr /C:"YOUR_GOOGLE_MAPS_API_KEY" android\app\src\main\AndroidManifest.xml >nul 2>&1
if %errorlevel% equ 0 (
    echo ❌ Google Maps API key is still placeholder
    echo    Update android/app/src/main/AndroidManifest.xml
) else (
    echo ✅ Google Maps API key appears to be configured
)
echo.

echo [5/6] Checking Android devices...
flutter devices | findstr "android" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Android device detected
    flutter devices | findstr "android"
) else (
    echo ⚠️  No Android devices detected
    echo    Connect device via USB with USB debugging enabled
)
echo.

echo [6/6] Testing Flutter doctor...
flutter doctor | findstr "Android"
echo.

echo ========================================
echo Setup validation complete!
echo.
echo Next steps:
echo 1. Fix any ❌ issues above
echo 2. Run: build_android.bat
echo 3. Install: flutter install
echo ========================================

:error
pause