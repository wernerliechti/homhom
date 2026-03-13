#!/bin/bash

# HomHom Firebase Deployment Script
# This script deploys everything to Firebase after login

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "🚀 HomHom Firebase Deployment"
echo "================================"
echo ""

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Install with: npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
echo "Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo ""
    echo "⚠️  You need to log in to Firebase first."
    echo "Run: firebase login"
    echo ""
    exit 1
fi

echo "✅ Authenticated"
echo ""

# Get project ID
echo "Available Firebase projects:"
firebase projects:list

echo ""
read -p "Enter your Firebase Project ID (e.g., homhom-app): " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Project ID is required"
    exit 1
fi

# Update .firebaserc
echo "Updating .firebaserc..."
cat > .firebaserc << EOF
{
  "projects": {
    "default": "$PROJECT_ID"
  }
}
EOF
echo "✅ .firebaserc updated"
echo ""

# Install Cloud Functions dependencies
echo "Installing Cloud Functions dependencies..."
cd functions
npm install
npm run build
cd ..
echo "✅ Dependencies installed and compiled"
echo ""

# Deploy
echo "🚀 Deploying to Firebase..."
echo ""

# Set environment variable for OpenAI API key
# Note: You'll be prompted to set this if not already set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  OPENAI_API_KEY environment variable not set"
    echo ""
    read -sp "Enter your OpenAI API key: " OPENAI_API_KEY
    echo ""
fi

export OPENAI_API_KEY="$OPENAI_API_KEY"

# Deploy Firestore rules
echo "Deploying Firestore security rules..."
firebase deploy --only firestore:rules
echo "✅ Firestore rules deployed"
echo ""

# Deploy Cloud Functions with environment variables
echo "Deploying Cloud Functions..."
firebase deploy --only functions
echo "✅ Cloud Functions deployed"
echo ""

# Deploy indexes if needed
if [ -f firestore.indexes.json ]; then
    echo "Deploying Firestore indexes..."
    firebase deploy --only firestore:indexes
    echo "✅ Firestore indexes deployed"
    echo ""
fi

echo "✅ ✅ ✅ All Done! ✅ ✅ ✅"
echo ""
echo "Next steps:"
echo "1. Download google-services.json from Firebase Console"
echo "   → Project Settings → Your apps → Android app"
echo "   → Place at: android/app/google-services.json"
echo ""
echo "2. Update Android build files (see FIREBASE_SETUP.md)"
echo ""
echo "3. Run: flutter pub get"
echo ""
echo "4. Run: flutterfire configure"
echo ""
echo "5. Test: flutter run"
echo ""
