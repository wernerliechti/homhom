# Firebase Authentication Setup

The app uses Firebase authentication for the meal analysis feature. You need to enable **Anonymous Authentication** in your Firebase project for users to access AI analysis without creating an account.

## Enable Anonymous Authentication

1. **Go to Firebase Console**
   - Open https://console.firebase.google.com
   - Select your project `homhom-app`

2. **Navigate to Authentication**
   - In the left sidebar, click **Authentication**
   - Click the **Sign-in method** tab

3. **Enable Anonymous Authentication**
   - Find "Anonymous" in the providers list
   - Click on it
   - Toggle **Enable** to turn it on
   - Click **Save**

✅ **Done!** Anonymous users can now sign in and use meal analysis.

## Why Anonymous Authentication?

- **No signup required** - Users can start using the app immediately
- **HOMs system works** - We can track user balance per device
- **Cloud Functions work** - Firebase functions can access Firestore with user context
- **Optional upgrade** - Users can later sign in with email if they want to sync across devices

## Alternative: Email/Password Authentication

If you want users to sign in with email instead of anonymous:

1. In **Authentication** > **Sign-in method**
2. Enable **Email/Password**
3. Users will need to create an account before using the app

This requires adding a sign-up screen to the app.

## Current Implementation

The app automatically:
1. Attempts to sign in anonymously when analyzing a meal
2. Falls back to local OpenAI API key if user has one configured
3. Uses Cloud Functions to deduct HOMs and run server-side analysis

See `lib/screens/ai_analysis_flow.dart` for implementation details.
