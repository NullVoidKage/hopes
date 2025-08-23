import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/achievements.dart';
import '../models/student.dart';
import '../models/assessment.dart';
import '../models/lesson.dart';
import '../models/learning_path.dart';
import '../models/student_progress.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';
import 'student_service.dart';
import 'assessment_service.dart';
import 'lesson_service.dart';
import 'learning_path_service.dart';
import 'progress_service.dart';

class AchievementsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService = ConnectivityService();
  
  final StudentService _studentService = StudentService();
  final AssessmentService _assessmentService = AssessmentService();
  final LessonService _lessonService = LessonService();
  final LearningPathService _learningPathService = LearningPathService();
  final ProgressService _progressService = ProgressService();

  // Create a new achievement
  Future<String> createAchievement(Achievement achievement) async {
    try {
      if (_connectivityService.isConnected) {
        // Save to Firestore
        final docRef = await _firestore.collection('achievements').add(achievement.toFirestore());
        
        // Also save to Realtime Database for offline support
        await _database.ref('achievements/${docRef.id}').set(achievement.toRealtimeDatabase());
        
        // Cache locally
        await _cacheAchievementLocally(achievement.copyWith(id: docRef.id));
        
        return docRef.id;
      } else {
        // Offline mode - save locally and queue for sync
        final tempId = 'temp_achievement_${DateTime.now().millisecondsSinceEpoch}';
        final achievementWithId = achievement.copyWith(id: tempId);
        
        await _cacheAchievementLocally(achievementWithId);
        await _queueAchievementForSync(achievementWithId);
        
        return tempId;
      }
    } catch (e) {
      print('Error creating achievement: $e');
      rethrow;
    }
  }

  // Get all achievements
  Future<List<Achievement>> getAllAchievements() async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('achievements')
            .where('isActive', isEqualTo: true)
            .orderBy('points', descending: true)
            .get();

        final achievements = querySnapshot.docs
            .map((doc) => Achievement.fromFirestore(doc))
            .toList();

        // Cache locally
        for (final achievement in achievements) {
          await _cacheAchievementLocally(achievement);
        }

        return achievements;
      } else {
        // Use cached data
        return await _getCachedAchievements();
      }
    } catch (e) {
      print('Error getting achievements: $e');
      return await _getCachedAchievements();
    }
  }

  // Get achievements by category
  Future<List<Achievement>> getAchievementsByCategory(String category) async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('achievements')
            .where('category', isEqualTo: category)
            .where('isActive', isEqualTo: true)
            .orderBy('points', descending: true)
            .get();

        final achievements = querySnapshot.docs
            .map((doc) => Achievement.fromFirestore(doc))
            .toList();

        // Cache locally
        for (final achievement in achievements) {
          await _cacheAchievementLocally(achievement);
        }

        return achievements;
      } else {
        // Use cached data
        final allAchievements = await _getCachedAchievements();
        return allAchievements.where((a) => a.category == category).toList();
      }
    } catch (e) {
      print('Error getting achievements by category: $e');
      final allAchievements = await _getCachedAchievements();
      return allAchievements.where((a) => a.category == category).toList();
    }
  }

  // Award achievement to student
  Future<String> awardAchievementToStudent(
    String studentId,
    String studentName,
    Achievement achievement,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final studentAchievement = StudentAchievement(
        id: '',
        studentId: studentId,
        studentName: studentName,
        achievementId: achievement.id,
        achievementTitle: achievement.title,
        achievementDescription: achievement.description,
        points: achievement.points,
        unlockedAt: DateTime.now(),
        metadata: metadata,
      );

      if (_connectivityService.isConnected) {
        // Save to Firestore
        final docRef = await _firestore
            .collection('student_achievements')
            .add(studentAchievement.toFirestore());

        // Save to Realtime Database
        await _database
            .ref('student_achievements/${docRef.id}')
            .set(studentAchievement.toRealtimeDatabase());

        // Update leaderboard
        await _updateLeaderboard(studentId, studentName, achievement.points);

        // Cache locally
        await _cacheStudentAchievementLocally(studentAchievement.copyWith(id: docRef.id));

        return docRef.id;
      } else {
        // Offline mode
        final tempId = 'temp_student_achievement_${DateTime.now().millisecondsSinceEpoch}';
        final studentAchievementWithId = studentAchievement.copyWith(id: tempId);

        await _cacheStudentAchievementLocally(studentAchievementWithId);
        await _queueStudentAchievementForSync(studentAchievementWithId);

        return tempId;
      }
    } catch (e) {
      print('Error awarding achievement: $e');
      rethrow;
    }
  }

  // Get student achievements
  Future<List<StudentAchievement>> getStudentAchievements(String studentId) async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('student_achievements')
            .where('studentId', isEqualTo: studentId)
            .orderBy('unlockedAt', descending: true)
            .get();

        final achievements = querySnapshot.docs
            .map((doc) => StudentAchievement.fromFirestore(doc))
            .toList();

        // Cache locally
        for (final achievement in achievements) {
          await _cacheStudentAchievementLocally(achievement);
        }

        return achievements;
      } else {
        // Use cached data
        return await _getCachedStudentAchievements(studentId);
      }
    } catch (e) {
      print('Error getting student achievements: $e');
      return await _getCachedStudentAchievements(studentId);
    }
  }

  // Get leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 50}) async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('leaderboard')
            .orderBy('totalPoints', descending: true)
            .orderBy('lastActivity', descending: true)
            .limit(limit)
            .get();

        final leaderboard = querySnapshot.docs
            .map((doc) => LeaderboardEntry.fromFirestore(doc))
            .toList();

        // Cache locally
        for (final entry in leaderboard) {
          await _cacheLeaderboardEntryLocally(entry);
        }

        return leaderboard;
      } else {
        // Use cached data
        return await _getCachedLeaderboard(limit);
      }
    } catch (e) {
      print('Error getting leaderboard: $e');
      return await _getCachedLeaderboard(limit);
    }
  }

  // Get student leaderboard position
  Future<LeaderboardEntry?> getStudentLeaderboardPosition(String studentId) async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final doc = await _firestore.collection('leaderboard').doc(studentId).get();
        
        if (doc.exists) {
          final entry = LeaderboardEntry.fromFirestore(doc);
          await _cacheLeaderboardEntryLocally(entry);
          return entry;
        }
        return null;
      } else {
        // Use cached data
        final leaderboard = await _getCachedLeaderboard(1000);
        return leaderboard.firstWhere(
          (entry) => entry.studentId == studentId,
          orElse: () => LeaderboardEntry(
            studentId: studentId,
            studentName: '',
            studentEmail: '',
            totalPoints: 0,
            achievementsCount: 0,
            rank: 0,
            lastActivity: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      print('Error getting student leaderboard position: $e');
      return null;
    }
  }

  // Check and award achievements based on student activity
  Future<List<StudentAchievement>> checkAndAwardAchievements(String studentId) async {
    try {
      final achievements = <StudentAchievement>[];
      final currentAchievements = await getStudentAchievements(studentId);
      final allAchievements = await getAllAchievements();
      
      // Get student data for achievement checking
      final student = await _studentService.getStudentById(studentId);
      final progress = await _progressService.getStudentProgress(studentId);
      
      // For now, use empty lists since we don't have direct student assessment/lesson methods
      // In a real implementation, these would be fetched from student-specific endpoints
      final assessments = <Assessment>[];
      final lessons = <Lesson>[];
      
      final learningPaths = await _learningPathService.getStudentLearningPaths(studentId);

      for (final achievement in allAchievements) {
        // Skip if already awarded
        if (currentAchievements.any((ca) => ca.achievementId == achievement.id)) {
          continue;
        }

        // Check if achievement criteria are met
        if (await _checkAchievementCriteria(achievement, {
          'student': student,
          'progress': progress,
          'assessments': assessments,
          'lessons': lessons,
          'learningPaths': learningPaths,
        })) {
          // Award achievement
          final studentAchievement = await awardAchievementToStudent(
            studentId,
            student?.name ?? 'Student',
            achievement,
            {'autoAwarded': true, 'checkedAt': DateTime.now().toIso8601String()},
          );
          
          if (studentAchievement.isNotEmpty) {
            achievements.add(StudentAchievement(
              id: studentAchievement,
              studentId: studentId,
              studentName: student?.name ?? 'Student',
              achievementId: achievement.id,
              achievementTitle: achievement.title,
              achievementDescription: achievement.description,
              points: achievement.points,
              unlockedAt: DateTime.now(),
              metadata: {'autoAwarded': true},
            ));
          }
        }
      }

      return achievements;
    } catch (e) {
      print('Error checking achievements: $e');
      return [];
    }
  }

  // Check if achievement criteria are met
  Future<bool> _checkAchievementCriteria(
    Achievement achievement,
    Map<String, dynamic> studentData,
  ) async {
    try {
      final criteria = achievement.criteria;
      final student = studentData['student'] as Student?;
      final progress = studentData['progress'] as List<StudentProgress>;
      final assessments = studentData['assessments'] as List<Assessment>;
      final lessons = studentData['lessons'] as List<Lesson>;
      final learningPaths = studentData['learningPaths'] as List<dynamic>;

      switch (achievement.category) {
        case 'academic':
          return _checkAcademicCriteria(criteria, progress, assessments);
        case 'participation':
          return _checkParticipationCriteria(criteria, lessons, learningPaths);
        case 'streak':
          return _checkStreakCriteria(criteria, progress);
        case 'milestone':
          return _checkMilestoneCriteria(criteria, progress, assessments);
        case 'special':
          return _checkSpecialCriteria(criteria, studentData);
        default:
          return false;
      }
    } catch (e) {
      print('Error checking achievement criteria: $e');
      return false;
    }
  }

  // Check academic achievement criteria
  bool _checkAcademicCriteria(
    Map<String, dynamic> criteria,
    List<StudentProgress> progress,
    List<Assessment> assessments,
  ) {
    try {
      final minScore = criteria['minScore'] ?? 0;
      final minAssessments = criteria['minAssessments'] ?? 0;
      final minLessons = criteria['minLessons'] ?? 0;

      // Check assessment scores - using totalPoints for now since score isn't available
      final highScores = assessments.where((a) => a.totalPoints >= minScore).length;
      if (highScores < minAssessments) return false;

      // Check lesson completion
      final completedLessons = progress.where((p) => p.completionRate >= 100).length;
      if (completedLessons < minLessons) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  // Check participation achievement criteria
  bool _checkParticipationCriteria(
    Map<String, dynamic> criteria,
    List<Lesson> lessons,
    List<dynamic> learningPaths,
  ) {
    try {
      final minLessons = criteria['minLessons'] ?? 0;
      final minPaths = criteria['minPaths'] ?? 0;
      final minDays = criteria['minDays'] ?? 0;

      // Check lesson participation
      if (lessons.length < minLessons) return false;

      // Check learning path participation
      if (learningPaths.length < minPaths) return false;

      // Check activity days (simplified)
      final now = DateTime.now();
      final daysActive = learningPaths.where((lp) {
        final lastActivity = lp['lastActivity'] ?? 0;
        final lastActivityDate = DateTime.fromMillisecondsSinceEpoch(lastActivity);
        return now.difference(lastActivityDate).inDays <= minDays;
      }).length;

      return daysActive >= minDays;
    } catch (e) {
      return false;
    }
  }

  // Check streak achievement criteria
  bool _checkStreakCriteria(
    Map<String, dynamic> criteria,
    List<StudentProgress> progress,
  ) {
    try {
      final minStreak = criteria['minStreak'] ?? 0;
      final streakType = criteria['streakType'] ?? 'daily';

      // Simplified streak calculation
      final recentProgress = progress
          .where((p) => p.lastActivity.isAfter(DateTime.now().subtract(Duration(days: minStreak * 2))))
          .toList();

      if (recentProgress.length < minStreak) return false;

      // Check for consecutive days (simplified)
      final dates = recentProgress
          .map((p) => DateTime(p.lastActivity.year, p.lastActivity.month, p.lastActivity.day))
          .toSet()
          .toList()
        ..sort();

      int currentStreak = 1;
      int maxStreak = 1;

      for (int i = 1; i < dates.length; i++) {
        final diff = dates[i].difference(dates[i - 1]).inDays;
        if (diff == 1) {
          currentStreak++;
          maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
        } else {
          currentStreak = 1;
        }
      }

      return maxStreak >= minStreak;
    } catch (e) {
      return false;
    }
  }

  // Check milestone achievement criteria
  bool _checkMilestoneCriteria(
    Map<String, dynamic> criteria,
    List<StudentProgress> progress,
    List<Assessment> assessments,
  ) {
    try {
      final totalLessons = criteria['totalLessons'] ?? 0;
      final totalAssessments = criteria['totalAssessments'] ?? 0;
      final totalPoints = criteria['totalPoints'] ?? 0;

      // Check total lessons completed
      final completedLessons = progress.where((p) => p.completionRate >= 100).length;
      if (completedLessons < totalLessons) return false;

      // Check total assessments taken
      if (assessments.length < totalAssessments) return false;

      // Check total points earned - using completionRate for now since points isn't available
      final earnedPoints = progress.fold<int>(0, (sum, p) => sum + p.completionRate.round());
      if (earnedPoints < totalPoints) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  // Check special achievement criteria
  bool _checkSpecialCriteria(
    Map<String, dynamic> criteria,
    Map<String, dynamic> studentData,
  ) {
    try {
      final specialCondition = criteria['specialCondition'] ?? '';
      
      switch (specialCondition) {
        case 'first_lesson':
          final lessons = studentData['lessons'] as List<Lesson>;
          return lessons.isNotEmpty;
        case 'perfect_score':
          final assessments = studentData['assessments'] as List<Assessment>;
          return assessments.any((a) => a.totalPoints == 100);
        case 'weekend_warrior':
          final progress = studentData['progress'] as List<StudentProgress>;
          final weekendActivity = progress.any((p) {
            final weekday = p.lastActivity.weekday;
            return weekday == DateTime.saturday || weekday == DateTime.sunday;
          });
          return weekendActivity;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Update leaderboard for a student
  Future<void> _updateLeaderboard(String studentId, String studentName, int points) async {
    try {
      if (_connectivityService.isConnected) {
        // Get current leaderboard entry
        final currentEntry = await getStudentLeaderboardPosition(studentId);
        final student = await _studentService.getStudentById(studentId);
        final achievements = await getStudentAchievements(studentId);

        int totalPoints = points;
        if (currentEntry != null) {
          totalPoints = currentEntry.totalPoints + points;
        }

        final newEntry = LeaderboardEntry(
          studentId: studentId,
          studentName: studentName,
          studentEmail: student?.email ?? '',
          totalPoints: totalPoints,
          achievementsCount: achievements.length,
          rank: 0, // Will be calculated when fetching leaderboard
          lastActivity: DateTime.now(),
          stats: {
            'lessonsCompleted': achievements.where((a) => a.achievementTitle.contains('Lesson')).length,
            'assessmentsCompleted': achievements.where((a) => a.achievementTitle.contains('Assessment')).length,
            'streakDays': achievements.where((a) => a.achievementTitle.contains('Streak')).length,
          },
        );

        // Update in Firestore
        await _firestore
            .collection('leaderboard')
            .doc(studentId)
            .set(newEntry.toFirestore());

        // Update in Realtime Database
        await _database
            .ref('leaderboard/$studentId')
            .set(newEntry.toRealtimeDatabase());

        // Cache locally
        await _cacheLeaderboardEntryLocally(newEntry);
      }
    } catch (e) {
      print('Error updating leaderboard: $e');
    }
  }

  // Offline caching methods
  Future<void> _cacheAchievementLocally(Achievement achievement) async {
    try {
      await OfflineService.cacheAchievement(achievement.toRealtimeDatabase());
    } catch (e) {
      print('Error caching achievement locally: $e');
    }
  }

  Future<void> _cacheStudentAchievementLocally(StudentAchievement studentAchievement) async {
    try {
      await OfflineService.cacheStudentAchievement(studentAchievement.toRealtimeDatabase());
    } catch (e) {
      print('Error caching student achievement locally: $e');
    }
  }

  Future<void> _cacheLeaderboardEntryLocally(LeaderboardEntry entry) async {
    try {
      await OfflineService.cacheLeaderboardEntry(entry.toRealtimeDatabase());
    } catch (e) {
      print('Error caching leaderboard entry locally: $e');
    }
  }

  Future<List<Achievement>> _getCachedAchievements() async {
    try {
      final cachedAchievements = await OfflineService.getCachedAchievements();
      return cachedAchievements.map((data) => 
        Achievement.fromRealtimeDatabase(data, data['id'] ?? '')
      ).toList();
    } catch (e) {
      print('Error getting cached achievements: $e');
      return [];
    }
  }

  Future<List<StudentAchievement>> _getCachedStudentAchievements(String studentId) async {
    try {
      final cachedAchievements = await OfflineService.getCachedStudentAchievements();
      return cachedAchievements
          .where((data) => data['studentId'] == studentId)
          .map((data) => StudentAchievement.fromRealtimeDatabase(data, data['id'] ?? ''))
          .toList();
    } catch (e) {
      print('Error getting cached student achievements: $e');
      return [];
    }
  }

  Future<List<LeaderboardEntry>> _getCachedLeaderboard(int limit) async {
    try {
      final cachedLeaderboard = await OfflineService.getCachedLeaderboard();
      final entries = cachedLeaderboard
          .map((data) => LeaderboardEntry.fromRealtimeDatabase(data, data['studentId'] ?? ''))
          .toList();
      
      // Sort by points and assign ranks
      entries.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      for (int i = 0; i < entries.length; i++) {
        entries[i] = entries[i].copyWith(rank: i + 1);
      }
      
      return entries.take(limit).toList();
    } catch (e) {
      print('Error getting cached leaderboard: $e');
      return [];
    }
  }

  // Queue methods for offline sync
  Future<void> _queueAchievementForSync(Achievement achievement) async {
    try {
      await OfflineService.queueAchievementForSync(achievement.toRealtimeDatabase());
    } catch (e) {
      print('Error queuing achievement for sync: $e');
    }
  }

  Future<void> _queueStudentAchievementForSync(StudentAchievement studentAchievement) async {
    try {
      await OfflineService.queueStudentAchievementForSync(studentAchievement.toRealtimeDatabase());
    } catch (e) {
      print('Error queuing student achievement for sync: $e');
    }
  }
}
