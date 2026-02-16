# Firebase App Check Setup Guide

## ✅ What Was Fixed

### 1. **Critical Bug - Firebase Initialization**
**Before:**
```dart
await Firebase.initializeApp(
  options: FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForDevelopment',  // ❌ Hardcoded dummy credentials
    appId: '1:1234567890:android:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'tooler-dev',
    storageBucket: 'tooler-dev.appspot.com',
  ),
);
```

**After:**
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,  // ✅ Uses real credentials
);
```

Your app now connects to the correct Firebase project: **`myblog-8ca17`**

### 2. **Firebase App Check Implementation**
Added App Check protection with Play Integrity for Android:
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
);
```

## 📋 Next Steps - Firebase Console Configuration

To complete the setup, you need to configure App Check in the Firebase Console:

### Step 1: Enable App Check

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **myblog-8ca17**
3. Navigate to **Build** → **App Check** in the left sidebar
4. Click **Get Started**

### Step 2: Register Your Android App

1. Under **Apps**, find your Android app: `com.example.tooler`
2. Click **Register** (or **Edit** if already registered)

### Step 3: Configure Play Integrity

1. Select **Play Integrity** as the provider
2. Follow the instructions to:
   - Enable Play Integrity API in Google Cloud Console
   - Link your app to Google Play Console (even for internal testing)
   - Wait 24-48 hours for initial verification

**Note:** Play Integrity requires your app to be registered with Google Play Console. For immediate testing without Play Integrity, see the Debug Provider section below.

### Step 4: Enforce App Check for Firebase Services

Enable enforcement for the services you use:

- ✅ **Firebase Authentication**
- ✅ **Cloud Firestore**
- ✅ **Firebase Storage**

Click **Enforce** for each service. This will block requests from unverified apps.

---

## 🔧 Development Setup - Debug Provider

For local development and testing, you need to register a debug token:

### Option 1: Generate Debug Token (Recommended)

1. Run your app in debug mode on an emulator or physical device
2. Check the Android Logcat for a message like:
   ```
   D/FirebaseAppCheck: App Check debug token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```
3. Copy the debug token
4. In Firebase Console → App Check → Apps → Android app → overflow menu (⋮) → **Manage debug tokens**
5. Click **Add debug token**, paste the token, and give it a name (e.g., "Azamat Dev Device")

### Option 2: Use Debug Provider in Code (Alternative)

For automatic debug token generation, update [main.dart](lib/main.dart):

```dart
import 'package:flutter/foundation.dart';

await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode 
    ? AndroidProvider.debug  // Debug builds use debug provider
    : AndroidProvider.playIntegrity,  // Release builds use Play Integrity
);
```

**⚠️ Warning:** Never ship to production with `AndroidProvider.debug` enabled in release mode!

---

## 🧪 Testing Your Implementation

### 1. Run the App
```bash
flutter run
```

### 2. Check Logs

**Success indicators:**
- ✅ Firebase initialization shows correct project ID: `myblog-8ca17`
- ✅ No "No AppCheckProvider installed" warning
- ✅ Auth, Firestore, and Storage operations work correctly

**What to look for in logs:**
```
I/FirebaseApp: Initialized Firebase with project myblog-8ca17
D/FirebaseAppCheck: App Check activated successfully
```

### 3. Verify in Firebase Console

1. Go to **App Check** → **Metrics**
2. You should see requests from your app being verified
3. Check that token exchange is successful

### 4. Test Firebase Operations

Run these operations in your app to verify everything works:
- Sign up / Login with email/password (Firebase Auth)
- Read/write tools data (Firestore)
- Upload profile images (Firebase Storage)

---

## 🌐 Web Support (Future)

For web platform support, you'll need to add reCAPTCHA v3:

1. Register your site for reCAPTCHA v3 at https://www.google.com/recaptcha/admin
2. Get your site key
3. Update [main.dart](lib/main.dart):

```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  webProvider: ReCaptchaV3Provider('YOUR-RECAPTCHA-V3-SITE-KEY'),
);
```

4. Add the reCAPTCHA script to [web/index.html](web/index.html)

---

## 🔒 Security Best Practices

### ✅ What's Protected Now:
- Firebase API keys (now using real credentials from `firebase_options.dart`)
- Authentication endpoints (requires App Check token)
- Firestore database (requests verified by App Check)
- Firebase Storage (upload/download protected)

### ⚠️ Important Notes:
1. **Play Integrity Setup Time:** Initial verification can take 24-48 hours after registering with Google Play Console
2. **Debug Tokens:** Manage them carefully; rotate them regularly
3. **Enforcement:** Start with "monitoring mode" in production to avoid blocking legitimate users during initial rollout
4. **iOS Support:** When you add iOS support, you'll need to configure App Attest

---

## 📊 Monitoring

After deployment, monitor App Check in Firebase Console:

1. **Metrics Tab**: View verification success rates
2. **Logs**: Check for failed verification attempts
3. **Alerts**: Set up alerts for unusual patterns

---

## 🆘 Troubleshooting

### "App Check token expired"
- Normal behavior; tokens auto-refresh every hour
- No action needed unless you see repeated failures

### "Play Integrity API error"
- Verify app is registered with Google Play Console
- Check that Play Integrity API is enabled in Google Cloud Console
- Wait 24-48 hours after initial setup

### "Requests blocked in production"
- Check enforcement settings in Firebase Console
- Verify debug tokens are registered for test devices
- Review metrics for verification failure patterns

### Development still showing warnings
- Register your debug token in Firebase Console (see Debug Provider section)
- Verify you're using the correct Firebase project (`myblog-8ca17`)

---

## 📝 Summary of Changes

**Files Modified:**
1. [lib/main.dart](lib/main.dart)
   - Added `firebase_app_check` import
   - Added `firebase_options.dart` import
   - Fixed Firebase initialization to use `DefaultFirebaseOptions.currentPlatform`
   - Added App Check activation with Play Integrity provider

2. [pubspec.yaml](pubspec.yaml)
   - Added `firebase_app_check: ^0.4.1+4` dependency

**What's Next:**
1. Configure App Check in Firebase Console (see steps above)
2. Register debug token for development
3. Test the app to verify everything works
4. Enable enforcement for production when ready

---

**Questions or Issues?** 
- Firebase App Check Docs: https://firebase.google.com/docs/app-check
- Play Integrity Setup: https://firebase.google.com/docs/app-check/android/play-integrity-provider
