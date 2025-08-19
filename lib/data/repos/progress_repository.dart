import '../models/progress.dart';

abstract class ProgressRepository {
  Future<List<Progress>> getProgressByUser(String userId);
  Future<Progress?> getProgress(String userId, String lessonId);
  Future<Progress> updateProgress({
    required String userId,
    required String lessonId,
    required ProgressStatus status,
    double? lastScore,
  });
  Future<String> determineTrack(double pretestScore);
  Future<int> getStreak(String userId);
} 