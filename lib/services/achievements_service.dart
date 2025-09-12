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
import 'lesson_service.dart';
import 'learning_path_service.dart';
import 'progress_service.dart';

class AchievementsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService = ConnectivityService();
  
  final StudentService _studentService = StudentService();
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
        // First try to get from leaderboard collection
        final leaderboardSnapshot = await _database
            .ref('leaderboard')
            .orderByChild('totalPoints')
            .get();

        if (leaderboardSnapshot.exists) {
          final Map<dynamic, dynamic> data = leaderboardSnapshot.value as Map<dynamic, dynamic>;
          final List<LeaderboardEntry> leaderboard = [];
          
          for (final entry in data.values) {
            if (entry is Map<String, dynamic>) {
              leaderboard.add(LeaderboardEntry.fromRealtimeDatabase(entry, entry['studentId'] ?? ''));
            }
          }
          
          // Sort by points descending
          leaderboard.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
          
          // Assign ranks
          for (int i = 0; i < leaderboard.length; i++) {
            leaderboard[i] = leaderboard[i].copyWith(rank: i + 1);
          }

          print('📊 Retrieved leaderboard from collection: ${leaderboard.length} students');
          return leaderboard.take(limit).toList();
        } else {
          // No leaderboard collection exists, calculate from submissions
          print('📊 No leaderboard collection found, calculating from submissions...');
          return await _calculateLeaderboardFromSubmissions(limit);
        }
      } else {
        // Use cached data
        return await _getCachedLeaderboard(limit);
      }
    } catch (e) {
      print('Error getting leaderboard: $e');
      return await _getCachedLeaderboard(limit);
    }
  }

  // Calculate leaderboard from assessment submissions
  Future<List<LeaderboardEntry>> _calculateLeaderboardFromSubmissions(int limit) async {
    try {
      print('📊 Calculating leaderboard from assessment submissions...');
      
      // Get all assessment submissions
      final submissionsSnapshot = await _database
          .ref('assessment_submissions')
          .get();

      print('📊 Submissions snapshot exists: ${submissionsSnapshot.exists}');
      
      if (!submissionsSnapshot.exists) {
        print('📊 No assessment submissions found');
        return [];
      }

      final Map<dynamic, dynamic> submissionsData = submissionsSnapshot.value as Map<dynamic, dynamic>;
      print('📊 Found ${submissionsData.length} submission entries');
      
      final Map<String, LeaderboardEntry> studentScores = {};

      // Process each submission
      for (final entry in submissionsData.entries) {
        final submissionId = entry.key;
        final submission = entry.value;
        
        print('📊 Processing submission $submissionId');
        print('📊 Submission type: ${submission.runtimeType}');
        print('📊 Is Map: ${submission is Map<String, dynamic>}');
        print('📊 Is LinkedMap: ${submission is Map}');
        
        if (submission is Map) {
          final studentId = submission['studentId'] as String?;
          final studentName = submission['studentName'] as String?;
          final studentEmail = submission['studentEmail'] as String?;
          final score = (submission['score'] as num?)?.toInt() ?? 0;
          final submittedAt = submission['submittedAt'] as int?;

          print('📊 Student: $studentName ($studentId), Score: $score');
          print('📊 StudentId is null: ${studentId == null}');
          print('📊 StudentName is null: ${studentName == null}');

          if (studentId != null && studentName != null && studentId.isNotEmpty && studentName.isNotEmpty) {
            print('📊 ✅ Processing student: $studentName ($studentId) with score: $score');
            if (studentScores.containsKey(studentId)) {
              // Add to existing score
              final existing = studentScores[studentId]!;
              studentScores[studentId] = existing.copyWith(
                totalPoints: existing.totalPoints + score,
                lastActivity: submittedAt != null 
                    ? DateTime.fromMillisecondsSinceEpoch(submittedAt)
                    : existing.lastActivity,
                stats: {
                  'assessmentsCompleted': (existing.stats?['assessmentsCompleted'] ?? 0) + 1,
                  'lessonsCompleted': existing.stats?['lessonsCompleted'] ?? 0,
                  'streakDays': existing.stats?['streakDays'] ?? 0,
                },
              );
            } else {
              // Create new entry
              studentScores[studentId] = LeaderboardEntry(
                studentId: studentId,
                studentName: studentName,
                studentEmail: studentEmail ?? '',
                totalPoints: score,
                achievementsCount: 0,
                rank: 0,
                lastActivity: submittedAt != null 
                    ? DateTime.fromMillisecondsSinceEpoch(submittedAt)
                    : DateTime.now(),
                stats: {
                  'assessmentsCompleted': 1,
                  'lessonsCompleted': 0,
                  'streakDays': 0,
                },
              );
            }
          } else {
            print('📊 ❌ Skipping student - invalid data: studentId=$studentId, studentName=$studentName');
          }
        } else {
          print('📊 ❌ Submission is not a Map: ${submission.runtimeType}');
        }
      }

      print('📊 Processed ${studentScores.length} unique students');

      // Convert to list and sort by points
      final List<LeaderboardEntry> leaderboard = studentScores.values.toList();
      leaderboard.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

      // Assign ranks
      for (int i = 0; i < leaderboard.length; i++) {
        leaderboard[i] = leaderboard[i].copyWith(rank: i + 1);
      }

      print('📊 Calculated leaderboard with ${leaderboard.length} students');
      for (final entry in leaderboard.take(5)) {
        print('📊 ${entry.studentName}: ${entry.totalPoints} points');
      }

      // Create leaderboard collection in Realtime Database
      await _createLeaderboardCollection(leaderboard);

      // Cache locally
      for (final entry in leaderboard) {
        await _cacheLeaderboardEntryLocally(entry);
      }

      return leaderboard.take(limit).toList();
    } catch (e) {
      print('Error calculating leaderboard from submissions: $e');
      return [];
    }
  }

  // Create leaderboard collection in Realtime Database
  Future<void> _createLeaderboardCollection(List<LeaderboardEntry> leaderboard) async {
    try {
      print('📊 Creating leaderboard collection in Realtime Database...');
      
      // Clear existing leaderboard data
      await _database.ref('leaderboard').remove();
      
      // Add each student to leaderboard
      for (final entry in leaderboard) {
        await _database
            .ref('leaderboard/${entry.studentId}')
            .set(entry.toRealtimeDatabase());
      }
      
      print('📊 Created leaderboard collection with ${leaderboard.length} students');
    } catch (e) {
      print('Error creating leaderboard collection: $e');
    }
  }

  // Get student leaderboard position
  Future<LeaderboardEntry?> getStudentLeaderboardPosition(String studentId) async {
    try {
      if (_connectivityService.isConnected) {
        // Calculate from submissions
        final leaderboard = await _calculateLeaderboardFromSubmissions(1000);
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
        case 'fast_learner':
          // Check if student completed lessons quickly (under 10 minutes each)
          final fastLessons = criteria['fastLessons'] ?? 3;
          final maxTimePerLesson = criteria['maxTimePerLesson'] ?? 10; // 10 minutes
          final progress = studentData['progress'] as List<StudentProgress>;
          
          // Count fast completed lessons across all progress entries
          int fastCompletedLessons = 0;
          for (final p in progress) {
            for (final lessonProgress in p.lessonProgress) {
              if (lessonProgress.isCompleted && lessonProgress.timeSpent <= maxTimePerLesson) {
                fastCompletedLessons++;
              }
            }
          }
          return fastCompletedLessons >= fastLessons;
        case 'perfect_quiz_master':
          // Check for consecutive perfect quiz scores
          final perfectQuizzes = criteria['perfectQuizzes'] ?? 5;
          final assessments = studentData['assessments'] as List<Assessment>;
          // For now, check if student has perfect scores (this would need actual quiz attempt data)
          final perfectScores = assessments.where((a) => a.totalPoints == 100).length;
          return perfectScores >= perfectQuizzes;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Update leaderboard with points (public method for assessment service)
  Future<void> updateLeaderboardWithPoints(String studentId, String studentName, int points) async {
    print('🏆 Updating leaderboard: $studentName earned $points points');
    await _updateLeaderboard(studentId, studentName, points);
  }

  // Check for existing submissions and calculate leaderboard
  Future<void> updateLeaderboardForExistingSubmissions() async {
    try {
      print('🔄 Calculating leaderboard from existing assessment submissions...');
      final leaderboard = await _calculateLeaderboardFromSubmissions(50);
      print('📊 Found ${leaderboard.length} students with assessment submissions');
    } catch (e) {
      print('Error calculating leaderboard from existing submissions: $e');
    }
  }

  // Update leaderboard for a student (now just logs - leaderboard is calculated from submissions)
  Future<void> _updateLeaderboard(String studentId, String studentName, int points) async {
    try {
      print('📊 Assessment submission recorded: $studentName earned $points points');
      print('📊 Leaderboard will be calculated from assessment submissions');
      // No need to update a separate leaderboard collection
      // Leaderboard is now calculated dynamically from assessment submissions
    } catch (e) {
      print('Error logging leaderboard update: $e');
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
