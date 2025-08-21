import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/lesson.dart';
import '../models/module.dart';
import '../models/subject.dart';
import '../models/assessment.dart';
import '../models/attempt.dart';
import '../models/progress.dart';
import '../models/badge.dart';
import '../models/points.dart';
import '../models/classroom.dart';
import '../models/content_version.dart';
import '../models/sync_queue.dart';

class FirestoreDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Users Collection
  CollectionReference<Map<String, dynamic>> get users => _firestore.collection('users');
  
  // Content Collections
  CollectionReference<Map<String, dynamic>> get subjects => _firestore.collection('subjects');
  CollectionReference<Map<String, dynamic>> get modules => _firestore.collection('modules');
  CollectionReference<Map<String, dynamic>> get lessons => _firestore.collection('lessons');
  CollectionReference<Map<String, dynamic>> get assessments => _firestore.collection('assessments');
  
  // User Progress Collections
  CollectionReference<Map<String, dynamic>> get userProgress => _firestore.collection('user_progress');
  CollectionReference<Map<String, dynamic>> get userAttempts => _firestore.collection('user_attempts');
  CollectionReference<Map<String, dynamic>> get userBadges => _firestore.collection('user_badges');
  CollectionReference<Map<String, dynamic>> get userPoints => _firestore.collection('user_points');
  
  // System Collections
  CollectionReference<Map<String, dynamic>> get classrooms => _firestore.collection('classrooms');
  CollectionReference<Map<String, dynamic>> get contentVersions => _firestore.collection('content_versions');
  CollectionReference<Map<String, dynamic>> get syncQueue => _firestore.collection('sync_queue');

  // User Management
  Future<void> createUser(User user) async {
    try {
      await users.doc(user.id).set({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'role': user.role.toString(),
        'section': user.section,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user: $e');
      }
      rethrow;
    }
  }

  Future<User?> getUser(String userId) async {
    try {
      final doc = await users.doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return User(
          id: data['id'],
          name: data['name'],
          email: data['email'],
          role: UserRole.values.firstWhere(
            (e) => e.toString() == data['role'],
            orElse: () => UserRole.student,
          ),
          section: data['section'],
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user: $e');
      }
      return null;
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await users.doc(user.id).update({
        'name': user.name,
        'email': user.email,
        'role': user.role.toString(),
        'section': user.section,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user: $e');
      }
      rethrow;
    }
  }

  // Content Management
  Future<List<Subject>> getSubjects() async {
    try {
      final querySnapshot = await subjects.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Subject(
          id: doc.id,
          name: data['name'],
          gradeLevel: data['gradeLevel'] ?? 7,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting subjects: $e');
      }
      return [];
    }
  }

  Future<List<Module>> getModules(String subjectId) async {
    try {
      final querySnapshot = await modules
          .where('subjectId', isEqualTo: subjectId)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Module(
          id: doc.id,
          subjectId: data['subjectId'],
          title: data['title'],
          version: data['version'] ?? '1.0',
          isPublished: data['isPublished'] ?? true,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting modules: $e');
      }
      return [];
    }
  }

  Future<List<Lesson>> getLessons(String moduleId) async {
    try {
      final querySnapshot = await lessons
          .where('moduleId', isEqualTo: moduleId)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Lesson(
          id: doc.id,
          moduleId: data['moduleId'],
          title: data['title'],
          bodyMarkdown: data['bodyMarkdown'] ?? '',
          estMins: data['estMins'] ?? 30,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting lessons: $e');
      }
      return [];
    }
  }

  Future<Lesson?> getLesson(String lessonId) async {
    try {
      final doc = await lessons.doc(lessonId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return Lesson(
          id: doc.id,
          moduleId: data['moduleId'],
          title: data['title'],
          bodyMarkdown: data['bodyMarkdown'] ?? '',
          estMins: data['estMins'] ?? 30,
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting lesson: $e');
      }
      return null;
    }
  }

  // Assessment Management
  Future<List<Assessment>> getAssessments(String moduleId) async {
    try {
      final querySnapshot = await assessments
          .where('moduleId', isEqualTo: moduleId)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Assessment(
          id: doc.id,
          lessonId: data['lessonId'],
          type: AssessmentType.values.firstWhere(
            (e) => e.toString() == data['type'],
            orElse: () => AssessmentType.quiz,
          ),
          items: (data['items'] as List<dynamic>? ?? []).map((item) {
            return Question(
              id: item['id'],
              text: item['text'],
              choices: List<String>.from(item['choices']),
              correctIndex: item['correctIndex'],
            );
          }).toList(),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting assessments: $e');
      }
      return [];
    }
  }

  // Progress Management
  Future<void> saveProgress(Progress progress) async {
    try {
      await userProgress.doc('${progress.userId}_${progress.lessonId}').set({
        'userId': progress.userId,
        'lessonId': progress.lessonId,
        'status': progress.status.toString(),
        'lastScore': progress.lastScore,
        'attemptCount': progress.attemptCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error saving progress: $e');
      }
      rethrow;
    }
  }

  Future<Progress?> getProgress(String userId, String lessonId) async {
    try {
      final doc = await userProgress.doc('${userId}_$lessonId').get();
      if (doc.exists) {
        final data = doc.data()!;
        return Progress(
          userId: data['userId'],
          lessonId: data['lessonId'],
          status: ProgressStatus.values.firstWhere(
            (e) => e.toString() == data['status'],
            orElse: () => ProgressStatus.locked,
          ),
          lastScore: data['lastScore'],
          attemptCount: data['attemptCount'] ?? 0,
          updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting progress: $e');
      }
      return null;
    }
  }

  Future<List<Progress>> getUserProgress(String userId) async {
    try {
      final querySnapshot = await userProgress
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Progress(
          userId: data['userId'],
          lessonId: data['lessonId'],
          status: ProgressStatus.values.firstWhere(
            (e) => e.toString() == data['status'],
            orElse: () => ProgressStatus.locked,
          ),
          lastScore: data['lastScore'],
          attemptCount: data['attemptCount'] ?? 0,
          updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user progress: $e');
      }
      return [];
    }
  }

  // Attempt Management
  Future<void> saveAttempt(Attempt attempt) async {
    try {
      await userAttempts.add({
        'userId': attempt.userId,
        'assessmentId': attempt.assessmentId,
        'score': attempt.score,
        'answersJson': attempt.answersJson,
        'startedAt': attempt.startedAt,
        'finishedAt': attempt.finishedAt,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error saving attempt: $e');
      }
      rethrow;
    }
  }

  Future<List<Attempt>> getUserAttempts(String userId) async {
    try {
      final querySnapshot = await userAttempts
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Attempt(
          id: doc.id,
          userId: data['userId'],
          assessmentId: data['assessmentId'],
          score: data['score'],
          answersJson: Map<String, int>.from(data['answersJson'] ?? {}),
          startedAt: data['startedAt']?.toDate() ?? DateTime.now(),
          finishedAt: data['finishedAt']?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user attempts: $e');
      }
      return [];
    }
  }

  // Points and Badges
  Future<void> updateUserPoints(String userId, int points) async {
    try {
      await userPoints.doc(userId).set({
        'userId': userId,
        'points': points,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user points: $e');
      }
      rethrow;
    }
  }

  Future<int> getUserPoints(String userId) async {
    try {
      final doc = await userPoints.doc(userId).get();
      if (doc.exists) {
        return doc.data()?['points'] ?? 0;
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user points: $e');
      }
      return 0;
    }
  }

  // Sync Queue Management
  Future<void> addToSyncQueue(SyncQueueItem item) async {
    try {
      await syncQueue.add({
        'entityTable': item.entityTable,
        'operation': item.operation.toString(),
        'recordId': item.recordId,
        'dataJson': item.dataJson,
        'createdAt': FieldValue.serverTimestamp(),
        'isSynced': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding to sync queue: $e');
      }
      rethrow;
    }
  }

  Future<List<SyncQueueItem>> getPendingSyncItems(String userId) async {
    try {
      final querySnapshot = await syncQueue
          .where('isSynced', isEqualTo: false)
          .orderBy('createdAt')
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return SyncQueueItem(
          id: doc.id,
          entityTable: data['entityTable'],
          operation: SyncOperation.values.firstWhere(
            (e) => e.toString() == data['operation'],
            orElse: () => SyncOperation.create,
          ),
          recordId: data['recordId'],
          dataJson: data['dataJson'],
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          isSynced: data['isSynced'] ?? false,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending sync items: $e');
      }
      return [];
    }
  }

  // Initialize with seed data
  Future<void> initializeWithSeedData() async {
    try {
      // Check if data already exists
      final subjectsSnapshot = await subjects.limit(1).get();
      if (subjectsSnapshot.docs.isNotEmpty) {
        if (kDebugMode) {
          print('Seed data already exists, skipping initialization');
        }
        return;
      }

      // Import seed data from JSON
      // This would typically come from your assets/seed/grade7_science.json
      if (kDebugMode) {
        print('Initializing database with seed data...');
      }
      
      // You can add seed data initialization here if needed
      // For now, we'll just create a placeholder
      
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing seed data: $e');
      }
    }
  }

  // Close database (no-op for Firestore)
  Future<void> close() async {
    // Firestore doesn't need explicit closing
  }
}
