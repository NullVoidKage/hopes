# Google Sign-In Web Setup Instructions

To fix the Google Sign-In issue on web, you need to get the **Web Client ID** from Google Cloud Console.

## Steps to Get Web Client ID:

### 1. Go to Google Cloud Console
Visit: https://console.cloud.google.com/

### 2. Select Your Project
Make sure you're in the project: `hope-elearning-52e9b`

### 3. Navigate to Credentials
- Go to **APIs & Services** > **Credentials**
- Or use this direct link: https://console.cloud.google.com/apis/credentials

### 4. Find OAuth 2.0 Client IDs
Look for the section **OAuth 2.0 Client IDs**. You should see entries like:
- **Web client** (for web applications)
- **Android client** (for Android app)
- **iOS client** (for iOS app)

### 5. Copy the Web Client ID
- Click on the **Web client** entry
- Copy the **Client ID** (it should look like: `105306415530-xxxxxxxxxx.apps.googleusercontent.com`)

### 6. Update the Code
Replace the placeholder in `lib/services/auth_service.dart` line 248:

**Current code:**
```dart
clientId: kIsWeb ? '105306415530-yourwebclientid.apps.googleusercontent.com' : null,
```

**Update to:**
```dart
clientId: kIsWeb ? 'YOUR_ACTUAL_WEB_CLIENT_ID_HERE.apps.googleusercontent.com' : null,
```

## Alternative: Create New Web Client ID (if needed)

If you don't see a Web client ID:

1. Click **+ CREATE CREDENTIALS** > **OAuth client ID**
2. Choose **Web application**
3. Add these **Authorized JavaScript origins**:
   - `http://localhost:3000` (for local testing)
   - `https://yourapp.com` (for production)
4. Add these **Authorized redirect URIs**:
   - `http://localhost:3000/__/auth/handler` (for local testing)
   - `https://yourapp.com/__/auth/handler` (for production)
5. Click **CREATE**
6. Copy the generated Client ID

## Test the Fix

After updating the Web Client ID:
1. Run `flutter run -d chrome`
2. Try clicking the Google Sign-In button
3. It should now open the Google authentication popup

## Common Issues

- **Nothing happens**: Check browser console for errors
- **Invalid client ID**: Make sure the Client ID is exactly copied
- **Origin not allowed**: Add your local/production URLs to authorized origins

## Current Firebase Project Details
- Project ID: `hope-elearning-52e9b`
- Sender ID: `105306415530`
- Your Web Client ID should start with: `105306415530-`
