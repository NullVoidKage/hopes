import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/user_model.dart';

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
        
        print('✅ Automatically enrolled student $displayName in all subjects: $allSubjects');
      }
    } catch (e) {
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
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
      final doc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }







  // Fix existing students who don't have subjects (for existing data)
  Future<void> fixExistingStudents() async {
    try {
      print('🔍 Checking for existing students without subjects...');
      
      // Get all users who are students
      final studentsQuery = await firestore.FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      print('🔍 Found ${studentsQuery.docs.length} students in Firestore');
      
      for (var doc in studentsQuery.docs) {
        final data = doc.data();
        final subjects = data['subjects'];
        
        if (subjects == null || (subjects is List && subjects.isEmpty)) {
          print('🔍 Fixing student: ${data['displayName']} - no subjects found');
          
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
          
          print('✅ Updated Firestore subjects for ${data['displayName']}');
          
          print('✅ Student ${data['displayName']} now has subjects in Firestore');
        } else {
          print('✅ Student ${data['displayName']} already has subjects: $subjects');
        }
      }
      
      print('✅ Finished fixing existing students');
    } catch (e) {
      print('❌ Error fixing existing students: $e');
    }
  }
}
