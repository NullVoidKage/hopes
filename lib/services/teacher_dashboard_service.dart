import 'package:firebase_database/firebase_database.dart';
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
  final FirebaseDatabase _database = FirebaseDatabase.instance;

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
    // For now, return empty list until we implement student progress
    return [];
  }

  // Get recent activities for teacher
  Future<List<TeacherActivity>> _getRecentActivities(String teacherId) async {
    try {
      final snapshot = await _database
          .ref('teacher_activities')
          .child(teacherId)
          .get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          final activities = <TeacherActivity>[];
          data.forEach((key, value) {
            if (value is Map) {
              try {
                final activity = TeacherActivity.fromRealtimeDatabase(key.toString(), value);
                activities.add(activity);
              } catch (e) {
                print('Error parsing teacher activity: $e');
              }
            }
          });
          
          // Sort by timestamp (newest first) and take last 10
          activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return activities.take(10).toList();
        }
      }
      
      return [];
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

  // Log a new teacher activity
  Future<void> logActivity(String teacherId, String type, String title, String description) async {
    try {
      await _database.ref('teacher_activities').child(teacherId).push().set({
        'type': type.toString().split('.').last,
        'title': title,
        'description': description,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to log activity: ${e.toString()}');
    }
  }
}
