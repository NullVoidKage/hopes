import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_progress.dart';

class ProgressService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all student progress for a teacher
  Future<List<StudentProgress>> getStudentProgress(String teacherId) async {
    try {
      final DatabaseReference ref = _database.ref('student_progress');
      final Query query = ref.orderByChild('teacherId').equalTo(teacherId);
      
      final DatabaseEvent event = await query.once();
      final DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value == null) return [];
      
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((entry) {
        return StudentProgress.fromRealtimeDatabase(
          Map<String, dynamic>.from(entry.value),
          entry.key.toString(),
        );
      }).toList();
    } catch (e) {
      print('Error getting student progress: $e');
      return [];
    }
  }

  // Get progress for a specific student
  Future<StudentProgress?> getStudentProgressById(String studentId) async {
    try {
      final DatabaseReference ref = _database.ref('student_progress/$studentId');
      final DatabaseEvent event = await ref.once();
      final DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value == null) return null;
      
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      return StudentProgress.fromRealtimeDatabase(
        Map<String, dynamic>.from(data),
        studentId,
      );
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
      final DatabaseReference ref = _database.ref('student_progress');
      final Query query = ref.orderByChild('teacherId').equalTo(teacherId);
      
      final DatabaseEvent event = await query.once();
      final DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value == null) return [];
      
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> activities = [];
      
      data.forEach((studentId, studentData) {
        final student = Map<String, dynamic>.from(studentData);
        
        // Add lesson completions
        if (student['lessonProgress'] != null) {
          final lessonProgress = Map<String, dynamic>.from(student['lessonProgress']);
          lessonProgress.forEach((lessonId, lessonData) {
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
        if (student['assessmentProgress'] != null) {
          final assessmentProgress = Map<String, dynamic>.from(student['assessmentProgress']);
          assessmentProgress.forEach((assessmentId, assessmentData) {
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
      return [];
    }
  }
}
