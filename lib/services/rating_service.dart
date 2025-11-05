import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_rating.dart';
import '../models/assessment_submission.dart';
import '../models/lesson_progress.dart';
import 'connectivity_service.dart';
import 'package:flutter/foundation.dart';

class RatingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Calculate and update rating for a student in a section/subject
  Future<StudentRating> calculateRating({
    required String studentId,
    required String studentName,
    required String sectionId,
    required String sectionName,
    required String subjectId,
    required String subjectName,
    required String teacherId,
    required String teacherName,
    required String schoolYear,
    List<AssessmentSubmission>? submissions,
    List<LessonProgress>? lessonProgress,
  }) async {
    try {
      // Calculate assessment metrics
      final assessmentSubmissions = submissions ?? await _getAssessmentSubmissions(studentId, subjectId);
      final totalAssessments = assessmentSubmissions.length;
      final completedAssessments = assessmentSubmissions.where((s) => s.isGraded).length;
      final averageAssessmentScore = totalAssessments > 0
          ? assessmentSubmissions.map((s) => s.accuracy).reduce((a, b) => a + b) / totalAssessments
          : 0.0;

      // Calculate lesson metrics
      final lessons = lessonProgress ?? await _getLessonProgress(studentId, subjectId);
      final totalLessons = lessons.length;
      final completedLessons = lessons.where((l) => l.isCompleted).length;
      final averageLessonProgress = totalLessons > 0
          ? lessons.map((l) => l.progressPercentage).reduce((a, b) => a + b) / totalLessons
          : 0.0;

      // Calculate category ratings
      final categoryRatings = <String, double>{
        'assessments': averageAssessmentScore,
        'lessons': averageLessonProgress * 100, // Convert to percentage
      };

      // Calculate overall rating (weighted average)
      final overallRating = (averageAssessmentScore * 0.6) + (averageLessonProgress * 100 * 0.4);

      // Check if rating exists
      final existingRating = await getRating(studentId, sectionId, subjectId);
      
      final rating = StudentRating(
        id: existingRating?.id ?? '',
        studentId: studentId,
        studentName: studentName,
        sectionId: sectionId,
        sectionName: sectionName,
        subjectId: subjectId,
        subjectName: subjectName,
        teacherId: teacherId,
        teacherName: teacherName,
        rating: overallRating,
        categoryRatings: categoryRatings,
        totalAssessments: totalAssessments,
        completedAssessments: completedAssessments,
        averageAssessmentScore: averageAssessmentScore,
        totalLessons: totalLessons,
        completedLessons: completedLessons,
        averageLessonProgress: averageLessonProgress,
        createdAt: existingRating?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        schoolYear: schoolYear,
      );

      // Save rating
      if (existingRating != null) {
        await updateRating(rating);
      } else {
        await createRating(rating);
      }

      return rating;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating rating: $e');
      }
      rethrow;
    }
  }

  // Create a new rating
  Future<String> createRating(StudentRating rating) async {
    try {
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot create rating while offline');
      }

      final ref = _database.ref().child('student_ratings').push();
      final ratingId = ref.key!;

      await ref.set(rating.copyWith(id: ratingId).toRealtimeDatabase());
      
      // Also save to Firestore
      await _firestore.collection('student_ratings').doc(ratingId).set(
        rating.copyWith(id: ratingId).toFirestore(),
      );

      return ratingId;
    } catch (e) {
      rethrow;
    }
  }

  // Update existing rating
  Future<void> updateRating(StudentRating rating) async {
    try {
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot update rating while offline');
      }

      await _database
          .ref()
          .child('student_ratings')
          .child(rating.id)
          .update(rating.toRealtimeDatabase());
      
      // Also update Firestore
      await _firestore.collection('student_ratings').doc(rating.id).update(
        rating.toFirestore(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get rating for a specific student/section/subject
  Future<StudentRating?> getRating(String studentId, String sectionId, String subjectId) async {
    try {
      final query = _database
          .ref()
          .child('student_ratings')
          .orderByChild('studentId')
          .equalTo(studentId);

      final snapshot = await query.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        for (final entry in data.entries) {
          if (entry.value is Map) {
            final ratingData = entry.value as Map;
            if (ratingData['sectionId'] == sectionId && ratingData['subjectId'] == subjectId) {
              return StudentRating.fromRealtimeDatabase(entry.key, ratingData);
            }
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all ratings for a student (all sections/subjects)
  Future<List<StudentRating>> getStudentRatings(String studentId) async {
    try {
      final query = _database
          .ref()
          .child('student_ratings')
          .orderByChild('studentId')
          .equalTo(studentId);

      final snapshot = await query.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final ratings = <StudentRating>[];
        
        data.forEach((key, value) {
          if (value is Map) {
            ratings.add(StudentRating.fromRealtimeDatabase(key, value));
          }
        });

        return ratings;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Get ratings for a teacher (with filters)
  Future<List<StudentRating>> getTeacherRatings({
    required String teacherId,
    String? studentId,
    String? sectionId,
    String? subjectId,
  }) async {
    try {
      final query = _database
          .ref()
          .child('student_ratings')
          .orderByChild('teacherId')
          .equalTo(teacherId);

      final snapshot = await query.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final ratings = <StudentRating>[];
        
        data.forEach((key, value) {
          if (value is Map) {
            final rating = StudentRating.fromRealtimeDatabase(key, value);
            
            // Apply filters
            if (studentId != null && rating.studentId != studentId) return;
            if (sectionId != null && rating.sectionId != sectionId) return;
            if (subjectId != null && rating.subjectId != subjectId) return;
            
            ratings.add(rating);
          }
        });

        return ratings;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Calculate overall rating (across all subjects)
  Future<double> calculateOverallRating(String studentId) async {
    try {
      final ratings = await getStudentRatings(studentId);
      
      if (ratings.isEmpty) return 0.0;
      
      final totalRating = ratings.map((r) => r.rating).reduce((a, b) => a + b);
      return totalRating / ratings.length;
    } catch (e) {
      return 0.0;
    }
  }

  // Get assessment submissions for rating calculation
  Future<List<AssessmentSubmission>> _getAssessmentSubmissions(String studentId, String subjectId) async {
    // This would query assessment submissions
    // For now, return empty list - should be implemented with AssessmentService
    return [];
  }

  // Get lesson progress for rating calculation
  Future<List<LessonProgress>> _getLessonProgress(String studentId, String subjectId) async {
    // This would query lesson progress
    // For now, return empty list - should be implemented with LessonProgressService
    return [];
  }
}

