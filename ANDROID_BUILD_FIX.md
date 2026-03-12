# Android Build Fixes for Release APK

## Issues Fixed

### 1. R8 Minification Errors (Missing Google Play Core Classes)
**Problem**: R8 was stripping out Google Play Core classes needed by Flutter.

**Fixes Applied**:
- ✅ Added `com.google.android.play:core:1.10.3` dependency to `build.gradle.kts`
- ✅ Added ProGuard keep rules in `proguard-rules.pro`:
  ```proguard
  -keep class com.google.android.play.core.** { *; }
  -dontwarn com.google.android.play.core.**
  ```

### 2. Java Compiler Warnings (source/target value 8 is obsolete)
**Problem**: Some dependency was still referencing Java 8.

**Solution**: Ensure your Gradle wrapper is up-to-date. Update if needed:

```bash
cd android
./gradlew wrapper --gradle-version=8.3
```

Or on Windows:
```bash
cd android
gradlew.bat wrapper --gradle-version=8.3
```

## Try Building Again

```bash
cd /home/ueli/.openclaw/workspace/homhom
flutter clean
flutter pub get
flutter build appbundle --release
```

## If You Still Get Errors

### Option A: Disable Minification (Testing Only)
In `android/app/build.gradle.kts`, change:
```kotlin
isMinifyEnabled = false  // Disable for testing
isShrinkResources = false  // Disable for testing
```

This will create a larger APK but faster build. Use this for testing, then re-enable for production.

### Option B: Disable Shrinking Only
```kotlin
isMinifyEnabled = true   // Keep minification
isShrinkResources = false  // Disable shrinking
```

### Option C: Add More ProGuard Rules
If specific classes are still being stripped, add to `proguard-rules.pro`:
```proguard
-keep class com.saynode.homhom.** { *; }  # Your app's own classes
```

## Files Modified
- `android/app/build.gradle.kts` — Added Google Play Core dependency
- `android/app/proguard-rules.pro` — Added keep rules for Play Core

## Expected Output
Successful build:
```
✓ Built build/app/outputs/bundle/release/app-release.aab (X MB)
```

This `.aab` file is what you upload to Google Play Store.
