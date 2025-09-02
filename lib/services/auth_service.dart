import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/student.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '105306415530-2909b849ca4890693b8bd3.apps.googleusercontent.com' : null,
    scopes: [
      'email',
      'profile',
    ],
  );
  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineService _offlineService = OfflineService();

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
      
      // Update display name and reload user to ensure it's saved
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();
      
      // Verify the display name was saved
      final updatedUser = _auth.currentUser;
      if (updatedUser?.displayName != displayName) {
        print('⚠️ Display name not updated properly, retrying...');
        await updatedUser?.updateDisplayName(displayName);
        await updatedUser?.reload();
      }
      
      print('✅ Display name updated: ${updatedUser?.displayName}');
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
      // Ensure we have a valid display name
      String finalDisplayName = displayName;
      if (finalDisplayName.isEmpty || finalDisplayName == 'User') {
        // Try to get display name from Firebase Auth user
        final currentUser = _auth.currentUser;
        if (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty) {
          finalDisplayName = currentUser.displayName!;
          print('✅ Using display name from Firebase Auth: $finalDisplayName');
        } else {
          // Fallback to email prefix
          finalDisplayName = email.split('@')[0];
          print('⚠️ Using email prefix as display name: $finalDisplayName');
        }
      }
      
      final userData = {
        'email': email,
        'displayName': finalDisplayName,
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

      print('✅ User profile created in Firestore with displayName: $finalDisplayName');

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
        
        // Also sync student data to Realtime Database
        await _syncStudentToRealtimeDatabase(uid, finalDisplayName, email, grade, allSubjects);
      }
    } catch (e) {
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  // Sync student data to Realtime Database
  Future<void> _syncStudentToRealtimeDatabase(
    String uid,
    String displayName,
    String email,
    String? grade,
    List<String> subjects,
  ) async {
    try {
      final student = Student(
        id: uid,
        name: displayName,
        email: email,
        grade: grade ?? 'Grade 7',
        section: 'A', // Default section
        subjects: subjects,
        teacherId: 'default_teacher', // Default teacher ID
        teacherName: 'Default Teacher',
        joinedAt: DateTime.now(),
        isActive: true,
        metadata: {
          'source': 'firestore_sync',
          'firestoreId': uid,
        },
      );

      final DatabaseReference ref = _database.ref('students/$uid');
      await ref.set(student.toRealtimeDatabase());
      
      print('✅ Student synced to Realtime Database: $displayName');
    } catch (e) {
      print('⚠️ Failed to sync student to Realtime Database: $e');
      // Don't throw error here as Firestore creation was successful
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        print('🔌 Offline mode, using cached user profile');
        return await _getCachedUserProfile(uid);
      }

      print('🌐 Online mode, fetching from Firestore');
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
      print('Firestore error, trying cached data: $e');
      // If Firestore fails, try to return cached data
      return await _getCachedUserProfile(uid);
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      // Update Firebase Auth user's display name if it's being changed
      if (data.containsKey('displayName') && _auth.currentUser?.uid == uid) {
        final newDisplayName = data['displayName'] as String;
        if (newDisplayName.isNotEmpty && _auth.currentUser?.displayName != newDisplayName) {
          await _auth.currentUser?.updateDisplayName(newDisplayName);
          await _auth.currentUser?.reload();
          print('✅ Updated Firebase Auth display name: $newDisplayName');
        }
      }
      
      data['lastLogin'] = firestore.FieldValue.serverTimestamp();
      await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(data);
      
      print('✅ Updated Firestore user profile for $uid with data: $data');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }

  // Check if user profile exists
  Future<bool> userProfileExists(String uid) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        print('🔌 Offline mode, checking cached user profile');
        final cachedProfile = await _getCachedUserProfile(uid);
        return cachedProfile != null;
      }

      print('🌐 Online mode, checking Firestore');
      // If online, check Firestore
      final doc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      print('Firestore error, checking cached data: $e');
      // If Firestore fails, check cached data
      final cachedProfile = await _getCachedUserProfile(uid);
      return cachedProfile != null;
    }
  }

  // Cache user profile locally
  Future<void> _cacheUserProfileLocally(UserModel user) async {
    try {
      final userData = user.toFirestore();
      userData['uid'] = user.uid; // Add uid to the data
      await OfflineService.cacheUserProfile(userData);
      print('✅ Cached user profile for ${user.uid}');
    } catch (e) {
      print('❌ Failed to cache user profile: $e');
    }
  }

  // Get cached user profile
  Future<UserModel?> _getCachedUserProfile(String uid) async {
    try {
      final cachedUserData = await OfflineService.getCachedUserProfile();
      if (cachedUserData != null && cachedUserData['uid'] == uid) {
        print('🔌 Offline mode, returning cached user profile for $uid');
        return UserModel.fromFirestore(cachedUserData, uid);
      }
      return null;
    } catch (e) {
      print('❌ Failed to get cached user profile: $e');
      return null;
    }
  }

  // Sync all existing students from Firestore to Realtime Database
  Future<void> syncAllStudentsToRealtimeDatabase() async {
    try {
      print('🔄 Syncing all students from Firestore to Realtime Database...');
      
      // Get all students from Firestore
      final studentsQuery = await firestore.FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      print('🔍 Found ${studentsQuery.docs.length} students in Firestore');
      
      for (var doc in studentsQuery.docs) {
        final data = doc.data();
        final uid = doc.id;
        final displayName = data['displayName'] ?? 'Unknown';
        final email = data['email'] ?? '';
        final grade = data['grade'] ?? 'Grade 7';
        final subjects = (data['subjects'] as List<dynamic>?)?.cast<String>() ?? [];
        
        // Check if student already exists in Realtime Database
        final DatabaseReference ref = _database.ref('students/$uid');
        final DatabaseEvent event = await ref.once();
        
        if (!event.snapshot.exists) {
          // Student doesn't exist in Realtime Database, sync it
          await _syncStudentToRealtimeDatabase(uid, displayName, email, grade, subjects);
          print('✅ Synced student: $displayName');
        } else {
          print('✅ Student already exists in Realtime Database: $displayName');
        }
      }
      
      print('✅ Finished syncing students to Realtime Database');
    } catch (e) {
      print('❌ Error syncing students to Realtime Database: $e');
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
