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
      
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
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
          return null;
        }
      }).whereType<StudentProgress>().toList();

      // Cache the data for offline use
      await _cacheStudentProgressLocally(progressList);
      
      return progressList;
    } catch (e) {
      // If Firebase fails, try to return cached data
      return await _getCachedStudentProgress(teacherId);
    }
  }

  // Get cached student progress
  Future<List<StudentProgress>> _getCachedStudentProgress(String teacherId) async {
    try {
      final cachedProgress = await OfflineService.getCachedStudentProgress();
      
      // Don't filter by teacher ID - show all progress to all teachers
      final result = cachedProgress.map((data) => 
        StudentProgress.fromRealtimeDatabase(data, data['id'] ?? '')
      ).toList();
      return result;
    } catch (e) {
      return [];
    }
  }

  // Cache student progress locally
  Future<void> _cacheStudentProgressLocally(List<StudentProgress> progressList) async {
    try {
      final progressData = progressList.map((progress) => progress.toRealtimeDatabase()).toList();
      await OfflineService.cacheStudentProgress(progressData);
    } catch (e) {
    }
  }

  // Get progress for a specific student by calculating from existing collections
  Future<StudentProgress?> getStudentProgressById(String studentId) async {
    try {
      // Get data from existing collections
      final lessonsRef = _database.ref('lessons');
      final submissionsRef = _database.ref('assessment_submissions');
      
      final lessonsSnapshot = await lessonsRef.once();
      final submissionsSnapshot = await submissionsRef.once();
      
      final lessonsData = lessonsSnapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final submissionsData = submissionsSnapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      // Calculate progress from lessons and submissions
      int lessonsCompleted = 0;
      int totalLessons = 0;
      int assessmentsTaken = 0;
      int totalAssessments = 0;
      double totalScore = 0.0;
      int scoreCount = 0;
      DateTime? lastActivity;
      
      // Count lessons
      lessonsData.forEach((key, value) {
        if (value is Map) {
          totalLessons++;
          if (value['isCompleted'] == true) {
            lessonsCompleted++;
          }
          // Update last activity if lesson was completed recently
          if (value['completedAt'] != null) {
            final completedAt = DateTime.fromMillisecondsSinceEpoch(value['completedAt'] as int);
            if (lastActivity == null || completedAt.isAfter(lastActivity!)) {
              lastActivity = completedAt;
            }
          }
        }
      });
      
      // Count assessments and calculate scores
      submissionsData.forEach((key, value) {
        if (value is Map && value['studentId'] == studentId) {
          assessmentsTaken++;
          if (value['score'] != null) {
            totalScore += (value['score'] as num).toDouble();
            scoreCount++;
          }
          // Update last activity if submission was recent
          if (value['submittedAt'] != null) {
            final submittedAt = DateTime.fromMillisecondsSinceEpoch(value['submittedAt'] as int);
            if (lastActivity == null || submittedAt.isAfter(lastActivity!)) {
              lastActivity = submittedAt;
            }
          }
        }
      });
      
      // Count total assessments (all assessments, not just submitted ones)
      totalAssessments = lessonsData.length; // Assuming each lesson has an assessment
      
      // Calculate averages
      final double averageScore = scoreCount > 0 ? totalScore / scoreCount : 0.0;
      final double completionRate = totalLessons > 0 ? (lessonsCompleted / totalLessons) * 100 : 0.0;
      
      // Create StudentProgress object
      return StudentProgress(
        id: 'calculated_$studentId',
        studentId: studentId,
        studentName: 'Student', // Will be updated with actual name
        studentEmail: '',
        subject: 'All', // Combined progress
        lessonsCompleted: lessonsCompleted,
        totalLessons: totalLessons,
        assessmentsTaken: assessmentsTaken,
        totalAssessments: totalAssessments,
        averageScore: averageScore,
        completionRate: completionRate,
        lastActivity: lastActivity ?? DateTime.now(),
        lessonProgress: [],
        assessmentProgress: [],
        metadata: {},
      );
    } catch (e) {
      return null;
    }
  }

  // Get progress by subject (calculate from existing collections)
  Future<List<StudentProgress>> getProgressBySubject(String teacherId, String subject) async {
    try {
      // Get data from existing collections
      final lessonsRef = _database.ref('lessons');
      final submissionsRef = _database.ref('assessment_submissions');
      
      final lessonsSnapshot = await lessonsRef.once();
      final submissionsSnapshot = await submissionsRef.once();
      
      final lessonsData = lessonsSnapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final submissionsData = submissionsSnapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      // Get unique student IDs from submissions
      final Set<String> studentIds = {};
      submissionsData.forEach((key, value) {
        if (value is Map && value['studentId'] != null) {
          studentIds.add(value['studentId'] as String);
        }
      });
      
      // Calculate progress for each student
      final List<StudentProgress> progressList = [];
      
      for (final studentId in studentIds) {
        // Filter lessons by subject
        int subjectLessonsCompleted = 0;
        int subjectTotalLessons = 0;
        int subjectAssessmentsTaken = 0;
        double subjectTotalScore = 0.0;
        int subjectScoreCount = 0;
        DateTime? subjectLastActivity;
        
        // Count lessons for this subject
        lessonsData.forEach((key, value) {
          if (value is Map && value['subject'] == subject) {
            subjectTotalLessons++;
            if (value['isCompleted'] == true) {
              subjectLessonsCompleted++;
            }
            if (value['completedAt'] != null) {
              final completedAt = DateTime.fromMillisecondsSinceEpoch(value['completedAt'] as int);
              if (subjectLastActivity == null || completedAt.isAfter(subjectLastActivity!)) {
                subjectLastActivity = completedAt;
              }
            }
          }
        });
        
        // Count submissions for this subject and student
        submissionsData.forEach((key, value) {
          if (value is Map && 
              value['studentId'] == studentId && 
              value['assessmentSubject'] == subject) {
            subjectAssessmentsTaken++;
            if (value['score'] != null) {
              subjectTotalScore += (value['score'] as num).toDouble();
              subjectScoreCount++;
            }
            if (value['submittedAt'] != null) {
              final submittedAt = DateTime.fromMillisecondsSinceEpoch(value['submittedAt'] as int);
              if (subjectLastActivity == null || submittedAt.isAfter(subjectLastActivity!)) {
                subjectLastActivity = submittedAt;
              }
            }
          }
        });
        
        // Calculate averages
        final double subjectAverageScore = subjectScoreCount > 0 ? subjectTotalScore / subjectScoreCount : 0.0;
        final double subjectCompletionRate = subjectTotalLessons > 0 ? (subjectLessonsCompleted / subjectTotalLessons) * 100 : 0.0;
        
        // Create progress entry
        progressList.add(StudentProgress(
          id: 'calculated_${studentId}_$subject',
          studentId: studentId,
          studentName: 'Student', // Will be updated with actual name
          studentEmail: '',
          subject: subject,
          lessonsCompleted: subjectLessonsCompleted,
          totalLessons: subjectTotalLessons,
          assessmentsTaken: subjectAssessmentsTaken,
          totalAssessments: subjectTotalLessons, // Assuming each lesson has an assessment
          averageScore: subjectAverageScore,
          completionRate: subjectCompletionRate,
          lastActivity: subjectLastActivity ?? DateTime.now(),
          lessonProgress: [],
          assessmentProgress: [],
          metadata: {},
        ));
      }
      
      return progressList;
    } catch (e) {
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
      return {};
    }
  }

  // Get recent activity for a teacher
  Future<List<Map<String, dynamic>>> getRecentActivity(String teacherId) async {
    try {
      
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
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
    
    return activities.take(10).toList();
  }
}
