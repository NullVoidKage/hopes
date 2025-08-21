# Firebase Setup Guide for HOPES App

This guide will help you set up Firebase and Google Sign-In for your HOPES Flutter application.

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. Android Studio / Xcode for mobile development

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter a project name (e.g., "hopes-app")
4. Choose whether to enable Google Analytics (recommended)
5. Click "Create project"

## Step 2: Add Android App

1. In your Firebase project, click the Android icon (</>) to add an Android app
2. Enter your Android package name: `com.example.hopes`
3. Enter app nickname: "HOPES"
4. Click "Register app"
5. Download the `google-services.json` file
6. Place it in `android/app/` directory (you already have this)

## Step 3: Add iOS App

1. In your Firebase project, click the iOS icon to add an iOS app
2. Enter your iOS bundle ID: `com.example.hopes`
3. Enter app nickname: "HOPES"
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Place it in `ios/Runner/` directory (you already have this)

## Step 4: Enable Authentication

1. In Firebase Console, go to "Authentication" > "Sign-in method"
2. Click on "Google" provider
3. Enable it and add your support email
4. Click "Save"

## Step 5: Enable Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" for development
4. Select a location close to your users
5. Click "Done"

## Step 6: Configure Security Rules

In Firestore Database > Rules, update the rules to:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can read and write their own progress
    match /users/{userId}/progress/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 7: Update Firebase Configuration

### For Web
1. In Firebase Console, go to Project Settings
2. Scroll down to "Your apps" section
3. Click on the web app (</>) icon
4. Copy the firebaseConfig object
5. Update the `web/index.html` file with your actual config

### For Mobile
The configuration files you downloaded (`google-services.json` and `GoogleService-Info.plist`) already contain the necessary configuration.

## Step 8: Install Dependencies

Run the following command to install the new Firebase dependencies:

```bash
flutter pub get
```

## Step 9: Test the Setup

1. Run your app: `flutter run`
2. Try signing in with Google
3. Check Firebase Console to see if users are being created

## Troubleshooting

### Common Issues

1. **Google Sign-In not working on Android**
   - Ensure `google-services.json` is in the correct location
   - Check that SHA-1 fingerprint is added to Firebase project
   - Verify Google Sign-In is enabled in Firebase Console

2. **Google Sign-In not working on iOS**
   - Ensure `GoogleService-Info.plist` is in the correct location
   - Check that bundle ID matches exactly
   - Verify Google Sign-In is enabled in Firebase Console

3. **Firestore permission denied**
   - Check your security rules
   - Ensure user is authenticated before accessing Firestore

### Getting SHA-1 Fingerprint (Android)

```bash
cd android
./gradlew signingReport
```

Add the SHA-1 fingerprint to your Firebase project settings.

## Next Steps

1. Customize the user data structure in Firestore
2. Implement data synchronization between local and cloud
3. Add offline support with Firestore offline persistence
4. Implement user role management
5. Add progress tracking and analytics

## Support

If you encounter issues:
1. Check Firebase Console for error logs
2. Review Flutter Firebase plugin documentation
3. Check Firebase status page for service issues
4. Review your security rules and authentication settings
