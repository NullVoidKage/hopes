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

  // Get all achievements from Realtime Database
  Future<List<Achievement>> getAllAchievements() async {
    try {
      print('🏆 Getting all achievements from Realtime Database...');
      
      if (_connectivityService.isConnected) {
        // Fetch from Realtime Database
        final snapshot = await _database
            .ref('achievements')
            .orderByChild('points')
            .get();

        if (!snapshot.exists) {
          print('🏆 No achievements found in Realtime Database');
          return [];
        }

        final achievements = <Achievement>[];
        final data = _convertLinkedMapToMap(snapshot.value as Map);
        
        for (final entry in data.entries) {
          final achievementData = _convertLinkedMapToMap(entry.value as Map);
          achievements.add(Achievement(
            id: entry.key,
            title: achievementData['title'] ?? '',
            description: achievementData['description'] ?? '',
            points: achievementData['points'] ?? 0,
            category: achievementData['category'] ?? 'general',
            criteria: Map<String, dynamic>.from(achievementData['criteria'] ?? {}),
            iconName: achievementData['iconName'] ?? 'star',
            colorHex: achievementData['colorHex'] ?? '#007AFF',
            isActive: achievementData['isActive'] ?? true,
            createdAt: achievementData['createdAt'] is int 
                ? DateTime.fromMillisecondsSinceEpoch(achievementData['createdAt'] as int)
                : DateTime.parse(achievementData['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
          ));
        }

        // Sort by points ascending
        achievements.sort((a, b) => a.points.compareTo(b.points));

        print('🏆 Found ${achievements.length} achievements in Realtime Database');
        
        // Debug: Print achievement details
        for (final achievement in achievements) {
          print('🏆 Achievement: ${achievement.title} - Points: ${achievement.points} - Criteria: ${achievement.criteria}');
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
        // Generate unique ID for Realtime Database
        final achievementId = 'achievement_${DateTime.now().millisecondsSinceEpoch}_${studentId}';
        
        // Save to Realtime Database only
        await _database
            .ref('student_achievements/$achievementId')
            .set(studentAchievement.toRealtimeDatabase());

        print('🏆 ✅ Saved achievement to Realtime Database: $achievementId');

        // Update leaderboard
        await _updateLeaderboard(studentId, studentName, achievement.points);

        // Cache locally
        await _cacheStudentAchievementLocally(studentAchievement.copyWith(id: achievementId));

        return achievementId;
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

  // Get student achievements from Realtime Database
  Future<List<StudentAchievement>> getStudentAchievements(String studentId) async {
    try {
      print('🏆 Getting student achievements from Realtime Database for student: $studentId');
      
      if (_connectivityService.isConnected) {
        // Fetch from Realtime Database
        final snapshot = await _database
            .ref('student_achievements')
            .orderByChild('studentId')
            .equalTo(studentId)
            .get();

        if (!snapshot.exists) {
          print('🏆 No achievements found for student: $studentId');
          return [];
        }

        final achievements = <StudentAchievement>[];
        final data = _convertLinkedMapToMap(snapshot.value as Map);
        
        for (final entry in data.entries) {
          final achievementData = _convertLinkedMapToMap(entry.value as Map);
          achievements.add(StudentAchievement(
            id: entry.key,
            studentId: achievementData['studentId'] ?? '',
            studentName: achievementData['studentName'] ?? '',
            achievementId: achievementData['achievementId'] ?? '',
            achievementTitle: achievementData['achievementTitle'] ?? '',
            achievementDescription: achievementData['achievementDescription'] ?? '',
            points: achievementData['points'] ?? 0,
            unlockedAt: achievementData['unlockedAt'] is int 
                ? DateTime.fromMillisecondsSinceEpoch(achievementData['unlockedAt'] as int)
                : DateTime.parse(achievementData['unlockedAt']?.toString() ?? DateTime.now().toIso8601String()),
            metadata: Map<String, dynamic>.from(achievementData['metadata'] ?? {}),
          ));
        }

        // Sort by unlockedAt descending
        achievements.sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));

        print('🏆 Found ${achievements.length} achievements for student: $studentId');
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
          print('📊 Raw leaderboard data: $data');
          print('📊 Data type: ${data.runtimeType}');
          print('📊 Data keys: ${data.keys.toList()}');
          final List<LeaderboardEntry> leaderboard = [];
          
          for (final entry in data.values) {
            print('📊 Processing entry: $entry');
            print('📊 Entry type: ${entry.runtimeType}');
            if (entry is Map) {
              try {
                // Convert LinkedMap to Map<String, dynamic> recursively
                final entryMap = _convertLinkedMapToMap(entry);
                print('📊 Entry map: $entryMap');
                final leaderboardEntry = LeaderboardEntry.fromRealtimeDatabase(entryMap, entryMap['studentId'] ?? '');
                leaderboard.add(leaderboardEntry);
                print('📊 ✅ Successfully added entry: ${leaderboardEntry.studentName}');
              } catch (e) {
                print('📊 ❌ Error processing entry: $e');
                print('📊 ❌ Problematic entry: $entry');
              }
            } else {
              print('📊 ❌ Entry is not a Map: $entry');
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
      print('🏆 Checking achievements for student: $studentId');
      final achievements = <StudentAchievement>[];
      final currentAchievements = await getStudentAchievements(studentId);
      final allAchievements = await getAllAchievements();
      
      // Get student data for achievement checking
      final student = await _studentService.getStudentById(studentId);
      final progress = await _progressService.getStudentProgress(studentId);
      
      // Get student's assessment submissions
      final studentSubmissions = await _getStudentAssessmentSubmissions(studentId);
      print('📊 Found ${studentSubmissions.length} assessment submissions for student');
      
      // Get student's lessons (for now, use empty list)
      final lessons = <Lesson>[];
      
      final learningPaths = await _learningPathService.getStudentLearningPaths(studentId);

      for (final achievement in allAchievements) {
        // Skip if already awarded
        if (currentAchievements.any((ca) => ca.achievementId == achievement.id)) {
          print('🏆 Achievement ${achievement.title} already awarded, skipping');
          continue;
        }

        print('🏆 Checking achievement: ${achievement.title}');

        // Check if achievement criteria are met
        if (await _checkAchievementCriteria(achievement, {
          'student': student,
          'progress': progress,
          'assessments': studentSubmissions,
          'lessons': lessons,
          'learningPaths': learningPaths,
        })) {
          print('🏆 ✅ Achievement criteria met for: ${achievement.title}');
          
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
            print('🏆 🎉 Awarded achievement: ${achievement.title}');
          }
        } else {
          print('🏆 ❌ Achievement criteria not met for: ${achievement.title}');
        }
      }

      print('🏆 Total achievements awarded: ${achievements.length}');
      return achievements;
    } catch (e) {
      print('Error checking achievements: $e');
      return [];
    }
  }

  // Check point-based achievements
  Future<List<StudentAchievement>> _checkPointBasedAchievements(String studentId, String studentName, int totalPoints) async {
    try {
      print('🏆 Checking point-based achievements for $totalPoints points...');
      final achievements = <StudentAchievement>[];
      final currentAchievements = await getStudentAchievements(studentId);
      final allAchievements = await getAllAchievements();
      
      // Filter only point-based achievements
      final pointAchievements = allAchievements.where((a) => 
        a.criteria.containsKey('totalPoints') && a.criteria['totalPoints'] is int
      ).toList();
      
      print('🏆 Found ${pointAchievements.length} point-based achievements');
      
      for (final achievement in pointAchievements) {
        final requiredPoints = achievement.criteria['totalPoints'] as int;
        
        // Skip if already awarded
        if (currentAchievements.any((ca) => ca.achievementId == achievement.id)) {
          print('🏆 Achievement ${achievement.title} already awarded, skipping');
          continue;
        }
        
        // Check if student has enough points
        if (totalPoints >= requiredPoints) {
          print('🏆 ✅ Student has $totalPoints points, meets requirement for ${achievement.title} (${requiredPoints} points)');
          
          // Award achievement
          final studentAchievement = await awardAchievementToStudent(
            studentId,
            studentName,
            achievement,
            {'autoAwarded': true, 'pointsEarned': totalPoints, 'checkedAt': DateTime.now().toIso8601String()},
          );
          
          if (studentAchievement.isNotEmpty) {
            achievements.add(StudentAchievement(
              id: studentAchievement,
              studentId: studentId,
              studentName: studentName,
              achievementId: achievement.id,
              achievementTitle: achievement.title,
              achievementDescription: achievement.description,
              points: achievement.points,
              unlockedAt: DateTime.now(),
              metadata: {'autoAwarded': true, 'pointsEarned': totalPoints},
            ));
            print('🏆 🎉 Awarded achievement: ${achievement.title}');
          }
        } else {
          print('🏆 ❌ Student has $totalPoints points, needs ${requiredPoints} for ${achievement.title}');
        }
      }
      
      return achievements;
    } catch (e) {
      print('Error checking point-based achievements: $e');
      return [];
    }
  }

  // Get total points from assessment submissions for a student
  Future<int> getTotalPointsFromSubmissions(String studentId) async {
    try {
      print('🏆 Getting total points from submissions for student: $studentId');
      
      final submissions = await _getStudentAssessmentSubmissions(studentId);
      int totalPoints = 0;
      
      for (final submission in submissions) {
        final score = (submission['score'] as num?)?.toInt() ?? 0;
        totalPoints += score;
      }
      
      print('🏆 Student $studentId has $totalPoints total points from ${submissions.length} submissions');
      return totalPoints;
    } catch (e) {
      print('Error getting total points from submissions: $e');
      return 0;
    }
  }

  // Convert LinkedMap to Map<String, dynamic> recursively
  Map<String, dynamic> _convertLinkedMapToMap(Map map) {
    final result = <String, dynamic>{};
    
    for (final key in map.keys) {
      final value = map[key];
      if (value is Map) {
        result[key.toString()] = _convertLinkedMapToMap(value);
      } else {
        result[key.toString()] = value;
      }
    }
    
    return result;
  }

  // Get student's assessment submissions
  Future<List<Map<String, dynamic>>> _getStudentAssessmentSubmissions(String studentId) async {
    try {
      final snapshot = await _database
          .ref('assessment_submissions')
          .orderByChild('studentId')
          .equalTo(studentId)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> submissions = [];
      
      for (final entry in data.values) {
        if (entry is Map) {
          submissions.add(Map<String, dynamic>.from(entry));
        }
      }
      
      return submissions;
    } catch (e) {
      print('Error getting student assessment submissions: $e');
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
      final assessments = studentData['assessments'] as List<Map<String, dynamic>>;
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
    List<Map<String, dynamic>> assessments,
  ) {
    try {
      final minScore = criteria['minScore'] ?? 0;
      final minAssessments = criteria['minAssessments'] ?? 0;
      final minLessons = criteria['minLessons'] ?? 0;

      // Check assessment scores from real submission data
      final highScores = assessments.where((a) {
        final score = (a['score'] as num?)?.toInt() ?? 0;
        final maxScore = (a['maxPossibleScore'] as num?)?.toInt() ?? 10;
        final percentage = maxScore > 0 ? (score / maxScore) * 100 : 0;
        return percentage >= minScore;
      }).length;
      
      if (highScores < minAssessments) return false;

      // Check lesson completion
      final completedLessons = progress.where((p) => p.completionRate >= 100).length;
      if (completedLessons < minLessons) return false;

      return true;
    } catch (e) {
      print('Error checking academic criteria: $e');
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
    List<Map<String, dynamic>> assessments,
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

      // Check total points earned from assessments
      final earnedPoints = assessments.fold<int>(0, (sum, a) => sum + ((a['score'] as num?)?.toInt() ?? 0));
      if (totalPoints > 0 && earnedPoints < totalPoints) return false;

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
          final assessments = studentData['assessments'] as List<Map<String, dynamic>>;
          return assessments.any((a) {
            final score = (a['score'] as num?)?.toInt() ?? 0;
            final maxScore = (a['maxPossibleScore'] as num?)?.toInt() ?? 10;
            return maxScore > 0 && score == maxScore;
          });
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
          final assessments = studentData['assessments'] as List<Map<String, dynamic>>;
          final perfectScores = assessments.where((a) {
            final score = (a['score'] as num?)?.toInt() ?? 0;
            final maxScore = (a['maxPossibleScore'] as num?)?.toInt() ?? 10;
            return maxScore > 0 && score == maxScore;
          }).length;
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

  // Manually process all existing assessment submissions for achievements
  Future<void> processExistingSubmissionsForAchievements() async {
    try {
      print('🔄 Processing existing assessment submissions for achievements...');
      
      // Get all assessment submissions
      final snapshot = await _database
          .ref('assessment_submissions')
          .get();

      if (!snapshot.exists) {
        print('📊 No assessment submissions found');
        return;
      }

      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      final Map<String, List<Map<String, dynamic>>> studentSubmissions = {};
      
      // Group submissions by student
      for (final entry in data.values) {
        if (entry is Map) {
          final submission = Map<String, dynamic>.from(entry);
          final studentId = submission['studentId'] as String?;
          if (studentId != null) {
            studentSubmissions.putIfAbsent(studentId, () => []).add(submission);
          }
        }
      }
      
      print('📊 Found submissions for ${studentSubmissions.length} students');
      
      // Process each student's submissions
      for (final studentId in studentSubmissions.keys) {
        print('🏆 Processing achievements for student: $studentId');
        final submissions = studentSubmissions[studentId]!;
        
        // Calculate total points for this student
        int totalPoints = 0;
        for (final submission in submissions) {
          final score = (submission['score'] as num?)?.toInt() ?? 0;
          totalPoints += score;
        }
        
        print('📊 Student $studentId has $totalPoints total points from ${submissions.length} submissions');
        
        // Get student name from submissions
        final studentName = submissions.isNotEmpty ? submissions.first['studentName'] ?? 'Student' : 'Student';
        print('🏆 Student name from submissions: $studentName');
        
        // Check and award achievements based on total points
        print('🏆 Checking point-based achievements for student $studentId ($studentName) with $totalPoints points...');
        final newAchievements = await _checkPointBasedAchievements(studentId, studentName, totalPoints);
        if (newAchievements.isNotEmpty) {
          print('🏆 🎉 Awarded ${newAchievements.length} achievements to student $studentId:');
          for (final achievement in newAchievements) {
            print('🏆 - ${achievement.achievementTitle}');
          }
        } else {
          print('🏆 No new achievements for student $studentId');
        }
      }
      
      print('✅ Finished processing existing submissions for achievements');
    } catch (e) {
      print('Error processing existing submissions for achievements: $e');
    }
  }

  // Create sample achievements in the database
  Future<void> createSampleAchievements() async {
    try {
      print('🏆 Creating sample achievements...');
      
      final sampleAchievements = [
        Achievement(
          id: 'achievement_1',
          title: 'First Steps',
          description: 'Complete your first lesson',
          category: 'milestone',
          points: 10,
          iconName: 'school',
          colorHex: '#007AFF',
          criteria: {'totalLessons': 1},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Achievement(
          id: 'achievement_2',
          title: 'Perfect Score',
          description: 'Get 100% on an assessment',
          category: 'academic',
          points: 25,
          iconName: 'star',
          colorHex: '#FFD700',
          criteria: {'minScore': 100, 'minAssessments': 1},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
        ),
        Achievement(
          id: 'achievement_3',
          title: 'Weekend Warrior',
          description: 'Study on weekends for 3 consecutive weeks',
          category: 'streak',
          points: 15,
          iconName: 'fire',
          colorHex: '#FF6B35',
          criteria: {'minStreak': 3, 'streakType': 'weekly'},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        Achievement(
          id: 'achievement_4',
          title: 'Knowledge Seeker',
          description: 'Complete 10 lessons',
          category: 'participation',
          points: 50,
          iconName: 'book',
          colorHex: '#34C759',
          criteria: {'minLessons': 10},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        Achievement(
          id: 'achievement_5',
          title: 'Fast Learner',
          description: 'Complete 3 lessons in under 10 minutes each',
          category: 'special',
          points: 30,
          iconName: 'lightbulb',
          colorHex: '#FF9500',
          criteria: {'specialCondition': 'fast_learner', 'fastLessons': 3, 'maxTimePerLesson': 10},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        Achievement(
          id: 'achievement_6',
          title: 'Perfect Quiz Master',
          description: 'Get perfect scores on 5 consecutive quizzes',
          category: 'special',
          points: 75,
          iconName: 'trophy',
          colorHex: '#FFD700',
          criteria: {'specialCondition': 'perfect_quiz_master', 'perfectQuizzes': 5, 'consecutive': true},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        // Points milestone badges
        Achievement(
          id: 'achievement_10_points',
          title: 'First Steps',
          description: 'Earn your first 10 points',
          category: 'milestone',
          points: 10,
          iconName: 'star',
          colorHex: '#34C759',
          criteria: {'totalPoints': 10},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Achievement(
          id: 'achievement_20_points',
          title: 'Rising Star',
          description: 'Earn 20 points',
          category: 'milestone',
          points: 15,
          iconName: 'star',
          colorHex: '#007AFF',
          criteria: {'totalPoints': 20},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Achievement(
          id: 'achievement_30_points',
          title: 'Learning Champion',
          description: 'Earn 30 points',
          category: 'milestone',
          points: 20,
          iconName: 'star',
          colorHex: '#FF9500',
          criteria: {'totalPoints': 30},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Achievement(
          id: 'achievement_40_points',
          title: 'Knowledge Builder',
          description: 'Earn 40 points',
          category: 'milestone',
          points: 25,
          iconName: 'star',
          colorHex: '#AF52DE',
          criteria: {'totalPoints': 40},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Achievement(
          id: 'achievement_50_points',
          title: 'Academic Achiever',
          description: 'Earn 50 points',
          category: 'milestone',
          points: 30,
          iconName: 'star',
          colorHex: '#FF6B35',
          criteria: {'totalPoints': 50},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Achievement(
          id: 'achievement_60_points',
          title: 'Study Master',
          description: 'Earn 60 points',
          category: 'milestone',
          points: 35,
          iconName: 'star',
          colorHex: '#5856D6',
          criteria: {'totalPoints': 60},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Achievement(
          id: 'achievement_70_points',
          title: 'Learning Expert',
          description: 'Earn 70 points',
          category: 'milestone',
          points: 40,
          iconName: 'star',
          colorHex: '#FF2D92',
          criteria: {'totalPoints': 70},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Achievement(
          id: 'achievement_80_points',
          title: 'Knowledge Warrior',
          description: 'Earn 80 points',
          category: 'milestone',
          points: 45,
          iconName: 'star',
          colorHex: '#32D74B',
          criteria: {'totalPoints': 80},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Achievement(
          id: 'achievement_90_points',
          title: 'Academic Legend',
          description: 'Earn 90 points',
          category: 'milestone',
          points: 50,
          iconName: 'star',
          colorHex: '#FF9F0A',
          criteria: {'totalPoints': 90},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Achievement(
          id: 'achievement_100_points',
          title: 'Century Scholar',
          description: 'Earn 100 points',
          category: 'milestone',
          points: 60,
          iconName: 'star',
          colorHex: '#FFD700',
          criteria: {'totalPoints': 100},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ];

      for (final achievement in sampleAchievements) {
        try {
          // Check if achievement already exists in Realtime Database
          final existing = await _database.ref('achievements/${achievement.id}').get();
          if (!existing.exists) {
            await _database.ref('achievements/${achievement.id}').set(achievement.toRealtimeDatabase());
            print('🏆 Created achievement: ${achievement.title}');
          } else {
            print('🏆 Achievement already exists: ${achievement.title}');
          }
        } catch (e) {
          print('🏆 Error creating achievement ${achievement.title}: $e');
          // Continue with other achievements even if one fails
        }
      }
      
      print('🏆 Sample achievements creation completed');
    } catch (e) {
      print('Error creating sample achievements: $e');
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
