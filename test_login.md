# Firebase Authentication Testing Guide

## Testing Login on All Platforms

### 🌐 **Web Testing**
```bash
# Test on Chrome
flutter run -d chrome

# Test on Edge (if available)
flutter run -d edge

# Test on Firefox (if available)  
flutter run -d web-server --web-port=8080
```

**Expected Web Behavior:**
- ✅ Firebase should initialize successfully
- ✅ Login form should appear
- ✅ Email/password validation should work
- ✅ Create account should work
- ✅ Login with existing account should work
- ✅ Error messages should be user-friendly
- ✅ Platform indicator should show "Web"

### 📱 **Android Testing**
```bash
# Test on Android device/emulator
flutter run

# Test specific Android device
flutter devices
flutter run -d [device-id]
```

**Expected Android Behavior:**
- ✅ Firebase should initialize successfully
- ✅ google-services.json should be properly configured
- ✅ All login functionality should work
- ✅ Platform indicator should show "Android"

### 🍎 **iOS Testing**
```bash
# Test on iOS simulator/device
flutter run

# Test specific iOS device
flutter devices
flutter run -d [device-id]
```

**Expected iOS Behavior:**
- ✅ Firebase should initialize successfully
- ✅ GoogleService-Info.plist should be properly configured
- ✅ All login functionality should work
- ✅ Platform indicator should show "iOS"

## 🧪 **Test Scenarios**

### 1. **Account Creation Test**
1. Open the app
2. Tap "Don't have an account? Sign up"
3. Enter: `test@example.com` / `password123`
4. Tap "Create Account"
5. ✅ Should show success message and navigate to home

### 2. **Login Test**
1. Open the app
2. Enter existing credentials
3. Tap "Login"
4. ✅ Should navigate to home screen

### 3. **Error Handling Test**
1. Try login with wrong password
2. ✅ Should show "Wrong password provided."
3. Try login with non-existent email
4. ✅ Should show "No user found with this email address."

### 4. **Platform Detection Test**
1. Login successfully
2. Check the platform badge on home screen
3. ✅ Should show correct platform (Web/Android/iOS)

### 5. **Debug Information Test** (Debug Mode Only)
1. Login successfully
2. Scroll down to see Debug Information card
3. Tap "Test Firebase Connection"
4. ✅ Should show success message

## 🔧 **Troubleshooting**

### Web Issues:
- Check browser console for Firebase errors
- Ensure CORS is enabled for your domain
- Verify Firebase web configuration

### Android Issues:
- Ensure `google-services.json` is in `android/app/`
- Check `android/app/build.gradle` has Firebase plugin
- Verify package name matches Firebase configuration

### iOS Issues:
- Ensure `GoogleService-Info.plist` is in `ios/Runner/`
- Check Bundle ID matches Firebase configuration
- Verify iOS project settings

## 📝 **Console Logs to Look For**

**Successful Initialization:**
```
Firebase initialized successfully
Running on [Platform] - Firebase Auth should work
Firebase Auth instance created successfully
```

**Successful Login:**
```
Attempting to sign in user: user@example.com
Sign in successful for: user@example.com
Auth state changed: User logged in - user@example.com
```

**Error Handling:**
```
Firebase Auth Error - Code: [error-code], Message: [error-message]
```
