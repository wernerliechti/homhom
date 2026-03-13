# Firebase Android Signing Setup

Your app is getting **UNAUTHENTICATED** errors from Cloud Functions because Firebase doesn't recognize your Android app's signing certificate.

## Problem

Firebase uses **SHA-1 fingerprint** to verify that requests are coming from your legitimate app. Without this, authentication fails on the server side.

## Solution

### Step 1: Get Your Debug SHA-1 Fingerprint

You have two options:

#### Option A: Using Flutter (Easiest)
```bash
cd android
./gradlew signingReport
```

Look for the `debugAndroidTest` or `debug` section. You'll see:
```
Variant: debugAndroidTest
Config: debug
Store: /path/to/.android/debug.keystore
Alias: androiddebugkey
MD5: ...
SHA1: AB:CD:EF:12:34:56:...  ← THIS ONE
SHA-256: ...
```

Copy the **SHA1** value (the one with colons, like `AB:CD:EF:12:34:56:...`)

#### Option B: Using Java Keytool
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

You should get output like:
```
SHA1: AB:CD:EF:12:34:56:...
```

### Step 2: Add to Firebase Console

1. **Go to Firebase Console** → https://console.firebase.google.com
2. Select your project: `homhom-app`
3. Go to **Project Settings** (gear icon, top left)
4. Select **Android** app from the list
5. Scroll down to **SHA certificate fingerprints**
6. Click **Add fingerprint**
7. Paste your **SHA-1** value (from Step 1)
8. **Save**

✅ Firebase will now recognize your debug app!

### Step 3: Rebuild and Test

```bash
flutter clean
flutter pub get
flutter run
```

Try analyzing a meal—it should now work!

## Note: Release Signing

When you build for release, you'll use a different signing key. You'll need to:

1. Generate a release key (if you haven't):
   ```bash
   keytool -genkey -v -keystore ~/release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
   ```

2. Get the SHA-1 from the release key:
   ```bash
   keytool -list -v -keystore ~/release.jks -keyalg RSA -alias my-key-alias
   ```

3. Add this SHA-1 to Firebase Console as well

## Troubleshooting

**Still getting UNAUTHENTICATED?**
- Make sure you copied the SHA1 **exactly** (with colons)
- Wait 5-10 minutes for Firebase to propagate
- Try `flutter clean` and rebuild
- Uninstall the app from your device and reinstall

**Getting a different error?**
- Check that Anonymous Auth is enabled (Authentication → Sign-in method)
- Verify Firestore security rules allow authenticated users
- Check Cloud Function logs in Firebase Console
