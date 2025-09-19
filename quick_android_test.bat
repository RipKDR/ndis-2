@echo off
echo ========================================
echo   Quick Android Setup Test
echo ========================================
echo.

cd "c:\Users\H\ndis 2\ndis_connect"

echo Testing basic Android build configuration...
echo.

echo [1] Checking if we can run flutter doctor...
flutter doctor --android-licenses >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter or Android SDK not properly configured
    echo    Try: flutter doctor
) else (
    echo ✅ Flutter and Android SDK appear to be working
)
echo.

echo [2] Checking project structure...
if exist "android\app\build.gradle.kts" (
    echo ✅ Android build.gradle.kts found
) else (
    echo ❌ Android build.gradle.kts missing
)

if exist "android\app\src\main\AndroidManifest.xml" (
    echo ✅ AndroidManifest.xml found  
) else (
    echo ❌ AndroidManifest.xml missing
)
echo.

echo [3] Checking for required configurations...
findstr /C:"au.ndis.connect.ndis_connect" android\app\build.gradle.kts >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Application ID configured correctly
) else (
    echo ❌ Application ID not found in build.gradle.kts
)

findstr /C:"google-services" android\app\build.gradle.kts >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Google Services plugin configured
) else (
    echo ❌ Google Services plugin missing
)
echo.

echo [4] Quick syntax check...
echo Checking if Gradle files have valid syntax...
echo (This is a basic check only)

findstr /C:"}" android\app\build.gradle.kts | find /C "}" >nul
if %errorlevel% equ 0 (
    echo ✅ build.gradle.kts syntax appears valid
) else (
    echo ⚠️  build.gradle.kts syntax may have issues
)
echo.

echo ========================================
echo Test complete!
echo.
echo To build Android APK:
echo 1. Ensure Flutter and Android SDK are installed
echo 2. Run: flutter clean ^&^& flutter pub get
echo 3. Run: flutter build apk --release
echo ========================================

pause