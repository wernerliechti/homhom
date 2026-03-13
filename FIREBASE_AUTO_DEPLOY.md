# Automated Firebase Deployment

Since you've provided credentials, I can automate most of the setup. Here's what you need to do:

---

## **Step 1: Create Firebase Project (Manual - 5 min)**

This is the ONLY browser-based step. After this, I can automate everything.

1. Go to **https://console.firebase.google.com**
2. Click **"Add project"**
3. Project name: `homhom-app`
4. Disable Analytics (optional)
5. Click **"Create project"** and wait (~30 seconds)
6. When ready, note your **Project ID** (usually same as name, but check)

---

## **Step 2: Enable Services (5 min)**

Still in Firebase Console:

### 2.1 Enable Authentication
1. **Build → Authentication**
2. **Get started**
3. Enable **Email/Password**

### 2.2 Create Firestore
1. **Build → Firestore Database**
2. **Create database**
3. Location: `europe-west1`
4. Mode: **Start in test mode** (we'll lock it down after)
5. **Create**

### 2.3 Get Your Project ID
If you forgot:
1. **Project Settings** (⚙️ top right)
2. Copy the **Project ID**

---

## **Step 3: Login to Firebase CLI (2 min)**

Run this in terminal:
```bash
cd ~/development/flutter_projects/homhom
firebase login
```

Your browser will open. Sign in with: **privat@wernerliechti.ch**

Come back here when done.

---

## **Step 4: Let Me Deploy Everything (5 min)**

Once you've completed Steps 1-3, send me a message with:
- ✅ Firebase Project ID (from Step 2.3)

I'll then:
- Deploy Cloud Functions (with OpenAI key securely)
- Set Firestore security rules
- Create service accounts
- Test everything

---

## **What I Can't Do Yet**

These still need your manual action:

1. **Download google-services.json**
   - Firebase Console → Project Settings → Your apps → Android
   - Download and place at `android/app/google-services.json`

2. **Google Play Console Setup**
   - Link Google Cloud project
   - Enable receipt verification API
   - Create service account for verification

But I can give you step-by-step instructions for both.

---

## **After I Deploy**

You'll run:
```bash
flutter pub get
flutterfire configure
flutter run
```

That's it. App is ready to test.

---

**When you're done with Step 1-3, just reply with your Project ID.**
