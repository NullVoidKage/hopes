import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/user_model.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '105306415530-2909b849ca4890693b8bd3.apps.googleusercontent.com' : null,
    scopes: [
      'email',
      'profile',
    ],
  );
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web implementation
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile implementation
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      
      return userCredential;
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get user display name
  String? get userDisplayName => _auth.currentUser?.displayName;

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Get user email
  String? get userEmail => _auth.currentUser?.email;

  // Get user photo URL
  String? get userPhotoURL => _auth.currentUser?.photoURL;

  // Create user profile in Firestore
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
    required UserRole role,
    String? grade,
    List<String>? subjects,
  }) async {
    try {
      final userData = {
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'role': role.toString().split('.').last,
        'grade': grade,
        'subjects': subjects,
        'createdAt': firestore.FieldValue.serverTimestamp(),
        'lastLogin': firestore.FieldValue.serverTimestamp(),
        'assessmentResults': {},
        'lessonProgress': {},
      };

      await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      // If the user is a student, automatically assign all subjects
      if (role == UserRole.student) {
        // Philippine curriculum subjects for Grade 7
        final allSubjects = [
          'Mathematics',
          'GMRC',
          'Values Education',
          'Araling Panlipunan',
          'English',
          'Filipino',
          'Music & Arts',
          'Science',
          'Physical Education & Health',
          'EPP',
          'TLE'
        ];
        
        // Update the Firestore document with subjects
        await firestore.FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'subjects': allSubjects,
        });
        
      }
    } catch (e) {
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedUserProfile(uid);
      }

      // If online, fetch from Firestore and cache
      final doc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final userProfile = UserModel.fromFirestore(doc.data()!, uid);
        
        // Cache the user profile for offline use
        await _cacheUserProfileLocally(userProfile);
        
        return userProfile;
      }
      return null;
    } catch (e) {
      // If Firestore fails, try to return cached data
      return await _getCachedUserProfile(uid);
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['lastLogin'] = firestore.FieldValue.serverTimestamp();
      await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }

  // Check if user profile exists
  Future<bool> userProfileExists(String uid) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        final cachedProfile = await _getCachedUserProfile(uid);
        return cachedProfile != null;
      }

      // If online, check Firestore
      final doc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      // If Firestore fails, check cached data
      final cachedProfile = await _getCachedUserProfile(uid);
      return cachedProfile != null;
    }
  }

  // Get all users from Firestore with their names, emails, and nicknames
  Future<List<Map<String, dynamic>>> getAllUsersInfo() async {
    try {
      final snapshot = await firestore.FirebaseFirestore.instance
          .collection('users')
          .get();

      final List<Map<String, dynamic>> usersInfo = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userInfo = {
          'uid': doc.id,
          'email': data['email'] ?? 'No email',
          'displayName': data['displayName'] ?? 'No display name',
          'role': data['role'] ?? 'unknown',
          'grade': data['grade'] ?? 'No grade',
          'createdAt': data['createdAt'] != null 
              ? (data['createdAt'] as firestore.Timestamp).toDate().toString()
              : 'Unknown',
          'lastLogin': data['lastLogin'] != null 
              ? (data['lastLogin'] as firestore.Timestamp).toDate().toString()
              : 'Unknown',
        };
        
        usersInfo.add(userInfo);
      }
      
      return usersInfo;
    } catch (e) {
      return [];
    }
  }

  // Cache user profile locally
  Future<void> _cacheUserProfileLocally(UserModel user) async {
    try {
      final userData = user.toFirestore();
      userData['uid'] = user.uid; // Add uid to the data
      await OfflineService.cacheUserProfile(userData);
    } catch (e) {
    }
  }

  // Get cached user profile
  Future<UserModel?> _getCachedUserProfile(String uid) async {
    try {
      final cachedUserData = await OfflineService.getCachedUserProfile();
      if (cachedUserData != null && cachedUserData['uid'] == uid) {
        return UserModel.fromFirestore(cachedUserData, uid);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Fix existing students who don't have subjects (for existing data)
  Future<void> fixExistingStudents() async {
    try {
      
      // Get all users who are students
      final studentsQuery = await firestore.FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      
      for (var doc in studentsQuery.docs) {
        final data = doc.data();
        final subjects = data['subjects'];
        
        if (subjects == null || (subjects is List && subjects.isEmpty)) {
          
          // Update Firestore with subjects
          await firestore.FirebaseFirestore.instance
              .collection('users')
              .doc(doc.id)
              .update({
            'subjects': [
              'Mathematics',
              'GMRC',
              'Values Education',
              'Araling Panlipunan',
              'English',
              'Filipino',
              'Music & Arts',
              'Science',
              'Physical Education & Health',
              'EPP',
              'TLE'
            ]
          });
          
          
        } else {
        }
      }
      
    } catch (e) {
    }
  }
}
