import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feedback.dart';
import '../models/student.dart';
import '../models/assessment.dart';
import '../models/lesson.dart';
import '../models/learning_path.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Create student feedback
  Future<String> createStudentFeedback(StudentFeedback feedback) async {
    try {
      if (_connectivityService.isConnected) {
        // Save to Firestore
        final docRef = await _firestore.collection('student_feedback').add(feedback.toFirestore());
        
        // Also save to Realtime Database for offline support
        await _database.ref('student_feedback/${docRef.id}').set(feedback.toRealtimeDatabase());
        
        // Cache locally
        await _cacheFeedbackLocally(feedback.copyWith(id: docRef.id));
        
        return docRef.id;
      } else {
        // Offline mode - save locally and queue for sync
        final tempId = 'temp_feedback_${DateTime.now().millisecondsSinceEpoch}';
        final feedbackWithId = feedback.copyWith(id: tempId);
        
        await _cacheFeedbackLocally(feedbackWithId);
        await _queueFeedbackForSync(feedbackWithId);
        
        return tempId;
      }
    } catch (e) {
      print('Error creating student feedback: $e');
      rethrow;
    }
  }

  // Create student recommendation
  Future<String> createStudentRecommendation(StudentRecommendation recommendation) async {
    try {
      if (_connectivityService.isConnected) {
        // Save to Firestore
        final docRef = await _firestore.collection('student_recommendations').add(recommendation.toFirestore());
        
        // Also save to Realtime Database for offline support
        await _database.ref('student_recommendations/${docRef.id}').set(recommendation.toRealtimeDatabase());
        
        // Cache locally
        await _cacheRecommendationLocally(recommendation.copyWith(id: docRef.id));
        
        return docRef.id;
      } else {
        // Offline mode - save locally and queue for sync
        final tempId = 'temp_recommendation_${DateTime.now().millisecondsSinceEpoch}';
        final recommendationWithId = recommendation.copyWith(id: tempId);
        
        await _cacheRecommendationLocally(recommendationWithId);
        await _queueRecommendationForSync(recommendationWithId);
        
        return tempId;
      }
    } catch (e) {
      print('Error creating student recommendation: $e');
      rethrow;
    }
  }

  // Get feedback for a specific student
  Future<List<StudentFeedback>> getStudentFeedback(String studentId) async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('student_feedback')
            .where('studentId', isEqualTo: studentId)
            .orderBy('createdAt', descending: true)
            .get();

        final feedbacks = querySnapshot.docs
            .map((doc) => StudentFeedback.fromFirestore(doc))
            .toList();

        // Cache locally
        for (final feedback in feedbacks) {
          await _cacheFeedbackLocally(feedback);
        }

        return feedbacks;
      } else {
        // Use cached data
        return await _getCachedStudentFeedback(studentId);
      }
    } catch (e) {
      print('Error getting student feedback: $e');
      return await _getCachedStudentFeedback(studentId);
    }
  }

  // Get recommendations for a specific student
  Future<List<StudentRecommendation>> getStudentRecommendations(String studentId) async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('student_recommendations')
            .where('studentId', isEqualTo: studentId)
            .orderBy('createdAt', descending: true)
            .get();

        final recommendations = querySnapshot.docs
            .map((doc) => StudentRecommendation.fromFirestore(doc))
            .toList();

        // Cache locally
        for (final recommendation in recommendations) {
          await _cacheRecommendationLocally(recommendation);
        }

        return recommendations;
      } else {
        // Use cached data
        return await _getCachedStudentRecommendations(studentId);
      }
    } catch (e) {
      print('Error getting student recommendations: $e');
      return await _getCachedStudentRecommendations(studentId);
    }
  }

  // Get feedback created by a teacher
  Future<List<StudentFeedback>> getTeacherFeedback(String teacherId) async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('student_feedback')
            .where('teacherId', isEqualTo: teacherId)
            .orderBy('createdAt', descending: true)
            .get();

        final feedbacks = querySnapshot.docs
            .map((doc) => StudentFeedback.fromFirestore(doc))
            .toList();

        // Cache locally
        for (final feedback in feedbacks) {
          await _cacheFeedbackLocally(feedback);
        }

        return feedbacks;
      } else {
        // Use cached data
        return await _getCachedTeacherFeedback(teacherId);
      }
    } catch (e) {
      print('Error getting teacher feedback: $e');
      return await _getCachedTeacherFeedback(teacherId);
    }
  }

  // Get recommendations created by a teacher
  Future<List<StudentRecommendation>> getTeacherRecommendations(String teacherId) async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('student_recommendations')
            .where('teacherId', isEqualTo: teacherId)
            .orderBy('createdAt', descending: true)
            .get();

        final recommendations = querySnapshot.docs
            .map((doc) => StudentRecommendation.fromFirestore(doc))
            .toList();

        // Cache locally
        for (final recommendation in recommendations) {
          await _cacheRecommendationLocally(recommendation);
        }

        return recommendations;
      } else {
        // Use cached data
        return await _getCachedTeacherRecommendations(teacherId);
      }
    } catch (e) {
      print('Error getting teacher recommendations: $e');
      return await _getCachedTeacherRecommendations(teacherId);
    }
  }

  // Update feedback
  Future<void> updateFeedback(StudentFeedback feedback) async {
    try {
      if (_connectivityService.isConnected) {
        // Update in Firestore
        await _firestore
            .collection('student_feedback')
            .doc(feedback.id)
            .update(feedback.toFirestore());

        // Update in Realtime Database
        await _database.ref('student_feedback/${feedback.id}').update(feedback.toRealtimeDatabase());

        // Update local cache
        await _cacheFeedbackLocally(feedback);
      } else {
        // Offline mode - update local cache and queue for sync
        await _cacheFeedbackLocally(feedback);
        await _queueFeedbackForSync(feedback);
      }
    } catch (e) {
      print('Error updating feedback: $e');
      rethrow;
    }
  }

  // Update recommendation
  Future<void> updateRecommendation(StudentRecommendation recommendation) async {
    try {
      if (_connectivityService.isConnected) {
        // Update in Firestore
        await _firestore
            .collection('student_recommendations')
            .doc(recommendation.id)
            .update(recommendation.toFirestore());

        // Update in Realtime Database
        await _database.ref('student_recommendations/${recommendation.id}').update(recommendation.toRealtimeDatabase());

        // Update local cache
        await _cacheRecommendationLocally(recommendation);
      } else {
        // Offline mode - update local cache and queue for sync
        await _cacheRecommendationLocally(recommendation);
        await _queueRecommendationForSync(recommendation);
      }
    } catch (e) {
      print('Error updating recommendation: $e');
      rethrow;
    }
  }

  // Mark feedback as read
  Future<void> markFeedbackAsRead(String feedbackId) async {
    try {
      if (_connectivityService.isConnected) {
        // Update in Firestore
        await _firestore
            .collection('student_feedback')
            .doc(feedbackId)
            .update({'isRead': true});

        // Update in Realtime Database
        await _database.ref('student_feedback/$feedbackId').update({'isRead': true});

        // Update local cache
        await _updateCachedFeedbackReadStatus(feedbackId, true);
      } else {
        // Offline mode
        await _updateCachedFeedbackReadStatus(feedbackId, true);
        await _queueFeedbackReadStatusForSync(feedbackId, true);
      }
    } catch (e) {
      print('Error marking feedback as read: $e');
      rethrow;
    }
  }

  // Mark recommendation as read
  Future<void> markRecommendationAsRead(String recommendationId) async {
    try {
      if (_connectivityService.isConnected) {
        // Update in Firestore
        await _firestore
            .collection('student_recommendations')
            .doc(recommendationId)
            .update({'isRead': true});

        // Update in Realtime Database
        await _database.ref('student_recommendations/$recommendationId').update({'isRead': true});

        // Update local cache
        await _updateCachedRecommendationReadStatus(recommendationId, true);
      } else {
        // Offline mode
        await _updateCachedRecommendationReadStatus(recommendationId, true);
        await _queueRecommendationReadStatusForSync(recommendationId, true);
      }
    } catch (e) {
      print('Error marking recommendation as read: $e');
      rethrow;
    }
  }

  // Generate AI-powered recommendations based on student performance
  Future<List<StudentRecommendation>> generateAIRecommendations(
    String studentId,
    String studentName,
    Map<String, dynamic> performanceData,
  ) async {
    try {
      final recommendations = <StudentRecommendation>[];
      final teacherId = _auth.currentUser?.uid ?? '';
      final teacherName = _auth.currentUser?.displayName ?? 'Teacher';

      // Analyze assessment performance
      if (performanceData['assessments'] != null) {
        final assessments = performanceData['assessments'] as List;
        final lowScores = assessments.where((a) => a['score'] < 70).toList();
        
        if (lowScores.isNotEmpty) {
          recommendations.add(StudentRecommendation(
            id: '',
            studentId: studentId,
            studentName: studentName,
            teacherId: teacherId,
            teacherName: teacherName,
            recommendationType: 'content',
            title: 'Review Low-Score Topics',
            description: 'Focus on improving understanding in areas with lower scores',
            reason: 'Assessment scores indicate gaps in understanding',
            actionItems: 'Review previous lessons, practice with similar questions, seek clarification',
            priority: 3,
            createdAt: DateTime.now(),
            metadata: {'lowScoreTopics': lowScores.map((a) => a['topic']).toList()},
          ));
        }
      }

      // Analyze learning path progress
      if (performanceData['learningPaths'] != null) {
        final learningPaths = performanceData['learningPaths'] as List;
        final slowProgress = learningPaths.where((lp) => lp['progress'] < 50).toList();
        
        if (slowProgress.isNotEmpty) {
          recommendations.add(StudentRecommendation(
            id: '',
            studentId: studentId,
            studentName: studentName,
            teacherId: teacherId,
            teacherName: teacherName,
            recommendationType: 'learning_path',
            title: 'Accelerate Learning Path Progress',
            description: 'Focus on completing learning path steps more efficiently',
            reason: 'Learning path progress is slower than expected',
            actionItems: 'Set daily study goals, break down complex steps, use study techniques',
            priority: 2,
            createdAt: DateTime.now(),
            metadata: {'slowProgressPaths': slowProgress.map((lp) => lp['title']).toList()},
          ));
        }
      }

      // Study habit recommendations
      if (performanceData['studyTime'] != null) {
        final studyTime = performanceData['studyTime'] as int;
        if (studyTime < 60) { // Less than 1 hour per day
          recommendations.add(StudentRecommendation(
            id: '',
            studentId: studentId,
            studentName: studentName,
            teacherId: teacherId,
            teacherName: teacherName,
            recommendationType: 'study_habit',
            title: 'Increase Study Time',
            description: 'Allocate more time for daily study sessions',
            reason: 'Current study time may not be sufficient for optimal learning',
            actionItems: 'Schedule dedicated study blocks, eliminate distractions, use time management techniques',
            priority: 4,
            createdAt: DateTime.now(),
            metadata: {'currentStudyTime': studyTime, 'recommendedStudyTime': 90},
          ));
        }
      }

      return recommendations;
    } catch (e) {
      print('Error generating AI recommendations: $e');
      return [];
    }
  }

  // Get feedback statistics for a teacher
  Future<Map<String, dynamic>> getFeedbackStatistics(String teacherId) async {
    try {
      if (_connectivityService.isConnected) {
        // Get feedback count
        final feedbackSnapshot = await _firestore
            .collection('student_feedback')
            .where('teacherId', isEqualTo: teacherId)
            .get();
        
        final feedbackCount = feedbackSnapshot.docs.length;
        final unreadFeedbackCount = feedbackSnapshot.docs
            .where((doc) => !(doc.data()['isRead'] ?? false))
            .length;

        // Get recommendation count
        final recommendationSnapshot = await _firestore
            .collection('student_recommendations')
            .where('teacherId', isEqualTo: teacherId)
            .get();
        
        final recommendationCount = recommendationSnapshot.docs.length;
        final completedRecommendations = recommendationSnapshot.docs
            .where((doc) => doc.data()['isCompleted'] ?? false)
            .length;

        return {
          'totalFeedback': feedbackCount,
          'unreadFeedback': unreadFeedbackCount,
          'totalRecommendations': recommendationCount,
          'completedRecommendations': completedRecommendations,
          'completionRate': recommendationCount > 0 ? (completedRecommendations / recommendationCount * 100).round() : 0,
        };
      } else {
        // Use cached data
        return await _getCachedFeedbackStatistics(teacherId);
      }
    } catch (e) {
      print('Error getting feedback statistics: $e');
      return await _getCachedFeedbackStatistics(teacherId);
    }
  }

  // Offline caching methods
  Future<void> _cacheFeedbackLocally(StudentFeedback feedback) async {
    try {
      await OfflineService.cacheFeedback(feedback.toRealtimeDatabase());
    } catch (e) {
      print('Error caching feedback locally: $e');
    }
  }

  Future<void> _cacheRecommendationLocally(StudentRecommendation recommendation) async {
    try {
      await OfflineService.cacheRecommendation(recommendation.toRealtimeDatabase());
    } catch (e) {
      print('Error caching recommendation locally: $e');
    }
  }

  Future<List<StudentFeedback>> _getCachedStudentFeedback(String studentId) async {
    try {
      final cachedFeedback = await OfflineService.getCachedFeedback();
      return cachedFeedback
          .where((data) => data['studentId'] == studentId)
          .map((data) => StudentFeedback.fromRealtimeDatabase(data, data['id'] ?? ''))
          .toList();
    } catch (e) {
      print('Error getting cached student feedback: $e');
      return [];
    }
  }

  Future<List<StudentRecommendation>> _getCachedStudentRecommendations(String studentId) async {
    try {
      final cachedRecommendations = await OfflineService.getCachedRecommendations();
      return cachedRecommendations
          .where((data) => data['studentId'] == studentId)
          .map((data) => StudentRecommendation.fromRealtimeDatabase(data, data['id'] ?? ''))
          .toList();
    } catch (e) {
      print('Error getting cached student recommendations: $e');
      return [];
    }
  }

  Future<List<StudentFeedback>> _getCachedTeacherFeedback(String teacherId) async {
    try {
      final cachedFeedback = await OfflineService.getCachedFeedback();
      return cachedFeedback
          .where((data) => data['teacherId'] == teacherId)
          .map((data) => StudentFeedback.fromRealtimeDatabase(data, data['id'] ?? ''))
          .toList();
    } catch (e) {
      print('Error getting cached teacher feedback: $e');
      return [];
    }
  }

  Future<List<StudentRecommendation>> _getCachedTeacherRecommendations(String teacherId) async {
    try {
      final cachedRecommendations = await OfflineService.getCachedRecommendations();
      return cachedRecommendations
          .where((data) => data['teacherId'] == teacherId)
          .map((data) => StudentRecommendation.fromRealtimeDatabase(data, data['id'] ?? ''))
          .toList();
    } catch (e) {
      print('Error getting cached teacher recommendations: $e');
      return [];
    }
  }

  // Queue methods for offline sync
  Future<void> _queueFeedbackForSync(StudentFeedback feedback) async {
    try {
      await OfflineService.queueFeedbackForSync(feedback.toRealtimeDatabase());
    } catch (e) {
      print('Error queuing feedback for sync: $e');
    }
  }

  Future<void> _queueRecommendationForSync(StudentRecommendation recommendation) async {
    try {
      await OfflineService.queueRecommendationForSync(recommendation.toRealtimeDatabase());
    } catch (e) {
      print('Error queuing recommendation for sync: $e');
    }
  }

  Future<void> _queueFeedbackReadStatusForSync(String feedbackId, bool isRead) async {
    try {
      await OfflineService.queueFeedbackReadStatusForSync({
        'feedbackId': feedbackId,
        'isRead': isRead,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error queuing feedback read status for sync: $e');
    }
  }

  Future<void> _queueRecommendationReadStatusForSync(String recommendationId, bool isRead) async {
    try {
      await OfflineService.queueRecommendationReadStatusForSync({
        'recommendationId': recommendationId,
        'isRead': isRead,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error queuing recommendation read status for sync: $e');
    }
  }

  // Update cached read status
  Future<void> _updateCachedFeedbackReadStatus(String feedbackId, bool isRead) async {
    try {
      await OfflineService.updateCachedFeedbackReadStatus(feedbackId, isRead);
    } catch (e) {
      print('Error updating cached feedback read status: $e');
    }
  }

  Future<void> _updateCachedRecommendationReadStatus(String recommendationId, bool isRead) async {
    try {
      await OfflineService.updateCachedRecommendationReadStatus(recommendationId, isRead);
    } catch (e) {
      print('Error updating cached recommendation read status: $e');
    }
  }

  // Get cached statistics
  Future<Map<String, dynamic>> _getCachedFeedbackStatistics(String teacherId) async {
    try {
      return await OfflineService.getCachedFeedbackStatistics(teacherId);
    } catch (e) {
      print('Error getting cached feedback statistics: $e');
      return {
        'totalFeedback': 0,
        'unreadFeedback': 0,
        'totalRecommendations': 0,
        'completedRecommendations': 0,
        'completionRate': 0,
      };
    }
  }
}
