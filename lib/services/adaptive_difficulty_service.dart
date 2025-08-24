import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/adaptive_difficulty.dart';
import '../models/assessment.dart';
import '../models/lesson.dart';
import '../models/student_progress.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';
import 'assessment_service.dart';
import 'lesson_service.dart';
import 'progress_service.dart';

class AdaptiveDifficultyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService = ConnectivityService();
  
  final AssessmentService _assessmentService = AssessmentService();
  final LessonService _lessonService = LessonService();
  final ProgressService _progressService = ProgressService();

  // Get or create adaptive difficulty profile for a student
  Future<AdaptiveDifficulty> getOrCreateAdaptiveDifficulty(
    String studentId,
    String studentName,
    String subject,
  ) async {
    try {
      if (_connectivityService.isConnected) {
        // Try to fetch from Firestore
        final doc = await _firestore
            .collection('adaptive_difficulties')
            .where('studentId', isEqualTo: studentId)
            .where('subject', isEqualTo: subject)
            .get();

        if (doc.docs.isNotEmpty) {
          final adaptiveDifficulty = AdaptiveDifficulty.fromFirestore(doc.docs.first);
          await _cacheAdaptiveDifficultyLocally(adaptiveDifficulty);
          return adaptiveDifficulty;
        }
      } else {
        // Try to get from cache
        final cached = await _getCachedAdaptiveDifficulty(studentId, subject);
        if (cached != null) return cached;
      }

      // Create new profile if none exists
      final newProfile = AdaptiveDifficulty(
        id: '',
        studentId: studentId,
        studentName: studentName,
        subject: subject,
        currentLevel: DifficultyLevel.beginner,
        performanceScore: 0.0,
        consecutiveCorrect: 0,
        consecutiveIncorrect: 0,
        totalAttempts: 0,
        lastUpdated: DateTime.now(),
        subjectPerformance: {},
        difficultyHistory: {},
        metadata: {'createdAt': DateTime.now().toIso8601String()},
      );

      return await createAdaptiveDifficulty(newProfile);
    } catch (e) {
      print('Error getting adaptive difficulty: $e');
      // Return default profile
      return AdaptiveDifficulty(
        id: 'default_$studentId',
        studentId: studentId,
        studentName: studentName,
        subject: subject,
        currentLevel: DifficultyLevel.beginner,
        performanceScore: 0.0,
        consecutiveCorrect: 0,
        consecutiveIncorrect: 0,
        totalAttempts: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  // Create new adaptive difficulty profile
  Future<AdaptiveDifficulty> createAdaptiveDifficulty(AdaptiveDifficulty profile) async {
    try {
      if (_connectivityService.isConnected) {
        // Save to Firestore
        final docRef = await _firestore
            .collection('adaptive_difficulties')
            .add(profile.toFirestore());
        
        // Save to Realtime Database
        await _database
            .ref('adaptive_difficulties/${docRef.id}')
            .set(profile.toRealtimeDatabase());
        
        // Cache locally
        final profileWithId = profile.copyWith(id: docRef.id);
        await _cacheAdaptiveDifficultyLocally(profileWithId);
        
        return profileWithId;
      } else {
        // Offline mode
        final tempId = 'temp_adaptive_${DateTime.now().millisecondsSinceEpoch}';
        final profileWithId = profile.copyWith(id: tempId);
        
        await _cacheAdaptiveDifficultyLocally(profileWithId);
        await _queueAdaptiveDifficultyForSync(profileWithId);
        
        return profileWithId;
      }
    } catch (e) {
      print('Error creating adaptive difficulty: $e');
      rethrow;
    }
  }

  // Update adaptive difficulty based on performance
  Future<AdaptiveDifficulty> updatePerformance(
    String studentId,
    String subject,
    bool isCorrect,
    double score,
    String topic,
  ) async {
    try {
      final currentProfile = await getOrCreateAdaptiveDifficulty(studentId, 'Student', subject);
      
      // Calculate new performance metrics
      final newTotalAttempts = currentProfile.totalAttempts + 1;
      final newConsecutiveCorrect = isCorrect 
          ? currentProfile.consecutiveCorrect + 1 
          : 0;
      final newConsecutiveIncorrect = !isCorrect 
          ? currentProfile.consecutiveIncorrect + 1 
          : 0;
      
      // Update topic performance
      final updatedSubjectPerformance = Map<String, dynamic>.from(currentProfile.subjectPerformance);
      if (updatedSubjectPerformance[topic] == null) {
        updatedSubjectPerformance[topic] = {
          'correct': 0,
          'incorrect': 0,
          'total': 0,
          'averageScore': 0.0,
        };
      }
      
      final topicData = Map<String, dynamic>.from(updatedSubjectPerformance[topic]);
      topicData['total'] = (topicData['total'] ?? 0) + 1;
      if (isCorrect) {
        topicData['correct'] = (topicData['correct'] ?? 0) + 1;
      } else {
        topicData['incorrect'] = (topicData['incorrect'] ?? 0) + 1;
      }
      
      // Calculate new average score for topic
      final currentTotal = (topicData['averageScore'] ?? 0.0) * (topicData['total'] - 1);
      topicData['averageScore'] = (currentTotal + score) / topicData['total'];
      updatedSubjectPerformance[topic] = topicData;
      
      // Calculate overall performance score
      final newPerformanceScore = _calculateOverallPerformance(updatedSubjectPerformance);
      
      // Check if difficulty should be adjusted
      final newLevel = _shouldAdjustDifficulty(
        currentProfile.currentLevel,
        newPerformanceScore,
        newConsecutiveCorrect,
        newConsecutiveIncorrect,
      );
      
      // Create difficulty adjustment record if level changed
      if (newLevel != currentProfile.currentLevel) {
        await _recordDifficultyAdjustment(
          studentId,
          subject,
          currentProfile.currentLevel,
          newLevel,
          newPerformanceScore,
          updatedSubjectPerformance,
        );
      }
      
      // Update profile
      final updatedProfile = currentProfile.copyWith(
        currentLevel: newLevel,
        performanceScore: newPerformanceScore,
        consecutiveCorrect: newConsecutiveCorrect,
        consecutiveIncorrect: newConsecutiveIncorrect,
        totalAttempts: newTotalAttempts,
        lastUpdated: DateTime.now(),
        subjectPerformance: updatedSubjectPerformance,
      );
      
      // Save updated profile
      await _saveAdaptiveDifficulty(updatedProfile);
      
      return updatedProfile;
    } catch (e) {
      print('Error updating performance: $e');
      rethrow;
    }
  }

  // Calculate overall performance score from topic performance
  double _calculateOverallPerformance(Map<String, dynamic> subjectPerformance) {
    if (subjectPerformance.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    int totalTopics = 0;
    
    for (final topic in subjectPerformance.values) {
      if (topic is Map<String, dynamic>) {
        final total = topic['total'] ?? 0;
        if (total > 0) {
          final correct = topic['correct'] ?? 0;
          final topicScore = total > 0 ? correct / total : 0.0;
          totalScore += topicScore;
          totalTopics++;
        }
      }
    }
    
    return totalTopics > 0 ? totalScore / totalTopics : 0.0;
  }

  // Determine if difficulty should be adjusted
  DifficultyLevel _shouldAdjustDifficulty(
    DifficultyLevel currentLevel,
    double performanceScore,
    int consecutiveCorrect,
    int consecutiveIncorrect,
  ) {
    switch (currentLevel) {
      case DifficultyLevel.beginner:
        if (performanceScore >= 0.8 && consecutiveCorrect >= 3) {
          return DifficultyLevel.intermediate;
        }
        break;
      case DifficultyLevel.intermediate:
        if (performanceScore >= 0.85 && consecutiveCorrect >= 4) {
          return DifficultyLevel.advanced;
        } else if (performanceScore < 0.6 && consecutiveIncorrect >= 3) {
          return DifficultyLevel.beginner;
        }
        break;
      case DifficultyLevel.advanced:
        if (performanceScore >= 0.9 && consecutiveCorrect >= 5) {
          return DifficultyLevel.expert;
        } else if (performanceScore < 0.7 && consecutiveIncorrect >= 3) {
          return DifficultyLevel.intermediate;
        }
        break;
      case DifficultyLevel.expert:
        if (performanceScore < 0.8 && consecutiveIncorrect >= 3) {
          return DifficultyLevel.advanced;
        }
        break;
    }
    
    return currentLevel;
  }

  // Record difficulty adjustment
  Future<void> _recordDifficultyAdjustment(
    String studentId,
    String subject,
    DifficultyLevel previousLevel,
    DifficultyLevel newLevel,
    double performanceThreshold,
    Map<String, dynamic> performanceData,
  ) async {
    try {
      final adjustment = DifficultyAdjustment(
        id: '',
        studentId: studentId,
        subject: subject,
        previousLevel: previousLevel,
        newLevel: newLevel,
        reason: _getAdjustmentReason(previousLevel, newLevel, performanceThreshold),
        performanceThreshold: performanceThreshold,
        adjustedAt: DateTime.now(),
        performanceData: performanceData,
      );

      if (_connectivityService.isConnected) {
        // Save to Firestore
        await _firestore
            .collection('difficulty_adjustments')
            .add(adjustment.toFirestore());
        
        // Save to Realtime Database
        await _database
            .ref('difficulty_adjustments/${adjustment.id}')
            .set(adjustment.toRealtimeDatabase());
      } else {
        // Queue for sync
        await _queueDifficultyAdjustmentForSync(adjustment);
      }
    } catch (e) {
      print('Error recording difficulty adjustment: $e');
    }
  }

  // Get adjustment reason
  String _getAdjustmentReason(
    DifficultyLevel previousLevel,
    DifficultyLevel newLevel,
    double performanceThreshold,
  ) {
    if (newLevel.index > previousLevel.index) {
      return 'Performance improved above ${(performanceThreshold * 100).round()}% threshold';
    } else if (newLevel.index < previousLevel.index) {
      return 'Performance dropped below ${(performanceThreshold * 100).round()}% threshold';
    }
    return 'No change in difficulty level';
  }

  // Get adaptive content recommendations
  Future<Map<String, dynamic>> getAdaptiveContentRecommendations(
    String studentId,
    String subject,
  ) async {
    try {
      final profile = await getOrCreateAdaptiveDifficulty(studentId, 'Student', subject);
      
      // Get content based on difficulty level
      final recommendations = <String, dynamic>{
        'currentLevel': profile.currentLevel,
        'performanceScore': profile.performanceScore,
        'recommendedLessons': await _getRecommendedLessons(profile),
        'recommendedAssessments': await _getRecommendedAssessments(profile),
        'nextLevelTarget': _getNextLevelTarget(profile.currentLevel),
        'performanceInsights': _getPerformanceInsights(profile),
      };
      
      return recommendations;
    } catch (e) {
      print('Error getting adaptive content recommendations: $e');
      return {};
    }
  }

  // Get recommended lessons based on difficulty
  Future<List<Map<String, dynamic>>> _getRecommendedLessons(AdaptiveDifficulty profile) async {
    try {
      // This would typically fetch from lesson service with difficulty filtering
      // For now, return mock recommendations
      return [
        {
          'id': 'lesson_1',
          'title': 'Adaptive Lesson for ${profile.difficultyLevelString}',
          'difficulty': profile.currentLevel.toString().split('.').last,
          'estimatedTime': '15-20 minutes',
          'topics': profile.subjectPerformance.keys.take(3).toList(),
        },
      ];
    } catch (e) {
      return [];
    }
  }

  // Get recommended assessments based on difficulty
  Future<List<Map<String, dynamic>>> _getRecommendedAssessments(AdaptiveDifficulty profile) async {
    try {
      // This would typically fetch from assessment service with difficulty filtering
      // For now, return mock recommendations
      return [
        {
          'id': 'assessment_1',
          'title': '${profile.difficultyLevelString} Level Assessment',
          'difficulty': profile.currentLevel.toString().split('.').last,
          'questionCount': 10,
          'timeLimit': 20,
        },
      ];
    } catch (e) {
      return [];
    }
  }

  // Get next level target
  String _getNextLevelTarget(DifficultyLevel currentLevel) {
    switch (currentLevel) {
      case DifficultyLevel.beginner:
        return 'Intermediate (80% performance + 3 consecutive correct)';
      case DifficultyLevel.intermediate:
        return 'Advanced (85% performance + 4 consecutive correct)';
      case DifficultyLevel.advanced:
        return 'Expert (90% performance + 5 consecutive correct)';
      case DifficultyLevel.expert:
        return 'Maintain Expert level (80%+ performance)';
    }
  }

  // Get performance insights
  Map<String, dynamic> _getPerformanceInsights(AdaptiveDifficulty profile) {
    final insights = <String, dynamic>{};
    
    if (profile.performanceScore >= 0.8) {
      insights['strength'] = 'Excellent performance! Consider advancing to next level.';
    } else if (profile.performanceScore >= 0.6) {
      insights['strength'] = 'Good performance. Focus on weak areas to improve.';
    } else {
      insights['strength'] = 'Performance needs improvement. Review basic concepts.';
    }
    
    if (profile.consecutiveCorrect >= 3) {
      insights['momentum'] = 'Great momentum! Keep up the good work.';
    } else if (profile.consecutiveIncorrect >= 3) {
      insights['momentum'] = 'Struggling with recent questions. Consider reviewing.';
    }
    
    return insights;
  }

  // Save adaptive difficulty profile
  Future<void> _saveAdaptiveDifficulty(AdaptiveDifficulty profile) async {
    try {
      if (_connectivityService.isConnected) {
        // Update in Firestore
        await _firestore
            .collection('adaptive_difficulties')
            .doc(profile.id)
            .set(profile.toFirestore());
        
        // Update in Realtime Database
        await _database
            .ref('adaptive_difficulties/${profile.id}')
            .set(profile.toRealtimeDatabase());
        
        // Cache locally
        await _cacheAdaptiveDifficultyLocally(profile);
      } else {
        // Cache locally and queue for sync
        await _cacheAdaptiveDifficultyLocally(profile);
        await _queueAdaptiveDifficultyForSync(profile);
      }
    } catch (e) {
      print('Error saving adaptive difficulty: $e');
    }
  }

  // Offline caching methods
  Future<void> _cacheAdaptiveDifficultyLocally(AdaptiveDifficulty profile) async {
    try {
      await OfflineService.cacheAdaptiveDifficulty(profile.toRealtimeDatabase());
    } catch (e) {
      print('Error caching adaptive difficulty locally: $e');
    }
  }

  Future<AdaptiveDifficulty?> _getCachedAdaptiveDifficulty(String studentId, String subject) async {
    try {
      final cached = await OfflineService.getCachedAdaptiveDifficulties();
      final matching = cached.where((data) => 
        data['studentId'] == studentId && data['subject'] == subject
      ).toList();
      
      if (matching.isNotEmpty) {
        return AdaptiveDifficulty.fromRealtimeDatabase(matching.first, matching.first['id'] ?? '');
      }
      return null;
    } catch (e) {
      print('Error getting cached adaptive difficulty: $e');
      return null;
    }
  }

  // Queue methods for offline sync
  Future<void> _queueAdaptiveDifficultyForSync(AdaptiveDifficulty profile) async {
    try {
      await OfflineService.queueAdaptiveDifficultyForSync(profile.toRealtimeDatabase());
    } catch (e) {
      print('Error queuing adaptive difficulty for sync: $e');
    }
  }

  Future<void> _queueDifficultyAdjustmentForSync(DifficultyAdjustment adjustment) async {
    try {
      await OfflineService.queueDifficultyAdjustmentForSync(adjustment.toRealtimeDatabase());
    } catch (e) {
      print('Error queuing difficulty adjustment for sync: $e');
    }
  }
}
