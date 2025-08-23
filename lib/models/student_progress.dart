import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProgress {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String subject;
  final double progressPercentage;
  final int completedLessons;
  final int totalLessons;
  final DateTime lastActivity;
  final Map<String, dynamic> assessmentScores;
  final bool isActive;

  StudentProgress({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.subject,
    required this.progressPercentage,
    required this.completedLessons,
    required this.totalLessons,
    required this.lastActivity,
    this.assessmentScores = const {},
    this.isActive = true,
  });

  // Create from Firestore document
  factory StudentProgress.fromFirestore(Map<String, dynamic> data, String id) {
    return StudentProgress(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      subject: data['subject'] ?? '',
      progressPercentage: (data['progressPercentage'] ?? 0.0).toDouble(),
      completedLessons: data['completedLessons'] ?? 0,
      totalLessons: data['totalLessons'] ?? 0,
      lastActivity: (data['lastActivity'] as Timestamp).toDate(),
      assessmentScores: data['assessmentScores'] ?? {},
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'subject': subject,
      'progressPercentage': progressPercentage,
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
      'lastActivity': lastActivity,
      'assessmentScores': assessmentScores,
      'isActive': isActive,
    };
  }
}
