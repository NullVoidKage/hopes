import '../models/assessment.dart';
import '../models/attempt.dart';

abstract class AssessmentRepository {
  Future<List<Assessment>> getAssessmentsByLesson(String lessonId);
  Future<Assessment?> getAssessment(String id);
  Future<Assessment?> getPretest();
  Future<Assessment> createAssessment(Assessment assessment);
  Future<Assessment> updateAssessment(Assessment assessment);
  Future<void> deleteAssessment(String id);
  Future<Attempt> createAttempt({
    required String assessmentId,
    required String userId,
    required Map<String, int> answers,
  });
  Future<List<Attempt>> getAttemptsByUser(String userId);
  Future<Attempt?> getAttempt(String id);
  Future<double> calculateScore(Assessment assessment, Map<String, int> answers);
} 