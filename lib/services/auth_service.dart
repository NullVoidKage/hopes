import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  bool isLoading = true;

  AuthService() {
    // Initialize with current user
    user = _auth.currentUser;
    isLoading = false;
    notifyListeners();
    
    // Listen for auth state changes
    _auth.authStateChanges().listen((User? newUser) async {
      user = newUser;
      isLoading = false;

      try {
        if (newUser != null) {
          // User is online - you can implement online status logic here
          print('User is online: ${newUser.email}');
        } else {
          // User is offline - you can implement offline status logic here
          print('User is offline');
        }
      } catch (e) {
        print('Error handling auth state change: $e');
      }

      notifyListeners();
    });
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Check if email already exists and clean up orphaned data
  Future<bool> _isEmailDuplicate(String email) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        // Check if the existing document belongs to a valid Firebase Auth user
        final existingDoc = query.docs.first;
        final existingUserId = existingDoc.id;
        
        try {
          // Check if the existing user ID matches any current Firebase Auth user
          final currentUser = FirebaseAuth.instance.currentUser;
          
          // If there's a current user and it matches the existing document, it's a legitimate duplicate
          if (currentUser != null && currentUser.uid == existingUserId) {
            return true;
          } else {
            // User doesn't exist in Auth but document exists in Firestore
            // This is orphaned data - clean it up
            await _cleanupOrphanedUserData(existingUserId);
            return false;
          }
        } catch (e) {
          // User doesn't exist in Auth - clean up orphaned data
          await _cleanupOrphanedUserData(existingUserId);
          return false;
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking email duplicate: $e');
      return false;
    }
  }

  // Clean up orphaned user data when email exists in Firestore but not in Auth
  Future<void> _cleanupOrphanedUserData(String userId) async {
    try {
      print('Cleaning up orphaned user data for: $userId');
      
      // Delete the orphaned user document and all related data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .delete();
      
      print('Orphaned user data cleaned up successfully');
    } catch (e) {
      print('Error cleaning up orphaned user data: $e');
    }
  }

  // Check if email is available (for real-time validation)
  Future<bool> isEmailAvailable(String email) async {
    if (email.trim().isEmpty) return false;
    
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      print('Error checking email availability: $e');
      return false;
    }
  }

  // Email/Password Signup
  Future<String?> signUp(String email, String password, String name) async {
    try {
      // Validate email format
      if (!_isValidEmail(email)) {
        return 'Please enter a valid email address';
      }

      // Check for duplicate email
      final isDuplicate = await _isEmailDuplicate(email);
      if (isDuplicate) {
        return 'An account with this email already exists';
      }

      // Create user in Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user?.updateDisplayName(name);

      // Double-check that no orphaned data exists for this email
      await _cleanupOrphanedUserData(cred.user!.uid);
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'email': email.toLowerCase(), // Store email in lowercase for consistency
        'nickname': name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account with this email already exists';
        case 'invalid-email':
          return 'Please enter a valid email address';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled. Please contact support.';
        default:
          return e.message ?? 'An error occurred during signup';
      }
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Email/Password Login
  Future<String?> signIn(String email, String password) async {
    try {
      // Normalize email to lowercase for consistency
      final normalizedEmail = email.toLowerCase().trim();
      
      // Add debug logging to help identify the issue
      print('Attempting to sign in with email: $normalizedEmail');
      
      await _auth.signInWithEmailAndPassword(email: normalizedEmail, password: password);
      
      print('Sign in successful for email: $normalizedEmail');
      return null;
    } on FirebaseAuthException catch (e) {
      // Add debug logging for specific error codes
      print('Firebase Auth error during sign in: ${e.code} - ${e.message}');
      
      // Handle specific Firebase Auth errors with user-friendly messages
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email address. Please check your email or create a new account.';
        case 'wrong-password':
          return 'Incorrect password. Please try again or use "Forgot Password" to reset it.';
        case 'invalid-email':
          return 'Please enter a valid email address';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your connection and try again.';
        case 'invalid-credential':
          return 'Invalid email or password. Please check your credentials and try again.';
        default:
          return 'Invalid email or password. Please try again.';
      }
    } catch (e) {
      print('Unexpected error during sign in: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      user = null;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  // Check Google Sign-In availability
  Future<bool> isGoogleSignInAvailable() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Google Sign In
  Future<String?> signInWithGoogle() async {
    try {
      // Configure Google Sign-In 
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // For web: You need to get the Web Client ID from Google Cloud Console
        // Go to: Console > APIs & Services > Credentials > OAuth 2.0 Client IDs
        // Copy the Web client ID that ends with .apps.googleusercontent.com
        clientId: kIsWeb ? '105306415530-qm2fjqi75l4vbvvfs4t0r4mrg909vipn.apps.googleusercontent.com' : null,
      );
      
      // Check if user is already signed in with Google
      final isSignedIn = await googleSignIn.isSignedIn();
      if (isSignedIn) {
        await googleSignIn.signOut();
      }
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return 'Sign-in aborted by user';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        return 'Failed to get authentication token. Please try again.';
      }

      print('Google Sign-In successful for: ${googleUser.email}');
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Sign in to Firebase with timeout
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential)
              .timeout(Duration(seconds: 30));

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        print('New user created via Google Sign-In');
        
        // Clean up any orphaned data for this user ID
        await _cleanupOrphanedUserData(userCredential.user!.uid);
        
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email?.toLowerCase(),
            'nickname': userCredential.user!.displayName ?? 'User',
            'photoURL': userCredential.user!.photoURL,
            'avatar': 'person', // Default avatar
            'vehicleTypes': [], // Default empty array
            'premium': false, // Default premium status
            'bio': '', // Default empty bio
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('User document created in Firestore');
        } catch (firestoreError) {
          print('Error creating user document: $firestoreError');
          // Don't return error here as auth was successful
        }
      } else {
        print('Existing user signed in via Google');
      }

      // Force refresh user state
      user = _auth.currentUser;
      isLoading = false;
      notifyListeners();
      
      return null;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors with user-friendly messages
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different sign-in method';
        case 'invalid-credential':
          return 'Invalid sign-in credentials. Please try again.';
        case 'operation-not-allowed':
          return 'Google sign-in is not enabled. Please contact support.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'user-not-found':
          return 'No account found with this email address';
        case 'network-request-failed':
          return 'Network error. Please check your connection and try again.';
        case 'too-many-requests':
          return 'Too many sign-in attempts. Please try again later.';
        default:
          return 'Unable to sign in with Google. Please try again.';
      }
    } catch (e) {
      if (e.toString().contains('network')) {
        return 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('cancelled')) {
        return 'Sign-in was cancelled.';
      } else if (e.toString().contains('popup')) {
        return 'Sign-in popup was blocked. Please allow popups and try again.';
      } else if (e.toString().contains('ApiException: 10')) {
        return 'Google Sign-In configuration error. Please check your Firebase setup and SHA-1 fingerprint.';
      } else if (e.toString().contains('ApiException')) {
        return 'Google Sign-In configuration error. Please check your Firebase setup.';
      } else if (e.toString().contains('DEVELOPER_ERROR')) {
        return 'Google Sign-In is not properly configured. Please contact support.';
      } else if (e.toString().contains('SIGN_IN_REQUIRED')) {
        return 'Sign-in required. Please try again.';
      }
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Refresh user state
  void refreshUserState() {
    user = _auth.currentUser;
    notifyListeners();
  }

  // Check if user exists with different provider
  Future<String?> checkExistingUser(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        if (methods.contains('google.com')) {
          return 'This email is already registered with Google. Please use "Sign in with Google" instead.';
        } else if (methods.contains('apple.com')) {
          return 'This email is already registered with Apple. Please use "Sign in with Apple" instead.';
        }
      }
      return null;
    } catch (e) {
      print('Error checking existing user: $e');
      return null;
    }
  }

  // Sign in with Apple
  Future<String?> signInWithApple() async {
    try {
      // Check if Sign in with Apple is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        return 'Sign in with Apple is not available on this device';
      }

      // Request Sign in with Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (appleCredential.userIdentifier == null) {
        return 'Sign-in aborted by user';
      }

      // Check if user exists with different provider
      if (appleCredential.email != null) {
        final existingUserError = await checkExistingUser(appleCredential.email!);
        if (existingUserError != null) {
          return existingUserError;
        }
      }

      // Create OAuth credential for Firebase
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with timeout
      final userCredential = await _auth.signInWithCredential(oauthCredential)
          .timeout(Duration(seconds: 30));

      // Handle new user creation
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        try {
          // Clean up any orphaned data for this user ID
          await _cleanupOrphanedUserData(userCredential.user!.uid);
          
          // Get user's name from Apple credential
          String displayName = 'User';
          if (appleCredential.givenName != null && appleCredential.familyName != null) {
            displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
          } else if (appleCredential.givenName != null) {
            displayName = appleCredential.givenName!;
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email?.toLowerCase(),
            'nickname': displayName,
            'photoURL': userCredential.user!.photoURL,
            'avatar': 'person', // Default avatar
            'vehicleTypes': [], // Default empty array
            'premium': false, // Default premium status
            'bio': '', // Default empty bio
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (firestoreError) {
          print('Error creating user document for Apple Sign-In: $firestoreError');
          // Don't return error here as auth was successful
        }
      }

      // Force refresh user state
      user = _auth.currentUser;
      isLoading = false;
      notifyListeners();
      
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'This email is already registered with Google. Please use "Sign in with Google" instead.';
        case 'invalid-credential':
          return 'Invalid sign-in credentials. Please try again.';
        case 'operation-not-allowed':
          return 'Sign in with Apple is not enabled. Please contact support.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'user-not-found':
          return 'No account found with this email address';
        case 'network-request-failed':
          return 'Network error. Please check your connection and try again.';
        case 'too-many-requests':
          return 'Too many sign-in attempts. Please try again later.';
        default:
          return 'Unable to sign in with Apple. Please try again.';
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          return 'Sign-in was canceled';
        case AuthorizationErrorCode.failed:
          return 'Sign-in failed. Please try again.';
        case AuthorizationErrorCode.invalidResponse:
          return 'Invalid response from Apple. Please try again.';
        case AuthorizationErrorCode.notHandled:
          return 'Sign-in not handled. Please try again.';
        case AuthorizationErrorCode.unknown:
          return 'An unknown error occurred during sign-in. Please try again.';
        default:
          return 'Unable to sign in with Apple. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
