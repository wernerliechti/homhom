# Android Signing Setup for HomHom

## Step 1: Generate Signing Key

Run this command from the `android/` directory:

```bash
cd ~/homhom/android
keytool -genkey -v -keystore homhom-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias homhom-release-key
```

You'll be prompted for:
- Store password (make it strong, e.g., `MySecurePass123!`)
- Key password (usually same as store password)
- First and last name
- Organizational unit
- Organization
- City/locality
- State/province
- Country code (CH for Switzerland)

**⚠️ IMPORTANT**: Save these passwords! You'll need them for releases.

## Step 2: Update Passwords in key.properties

Open `android/key.properties`:

```properties
storeFile=homhom-release-key.jks
storePassword=YOUR_STORE_PASSWORD_HERE
keyAlias=homhom-release-key
keyPassword=YOUR_KEY_PASSWORD_HERE
```

Replace `YOUR_STORE_PASSWORD_HERE` and `YOUR_KEY_PASSWORD_HERE` with your passwords.

## Step 3: Test Build

```bash
flutter clean
flutter build appbundle --release
```

Output will be at: `build/app/outputs/bundle/release/app-release.aab`

## Step 4: Build and Deploy

Once you have the `.aab` file, upload it to Google Play Console.

---

## ⚠️ Security Notes

- **Never commit `key.properties`** to git (add to `.gitignore`)
- **Never share your keystore file** (`homhom-release-key.jks`)
- **Backup the keystore file** in a secure location (you'll need it for future updates)
- For CI/CD, use environment variables instead of committing credentials

Add to `.gitignore`:
```
android/key.properties
android/homhom-release-key.jks
```
