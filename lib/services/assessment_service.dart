import 'package:firebase_database/firebase_database.dart';
import '../models/assessment.dart';

class AssessmentService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Create a new assessment
  Future<String> createAssessment(Assessment assessment) async {
    try {
      final ref = _database.ref('assessments').push();
      await ref.set(assessment.toRealtimeDatabase());
      return ref.key!;
    } catch (e) {
      throw Exception('Failed to create assessment: ${e.toString()}');
    }
  }

  // Get assessments by teacher
  Future<List<Assessment>> getAssessmentsByTeacher(String teacherId) async {
    try {
      final snapshot = await _database
          .ref('assessments')
          .orderByChild('teacherId')
          .equalTo(teacherId)
          .get();

      if (snapshot.exists) {
        final assessments = <Assessment>[];
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map) {
            try {
              final assessment = Assessment.fromRealtimeDatabase(key, value);
              assessments.add(assessment);
            } catch (e) {
              print('Error parsing assessment: $e');
            }
          }
        });

        // Sort by creation date (newest first)
        assessments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return assessments;
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get assessments: ${e.toString()}');
    }
  }

  // Get assessments by subject
  Future<List<Assessment>> getAssessmentsBySubject(String subject) async {
    try {
      final snapshot = await _database
          .ref('assessments')
          .orderByChild('subject')
          .equalTo(subject)
          .get();

      if (snapshot.exists) {
        final assessments = <Assessment>[];
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map) {
            try {
              final assessment = Assessment.fromRealtimeDatabase(key, value);
              // Only return published assessments
              if (assessment.isPublished) {
                assessments.add(assessment);
              }
            } catch (e) {
              print('Error parsing assessment: $e');
            }
          }
        });

        // Sort by creation date (newest first)
        assessments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return assessments;
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get assessments by subject: ${e.toString()}');
    }
  }

  // Get a specific assessment by ID
  Future<Assessment?> getAssessmentById(String assessmentId) async {
    try {
      final snapshot = await _database
          .ref('assessments')
          .child(assessmentId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return Assessment.fromRealtimeDatabase(assessmentId, data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get assessment: ${e.toString()}');
    }
  }

  // Update an assessment
  Future<void> updateAssessment(Assessment assessment) async {
    try {
      await _database
          .ref('assessments')
          .child(assessment.id)
          .update(assessment.toRealtimeDatabase());
    } catch (e) {
      throw Exception('Failed to update assessment: ${e.toString()}');
    }
  }

  // Delete an assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _database
          .ref('assessments')
          .child(assessmentId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete assessment: ${e.toString()}');
    }
  }

  // Toggle assessment publish status
  Future<void> toggleAssessmentPublish(String assessmentId, bool isPublished) async {
    try {
      await _database
          .ref('assessments')
          .child(assessmentId)
          .update({
        'isPublished': isPublished,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to toggle assessment publish status: ${e.toString()}');
    }
  }

  // Get assessment statistics
  Future<Map<String, dynamic>> getAssessmentStats(String teacherId) async {
    try {
      final assessments = await getAssessmentsByTeacher(teacherId);
      
      int totalAssessments = assessments.length;
      int publishedAssessments = assessments.where((a) => a.isPublished).length;
      int draftAssessments = totalAssessments - publishedAssessments;
      
      // Count assessments by subject
      Map<String, int> subjectCounts = {};
      for (var assessment in assessments) {
        subjectCounts[assessment.subject] = (subjectCounts[assessment.subject] ?? 0) + 1;
      }
      
      return {
        'totalAssessments': totalAssessments,
        'publishedAssessments': publishedAssessments,
        'draftAssessments': draftAssessments,
        'subjectCounts': subjectCounts,
      };
    } catch (e) {
      throw Exception('Failed to get assessment stats: ${e.toString()}');
    }
  }
}
