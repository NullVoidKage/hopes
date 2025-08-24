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
  static const String _learningPathsKey = 'cached_learning_paths';
  static const String _studentLearningPathsKey = 'cached_student_learning_paths';
  static const String _feedbackKey = 'cached_feedback';
  static const String _recommendationsKey = 'cached_recommendations';
  static const String _achievementsKey = 'cached_achievements';
  static const String _studentAchievementsKey = 'cached_student_achievements';
  static const String _leaderboardKey = 'cached_leaderboard';
  static const String _adaptiveDifficultiesKey = 'cached_adaptive_difficulties';
  static const String _difficultyAdjustmentsKey = 'cached_difficulty_adjustments';
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

  // Cache learning paths data
  static Future<void> cacheLearningPath(Map<String, dynamic> learningPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingPaths = await getCachedLearningPaths();
      
      // Check if path already exists
      final existingIndex = existingPaths.indexWhere((path) => path['id'] == learningPath['id']);
      if (existingIndex != -1) {
        existingPaths[existingIndex] = learningPath;
      } else {
        existingPaths.add(learningPath);
      }
      
      final pathsJson = jsonEncode(existingPaths);
      await prefs.setString(_learningPathsKey, pathsJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching learning path: $e');
      }
    }
  }

  // Get cached learning paths
  static Future<List<Map<String, dynamic>>> getCachedLearningPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pathsJson = prefs.getString(_learningPathsKey);
      if (pathsJson != null) {
        final List<dynamic> pathsList = jsonDecode(pathsJson);
        return pathsList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached learning paths: $e');
      }
      return [];
    }
  }

  // Cache student learning paths data
  static Future<void> cacheStudentLearningPath(Map<String, dynamic> studentLearningPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingAssignments = await getCachedStudentLearningPaths();
      
      // Check if assignment already exists
      final existingIndex = existingAssignments.indexWhere((assignment) => assignment['id'] == studentLearningPath['id']);
      if (existingIndex != -1) {
        existingAssignments[existingIndex] = studentLearningPath;
      } else {
        existingAssignments.add(studentLearningPath);
      }
      
      final assignmentsJson = jsonEncode(existingAssignments);
      await prefs.setString(_studentLearningPathsKey, assignmentsJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching student learning path: $e');
      }
    }
  }

  // Get cached student learning paths
  static Future<List<Map<String, dynamic>>> getCachedStudentLearningPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assignmentsJson = prefs.getString(_studentLearningPathsKey);
      if (assignmentsJson != null) {
        final List<dynamic> assignmentsList = jsonDecode(assignmentsJson);
        return assignmentsList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached student learning paths: $e');
      }
      return [];
    }
  }

  // Queue learning path for sync
  static Future<void> queueLearningPathForSync(Map<String, dynamic> learningPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'sync_learning_paths';
      final existingQueue = prefs.getString(syncKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        final List<dynamic> queueList = jsonDecode(existingQueue);
        queue = queueList.cast<Map<String, dynamic>>();
      }
      
      queue.add(learningPath);
      final queueJson = jsonEncode(queue);
      await prefs.setString(syncKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error queuing learning path for sync: $e');
      }
    }
  }

  // Queue assignment for sync
  static Future<void> queueAssignmentForSync(Map<String, dynamic> assignment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'sync_assignments';
      final existingQueue = prefs.getString(syncKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        final List<dynamic> queueList = jsonDecode(existingQueue);
        queue = queueList.cast<Map<String, dynamic>>();
      }
      
      queue.add(assignment);
      final queueJson = jsonEncode(queue);
      await prefs.setString(syncKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error queuing assignment for sync: $e');
      }
    }
  }

  // Queue progress update for sync
  static Future<void> queueProgressUpdateForSync(Map<String, dynamic> progressUpdate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'sync_progress_updates';
      final existingQueue = prefs.getString(syncKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        final List<dynamic> queueList = jsonDecode(existingQueue);
        queue = queueList.cast<Map<String, dynamic>>();
      }
      
      queue.add(progressUpdate);
      final queueJson = jsonEncode(queue);
      await prefs.setString(syncKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error queuing progress update for sync: $e');
      }
    }
  }

  // Queue customization for sync
  static Future<void> queueCustomizationForSync(Map<String, dynamic> customization) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'sync_customizations';
      final existingQueue = prefs.getString(syncKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        final List<dynamic> queueList = jsonDecode(existingQueue);
        queue = queueList.cast<Map<String, dynamic>>();
      }
      
      queue.add(customization);
      final queueJson = jsonEncode(queue);
      await prefs.setString(syncKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error queuing customization for sync: $e');
      }
    }
  }

  // Remove learning path from cache
  static Future<void> removeLearningPathFromCache(String pathId) async {
    try {
      final existingPaths = await getCachedLearningPaths();
      existingPaths.removeWhere((path) => path['id'] == pathId);
      
      final prefs = await SharedPreferences.getInstance();
      final pathsJson = jsonEncode(existingPaths);
      await prefs.setString(_learningPathsKey, pathsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing learning path from cache: $e');
      }
    }
  }

  // Mark learning path for deletion
  static Future<void> markLearningPathForDeletion(String pathId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletionKey = 'deleted_learning_paths';
      final existingDeletions = prefs.getString(deletionKey);
      List<String> deletions = [];
      
      if (existingDeletions != null) {
        final List<dynamic> deletionsList = jsonDecode(existingDeletions);
        deletions = deletionsList.cast<String>();
      }
      
      if (!deletions.contains(pathId)) {
        deletions.add(pathId);
        final deletionsJson = jsonEncode(deletions);
        await prefs.setString(deletionKey, deletionsJson);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking learning path for deletion: $e');
      }
    }
  }

  // Update cached student learning path
  static Future<void> updateCachedStudentLearningPath(
    String assignmentId,
    List<Map<String, dynamic>> stepProgress,
    String status,
  ) async {
    try {
      final existingAssignments = await getCachedStudentLearningPaths();
      final assignmentIndex = existingAssignments.indexWhere((assignment) => assignment['id'] == assignmentId);
      
      if (assignmentIndex != -1) {
        existingAssignments[assignmentIndex]['stepProgress'] = stepProgress;
        existingAssignments[assignmentIndex]['status'] = status;
        
        final prefs = await SharedPreferences.getInstance();
        final assignmentsJson = jsonEncode(existingAssignments);
        await prefs.setString(_studentLearningPathsKey, assignmentsJson);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating cached student learning path: $e');
      }
    }
  }

  // Update cached customizations
  static Future<void> updateCachedCustomizations(
    String assignmentId,
    Map<String, dynamic> customizations,
  ) async {
    try {
      final existingAssignments = await getCachedStudentLearningPaths();
      final assignmentIndex = existingAssignments.indexWhere((assignment) => assignment['id'] == assignmentId);
      
      if (assignmentIndex != -1) {
        existingAssignments[assignmentIndex]['customizations'] = customizations;
        
        final prefs = await SharedPreferences.getInstance();
        final assignmentsJson = jsonEncode(existingAssignments);
        await prefs.setString(_studentLearningPathsKey, assignmentsJson);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating cached customizations: $e');
      }
    }
  }

  // Get cached available content
  static Future<Map<String, List<dynamic>>> getCachedAvailableContent() async {
    try {
      final lessons = await getCachedLessons();
      final assessments = await getCachedAssessments();
      
      final lessonContent = lessons.map((lesson) => {
        'id': lesson['id'],
        'title': lesson['title'],
        'type': 'lesson',
      }).toList();
      
      final assessmentContent = assessments.map((assessment) => {
        'id': assessment['id'],
        'title': assessment['title'],
        'type': 'assessment',
      }).toList();
      
      return {
        'lessons': lessonContent,
        'assessments': assessmentContent,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached available content: $e');
      }
      return {'lessons': [], 'assessments': []};
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
      final learningPaths = prefs.getString(_learningPathsKey)?.length ?? 0;
      final studentLearningPaths = prefs.getString(_studentLearningPathsKey)?.length ?? 0;
      final feedback = prefs.getString(_feedbackKey)?.length ?? 0;
      final recommendations = prefs.getString(_recommendationsKey)?.length ?? 0;
      final achievements = prefs.getString(_achievementsKey)?.length ?? 0;
      final studentAchievements = prefs.getString(_studentAchievementsKey)?.length ?? 0;
      final leaderboard = prefs.getString(_leaderboardKey)?.length ?? 0;
      final adaptiveDifficulties = prefs.getString(_adaptiveDifficultiesKey)?.length ?? 0;
      final difficultyAdjustments = prefs.getString(_difficultyAdjustmentsKey)?.length ?? 0;
      
      return {
        'lessons': lessons,
        'assessments': assessments,
        'progress': progress,
        'students': students,
        'profile': profile,
        'activities': activities,
        'learningPaths': learningPaths,
        'studentLearningPaths': studentLearningPaths,
        'feedback': feedback,
        'recommendations': recommendations,
        'achievements': achievements,
        'studentAchievements': studentAchievements,
        'leaderboard': leaderboard,
        'adaptiveDifficulties': adaptiveDifficulties,
        'difficultyAdjustments': difficultyAdjustments,
        'total': lessons + assessments + progress + students + profile + activities + learningPaths + studentLearningPaths + feedback + recommendations + achievements + studentAchievements + leaderboard + adaptiveDifficulties + difficultyAdjustments,
      };
    } catch (e) {
      return {
        'lessons': 0,
        'assessments': 0,
        'progress': 0,
        'students': 0,
        'profile': 0,
        'activities': 0,
        'learningPaths': 0,
        'studentLearningPaths': 0,
        'feedback': 0,
        'recommendations': 0,
        'achievements': 0,
        'studentAchievements': 0,
        'leaderboard': 0,
        'adaptiveDifficulties': 0,
        'difficultyAdjustments': 0,
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
      await prefs.remove(_learningPathsKey);
      await prefs.remove(_studentLearningPathsKey);
      await prefs.remove(_feedbackKey);
      await prefs.remove(_recommendationsKey);
      await prefs.remove(_achievementsKey);
      await prefs.remove(_studentAchievementsKey);
      await prefs.remove(_leaderboardKey);
      await prefs.remove(_adaptiveDifficultiesKey);
      await prefs.remove(_difficultyAdjustmentsKey);
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

      // Sample learning paths data
      final sampleLearningPaths = [
        {
          'id': 'sample_path_1',
          'title': 'Mathematics Fundamentals',
          'description': 'Complete mathematics foundation course for Grade 7',
          'teacherId': currentTeacherId ?? 'current_teacher',
          'teacherName': 'Sample Teacher',
          'subjects': ['Mathematics'],
          'tags': ['fundamentals', 'basics', 'grade7'],
          'steps': [
            {
              'id': 'step_1',
              'title': 'Introduction to Algebra',
              'description': 'Learn basic algebraic concepts',
              'type': 'lesson',
              'contentId': 'sample_lesson_1',
              'order': 1,
              'estimatedDuration': 45,
              'requirements': {},
              'metadata': {},
            },
            {
              'id': 'step_2',
              'title': 'Algebra Quiz',
              'description': 'Test your understanding of algebra',
              'type': 'assessment',
              'contentId': 'sample_assessment_1',
              'order': 2,
              'estimatedDuration': 30,
              'requirements': {'step_1': 'completed'},
              'metadata': {},
            },
          ],
          'isPublished': true,
          'createdAt': DateTime.now().subtract(const Duration(days: 5)).millisecondsSinceEpoch,
          'updatedAt': DateTime.now().subtract(const Duration(days: 5)).millisecondsSinceEpoch,
          'metadata': {},
        },
      ];

      // Sample student learning paths data
      final sampleStudentLearningPaths = [
        {
          'id': 'sample_assignment_1',
          'studentId': 'student_1',
          'studentName': 'John Doe',
          'learningPathId': 'sample_path_1',
          'learningPathTitle': 'Mathematics Fundamentals',
          'teacherId': currentTeacherId ?? 'current_teacher',
          'assignedAt': DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch,
          'startedAt': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          'completedAt': null,
          'stepProgress': [
            {
              'stepId': 'step_1',
              'stepTitle': 'Introduction to Algebra',
              'status': 'completed',
              'startedAt': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
              'completedAt': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
              'score': 85.0,
              'timeSpent': 42,
              'metadata': {},
            },
            {
              'stepId': 'step_2',
              'stepTitle': 'Algebra Quiz',
              'status': 'not_started',
              'startedAt': null,
              'completedAt': null,
              'score': null,
              'timeSpent': 0,
              'metadata': {},
            },
          ],
          'customizations': {'difficulty': 'medium', 'pace': 'normal'},
          'status': 'in_progress',
          'metadata': {},
        },
      ];

      // Sample feedback data
      final sampleFeedback = [
        {
          'id': 'sample_feedback_1',
          'studentId': 'student_1',
          'studentName': 'John Doe',
          'teacherId': currentTeacherId ?? 'current_teacher',
          'teacherName': 'Current Teacher',
          'feedbackType': 'assessment',
          'contentId': 'assessment_1',
          'contentTitle': 'Mathematics Quiz',
          'feedback': 'Great work on algebraic expressions! Your problem-solving approach shows strong analytical thinking.',
          'recommendations': 'Continue practicing with more complex equations. Consider using visual aids for geometry problems.',
          'rating': 4.5,
          'createdAt': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          'updatedAt': null,
          'isRead': false,
          'metadata': {},
        },
        {
          'id': 'sample_feedback_2',
          'studentId': 'student_2',
          'studentName': 'Jane Smith',
          'teacherId': currentTeacherId ?? 'current_teacher',
          'teacherName': 'Current Teacher',
          'feedbackType': 'lesson',
          'contentId': 'lesson_1',
          'contentTitle': 'Introduction to Physics',
          'feedback': 'Excellent participation in class discussions. Your questions demonstrate deep understanding.',
          'recommendations': 'Try to connect theoretical concepts with real-world examples. Practice problem-solving regularly.',
          'rating': 5.0,
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
          'updatedAt': null,
          'isRead': true,
          'metadata': {},
        },
      ];

      // Sample recommendations data
      final sampleRecommendations = [
        {
          'id': 'sample_recommendation_1',
          'studentId': 'student_1',
          'studentName': 'John Doe',
          'teacherId': currentTeacherId ?? 'current_teacher',
          'teacherName': 'Current Teacher',
          'recommendationType': 'content',
          'title': 'Advanced Algebra Practice',
          'description': 'Focus on mastering quadratic equations and complex algebraic expressions',
          'reason': 'Strong foundation in basic algebra, ready for advanced topics',
          'actionItems': 'Complete 10 practice problems daily, use online resources for additional practice',
          'priority': 2,
          'createdAt': DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch,
          'dueDate': DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
          'isCompleted': false,
          'isRead': false,
          'metadata': {},
        },
        {
          'id': 'sample_recommendation_2',
          'studentId': 'student_2',
          'studentName': 'Jane Smith',
          'teacherId': currentTeacherId ?? 'current_teacher',
          'teacherName': 'Current Teacher',
          'recommendationType': 'study_habit',
          'title': 'Study Schedule Optimization',
          'description': 'Create a consistent study routine for better retention',
          'reason': 'Irregular study patterns affecting long-term memory',
          'actionItems': 'Set aside 2 hours daily, use spaced repetition techniques, review notes weekly',
          'priority': 3,
          'createdAt': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          'dueDate': null,
          'isCompleted': false,
          'isRead': true,
          'metadata': {},
        },
      ];

      await cacheStudentProgress(sampleProgress);
      await cacheAssessments(sampleAssessments);
      await cacheTeacherActivities(sampleActivities);
      await cacheStudents(sampleStudents);
      await cacheLearningPath(sampleLearningPaths[0]);
      await cacheStudentLearningPath(sampleStudentLearningPaths[0]);
      
      // Cache sample feedback and recommendations
      for (final feedback in sampleFeedback) {
        await cacheFeedback(feedback);
      }
      for (final recommendation in sampleRecommendations) {
        await cacheRecommendation(recommendation);
      }
      
      if (kDebugMode) {
        print('Sample data populated successfully');
        print('📊 Cached ${sampleProgress.length} progress items');
        print('📊 Cached ${sampleAssessments.length} assessments');
        print('📊 Cached ${sampleActivities.length} activities');
        print('📊 Cached ${sampleStudents.length} students');
        print('📊 Cached ${sampleLearningPaths.length} learning paths');
        print('📊 Cached ${sampleStudentLearningPaths.length} student learning paths');
        print('📊 Cached ${sampleFeedback.length} feedback items');
        print('📊 Cached ${sampleRecommendations.length} recommendations');
        
        // Sample achievements data
        final sampleAchievements = [
          {
            'id': 'achievement_1',
            'title': 'First Steps',
            'description': 'Complete your first lesson',
            'category': 'milestone',
            'points': 10,
            'iconName': 'school',
            'colorHex': '#007AFF',
            'criteria': {'totalLessons': 1},
            'isActive': true,
            'createdAt': DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch,
            'updatedAt': null,
          },
          {
            'id': 'achievement_2',
            'title': 'Perfect Score',
            'description': 'Get 100% on an assessment',
            'category': 'academic',
            'points': 25,
            'iconName': 'star',
            'colorHex': '#FFD700',
            'criteria': {'minScore': 100, 'minAssessments': 1},
            'isActive': true,
            'createdAt': DateTime.now().subtract(const Duration(days: 25)).millisecondsSinceEpoch,
            'updatedAt': null,
          },
          {
            'id': 'achievement_3',
            'title': 'Weekend Warrior',
            'description': 'Study on weekends for 3 consecutive weeks',
            'category': 'streak',
            'points': 15,
            'iconName': 'fire',
            'colorHex': '#FF6B35',
            'criteria': {'minStreak': 3, 'streakType': 'weekly'},
            'isActive': true,
            'createdAt': DateTime.now().subtract(const Duration(days: 20)).millisecondsSinceEpoch,
            'updatedAt': null,
          },
          {
            'id': 'achievement_4',
            'title': 'Knowledge Seeker',
            'description': 'Complete 10 lessons',
            'category': 'participation',
            'points': 50,
            'iconName': 'book',
            'colorHex': '#34C759',
            'criteria': {'minLessons': 10},
            'isActive': true,
            'createdAt': DateTime.now().subtract(const Duration(days: 15)).millisecondsSinceEpoch,
            'updatedAt': null,
          },
        ];

        // Sample student achievements data
        final sampleStudentAchievements = [
          {
            'id': 'student_achievement_1',
            'studentId': 'student_1',
            'studentName': 'John Doe',
            'achievementId': 'achievement_1',
            'achievementTitle': 'First Steps',
            'achievementDescription': 'Complete your first lesson',
            'points': 10,
            'unlockedAt': DateTime.now().subtract(const Duration(days: 28)).millisecondsSinceEpoch,
            'metadata': {'autoAwarded': true},
          },
          {
            'id': 'student_achievement_2',
            'studentId': 'student_2',
            'studentName': 'Jane Smith',
            'achievementId': 'achievement_2',
            'achievementTitle': 'Perfect Score',
            'achievementDescription': 'Get 100% on an assessment',
            'points': 25,
            'unlockedAt': DateTime.now().subtract(const Duration(days: 22)).millisecondsSinceEpoch,
            'metadata': {'autoAwarded': true},
          },
        ];

        // Sample leaderboard data
        final sampleLeaderboard = [
          {
            'studentId': 'student_1',
            'studentName': 'John Doe',
            'studentEmail': 'john@example.com',
            'totalPoints': 85,
            'achievementsCount': 3,
            'rank': 1,
            'lastActivity': DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
            'stats': {'lessonsCompleted': 8, 'assessmentsCompleted': 3, 'streakDays': 5},
          },
          {
            'studentId': 'student_2',
            'studentName': 'Jane Smith',
            'studentEmail': 'jane@example.com',
            'totalPoints': 72,
            'achievementsCount': 2,
            'rank': 2,
            'lastActivity': DateTime.now().subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
            'stats': {'lessonsCompleted': 6, 'assessmentsCompleted': 2, 'streakDays': 3},
          },
          {
            'studentId': 'student_3',
            'studentName': 'Mike Johnson',
            'studentEmail': 'mike@example.com',
            'totalPoints': 65,
            'achievementsCount': 2,
            'rank': 3,
            'lastActivity': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
            'stats': {'lessonsCompleted': 5, 'assessmentsCompleted': 2, 'streakDays': 2},
          },
        ];

        // Sample adaptive difficulties
        final sampleAdaptiveDifficulties = [
          {
            'id': 'adaptive_1',
            'studentId': 'student_1',
            'studentName': 'John Doe',
            'subject': 'Mathematics',
            'currentLevel': 'intermediate',
            'performanceScore': 0.75,
            'consecutiveCorrect': 2,
            'consecutiveIncorrect': 0,
            'totalAttempts': 15,
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
            'subjectPerformance': {
              'Algebra': {'correct': 8, 'incorrect': 2, 'total': 10, 'averageScore': 0.8},
              'Geometry': {'correct': 3, 'incorrect': 2, 'total': 5, 'averageScore': 0.6},
            },
            'difficultyHistory': {},
            'metadata': {'createdAt': DateTime.now().subtract(const Duration(days: 10)).toIso8601String()},
          },
          {
            'id': 'adaptive_2',
            'studentId': 'student_2',
            'studentName': 'Jane Smith',
            'subject': 'Mathematics',
            'currentLevel': 'beginner',
            'performanceScore': 0.6,
            'consecutiveCorrect': 1,
            'consecutiveIncorrect': 1,
            'totalAttempts': 12,
            'lastUpdated': DateTime.now().subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
            'subjectPerformance': {
              'Algebra': {'correct': 5, 'incorrect': 3, 'total': 8, 'averageScore': 0.625},
              'Geometry': {'correct': 2, 'incorrect': 2, 'total': 4, 'averageScore': 0.5},
            },
            'difficultyHistory': {},
            'metadata': {'createdAt': DateTime.now().subtract(const Duration(days: 8)).toIso8601String()},
          },
        ];

        // Cache sample achievements data
        for (final achievement in sampleAchievements) {
          await cacheAchievement(achievement);
        }
        for (final studentAchievement in sampleStudentAchievements) {
          await cacheStudentAchievement(studentAchievement);
        }
        for (final leaderboardEntry in sampleLeaderboard) {
          await cacheLeaderboardEntry(leaderboardEntry);
        }
        for (final adaptiveDifficulty in sampleAdaptiveDifficulties) {
          await cacheAdaptiveDifficulty(adaptiveDifficulty);
        }
        
        print('📊 Cached ${sampleAchievements.length} achievements');
        print('📊 Cached ${sampleStudentAchievements.length} student achievements');
        print('📊 Cached ${sampleLeaderboard.length} leaderboard entries');
        print('📊 Cached ${sampleAdaptiveDifficulties.length} adaptive difficulties');
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

  // Cache feedback data
  static Future<void> cacheFeedback(Map<String, dynamic> feedback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingFeedback = await getCachedFeedback();
      existingFeedback.add(feedback);
      final feedbackJson = jsonEncode(existingFeedback);
      await prefs.setString(_feedbackKey, feedbackJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching feedback: $e');
      }
    }
  }

  // Get cached feedback
  static Future<List<Map<String, dynamic>>> getCachedFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackJson = prefs.getString(_feedbackKey);
      if (feedbackJson != null) {
        final List<dynamic> feedbackList = jsonDecode(feedbackJson);
        return feedbackList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached feedback: $e');
      }
      return [];
    }
  }

  // Cache recommendation data
  static Future<void> cacheRecommendation(Map<String, dynamic> recommendation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingRecommendations = await getCachedRecommendations();
      existingRecommendations.add(recommendation);
      final recommendationsJson = jsonEncode(existingRecommendations);
      await prefs.setString(_recommendationsKey, recommendationsJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching recommendation: $e');
      }
    }
  }

  // Get cached recommendations
  static Future<List<Map<String, dynamic>>> getCachedRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recommendationsJson = prefs.getString(_recommendationsKey);
      if (recommendationsJson != null) {
        final List<dynamic> recommendationsList = jsonDecode(recommendationsJson);
        return recommendationsList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached recommendations: $e');
      }
      return [];
    }
  }

  // Queue feedback for sync
  static Future<void> queueFeedbackForSync(Map<String, dynamic> feedback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'sync_feedback';
      final existingQueue = prefs.getString(syncKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        final List<dynamic> queueList = jsonDecode(existingQueue);
        queue = queueList.cast<Map<String, dynamic>>();
      }
      
      queue.add(feedback);
      final queueJson = jsonEncode(queue);
      await prefs.setString(syncKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error queuing feedback for sync: $e');
      }
    }
  }

  // Queue recommendation for sync
  static Future<void> queueRecommendationForSync(Map<String, dynamic> recommendation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'sync_recommendations';
      final existingQueue = prefs.getString(syncKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        final List<dynamic> queueList = jsonDecode(existingQueue);
        queue = queueList.cast<Map<String, dynamic>>();
      }
      
      queue.add(recommendation);
      final queueJson = jsonEncode(queue);
      await prefs.setString(syncKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error queuing recommendation for sync: $e');
      }
    }
  }

  // Queue feedback read status for sync
  static Future<void> queueFeedbackReadStatusForSync(Map<String, dynamic> readStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'sync_feedback_read_status';
      final existingQueue = prefs.getString(syncKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        final List<dynamic> queueList = jsonDecode(existingQueue);
        queue = queueList.cast<Map<String, dynamic>>();
      }
      
      queue.add(readStatus);
      final queueJson = jsonEncode(queue);
      await prefs.setString(syncKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error queuing feedback read status for sync: $e');
      }
    }
  }

  // Queue recommendation read status for sync
  static Future<void> queueRecommendationReadStatusForSync(Map<String, dynamic> readStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'sync_recommendation_read_status';
      final existingQueue = prefs.getString(syncKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        final List<dynamic> queueList = jsonDecode(existingQueue);
        queue = queueList.cast<Map<String, dynamic>>();
      }
      
      queue.add(readStatus);
      final queueJson = jsonEncode(queue);
      await prefs.setString(syncKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error queuing recommendation read status for sync: $e');
      }
    }
  }

  // Update cached feedback read status
  static Future<void> updateCachedFeedbackReadStatus(String feedbackId, bool isRead) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingFeedback = await getCachedFeedback();
      final feedbackIndex = existingFeedback.indexWhere((f) => f['id'] == feedbackId);
      if (feedbackIndex != -1) {
        existingFeedback[feedbackIndex]['isRead'] = isRead;
        final feedbackJson = jsonEncode(existingFeedback);
        await prefs.setString(_feedbackKey, feedbackJson);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating cached feedback read status: $e');
      }
    }
  }

  // Update cached recommendation read status
  static Future<void> updateCachedRecommendationReadStatus(String recommendationId, bool isRead) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingRecommendations = await getCachedRecommendations();
      final recommendationIndex = existingRecommendations.indexWhere((r) => r['id'] == recommendationId);
      if (recommendationIndex != -1) {
        existingRecommendations[recommendationIndex]['isRead'] = isRead;
        final recommendationsJson = jsonEncode(existingRecommendations);
        await prefs.setString(_recommendationsKey, recommendationsJson);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating cached recommendation read status: $e');
      }
    }
  }

  // Get cached feedback statistics
  static Future<Map<String, dynamic>> getCachedFeedbackStatistics(String teacherId) async {
    try {
      final feedback = await getCachedFeedback();
      final recommendations = await getCachedRecommendations();
      
      final teacherFeedback = feedback.where((f) => f['teacherId'] == teacherId).toList();
      final teacherRecommendations = recommendations.where((r) => r['teacherId'] == teacherId).toList();
      
      final unreadFeedback = teacherFeedback.where((f) => !(f['isRead'] ?? false)).length;
      final completedRecommendations = teacherRecommendations.where((r) => r['isCompleted'] ?? false).length;
      
      return {
        'totalFeedback': teacherFeedback.length,
        'unreadFeedback': unreadFeedback,
        'totalRecommendations': teacherRecommendations.length,
        'completedRecommendations': completedRecommendations,
        'completionRate': teacherRecommendations.isNotEmpty ? (completedRecommendations / teacherRecommendations.length * 100).round() : 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached feedback statistics: $e');
      }
      return {
        'totalFeedback': 0,
        'unreadFeedback': 0,
        'totalRecommendations': 0,
        'completedRecommendations': 0,
        'completionRate': 0,
      };
    }
  }

  // Cache achievement data
  static Future<void> cacheAchievement(Map<String, dynamic> achievement) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingAchievements = await getCachedAchievements();
      final existingIndex = existingAchievements.indexWhere((a) => a['id'] == achievement['id']);
      
      if (existingIndex != -1) {
        existingAchievements[existingIndex] = achievement;
      } else {
        existingAchievements.add(achievement);
      }
      
      final achievementsJson = jsonEncode(existingAchievements);
      await prefs.setString(_achievementsKey, achievementsJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching achievement: $e');
      }
    }
  }

  // Get cached achievements
  static Future<List<Map<String, dynamic>>> getCachedAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString(_achievementsKey);
      if (achievementsJson != null) {
        final List<dynamic> achievementsList = jsonDecode(achievementsJson);
        return achievementsList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached achievements: $e');
      }
      return [];
    }
  }

  // Cache student achievement data
  static Future<void> cacheStudentAchievement(Map<String, dynamic> studentAchievement) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingStudentAchievements = await getCachedStudentAchievements();
      final existingIndex = existingStudentAchievements.indexWhere((sa) => sa['id'] == studentAchievement['id']);
      
      if (existingIndex != -1) {
        existingStudentAchievements[existingIndex] = studentAchievement;
      } else {
        existingStudentAchievements.add(studentAchievement);
      }
      
      final studentAchievementsJson = jsonEncode(existingStudentAchievements);
      await prefs.setString(_studentAchievementsKey, studentAchievementsJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching student achievement: $e');
      }
    }
  }

  // Get cached student achievements
  static Future<List<Map<String, dynamic>>> getCachedStudentAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentAchievementsJson = prefs.getString(_studentAchievementsKey);
      if (studentAchievementsJson != null) {
        final List<dynamic> studentAchievementsList = jsonDecode(studentAchievementsJson);
        return studentAchievementsList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached student achievements: $e');
      }
      return [];
    }
  }

  // Cache leaderboard entry data
  static Future<void> cacheLeaderboardEntry(Map<String, dynamic> leaderboardEntry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingLeaderboard = await getCachedLeaderboard();
      final existingIndex = existingLeaderboard.indexWhere((le) => le['studentId'] == leaderboardEntry['studentId']);
      
      if (existingIndex != -1) {
        existingLeaderboard[existingIndex] = leaderboardEntry;
      } else {
        existingLeaderboard.add(leaderboardEntry);
      }
      
      final leaderboardJson = jsonEncode(existingLeaderboard);
      await prefs.setString(_leaderboardKey, leaderboardJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching leaderboard entry: $e');
      }
    }
  }

  // Get cached leaderboard
  static Future<List<Map<String, dynamic>>> getCachedLeaderboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final leaderboardJson = prefs.getString(_leaderboardKey);
      if (leaderboardJson != null) {
        final List<dynamic> leaderboardList = jsonDecode(leaderboardJson);
        return leaderboardList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached leaderboard: $e');
      }
      return [];
    }
  }

  // Queue achievement for sync
  static Future<void> queueAchievementForSync(Map<String, dynamic> achievement) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'sync_achievements';
      final existingQueue = prefs.getString(syncKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        final List<dynamic> queueList = jsonDecode(existingQueue);
        queue = queueList.cast<Map<String, dynamic>>();
      }
      
      queue.add(achievement);
      final queueJson = jsonEncode(queue);
      await prefs.setString(syncKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error queuing achievement for sync: $e');
      }
    }
  }

  // Queue student achievement for sync
  static Future<void> queueStudentAchievementForSync(Map<String, dynamic> studentAchievement) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'sync_student_achievements';
      final existingQueue = prefs.getString(syncKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        final List<dynamic> queueList = jsonDecode(existingQueue);
        queue = queueList.cast<Map<String, dynamic>>();
      }
      
      queue.add(studentAchievement);
      final queueJson = jsonEncode(queue);
      await prefs.setString(syncKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error queuing student achievement for sync: $e');
      }
    }
  }

  // Cache adaptive difficulty data
  static Future<void> cacheAdaptiveDifficulty(Map<String, dynamic> adaptiveDifficulty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingAdaptiveDifficulties = await getCachedAdaptiveDifficulties();
      final existingIndex = existingAdaptiveDifficulties.indexWhere((ad) => ad['id'] == adaptiveDifficulty['id']);
      
      if (existingIndex != -1) {
        existingAdaptiveDifficulties[existingIndex] = adaptiveDifficulty;
      } else {
        existingAdaptiveDifficulties.add(adaptiveDifficulty);
      }
      
      final adaptiveDifficultiesJson = jsonEncode(existingAdaptiveDifficulties);
      await prefs.setString(_adaptiveDifficultiesKey, adaptiveDifficultiesJson);
      await _updateLastSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error caching adaptive difficulty: $e');
      }
    }
  }

  // Get cached adaptive difficulties
  static Future<List<Map<String, dynamic>>> getCachedAdaptiveDifficulties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adaptiveDifficultiesJson = prefs.getString(_adaptiveDifficultiesKey);
      if (adaptiveDifficultiesJson != null) {
        final List<dynamic> adaptiveDifficultiesList = jsonDecode(adaptiveDifficultiesJson);
        return adaptiveDifficultiesList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached adaptive difficulties: $e');
      }
      return [];
    }
  }

  // Queue adaptive difficulty for sync
  static Future<void> queueAdaptiveDifficultyForSync(Map<String, dynamic> adaptiveDifficulty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'sync_adaptive_difficulties';
      final existingQueue = prefs.getString(syncKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        final List<dynamic> queueList = jsonDecode(existingQueue);
        queue = queueList.cast<Map<String, dynamic>>();
      }
      
      queue.add(adaptiveDifficulty);
      final queueJson = jsonEncode(queue);
      await prefs.setString(syncKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error queuing adaptive difficulty for sync: $e');
      }
    }
  }

  // Queue difficulty adjustment for sync
  static Future<void> queueDifficultyAdjustmentForSync(Map<String, dynamic> difficultyAdjustment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'sync_difficulty_adjustments';
      final existingQueue = prefs.getString(syncKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        final List<dynamic> queueList = jsonDecode(existingQueue);
        queue = queueList.cast<Map<String, dynamic>>();
      }
      
      queue.add(difficultyAdjustment);
      final queueJson = jsonEncode(queue);
      await prefs.setString(syncKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error queuing difficulty adjustment for sync: $e');
      }
    }
  }
}
