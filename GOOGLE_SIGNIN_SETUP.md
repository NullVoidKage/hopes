# Google Sign-In Setup Guide for Hopes

This guide explains how to set up Google Sign-In for the Hopes e-learning platform across web, iOS, and Android platforms.

## Prerequisites

- Flutter SDK (3.2.3 or higher)
- Firebase project with Authentication enabled
- Google Cloud Console project
- Android Studio (for Android development)
- Xcode (for iOS development)

## Firebase Configuration

### 1. Enable Google Sign-In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (hope-elearning-52e9b)
3. Navigate to Authentication > Sign-in method
4. Enable Google as a sign-in provider
5. Add your authorized domains for web

### 2. Download Configuration Files

- **Android**: `google-services.json` (already in `android/app/`)
- **iOS**: `GoogleService-Info.plist` (already in `ios/Runner/`)
- **Web**: Configuration is already in `web/firebase-config.js`

## Platform-Specific Setup

### Web Setup

The web configuration is already complete with:
- Google Sign-In script in `web/index.html`
- Firebase configuration in `web/firebase-config.js`
- Proper CORS settings

### Android Setup

#### 1. SHA-1 Certificate Fingerprint

For Google Sign-In to work, you need to add your app's SHA-1 fingerprint to Firebase:

```bash
# Debug SHA-1
cd android && ./gradlew signingReport
```

Add the SHA-1 fingerprint to your Firebase project:
1. Go to Project Settings > Your Apps > Android app
2. Add the SHA-1 fingerprint

#### 2. Package Name

Ensure your package name in `android/app/build.gradle` matches Firebase:
```gradle
applicationId = "com.example.hopes"
```

#### 3. Dependencies

The following are already configured:
- `google-services.json` in `android/app/`
- Google Services plugin in `android/build.gradle`
- Google Services plugin in `android/app/build.gradle`

### iOS Setup

#### 1. Bundle Identifier

Ensure your bundle identifier in Xcode matches Firebase:
- Open `ios/Runner.xcworkspace` in Xcode
- Set Bundle Identifier to match your Firebase iOS app

#### 2. URL Schemes

The URL scheme is already configured in `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.105306415530-2909b849ca4890693b8bd3</string>
        </array>
    </dict>
</array>
```

#### 3. GoogleService-Info.plist

The file is already in place at `ios/Runner/GoogleService-Info.plist`.

## Testing Google Sign-In

### 1. Web Testing

```bash
flutter run -d chrome
```

### 2. Android Testing

```bash
flutter run -d android
```

### 3. iOS Testing

```bash
flutter run -d ios
```

## Troubleshooting

### Common Issues

#### 1. "Sign in failed" Error

- Check if Google Sign-In is enabled in Firebase Console
- Verify SHA-1 fingerprint is correct for Android
- Ensure bundle identifier matches for iOS
- Check if the app is running on an authorized domain (web)

#### 2. Android Build Issues

- Ensure `google-services.json` is in `android/app/`
- Verify Google Services plugin is applied
- Clean and rebuild: `flutter clean && flutter pub get`

#### 3. iOS Build Issues

- Ensure `GoogleService-Info.plist` is in `ios/Runner/`
- Verify URL schemes are configured correctly
- Clean and rebuild: `flutter clean && flutter pub get`

#### 4. Web Issues

- Check browser console for errors
- Ensure Firebase configuration is correct
- Verify authorized domains in Firebase Console

### Debug Mode

Enable debug logging by adding this to your code:
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kDebugMode) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  runApp(MyApp());
}
```

## Security Considerations

1. **API Keys**: Never commit API keys to public repositories
2. **OAuth Consent Screen**: Configure properly in Google Cloud Console
3. **Authorized Domains**: Restrict to your production domains
4. **SHA-1 Fingerprints**: Only add necessary fingerprints

## Production Deployment

### 1. Release Builds

For production, ensure you're using release signing configurations:

**Android**:
```bash
flutter build apk --release
```

**iOS**:
```bash
flutter build ios --release
```

**Web**:
```bash
flutter build web --release
```

### 2. Environment Variables

Consider using environment-specific Firebase configurations for production vs development.

## Support

If you encounter issues:

1. Check Firebase Console logs
2. Review Flutter and Firebase documentation
3. Check platform-specific logs (Android Studio/Xcode)
4. Verify all configuration files are in place

## Additional Resources

- [Firebase Authentication Documentation](https://firebase.google.com/docs/auth)
- [Google Sign-In Flutter Plugin](https://pub.dev/packages/google_sign_in)
- [Flutter Firebase Documentation](https://firebase.flutter.dev/)
- [Google Cloud Console](https://console.cloud.google.com/)
