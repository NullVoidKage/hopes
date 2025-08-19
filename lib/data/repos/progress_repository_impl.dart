import 'package:drift/drift.dart';
import '../db/database.dart' as db;
import '../models/progress.dart';
import 'progress_repository.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final db.HopesDatabase _database;

  ProgressRepositoryImpl(this._database);

  @override
  Future<List<Progress>> getProgressByUser(String userId) async {
    final progress = await (_database.select(_database.progress)..where((p) => p.userId.equals(userId))).get();
    return progress.map((p) => Progress(
      userId: p.userId,
      lessonId: p.lessonId,
      status: _convertProgressStatus(p.status),
      lastScore: p.lastScore,
      updatedAt: p.updatedAt,
    )).toList();
  }

  @override
  Future<Progress?> getProgress(String userId, String lessonId) async {
    final progress = await (_database.select(_database.progress)
      ..where((p) => p.userId.equals(userId) & p.lessonId.equals(lessonId))).get();
    
    if (progress.isEmpty) return null;
    
    final p = progress.first;
    return Progress(
      userId: p.userId,
      lessonId: p.lessonId,
      status: _convertProgressStatus(p.status),
      lastScore: p.lastScore,
      updatedAt: p.updatedAt,
    );
  }

  @override
  Future<Progress> updateProgress({
    required String userId,
    required String lessonId,
    required ProgressStatus status,
    double? lastScore,
  }) async {
    final now = DateTime.now();
    
    await _database.into(_database.progress).insertOnConflictUpdate(
      db.ProgressCompanion.insert(
        userId: userId,
        lessonId: lessonId,
        status: _convertToDbProgressStatus(status),
        lastScore: Value(lastScore),
        updatedAt: now,
      ),
    );

    return Progress(
      userId: userId,
      lessonId: lessonId,
      status: status,
      lastScore: lastScore,
      updatedAt: now,
    );
  }

  @override
  Future<String> determineTrack(double pretestScore) async {
    if (pretestScore < 50) {
      return 'Remedial';
    } else if (pretestScore < 85) {
      return 'Core';
    } else {
      return 'Advanced';
    }
  }

  @override
  Future<int> getStreak(String userId) async {
    // Simple implementation - count consecutive days with activity
    // In a real app, this would be more sophisticated
    final attempts = await (_database.select(_database.attempts)..where((a) => a.userId.equals(userId))).get();
    
    if (attempts.isEmpty) return 0;
    
    // For now, return a simple count of attempts as streak
    return attempts.length;
  }

  ProgressStatus _convertProgressStatus(db.ProgressStatus status) {
    switch (status) {
      case db.ProgressStatus.locked:
        return ProgressStatus.locked;
      case db.ProgressStatus.inProgress:
        return ProgressStatus.inProgress;
      case db.ProgressStatus.mastered:
        return ProgressStatus.mastered;
    }
  }

  db.ProgressStatus _convertToDbProgressStatus(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.locked:
        return db.ProgressStatus.locked;
      case ProgressStatus.inProgress:
        return db.ProgressStatus.inProgress;
      case ProgressStatus.mastered:
        return db.ProgressStatus.mastered;
    }
  }
} 