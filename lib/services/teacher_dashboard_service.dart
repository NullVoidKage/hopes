import 'package:firebase_database/firebase_database.dart';
import '../models/student_progress.dart';
import '../models/teacher_activity.dart';
import 'offline_service.dart';
import 'connectivity_service.dart';

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
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get all dashboard data for a teacher
  Future<TeacherDashboardData> getDashboardData(String teacherId, List<String> teacherSubjects) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedDashboardData(teacherId, teacherSubjects);
      }

      // If online, fetch from Firebase and cache
      final studentProgress = await _getStudentProgress(teacherSubjects);
      final recentActivities = await _getRecentActivities(teacherId);
      final stats = _calculateStats(studentProgress);
      
      final dashboardData = TeacherDashboardData(
        studentProgress: studentProgress,
        recentActivities: recentActivities,
        subjectStats: stats['subjectStats'],
        totalStudents: stats['totalStudents'],
        activeStudents: stats['activeStudents'],
        averageProgress: stats['averageProgress'],
      );

      // Cache the data for offline use
      await _cacheDashboardData(dashboardData);
      
      return dashboardData;
    } catch (e) {
      // If Firebase fails, try to return cached data
      print('Firebase error, trying cached data: $e');
      return await _getCachedDashboardData(teacherId, teacherSubjects);
    }
  }

  // Get student progress for teacher's subjects
  Future<List<StudentProgress>> _getStudentProgress(List<String> subjects) async {
    try {
      print('🔍 TeacherDashboardService: Fetching student progress for subjects: $subjects');
      
      final DatabaseReference ref = _database.ref('student_progress');
      final DatabaseEvent event = await ref.once();
      final DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value == null) {
        print('🔍 TeacherDashboardService: No student progress data found');
        return [];
      }
      
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        print('🔍 TeacherDashboardService: Student progress data is null');
        return [];
      }
      
      print('🔍 TeacherDashboardService: Found ${data.entries.length} progress entries');
      
      final progressList = data.entries.map((entry) {
        final entryData = entry.value as Map<dynamic, dynamic>?;
        if (entryData == null) return null;
        
        try {
          return StudentProgress.fromRealtimeDatabase(
            Map<String, dynamic>.from(entryData),
            entry.key.toString(),
          );
        } catch (e) {
          print('🔍 TeacherDashboardService: Error parsing progress data: $e');
          return null;
        }
      }).whereType<StudentProgress>().toList();
      
      print('🔍 TeacherDashboardService: Successfully parsed ${progressList.length} progress records');
      return progressList;
    } catch (e) {
      print('🔍 TeacherDashboardService: Error fetching student progress: $e');
      return [];
    }
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
      
      // Count active students (with activity in last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      if (progress.lastActivity.isAfter(weekAgo)) {
        activeStudents++;
      }
      
      // Calculate total progress
      totalProgress += progress.completionRate;
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

  // Get cached dashboard data
  Future<TeacherDashboardData> _getCachedDashboardData(String teacherId, List<String> teacherSubjects) async {
    try {
      final cachedProgress = await OfflineService.getCachedStudentProgress();
      final cachedActivities = await OfflineService.getCachedTeacherActivities();
      
      // Convert cached data to proper models
      final studentProgress = cachedProgress.map((data) => 
        StudentProgress.fromRealtimeDatabase(data, data['id'] ?? '')
      ).toList();
      
      final recentActivities = cachedActivities.map((data) => 
        TeacherActivity.fromRealtimeDatabase(data['id'] ?? '', data)
      ).toList();
      
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
      print('Error getting cached dashboard data: $e');
      // Return empty dashboard data if cache fails
      return TeacherDashboardData(
        studentProgress: [],
        recentActivities: [],
        subjectStats: <String, int>{},
        totalStudents: 0,
        activeStudents: 0,
        averageProgress: 0.0,
      );
    }
  }

  // Cache dashboard data
  Future<void> _cacheDashboardData(TeacherDashboardData data) async {
    try {
      // Cache student progress
      final progressData = data.studentProgress.map((progress) => {
        'id': progress.id,
        'studentId': progress.studentId,
        'studentName': progress.studentName,
        'studentEmail': progress.studentEmail,
        'subject': progress.subject,
        'lessonsCompleted': progress.lessonsCompleted,
        'totalLessons': progress.totalLessons,
        'assessmentsTaken': progress.assessmentsTaken,
        'totalAssessments': progress.totalAssessments,
        'averageScore': progress.averageScore,
        'completionRate': progress.completionRate,
        'lastActivity': progress.lastActivity.millisecondsSinceEpoch,
        'lessonProgress': progress.lessonProgress.fold<Map<String, dynamic>>({}, (map, lesson) {
          map[lesson.lessonId] = lesson.toMap();
          return map;
        }),
        'assessmentProgress': progress.assessmentProgress.fold<Map<String, dynamic>>({}, (map, assessment) {
          map[assessment.assessmentId] = assessment.toMap();
          return map;
        }),
        'metadata': progress.metadata,
      }).toList();
      
      await OfflineService.cacheStudentProgress(progressData);
      
      // Cache teacher activities
      final activitiesData = data.recentActivities.map((activity) => {
        'id': activity.id,
        'teacherId': activity.teacherId,
        'type': activity.type.toString().split('.').last,
        'title': activity.title,
        'description': activity.description,
        'subject': activity.subject,
        'timestamp': activity.timestamp.millisecondsSinceEpoch,
        'metadata': activity.metadata,
      }).toList();
      
      await OfflineService.cacheTeacherActivities(activitiesData);
    } catch (e) {
      print('Error caching dashboard data: $e');
    }
  }
}
