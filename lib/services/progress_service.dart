import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/progress.dart';
import '../data/models/lesson.dart';
import '../data/models/assessment.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save lesson progress
  Future<void> saveLessonProgress({
    required String userId,
    required String lessonId,
    required int completedPages,
    required int totalPages,
    required bool isCompleted,
  }) async {
    try {
      final progressData = {
        'lessonId': lessonId,
        'completedPages': completedPages,
        'totalPages': totalPages,
        'isCompleted': isCompleted,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'lesson',
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(lessonId)
          .set(progressData, SetOptions(merge: true));
    } catch (e) {
      print('Error saving lesson progress: $e');
    }
  }

  // Save assessment progress
  Future<void> saveAssessmentProgress({
    required String userId,
    required String assessmentId,
    required int score,
    required int totalQuestions,
    required bool isPassed,
    required List<String> correctAnswers,
    required List<String> userAnswers,
  }) async {
    try {
      final progressData = {
        'assessmentId': assessmentId,
        'score': score,
        'totalQuestions': totalQuestions,
        'isPassed': isPassed,
        'correctAnswers': correctAnswers,
        'userAnswers': userAnswers,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'assessment',
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(assessmentId)
          .set(progressData, SetOptions(merge: true));
    } catch (e) {
      print('Error saving assessment progress: $e');
    }
  }

  // Get lesson progress
  Future<Map<String, dynamic>?> getLessonProgress({
    required String userId,
    required String lessonId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(lessonId)
          .get();

      if (doc.exists && doc.data()?['type'] == 'lesson') {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting lesson progress: $e');
      return null;
    }
  }

  // Get assessment progress
  Future<Map<String, dynamic>?> getAssessmentProgress({
    required String userId,
    required String assessmentId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(assessmentId)
          .get();

      if (doc.exists && doc.data()?['type'] == 'assessment') {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting assessment progress: $e');
      return null;
    }
  }

  // Get all progress for a user
  Future<List<Map<String, dynamic>>> getAllProgress({
    required String userId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('Error getting all progress: $e');
      return [];
    }
  }

  // Get progress summary for dashboard
  Future<Map<String, dynamic>> getProgressSummary({
    required String userId,
  }) async {
    try {
      final allProgress = await getAllProgress(userId: userId);
      
      int totalLessons = 0;
      int completedLessons = 0;
      int totalAssessments = 0;
      int passedAssessments = 0;
      double averageScore = 0.0;
      int totalScore = 0;
      int assessmentCount = 0;

      for (final progress in allProgress) {
        if (progress['type'] == 'lesson') {
          totalLessons++;
          if (progress['isCompleted'] == true) {
            completedLessons++;
          }
        } else if (progress['type'] == 'assessment') {
          totalAssessments++;
          if (progress['isPassed'] == true) {
            passedAssessments++;
          }
          totalScore += (progress['score'] ?? 0) as int;
          assessmentCount++;
        }
      }

      averageScore = assessmentCount > 0 ? totalScore / assessmentCount : 0.0;

      return {
        'totalLessons': totalLessons,
        'completedLessons': completedLessons,
        'totalAssessments': totalAssessments,
        'passedAssessments': passedAssessments,
        'averageScore': averageScore,
        'completionRate': totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0.0,
        'passRate': totalAssessments > 0 ? (passedAssessments / totalAssessments) * 100 : 0.0,
      };
    } catch (e) {
      print('Error getting progress summary: $e');
      return {
        'totalLessons': 0,
        'completedLessons': 0,
        'totalAssessments': 0,
        'passedAssessments': 0,
        'averageScore': 0.0,
        'completionRate': 0.0,
        'passRate': 0.0,
      };
    }
  }

  // Delete progress (for testing or user request)
  Future<void> deleteProgress({
    required String userId,
    required String progressId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(progressId)
          .delete();
    } catch (e) {
      print('Error deleting progress: $e');
    }
  }
}
