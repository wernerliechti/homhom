# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# In-app purchase rules
-keep class com.android.vending.billing.** { *; }
-keep class io.flutter.plugins.inapppurchase.** { *; }

# Google Play Core library (for deferred components)
# NOTE: Commented out - only needed if you add com.google.android.play:core dependency
# Uncomment if you re-add the dependency to your build.gradle.kts
# -keep class com.google.android.play.core.** { *; }
# -dontwarn com.google.android.play.core.**