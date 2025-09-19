# Android Setup Guide for NDIS Connect

## 🔧 Required Configurations

### Step 1: Firebase Configuration

#### A. Download google-services.json

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your `ndis-connect-prod` project
3. Click ⚙️ Settings → Project Settings
4. Scroll to "Your apps" section
5. Click Android app or "Add app" if none exists
6. Use package name: `au.ndis.connect.ndis_connect`
7. Download `google-services.json`
8. Place it in: `ndis_connect/android/app/google-services.json`

#### B. Get Firebase API Keys

In Firebase Console → Project Settings → General tab:

- Copy the **Android API Key**
- Copy the **App ID**
- Copy the **Sender ID**

### Step 2: Google Maps API

#### A. Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Enable "Maps SDK for Android"
4. Create API Key in Credentials
5. Restrict key to Android apps with your package name

### Step 3: Update Configuration Files

Replace placeholder values in:

- `lib/firebase_options.dart` (Android section)
- `android/app/src/main/AndroidManifest.xml` (Google Maps API key)

### Step 4: Build & Test

```bash
# Run the build script
build_android.bat

# Or manually:
cd ndis_connect
flutter clean
flutter pub get
flutter build apk --release
```

### Step 5: Install on Device

```bash
# Connect Android device via USB (Developer mode + USB debugging enabled)
flutter install

# Or install APK manually:
# Transfer build/app/outputs/flutter-apk/app-release.apk to device
```

## 🔍 Troubleshooting

### Common Issues:

1. **"google-services.json not found"** → Download from Firebase Console
2. **"GoogleMap API key not found"** → Add to AndroidManifest.xml
3. **"Firebase project not found"** → Check projectId in firebase_options.dart
4. **"App not installing"** → Enable USB debugging on device

### Verify Setup:

- [ ] google-services.json in android/app/
- [ ] Real API keys in firebase_options.dart
- [ ] Google Maps API key in AndroidManifest.xml
- [ ] Device connected and recognized: `flutter devices`
