# Google Maps API Setup for Android

## 🗺️ Getting Your Google Maps API Key

### Step 1: Enable Maps API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create one)
3. Navigate to **APIs & Services** → **Library**
4. Search for "Maps SDK for Android"
5. Click and **Enable** it

### Step 2: Create API Key

1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **API Key**
3. Copy the generated API key
4. Click **Restrict Key** for security

### Step 3: Restrict API Key (Recommended)

1. **Application restrictions**:

   - Select "Android apps"
   - Add package name: `au.ndis.connect.ndis_connect`
   - Add SHA-1 certificate fingerprint (optional for development)

2. **API restrictions**:
   - Select "Restrict key"
   - Choose "Maps SDK for Android"

### Step 4: Get SHA-1 Fingerprint (for production)

Run this command in your project directory:

```bash
cd android
./gradlew signingReport
```

Or for debug builds:

```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Step 5: Update AndroidManifest.xml

Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key:

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="AIza_your_actual_api_key_here"/>
```

## 🔧 Testing Maps Integration

After setup, test maps functionality:

1. Build and install app: `flutter install`
2. Navigate to any screen using Google Maps
3. Verify map loads without errors
4. Check device logs: `flutter logs`

## ⚠️ Common Issues

1. **"Google Play services not available"**

   - Ensure device has Google Play Store
   - Update Google Play services

2. **"Map tiles not loading"**

   - Check API key in AndroidManifest.xml
   - Verify API is enabled in Cloud Console
   - Check package name restrictions

3. **"Authorization failure"**
   - Verify SHA-1 fingerprint matches
   - Check package name is correct
   - Ensure API key restrictions allow your app
