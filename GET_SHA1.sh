#!/bin/bash

# This script extracts the SHA-1 fingerprint from your Android debug keystore
# Firebase needs this to authenticate your app

echo "🔍 Getting SHA-1 fingerprint for Firebase..."
echo ""

# Try using Java keytool (comes with Java/Android SDK)
KEYSTORE_PATH="$HOME/.android/debug.keystore"

if [ -f "$KEYSTORE_PATH" ]; then
    echo "✅ Found debug keystore at: $KEYSTORE_PATH"
    echo ""
    echo "🔑 Extracting SHA-1 fingerprint..."
    echo "Run this command to get your SHA-1:"
    echo ""
    echo 'keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1'
    echo ""
    echo "Or if keytool is not found, try:"
    echo '~/Library/Android/sdk/tools/keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1'
    echo ""
else
    echo "❌ Debug keystore not found at: $KEYSTORE_PATH"
    echo "Run 'flutter run' first to create it."
fi
