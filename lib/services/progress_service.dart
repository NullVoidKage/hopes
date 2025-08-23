import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_progress.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';

class ProgressService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get all student progress for a teacher
  Future<List<StudentProgress>> getStudentProgress(String teacherId) async {
    try {
      print('🔍 ProgressService: Getting student progress for teacher: $teacherId');
      print('🔍 ProgressService: shouldUseCachedData: ${_connectivityService.shouldUseCachedData}');
      print('🔍 ProgressService: isConnected: ${_connectivityService.isConnected}');
      
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        print('🔍 ProgressService: Using cached data');
        return await _getCachedStudentProgress(teacherId);
      }

      // If online, fetch from Firebase and cache
      final DatabaseReference ref = _database.ref('student_progress');
      
      // Don't filter by teacherId - show all progress to all teachers
      final DatabaseEvent event = await ref.once();
      final DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value == null) return [];
      
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      final progressList = data.entries.map((entry) {
        final entryData = entry.value as Map<dynamic, dynamic>?;
        if (entryData == null) return null;
        
        try {
          return StudentProgress.fromRealtimeDatabase(
            Map<String, dynamic>.from(entryData),
            entry.key.toString(),
          );
        } catch (e) {
          print('Error parsing student progress data: $e');
          return null;
        }
      }).whereType<StudentProgress>().toList();

      // Cache the data for offline use
      await _cacheStudentProgressLocally(progressList);
      
      return progressList;
    } catch (e) {
      print('Error getting student progress: $e');
      // If Firebase fails, try to return cached data
      return await _getCachedStudentProgress(teacherId);
    }
  }

  // Get cached student progress
  Future<List<StudentProgress>> _getCachedStudentProgress(String teacherId) async {
    try {
      print('🔍 ProgressService: Getting cached progress for teacher: $teacherId');
      final cachedProgress = await OfflineService.getCachedStudentProgress();
      print('🔍 ProgressService: Total cached progress items: ${cachedProgress.length}');
      
      // Don't filter by teacher ID - show all progress to all teachers
      final result = cachedProgress.map((data) => 
        StudentProgress.fromRealtimeDatabase(data, data['id'] ?? '')
      ).toList();
      print('🔍 ProgressService: Returning ${result.length} progress items');
      return result;
    } catch (e) {
      print('Error getting cached student progress: $e');
      return [];
    }
  }

  // Cache student progress locally
  Future<void> _cacheStudentProgressLocally(List<StudentProgress> progressList) async {
    try {
      final progressData = progressList.map((progress) => progress.toRealtimeDatabase()).toList();
      await OfflineService.cacheStudentProgress(progressData);
    } catch (e) {
      print('Error caching student progress: $e');
    }
  }

  // Get progress for a specific student
  Future<StudentProgress?> getStudentProgressById(String studentId) async {
    try {
      final DatabaseReference ref = _database.ref('student_progress/$studentId');
      final DatabaseEvent event = await ref.once();
      final DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value == null) return null;
      
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      
      try {
        return StudentProgress.fromRealtimeDatabase(
          Map<String, dynamic>.from(data),
          studentId,
        );
      } catch (e) {
        print('Error parsing student progress data: $e');
        return null;
      }
    } catch (e) {
      print('Error getting student progress by ID: $e');
      return null;
    }
  }

  // Get progress by subject
  Future<List<StudentProgress>> getProgressBySubject(String teacherId, String subject) async {
    try {
      final DatabaseReference ref = _database.ref('student_progress');
      final Query query = ref.orderByChild('teacherId').equalTo(teacherId);
      
      final DatabaseEvent event = await query.once();
      final DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value == null) return [];
      
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .where((entry) {
            final progress = Map<String, dynamic>.from(entry.value);
            return progress['subject'] == subject;
          })
          .map((entry) {
            return StudentProgress.fromRealtimeDatabase(
              Map<String, dynamic>.from(entry.value),
              entry.key.toString(),
            );
          })
          .toList();
    } catch (e) {
      print('Error getting progress by subject: $e');
      return [];
    }
  }

  // Update student progress
  Future<bool> updateStudentProgress(StudentProgress progress) async {
    try {
      final DatabaseReference ref = _database.ref('student_progress/${progress.id}');
      await ref.set(progress.toRealtimeDatabase());
      return true;
    } catch (e) {
      print('Error updating student progress: $e');
      return false;
    }
  }

  // Create or update lesson progress
  Future<bool> updateLessonProgress(String studentId, LessonProgress lessonProgress) async {
    try {
      final DatabaseReference ref = _database.ref('student_progress/$studentId/lessonProgress/${lessonProgress.lessonId}');
      await ref.set(lessonProgress.toMap());
      return true;
    } catch (e) {
      print('Error updating lesson progress: $e');
      return false;
    }
  }

  // Create or update assessment progress
  Future<bool> updateAssessmentProgress(String studentId, AssessmentProgress assessmentProgress) async {
    try {
      final DatabaseReference ref = _database.ref('student_progress/$studentId/assessmentProgress/${assessmentProgress.assessmentId}');
      await ref.set(assessmentProgress.toMap());
      return true;
    } catch (e) {
      print('Error updating assessment progress: $e');
      return false;
    }
  }

  // Get progress statistics for a teacher
  Future<Map<String, dynamic>> getProgressStatistics(String teacherId) async {
    try {
      final List<StudentProgress> allProgress = await getStudentProgress(teacherId);
      
      if (allProgress.isEmpty) {
        return {
          'totalStudents': 0,
          'averageCompletionRate': 0.0,
          'averageScore': 0.0,
          'totalLessonsCompleted': 0,
          'totalAssessmentsTaken': 0,
          'activeStudents': 0,
        };
      }

      final int totalStudents = allProgress.length;
      final double averageCompletionRate = allProgress
          .map((p) => p.completionRate)
          .reduce((a, b) => a + b) / totalStudents;
      final double averageScore = allProgress
          .map((p) => p.averageScore)
          .reduce((a, b) => a + b) / totalStudents;
      final int totalLessonsCompleted = allProgress
          .map((p) => p.lessonsCompleted)
          .reduce((a, b) => a + b);
      final int totalAssessmentsTaken = allProgress
          .map((p) => p.assessmentsTaken)
          .reduce((a, b) => a + b);
      
      // Count active students (with activity in last 7 days)
      final DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final int activeStudents = allProgress
          .where((p) => p.lastActivity.isAfter(weekAgo))
          .length;

      return {
        'totalStudents': totalStudents,
        'averageCompletionRate': averageCompletionRate,
        'averageScore': averageScore,
        'totalLessonsCompleted': totalLessonsCompleted,
        'totalAssessmentsTaken': totalAssessmentsTaken,
        'activeStudents': activeStudents,
      };
    } catch (e) {
      print('Error getting progress statistics: $e');
      return {};
    }
  }

  // Get recent activity for a teacher
  Future<List<Map<String, dynamic>>> getRecentActivity(String teacherId) async {
    try {
      print('🔍 ProgressService: Getting recent activity for teacher: $teacherId');
      print('🔍 ProgressService: shouldUseCachedData: ${_connectivityService.shouldUseCachedData}');
      
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        print('🔍 ProgressService: Using cached data for recent activity');
        // When offline, derive activity from cached student progress
        final studentProgressList = await _getCachedStudentProgress(teacherId);
        return _generateActivitiesFromProgress(studentProgressList);
      }

      // If online, fetch from Firebase
      final DatabaseReference ref = _database.ref('student_progress');
      final Query query = ref.orderByChild('teacherId').equalTo(teacherId);
      
      final DatabaseEvent event = await query.once();
      final DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value == null) return [];
      
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      final List<Map<String, dynamic>> activities = [];
      
      data.forEach((studentId, studentData) {
        if (studentData is! Map) return;
        final student = Map<String, dynamic>.from(studentData);
        
        // Add lesson completions
        if (student['lessonProgress'] != null && student['lessonProgress'] is Map) {
          final lessonProgress = Map<String, dynamic>.from(student['lessonProgress']);
          lessonProgress.forEach((lessonId, lessonData) {
            if (lessonData is! Map) return;
            final lesson = Map<String, dynamic>.from(lessonData);
            if (lesson['isCompleted'] == true && lesson['completedAt'] != null) {
              activities.add({
                'type': 'lesson_completed',
                'studentName': student['studentName'],
                'lessonTitle': lesson['lessonTitle'],
                'timestamp': lesson['completedAt'],
                'score': lesson['score'],
              });
            }
          });
        }
        
        // Add assessment completions
        if (student['assessmentProgress'] != null && student['assessmentProgress'] is Map) {
          final assessmentProgress = Map<String, dynamic>.from(student['assessmentProgress']);
          assessmentProgress.forEach((assessmentId, assessmentData) {
            if (assessmentData is! Map) return;
            final assessment = Map<String, dynamic>.from(assessmentData);
            if (assessment['isCompleted'] == true && assessment['completedAt'] != null) {
              activities.add({
                'type': 'assessment_completed',
                'studentName': student['studentName'],
                'assessmentTitle': assessment['assessmentTitle'],
                'timestamp': assessment['completedAt'],
                'score': assessment['score'],
              });
            }
          });
        }
      });
      
      // Sort by timestamp (most recent first)
      activities.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      
      // Return only the most recent 20 activities
      return activities.take(20).toList();
    } catch (e) {
      print('Error getting recent activity: $e');
      // If Firebase fails, try to return cached data
      if (_connectivityService.shouldUseCachedData) {
        final studentProgressList = await _getCachedStudentProgress(teacherId);
        return _generateActivitiesFromProgress(studentProgressList);
      }
      return [];
    }
  }

  // Generate activities from student progress data (for offline mode)
  List<Map<String, dynamic>> _generateActivitiesFromProgress(List<StudentProgress> progressList) {
    final List<Map<String, dynamic>> activities = [];
    
    for (final progress in progressList) {
      // Generate some placeholder activities based on progress data
      if (progress.lessonsCompleted > 0) {
        activities.add({
          'type': 'lesson_completed',
          'studentName': progress.studentName,
          'lessonTitle': 'Recent Lesson (${progress.subject})',
          'timestamp': progress.lastActivity.millisecondsSinceEpoch,
          'score': progress.averageScore,
        });
      }
      
      if (progress.assessmentsTaken > 0) {
        activities.add({
          'type': 'assessment_completed',
          'studentName': progress.studentName,
          'assessmentTitle': 'Recent Assessment (${progress.subject})',
          'timestamp': progress.lastActivity.millisecondsSinceEpoch,
          'score': progress.averageScore,
        });
      }
    }
    
    // Sort by timestamp (most recent first)
    activities.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    
    print('🔍 ProgressService: Generated ${activities.length} activities from ${progressList.length} progress items');
    return activities.take(10).toList();
  }
}
