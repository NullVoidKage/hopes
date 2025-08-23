import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/student.dart';
import '../models/student_progress.dart';

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

      // If the user is a student, automatically create a student record with all subjects
      if (role == UserRole.student) {
        await _createStudentRecord(
          uid: uid,
          email: email,
          displayName: displayName,
          grade: grade ?? 'Grade 7',
        );
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

  // Create student record in Firebase Realtime Database with all subjects
  Future<void> _createStudentRecord({
    required String uid,
    required String email,
    required String displayName,
    required String grade,
  }) async {
    try {
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
      
      // Get the current teacher ID from the auth context
      // For now, we'll use a default teacher ID that matches the first teacher in the system
      String teacherId = 'default_teacher';
      String teacherName = 'Default Teacher';
      
      // Try to find the first available teacher in the system
      try {
        final teachersQuery = await firestore.FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .limit(1)
            .get();
        
        if (teachersQuery.docs.isNotEmpty) {
          teacherId = teachersQuery.docs.first.id;
          teacherName = teachersQuery.docs.first.data()['displayName'] ?? 'Teacher';
          print('✅ Found teacher: $teacherName with ID: $teacherId');
        } else {
          print('⚠️ No teachers found, using default teacher ID');
        }
      } catch (e) {
        print('❌ Error finding teacher: $e');
      }

      // First, update the Firestore document with subjects
      try {
        await firestore.FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'subjects': allSubjects,
        });
        print('✅ Updated Firestore subjects for $displayName');
      } catch (e) {
        print('❌ Error updating Firestore subjects: $e');
      }

      final student = Student(
        id: '', // Will be set by Firebase
        name: displayName,
        email: email,
        grade: grade,
        section: 'A', // Default section
        subjects: allSubjects, // Automatically enrolled in all subjects
        teacherId: teacherId,
        teacherName: teacherName,
        joinedAt: DateTime.now(),
        isActive: true,
        metadata: {
          'autoEnrolled': true,
          'enrolledAt': DateTime.now().millisecondsSinceEpoch,
        },
      );

      print('🔍 Creating student record in Firebase Realtime Database...');
      print('🔍 Student data: ${student.toRealtimeDatabase()}');
      
      final DatabaseReference ref = FirebaseDatabase.instance.ref('students');
      final DatabaseReference newStudentRef = ref.push();
      
      try {
        await newStudentRef.set(student.toRealtimeDatabase());
        print('✅ Student record saved to Firebase Realtime Database');
        
        final studentId = newStudentRef.key!;
        print('🔍 Student ID generated: $studentId');

        // Create progress records for each subject
        await _createStudentProgressRecords(
          studentId: studentId,
          studentName: displayName,
          studentEmail: email,
          subjects: allSubjects,
          teacherId: teacherId,
        );

        print('✅ Student record created successfully for $displayName with all subjects: $allSubjects');
      } catch (e) {
        print('❌ Error saving student to Firebase Realtime Database: $e');
        rethrow;
      }
    } catch (e) {
      print('❌ Error creating student record: $e');
      // Don't throw here to avoid breaking the user registration flow
    }
  }

  // Create student progress records for each subject
  Future<void> _createStudentProgressRecords({
    required String studentId,
    required String studentName,
    required String studentEmail,
    required List<String> subjects,
    required String teacherId,
  }) async {
    try {
      print('🔍 Creating progress records for $studentName in ${subjects.length} subjects...');
      final DatabaseReference progressRef = FirebaseDatabase.instance.ref('student_progress');
      
      for (String subject in subjects) {
        print('🔍 Creating progress record for subject: $subject');
        
        final progressRecord = StudentProgress(
          id: '', // Will be set by Firebase
          studentId: studentId,
          studentName: studentName,
          studentEmail: studentEmail,
          subject: subject,
          lessonsCompleted: 0,
          totalLessons: 0,
          assessmentsTaken: 0,
          totalAssessments: 0,
          averageScore: 0.0,
          completionRate: 0.0,
          lastActivity: DateTime.now(),
          lessonProgress: [],
          assessmentProgress: [],
          metadata: {
            'autoCreated': true,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'teacherId': teacherId,
          },
        );

        try {
          await progressRef.push().set(progressRecord.toRealtimeDatabase());
          print('✅ Progress record created for $subject');
        } catch (e) {
          print('❌ Error creating progress record for $subject: $e');
        }
      }

      print('✅ Created progress records for $studentName in ${subjects.length} subjects');
    } catch (e) {
      print('❌ Error creating student progress records: $e');
      // Don't throw here to avoid breaking the flow
    }
  }

  // Create student record in Realtime Database only (for fixing existing students)
  Future<void> _createStudentRecordInRealtimeOnly({
    required String uid,
    required String email,
    required String displayName,
    required String grade,
  }) async {
    try {
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
      
      // Get the current teacher ID from the auth context
      String teacherId = 'default_teacher';
      String teacherName = 'Default Teacher';
      
      // Try to find the first available teacher in the system
      try {
        final teachersQuery = await firestore.FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .limit(1)
            .get();
        
        if (teachersQuery.docs.isNotEmpty) {
          teacherId = teachersQuery.docs.first.id;
          teacherName = teachersQuery.docs.first.data()['displayName'] ?? 'Teacher';
          print('✅ Found teacher: $teacherName with ID: $teacherId');
        } else {
          print('⚠️ No teachers found, using default teacher ID');
        }
      } catch (e) {
        print('❌ Error finding teacher: $e');
      }

      final student = Student(
        id: '', // Will be set by Firebase
        name: displayName,
        email: email,
        grade: grade,
        section: 'A', // Default section
        subjects: allSubjects, // Automatically enrolled in all subjects
        teacherId: teacherId,
        teacherName: teacherName,
        joinedAt: DateTime.now(),
        isActive: true,
        metadata: {
          'autoEnrolled': true,
          'enrolledAt': DateTime.now().millisecondsSinceEpoch,
        },
      );

      print('🔍 Creating student record in Firebase Realtime Database...');
      print('🔍 Student data: ${student.toRealtimeDatabase()}');
      
      final DatabaseReference ref = FirebaseDatabase.instance.ref('students');
      final DatabaseReference newStudentRef = ref.push();
      
      try {
        await newStudentRef.set(student.toRealtimeDatabase());
        print('✅ Student record saved to Firebase Realtime Database');
        
        final studentId = newStudentRef.key!;
        print('🔍 Student ID generated: $studentId');

        // Create progress records for each subject
        await _createStudentProgressRecords(
          studentId: studentId,
          studentName: displayName,
          studentEmail: email,
          subjects: allSubjects,
          teacherId: teacherId,
        );

        print('✅ Student record created successfully for $displayName with all subjects: $allSubjects');
      } catch (e) {
        print('❌ Error saving student to Firebase Realtime Database: $e');
        rethrow;
      }
    } catch (e) {
      print('❌ Error creating student record: $e');
      // Don't throw here to avoid breaking the flow
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
          
          // Check if student record exists in Realtime Database
          final DatabaseReference ref = FirebaseDatabase.instance.ref('students');
          final Query query = ref.orderByChild('email').equalTo(data['email']);
          final DatabaseEvent event = await query.once();
          
          if (event.snapshot.value == null) {
            print('🔍 Creating missing student record in Realtime Database for ${data['displayName']}');
            
            // Create student record in Realtime Database only (Firestore already updated above)
            await _createStudentRecordInRealtimeOnly(
              uid: doc.id,
              email: data['email'],
              displayName: data['displayName'],
              grade: data['grade'] ?? 'Grade 7',
            );
          } else {
            print('✅ Student record already exists in Realtime Database for ${data['displayName']}');
          }
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
