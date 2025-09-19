@echo off
echo ========================================
echo   NDIS Connect Android Deployment
echo ========================================
echo.

cd "c:\Users\H\ndis 2\ndis_connect"

echo [STEP 1] Pre-flight validation...
call "..\validate_android_setup.bat"
echo.

echo [STEP 2] Clean previous builds...
flutter clean
echo.

echo [STEP 3] Get dependencies...
flutter pub get
echo.

echo [STEP 4] Check for compilation issues...
echo Running: flutter analyze
flutter analyze
if %errorlevel% neq 0 (
    echo ❌ Code analysis failed - fix issues before deploying
    pause
    exit /b 1
)
echo ✅ Code analysis passed
echo.

echo [STEP 5] Run basic tests...
if exist "test\" (
    echo Running: flutter test
    flutter test
    if %errorlevel% neq 0 (
        echo ⚠️  Some tests failed - review before deploying
        pause
    ) else (
        echo ✅ Tests passed
    )
) else (
    echo ⚠️  No test directory found
)
echo.

echo [STEP 6] Build APK...
echo Building release APK...
flutter build apk --release --verbose
if %errorlevel% neq 0 (
    echo ❌ APK build failed
    pause
    exit /b 1
)
echo ✅ APK build successful
echo.

echo [STEP 7] Build App Bundle (for Play Store)...
echo Building app bundle...
flutter build appbundle --release
if %errorlevel% neq 0 (
    echo ❌ App bundle build failed
    pause
    exit /b 1
)
echo ✅ App bundle build successful
echo.

echo ========================================
echo 🎉 DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo Build artifacts:
echo 📱 APK (for direct install):
echo    %cd%\build\app\outputs\flutter-apk\app-release.apk
echo.
echo 📦 App Bundle (for Play Store):
echo    %cd%\build\app\outputs\bundle\release\app-release.aab
echo.
echo Installation options:
echo 1. Direct install: flutter install
echo 2. Transfer APK to device and install
echo 3. Upload AAB to Google Play Store
echo.
echo File sizes:
for %%f in ("build\app\outputs\flutter-apk\app-release.apk") do echo APK: %%~zf bytes
for %%f in ("build\app\outputs\bundle\release\app-release.aab") do echo AAB: %%~zf bytes
echo.

pause