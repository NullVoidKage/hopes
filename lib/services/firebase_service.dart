import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/models/user.dart';

class FirebaseService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current Firebase user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<firebase_auth.UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Create or update user document in Firestore
      if (userCredential.user != null) {
        await _createOrUpdateUser(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Create or update user document in Firestore
  Future<void> _createOrUpdateUser(firebase_auth.User firebaseUser) async {
    try {
      final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
      
      final userData = {
        'uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'displayName': firebaseUser.displayName,
        'photoURL': firebaseUser.photoURL,
        'lastSignInTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await userDoc.set(userData, SetOptions(merge: true));
    } catch (e) {
      print('Error creating/updating user document: $e');
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user role and section
  Future<void> updateUserRole(String uid, String role, String section) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role,
        'section': section,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user role: $e');
    }
  }

  // Save progress to Firestore
  Future<void> saveProgress(String userId, Map<String, dynamic> progressData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .add({
        ...progressData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  // Get user progress from Firestore
  Future<List<Map<String, dynamic>>> getUserProgress(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('Error getting user progress: $e');
      return [];
    }
  }
}
