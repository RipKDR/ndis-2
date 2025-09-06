@echo off
echo Setting up Firebase for NDIS Connect...

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Firebase CLI not found. Installing...
    npm install -g firebase-tools
)

REM Check if FlutterFire CLI is installed
dart pub global list | findstr flutterfire_cli >nul 2>&1
if %errorlevel% neq 0 (
    echo FlutterFire CLI not found. Installing...
    dart pub global activate flutterfire_cli
)

echo.
echo Please login to Firebase:
firebase login

echo.
echo Creating Firebase projects...

REM Create development project
echo Creating development project...
firebase projects:create ndis-connect-dev --display-name "NDIS Connect Development"

REM Create staging project
echo Creating staging project...
firebase projects:create ndis-connect-staging --display-name "NDIS Connect Staging"

REM Create production project
echo Creating production project...
firebase projects:create ndis-connect-prod --display-name "NDIS Connect Production"

echo.
echo Configuring FlutterFire for each environment...

cd ndis_connect

REM Configure development
echo Configuring development environment...
flutterfire configure --project=ndis-connect-dev --platforms=android,ios,web

REM Configure staging
echo Configuring staging environment...
flutterfire configure --project=ndis-connect-staging --platforms=android,ios,web

REM Configure production
echo Configuring production environment...
flutterfire configure --project=ndis-connect-prod --platforms=android,ios,web

echo.
echo Setting up Firebase services...

REM Set up Firestore
echo Setting up Firestore...
firebase use ndis-connect-dev
firebase deploy --only firestore:rules

REM Set up Remote Config
echo Setting up Remote Config...
firebase deploy --only remoteconfig

echo.
echo Firebase setup complete!
echo.
echo Next steps:
echo 1. Enable Authentication in Firebase Console
echo 2. Enable Analytics in Firebase Console
echo 3. Enable Crashlytics in Firebase Console
echo 4. Configure Cloud Messaging
echo 5. Set up Storage rules
echo.
echo Run 'firebase emulators:start' to test locally
echo Run 'firebase deploy' to deploy to production

pause
