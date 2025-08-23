import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class OfflineService {
  static const String _lessonsKey = 'cached_lessons';
  static const String _assessmentsKey = 'cached_assessments';
  static const String _studentProgressKey = 'cached_student_progress';
  static const String _studentsKey = 'cached_students';
  static const String _userProfileKey = 'cached_user_profile';
  static const String _teacherActivitiesKey = 'cached_teacher_activities';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _isOnlineKey = 'is_online_status';

  // Check if device is online
  static bool _isOnline = true;
  static bool get isOnline => _isOnline;

  // Set online/offline status
  static void setOnlineStatus(bool status) {
    _isOnline = status;
    _saveOnlineStatus(status);
  }

  // Save online status to local storage
  static Future<void> _saveOnlineStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isOnlineKey, status);
  }

  // Cache lessons data
  static Future<void> cacheLessons(List<Map<String, dynamic>> lessons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessonsJson = jsonEncode(lessons);
      await prefs.setString(_lessonsKey, lessonsJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching lessons: $e');
      }
    }
  }

  // Get cached lessons
  static Future<List<Map<String, dynamic>>> getCachedLessons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessonsJson = prefs.getString(_lessonsKey);
      if (lessonsJson != null) {
        final List<dynamic> lessonsList = jsonDecode(lessonsJson);
        return lessonsList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached lessons: $e');
      }
      return [];
    }
  }

  // Cache assessments data
  static Future<void> cacheAssessments(List<Map<String, dynamic>> assessments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assessmentsJson = jsonEncode(assessments);
      await prefs.setString(_assessmentsKey, assessmentsJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching assessments: $e');
      }
    }
  }

  // Get cached assessments
  static Future<List<Map<String, dynamic>>> getCachedAssessments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assessmentsJson = prefs.getString(_assessmentsKey);
      if (assessmentsJson != null) {
        final List<dynamic> assessmentsList = jsonDecode(assessmentsJson);
        return assessmentsList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached assessments: $e');
      }
      return [];
    }
  }

  // Cache teacher activities data
  static Future<void> cacheTeacherActivities(List<Map<String, dynamic>> activities) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = jsonEncode(activities);
      await prefs.setString(_teacherActivitiesKey, activitiesJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching teacher activities: $e');
      }
    }
  }

  // Get cached teacher activities
  static Future<List<Map<String, dynamic>>> getCachedTeacherActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = prefs.getString(_teacherActivitiesKey);
      if (activitiesJson != null) {
        final List<dynamic> activitiesList = jsonDecode(activitiesJson);
        return activitiesList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached teacher activities: $e');
      }
      return [];
    }
  }

  // Cache student progress data
  static Future<void> cacheStudentProgress(List<Map<String, dynamic>> progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = jsonEncode(progress);
      await prefs.setString(_studentProgressKey, progressJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching student progress: $e');
      }
    }
  }

  // Get cached student progress
  static Future<List<Map<String, dynamic>>> getCachedStudentProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_studentProgressKey);
      if (progressJson != null) {
        final List<dynamic> progressList = jsonDecode(progressJson);
        return progressList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached student progress: $e');
      }
      return [];
    }
  }

  // Cache user profile
  static Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile);
      await prefs.setString(_userProfileKey, profileJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching user profile: $e');
      }
    }
  }

  // Get cached user profile
  static Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      if (profileJson != null) {
        return jsonDecode(profileJson);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached user profile: $e');
      }
      return null;
    }
  }

  // Update last sync timestamp
  static Future<void> _updateLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating last sync: $e');
      }
    }
  }

  // Get last sync timestamp
  static Future<DateTime?> getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last sync: $e');
      }
      return null;
    }
  }

  // Get cache size info
  static Future<Map<String, int>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessons = prefs.getString(_lessonsKey)?.length ?? 0;
      final assessments = prefs.getString(_assessmentsKey)?.length ?? 0;
      final progress = prefs.getString(_studentProgressKey)?.length ?? 0;
      final students = prefs.getString(_studentsKey)?.length ?? 0;
      final profile = prefs.getString(_userProfileKey)?.length ?? 0;
      final activities = prefs.getString(_teacherActivitiesKey)?.length ?? 0;
      
      return {
        'lessons': lessons,
        'assessments': assessments,
        'progress': progress,
        'students': students,
        'profile': profile,
        'activities': activities,
        'total': lessons + assessments + progress + students + profile + activities,
      };
    } catch (e) {
      return {
        'lessons': 0,
        'assessments': 0,
        'progress': 0,
        'students': 0,
        'profile': 0,
        'activities': 0,
        'total': 0,
      };
    }
  }

  // Check if data is stale (older than 1 hour)
  static Future<bool> isDataStale() async {
    try {
      final lastSync = await getLastSync();
      if (lastSync == null) return true;
      
      final now = DateTime.now();
      final difference = now.difference(lastSync);
      return difference.inHours > 1;
    } catch (e) {
      return true;
    }
  }

  // Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lessonsKey);
      await prefs.remove(_assessmentsKey);
      await prefs.remove(_studentProgressKey);
      await prefs.remove(_studentsKey);
      await prefs.remove(_userProfileKey);
      await prefs.remove(_teacherActivitiesKey);
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cache: $e');
      }
    }
  }

  // Populate cache with sample data for offline testing
  static Future<void> populateSampleData([String? currentTeacherId]) async {
    try {
      // Sample student progress data
      final sampleProgress = [
        {
          'id': 'sample_progress_1',
          'studentId': 'student_1',
          'studentName': 'John Doe',
          'studentEmail': 'john@example.com',
          'subject': 'Mathematics',
          'lessonsCompleted': 5,
          'totalLessons': 10,
          'assessmentsTaken': 2,
          'totalAssessments': 3,
          'averageScore': 85.0,
          'completionRate': 50.0,
          'lastActivity': DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
          'lessonProgress': {},
          'assessmentProgress': {},
          'metadata': {},
        },
        {
          'id': 'sample_progress_2',
          'studentId': 'student_2',
          'studentName': 'Jane Smith',
          'studentEmail': 'jane@example.com',
          'subject': 'GMRC',
          'lessonsCompleted': 8,
          'totalLessons': 12,
          'assessmentsTaken': 3,
          'totalAssessments': 4,
          'averageScore': 92.0,
          'completionRate': 66.7,
          'lastActivity': DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
          'lessonProgress': {},
          'assessmentProgress': {},
          'metadata': {},
        },
      ];

      // Sample assessments data
      final sampleAssessments = [
        {
          'id': 'sample_assessment_1',
          'title': 'Math Quiz 1',
          'description': 'Basic algebra assessment for Chapter 1',
          'subject': 'Mathematics',
          'teacherId': currentTeacherId ?? 'current_teacher',
          'teacherName': 'Sample Teacher',
          'createdAt': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          'updatedAt': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          'isPublished': true,
          'tags': ['algebra', 'basics'],
          'timeLimit': 30,
          'totalPoints': 100,
          'questions': [],
          'dueDate': DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
          'instructions': 'Complete all questions within the time limit.',
        },
        {
          'id': 'sample_assessment_2',
          'title': 'Values Education Test 1',
          'description': 'Introduction to moral values and ethics',
          'subject': 'Values Education',
          'teacherId': currentTeacherId ?? 'current_teacher',
          'teacherName': 'Sample Teacher',
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
          'updatedAt': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
          'isPublished': false,
          'tags': ['values', 'ethics', 'morals'],
          'timeLimit': 45,
          'totalPoints': 100,
          'questions': [],
          'dueDate': null,
          'instructions': 'Answer all questions carefully.',
        },
      ];

      // Sample teacher activities
      final sampleActivities = [
        {
          'id': 'sample_activity_1',
          'teacherId': currentTeacherId ?? 'current_teacher',
          'type': 'lessonUpload',
          'title': 'Algebra Basics',
          'description': 'Uploaded new lesson on algebraic expressions',
          'subject': 'Mathematics',
          'timestamp': DateTime.now().subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
          'metadata': {},
        },
        {
          'id': 'sample_activity_2',
          'teacherId': currentTeacherId ?? 'current_teacher',
          'type': 'assessmentCreated',
          'title': 'Values Education Assessment',
          'description': 'Created assessment for moral values',
          'subject': 'Values Education',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
          'metadata': {},
        },
      ];

      // Sample students data
      final sampleStudents = [
        {
          'id': 'student_1',
          'name': 'John Doe',
          'email': 'john@example.com',
          'grade': '7',
          'teacherId': currentTeacherId ?? 'current_teacher',
          'subjects': ['Mathematics', 'GMRC', 'Values Education', 'Araling Panlipunan', 'English', 'Filipino', 'Music & Arts', 'Science', 'Physical Education & Health', 'EPP', 'TLE'],
          'joinedAt': DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'isActive': true,
          'photoURL': null,
        },
        {
          'id': 'student_2',
          'name': 'Jane Smith',
          'email': 'jane@example.com',
          'grade': '7',
          'teacherId': currentTeacherId ?? 'current_teacher',
          'subjects': ['Mathematics', 'GMRC', 'Values Education', 'Araling Panlipunan', 'English', 'Filipino', 'Music & Arts', 'Science', 'Physical Education & Health', 'EPP', 'TLE'],
          'joinedAt': DateTime.now().subtract(const Duration(days: 25)).millisecondsSinceEpoch,
          'isActive': true,
          'photoURL': null,
        },
      ];

      await cacheStudentProgress(sampleProgress);
      await cacheAssessments(sampleAssessments);
      await cacheTeacherActivities(sampleActivities);
      await cacheStudents(sampleStudents);
      
      if (kDebugMode) {
        print('Sample data populated successfully');
        print('📊 Cached ${sampleProgress.length} progress items');
        print('📊 Cached ${sampleAssessments.length} assessments');
        print('📊 Cached ${sampleActivities.length} activities');
        print('📊 Cached ${sampleStudents.length} students');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error populating sample data: $e');
      }
    }
  }

  // Cache students data
  static Future<void> cacheStudents(List<Map<String, dynamic>> students) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentsJson = jsonEncode(students);
      await prefs.setString(_studentsKey, studentsJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching students: $e');
      }
    }
  }

  // Get cached students
  static Future<List<Map<String, dynamic>>> getCachedStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentsJson = prefs.getString(_studentsKey);
      if (studentsJson != null) {
        final List<dynamic> studentsList = jsonDecode(studentsJson);
        return studentsList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached students: $e');
      }
      return [];
    }
  }
}
