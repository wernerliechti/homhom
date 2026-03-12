# Firebase Setup Checklist

## Quick Reference - What's Been Done ✅

### Code Generation
- ✅ Updated `pubspec.yaml` with Firebase packages
- ✅ Created Cloud Functions (`functions/src/index.ts`)
- ✅ Created Firestore security rules (`firestore.rules`)
- ✅ Created Firebase service layer (`lib/services/firebase_service.dart`)
- ✅ Created Firebase provider (`lib/providers/firebase_provider.dart`)
- ✅ Created comprehensive setup guide (`FIREBASE_SETUP.md`)

### Files Created
```
functions/
  src/
    index.ts                 # Cloud Functions code
  package.json              # Cloud Functions dependencies
  tsconfig.json             # TypeScript config
firestore.rules             # Security rules
firebase.json               # Firebase config
.firebaserc                 # Firebase project config
lib/services/firebase_service.dart
lib/providers/firebase_provider.dart
FIREBASE_SETUP.md           # Setup instructions
FIREBASE_CHECKLIST.md       # This file
```

---

## What You Need to Do 🚀

### Phase 1: Firebase Project Setup (15 min)
1. [ ] Go to https://console.firebase.google.com
2. [ ] Create project named `homhom-app`
3. [ ] Enable Email/Password authentication
4. [ ] Create Firestore database (europe-west1)
5. [ ] Replace Firestore rules with content from `firestore.rules`

### Phase 2: Service Account & Deployment (20 min)
6. [ ] Download service account JSON (Project Settings → Service Accounts)
7. [ ] Save as `functions/credentials.json`
8. [ ] Run: `firebase login`
9. [ ] Set environment: `export OPENAI_API_KEY="your_key"`
10. [ ] Deploy: `firebase deploy --only functions`
11. [ ] Verify in Firebase Console → Functions (should see 4 functions)

### Phase 3: Android Integration (15 min)
12. [ ] Download `google-services.json` from Firebase
13. [ ] Place at `android/app/google-services.json`
14. [ ] Update `android/build.gradle.kts` with Google Services classpath
15. [ ] Update `android/app/build.gradle.kts` with Firebase BOM

### Phase 4: Flutter App Setup (10 min)
16. [ ] Run: `flutter pub get`
17. [ ] Run: `flutterfire configure`
18. [ ] Update `lib/main.dart` to initialize Firebase
19. [ ] Test: `flutter run` (Android or iOS)

### Phase 5: Google Play Setup (10 min)
20. [ ] Link Google Cloud project (Firebase Settings → Cloud Console)
21. [ ] Enable "Google Play Android Developer API"
22. [ ] Create service account for receipt verification
23. [ ] Give service account Admin role in Google Play Console

---

## Testing Progression 📊

### Stage 1: Local Testing
- [ ] Flutter app connects to Firebase
- [ ] Can create account
- [ ] Can sign in
- [ ] Balance loads from Firestore
- [ ] Cloud Functions respond (check logs)

### Stage 2: Purchase Testing
- [ ] Buy HOMs in internal testing
- [ ] Receipt validates via Google Play
- [ ] Balance increases in Firestore
- [ ] Transaction logged correctly

### Stage 3: Meal Processing
- [ ] Take photo in app
- [ ] Send to `processMeal` function
- [ ] OpenAI returns meal analysis
- [ ] HOM balance decreases
- [ ] Results saved to user's meals collection

---

## Important Notes 📌

### Security
- Never commit `functions/credentials.json`
- Never commit `android/app/google-services.json`
- Never hardcode API keys in Flutter code
- All sensitive data stored server-side only (Cloud Functions)

### Firestore Structure
```
users/
  {userId}/
    balance: 10
    isUnlimited: false
    createdAt: timestamp
    
    transactions/
      {transactionId}/
        type: "purchase" | "consumption"
        homsAdded/Consumed: number
        timestamp: timestamp
    
    meals/
      {mealId}/
        analysis: {...}
        homsUsed: 1
        processedAt: timestamp
```

### Cloud Function Environment
```
OPENAI_API_KEY=sk-proj-...
GOOGLE_PACKAGE_NAME=com.homhom.app
```

---

## Troubleshooting 🔧

### Functions Won't Deploy
```bash
# Check dependencies
cd functions
npm install

# Check TypeScript compilation
npm run build

# Deploy with verbose output
firebase deploy --only functions --debug
```

### Firestore Access Denied
- Check rules: Firebase Console → Firestore → Rules
- Verify user is authenticated before calling functions
- In test mode, all reads/writes allowed

### Cloud Functions Not Triggering
- Check function logs: `firebase functions:log`
- Verify function names in Flutter code match deployed functions
- Test via Firebase CLI: `firebase functions:shell`

### OpenAI Errors
- Verify API key is set: `echo $OPENAI_API_KEY`
- Check API key has Vision API access
- Monitor Cloud Function logs for detailed errors

---

## Next Phase: Production Ready 🎯

Once testing is complete:
- [ ] Replace local receipt validation with real Google Play API
- [ ] Enable Firebase App Check
- [ ] Set up error tracking (Firebase Crashlytics)
- [ ] Configure monitoring and alerts
- [ ] Create comprehensive logging
- [ ] Handle payment edge cases (refunds, reversions)
- [ ] Set up backup/restore procedures

---

## Files to Add to .gitignore 🔐

Already configured in .gitignore:
- `functions/credentials.json` ✅
- `android/app/google-services.json` ✅
- `.firebaserc` (project ID, can be public)
- `.env` files with API keys

---

## Quick Commands 🚀

```bash
# Initialize Firebase (login)
firebase login

# Deploy everything
firebase deploy

# Deploy only functions
firebase deploy --only functions

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# View function logs
firebase functions:log

# Test locally
firebase emulators:start

# Build Flutter app
flutter build apk --release

# Test on device
flutter run --release
```

---

**Ready to begin? Start with Phase 1: Firebase Project Setup above!**
