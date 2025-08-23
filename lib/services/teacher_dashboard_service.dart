import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_progress.dart';
import '../models/teacher_activity.dart';

class TeacherDashboardData {
  final List<StudentProgress> studentProgress;
  final List<TeacherActivity> recentActivities;
  final Map<String, int> subjectStats;
  final int totalStudents;
  final int activeStudents;
  final double averageProgress;

  TeacherDashboardData({
    required this.studentProgress,
    required this.recentActivities,
    required this.subjectStats,
    required this.totalStudents,
    required this.activeStudents,
    required this.averageProgress,
  });
}

class TeacherDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all dashboard data for a teacher
  Future<TeacherDashboardData> getDashboardData(String teacherId, List<String> teacherSubjects) async {
    try {
      // Fetch student progress for teacher's subjects
      final studentProgress = await _getStudentProgress(teacherSubjects);
      
      // Fetch recent activities for this teacher
      final recentActivities = await _getRecentActivities(teacherId);
      
      // Calculate statistics
      final stats = _calculateStats(studentProgress);
      
      return TeacherDashboardData(
        studentProgress: studentProgress,
        recentActivities: recentActivities,
        subjectStats: stats['subjectStats'],
        totalStudents: stats['totalStudents'],
        activeStudents: stats['activeStudents'],
        averageProgress: stats['averageProgress'],
      );
    } catch (e) {
      throw Exception('Failed to load dashboard data: ${e.toString()}');
    }
  }

  // Get student progress for teacher's subjects
  Future<List<StudentProgress>> _getStudentProgress(List<String> subjects) async {
    try {
      final List<StudentProgress> allProgress = [];
      
      for (String subject in subjects) {
        final query = await _firestore
            .collection('student_progress')
            .where('subject', isEqualTo: subject)
            .orderBy('progressPercentage', descending: true)
            .limit(20)
            .get();
        
        final subjectProgress = query.docs
            .map((doc) => StudentProgress.fromFirestore(doc.data(), doc.id))
            .toList();
        
        allProgress.addAll(subjectProgress);
      }
      
      return allProgress;
    } catch (e) {
      // Return empty list if collection doesn't exist yet
      return [];
    }
  }

  // Get recent activities for teacher
  Future<List<TeacherActivity>> _getRecentActivities(String teacherId) async {
    try {
      final query = await _firestore
          .collection('teacher_activities')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      
      return query.docs
          .map((doc) => TeacherActivity.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Return empty list if collection doesn't exist yet
      return [];
    }
  }

  // Calculate dashboard statistics
  Map<String, dynamic> _calculateStats(List<StudentProgress> studentProgress) {
    if (studentProgress.isEmpty) {
      return {
        'subjectStats': <String, int>{},
        'totalStudents': 0,
        'activeStudents': 0,
        'averageProgress': 0.0,
      };
    }

    final Map<String, int> subjectStats = {};
    final Set<String> uniqueStudents = {};
    int activeStudents = 0;
    double totalProgress = 0.0;

    for (final progress in studentProgress) {
      // Count subjects
      subjectStats[progress.subject] = (subjectStats[progress.subject] ?? 0) + 1;
      
      // Count unique students
      uniqueStudents.add(progress.studentId);
      
      // Count active students
      if (progress.isActive) {
        activeStudents++;
      }
      
      // Calculate total progress
      totalProgress += progress.progressPercentage;
    }

    return {
      'subjectStats': subjectStats,
      'totalStudents': uniqueStudents.length,
      'activeStudents': activeStudents,
      'averageProgress': studentProgress.isNotEmpty ? totalProgress / studentProgress.length : 0.0,
    };
  }



  // Add a new activity (called when teacher performs actions)
  Future<void> addActivity({
    required String teacherId,
    required ActivityType type,
    required String title,
    required String description,
    required String subject,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      await _firestore.collection('teacher_activities').add({
        'teacherId': teacherId,
        'type': type.toString().split('.').last,
        'title': title,
        'description': description,
        'subject': subject,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata,
      });
    } catch (e) {
      throw Exception('Failed to add activity: ${e.toString()}');
    }
  }
}
