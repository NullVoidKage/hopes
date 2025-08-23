import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  teacher,
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final UserRole role;
  final String? grade; // For students
  final List<String>? subjects; // For teachers
  final DateTime createdAt;
  final DateTime lastLogin;
  final Map<String, dynamic>? assessmentResults; // For students
  final Map<String, dynamic>? lessonProgress; // For students

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.role,
    this.grade,
    this.subjects,
    required this.createdAt,
    required this.lastLogin,
    this.assessmentResults,
    this.lessonProgress,
  });

  // Create from Firebase User
  factory UserModel.fromFirebaseUser(
    String uid,
    String email,
    String displayName,
    String? photoURL,
    UserRole role, {
    String? grade,
    List<String>? subjects,
    Map<String, dynamic>? assessmentResults,
    Map<String, dynamic>? lessonProgress,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      role: role,
      grade: grade,
      subjects: subjects,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      assessmentResults: assessmentResults,
      lessonProgress: lessonProgress,
    );
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.student,
      ),
      grade: data['grade'],
      subjects: data['subjects'] != null
          ? List<String>.from(data['subjects'])
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
      assessmentResults: data['assessmentResults'],
      lessonProgress: data['lessonProgress'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.toString().split('.').last,
      'grade': grade,
      'subjects': subjects,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'assessmentResults': assessmentResults,
      'lessonProgress': lessonProgress,
    };
  }

  // Create copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? role,
    String? grade,
    List<String>? subjects,
    DateTime? createdAt,
    DateTime? lastLogin,
    Map<String, dynamic>? assessmentResults,
    Map<String, dynamic>? lessonProgress,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      grade: grade ?? this.grade,
      subjects: subjects ?? this.subjects,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      assessmentResults: assessmentResults ?? this.assessmentResults,
      lessonProgress: lessonProgress ?? this.lessonProgress,
    );
  }

  // Check if user is a student
  bool get isStudent => role == UserRole.student;

  // Check if user is a teacher
  bool get isTeacher => role == UserRole.teacher;

  // Get role display name
  String get roleDisplayName {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
    }
  }
}
