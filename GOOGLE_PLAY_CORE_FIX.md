# Google Play Core Library SDK 34 Compatibility

## The Issue
Google Play Store is rejecting your APK because:
- Your targetSdkVersion = 34 (Android 14)
- Your Google Play Core library version 1.10.3 doesn't properly handle Android 14's stricter broadcast receiver requirements

## Solution Options

### Option 1: Disable Deferred Components (Simplest ✅)
If you're not using deferred/dynamic features, remove the dependency entirely:

In `android/app/build.gradle.kts`:
```kotlin
dependencies {
    // Remove or comment out the Play Core library if not needed
    // implementation("com.google.android.play:core:1.10.3")
}
```

Then remove the ProGuard rules from `android/app/proguard-rules.pro`:
```proguard
# Delete or comment out these lines:
# -keep class com.google.android.play.core.** { *; }
# -dontwarn com.google.android.play.core.**
```

**Check if you need it**: Do you have dynamic or deferred feature modules? If no, remove it.

### Option 2: Update to Latest Compatible Version (Recommended)
Use the latest version that explicitly supports Android 14:

In `android/app/build.gradle.kts`:
```kotlin
dependencies {
    implementation("com.google.android.play:core:1.11.0") // Or later
}
```

Check Maven Central for the latest stable version:
https://mvnrepository.com/artifact/com.google.android.play/core

### Option 3: Lower Your Target SDK (Not Recommended)
Change targetSdkVersion to 33 or lower, but this is not recommended as Google Play requires SDK 34+ for new apps.

## Which Option to Choose?

1. **Are you using dynamic feature modules or deferred components?**
   - YES → Use Option 2 (update to latest version)
   - NO → Use Option 1 (remove dependency)

2. **What is your app's core architecture?**
   - Simple app (nutrition tracking) → Probably don't need deferred components
   - Complex app with optional features → Might need them

## For HomHom (Your App)
**HomHom is a nutrition tracking app**, so it likely **doesn't need deferred components**.

**Recommendation**: Use **Option 1** — remove the Play Core dependency unless you're planning:
- In-app updates
- Dynamic module loading
- Dynamic feature delivery

## Quick Fix Commands

### To remove the dependency:
```bash
# 1. Remove from build.gradle.kts (comment out the line)
# 2. Remove ProGuard rules from proguard-rules.pro
# 3. Build again
flutter clean
flutter build appbundle --release
```

### To update the version:
```bash
# Edit build.gradle.kts
# Change: implementation("com.google.android.play:core:1.10.3")
# To:     implementation("com.google.android.play:core:1.11.0")  # or latest
# Then rebuild
flutter clean
flutter build appbundle --release
```

## References
- [Google Play Core Library Release Notes](https://developer.android.com/guide/playcore)
- [Android 14 Broadcast Receiver Changes](https://developer.android.com/about/versions/14/changes/runtime-broadcast-receivers)
