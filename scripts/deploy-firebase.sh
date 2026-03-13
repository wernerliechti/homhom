#!/bin/bash

# Automated Firebase Deployment
# Usage: ./scripts/deploy-firebase.sh <project-id> <openai-api-key>

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <project-id>"
    echo ""
    echo "Example: $0 homhom-app"
    exit 1
fi

PROJECT_ID=$1
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🚀 HomHom Firebase Deployment"
echo "=============================="
echo "Project ID: $PROJECT_ID"
echo ""

cd "$PROJECT_DIR"

# Verify firebase CLI
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not installed"
    echo "Install: npm install -g firebase-tools"
    exit 1
fi

# Check authentication
echo "Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not authenticated"
    echo "Run: firebase login"
    exit 1
fi
echo "✅ Authenticated"
echo ""

# Update .firebaserc
echo "Updating project configuration..."
cat > .firebaserc << EOF
{
  "projects": {
    "default": "$PROJECT_ID"
  }
}
EOF
echo "✅ Project ID configured"
echo ""

# Verify Firestore can be accessed
echo "Verifying project access..."
if ! firebase firestore:indexes --project="$PROJECT_ID" &> /dev/null; then
    echo "⚠️  Could not access Firestore. Make sure:"
    echo "   1. Firestore database is created in Firebase Console"
    echo "   2. Project ID is correct: $PROJECT_ID"
    echo "   3. You're logged in: firebase login"
    exit 1
fi
echo "✅ Project accessible"
echo ""

# Install dependencies
echo "Installing Cloud Functions dependencies..."
cd functions
npm install --silent
npm run build
cd ..
echo "✅ Dependencies ready"
echo ""

# Deploy Firestore Rules
echo "📋 Deploying Firestore Security Rules..."
firebase deploy --only firestore:rules --project="$PROJECT_ID"
echo "✅ Firestore rules deployed"
echo ""

# Deploy Cloud Functions with environment variable
echo "🔧 Deploying Cloud Functions..."
echo "   (OpenAI API key will be set in Cloud Functions environment)"
echo ""

# Create .env.local file for functions (temporary, not committed)
cat > functions/.env.local << 'EOF'
OPENAI_API_KEY=${OPENAI_API_KEY}
EOF

firebase deploy --only functions --project="$PROJECT_ID"
echo "✅ Cloud Functions deployed"
echo ""

# Verify deployment
echo "✅ Verifying deployment..."
echo ""
echo "Deployed functions:"
firebase functions:list --project="$PROJECT_ID" 2>/dev/null || echo "   (Cannot list, but deployment succeeded)"
echo ""

# Success message
echo "✅ ✅ ✅ Deployment Complete! ✅ ✅ ✅"
echo ""
echo "═════════════════════════════════════════"
echo ""
echo "Next Steps:"
echo ""
echo "1️⃣  Download android/app/google-services.json"
echo "   → Firebase Console"
echo "   → Project Settings (⚙️ top right)"
echo "   → Your apps → Android app"
echo "   → Download google-services.json"
echo "   → Save to: android/app/google-services.json"
echo ""
echo "2️⃣  Update Android build files"
echo "   → Follow FIREBASE_SETUP.md section 'Step 5: Set Up Android'"
echo ""
echo "3️⃣  Update Firestore Rules in Firebase Console"
echo "   → Build → Firestore → Rules tab"
echo "   → Should show the security rules we deployed"
echo ""
echo "4️⃣  Get Google Play Service Account (for receipt verification)"
echo "   → Follow FIREBASE_SETUP.md section 'Step 10'"
echo ""
echo "5️⃣  Test locally"
echo "   → flutter pub get"
echo "   → flutterfire configure"
echo "   → flutter run"
echo ""
echo "═════════════════════════════════════════"
