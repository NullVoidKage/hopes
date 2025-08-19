import 'dart:convert';
import 'package:drift/drift.dart';
import '../../data/db/database.dart' as db;
import '../../data/models/sync_queue.dart';

abstract class ProgressSyncService {
  Future<bool> syncProgress();
  Future<bool> uploadProgress();
  Future<bool> downloadProgress();
  Future<void> queueProgressChange(String userId, String lessonId, Map<String, dynamic> progressData);
  Future<void> awardPoints(String userId, int points);
  Future<void> checkAndAwardBadges(String userId);
}

class ProgressSyncServiceImpl implements ProgressSyncService {
  final db.HopesDatabase _database;
  bool _isOnline = true; // Simulate online status

  ProgressSyncServiceImpl(this._database);

  @override
  Future<bool> syncProgress() async {
    try {
      if (!_isOnline) {
        return false; // Queue changes for later sync
      }

      await uploadProgress();
      await downloadProgress();
      return true;
    } catch (e) {
      print('Progress sync error: $e');
      return false;
    }
  }

  @override
  Future<bool> uploadProgress() async {
    try {
      if (!_isOnline) return false;

      // Simulate uploading progress to server
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      print('Progress upload error: $e');
      return false;
    }
  }

  @override
  Future<bool> downloadProgress() async {
    try {
      if (!_isOnline) return false;

      // Simulate downloading progress from server
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (e) {
      print('Progress download error: $e');
      return false;
    }
  }

  @override
  Future<void> queueProgressChange(String userId, String lessonId, Map<String, dynamic> progressData) async {
    final syncItem = db.SyncQueueCompanion.insert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      entityTable: 'progress',
      operation: 'update',
      recordId: '${userId}_${lessonId}',
      dataJson: jsonEncode(progressData),
      createdAt: DateTime.now(),
      isSynced: false,
    );

    await _database.into(_database.syncQueue).insert(syncItem);
  }

  @override
  Future<void> awardPoints(String userId, int points) async {
    // Get current points or create new record
    final currentPoints = await (_database.select(_database.points)
          ..where((tbl) => tbl.userId.equals(userId)))
        .getSingleOrNull();

    if (currentPoints != null) {
      // Update existing points
      await (_database.update(_database.points)
            ..where((tbl) => tbl.userId.equals(userId)))
          .write(db.PointsCompanion(
        totalPoints: Value(currentPoints.totalPoints + points),
      ));
    } else {
      // Create new points record
      await _database.into(_database.points).insert(
        db.PointsCompanion.insert(
          userId: userId,
          totalPoints: points,
        ),
      );
    }

    // Queue for sync
    await queueProgressChange(userId, 'points', {
      'userId': userId,
      'totalPoints': (currentPoints?.totalPoints ?? 0) + points,
    });
  }

  @override
  Future<void> checkAndAwardBadges(String userId) async {
    // Get user's progress data
    final attempts = await (_database.select(_database.attempts)
          ..where((tbl) => tbl.userId.equals(userId)))
        .get();

    final progress = await (_database.select(_database.progress)
          ..where((tbl) => tbl.userId.equals(userId)))
        .get();

    // Check for "First Quiz Completed" badge
    if (attempts.isNotEmpty) {
      await _awardBadgeIfNotEarned(userId, 'starter_badge', 'Starter Badge');
    }

    // Check for "Achiever Badge" (score ≥ 85% three times)
    final highScores = attempts.where((a) => a.score >= 0.85).length;
    if (highScores >= 3) {
      await _awardBadgeIfNotEarned(userId, 'achiever_badge', 'Achiever Badge');
    }

    // Check for "Consistency Badge" (7-day streak)
    if (await _checkSevenDayStreak(userId)) {
      await _awardBadgeIfNotEarned(userId, 'consistency_badge', 'Consistency Badge');
    }
  }

  Future<void> _awardBadgeIfNotEarned(String userId, String badgeId, String badgeName) async {
    // Check if badge already exists
    final existingBadge = await (_database.select(_database.badges)
          ..where((tbl) => tbl.id.equals(badgeId)))
        .getSingleOrNull();

    if (existingBadge == null) {
      // Create badge if it doesn't exist
      await _database.into(_database.badges).insert(
        db.BadgesCompanion.insert(
          id: badgeId,
          name: badgeName,
          ruleJson: '{"type": "automatic"}',
        ),
      );
    }

    // Check if user already has this badge
    final userBadge = await (_database.select(_database.userBadges)
          ..where((tbl) => tbl.userId.equals(userId) & tbl.badgeId.equals(badgeId)))
        .getSingleOrNull();

    if (userBadge == null) {
      // Award badge to user
      await _database.into(_database.userBadges).insert(
        db.UserBadgesCompanion.insert(
          userId: userId,
          badgeId: badgeId,
          awardedAt: DateTime.now(),
        ),
      );

      // Queue for sync
      await queueProgressChange(userId, 'badge_$badgeId', {
        'userId': userId,
        'badgeId': badgeId,
        'awardedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<bool> _checkSevenDayStreak(String userId) async {
    final attempts = await (_database.select(_database.attempts)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.finishedAt)]))
        .get();

    if (attempts.length < 7) return false;

    // Check if there are attempts on 7 consecutive days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    int consecutiveDays = 0;
    DateTime? lastDate;

    for (final attempt in attempts) {
      final attemptDate = DateTime(attempt.finishedAt.year, attempt.finishedAt.month, attempt.finishedAt.day);
      
      if (lastDate == null) {
        lastDate = attemptDate;
        consecutiveDays = 1;
      } else {
        final difference = lastDate.difference(attemptDate).inDays;
        if (difference == 1) {
          consecutiveDays++;
          lastDate = attemptDate;
        } else if (difference > 1) {
          break;
        }
      }
    }

    return consecutiveDays >= 7;
  }

  // Method to simulate online/offline status
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
  }

  bool get isOnline => _isOnline;
} 