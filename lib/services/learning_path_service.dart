import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/learning_path.dart';
import '../models/student.dart';
import '../models/lesson.dart';
import '../models/assessment.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';

class LearningPathService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Create a new learning path
  Future<String> createLearningPath(LearningPath learningPath) async {
    try {
      if (_connectivityService.isConnected) {
        // Save to Firestore
        final docRef = await _firestore.collection('learning_paths').add(learningPath.toFirestore());
        
        // Also save to Realtime Database for offline support
        await _database.ref('learning_paths/${docRef.id}').set(learningPath.toRealtimeDatabase());
        
        // Cache locally
        await _cacheLearningPathLocally(learningPath.copyWith(id: docRef.id));
        
        return docRef.id;
      } else {
        // Offline mode - save locally and queue for sync
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final pathWithId = learningPath.copyWith(id: tempId);
        
        await _cacheLearningPathLocally(pathWithId);
        await _queueLearningPathForSync(pathWithId);
        
        return tempId;
      }
    } catch (e) {
      print('Error creating learning path: $e');
      rethrow;
    }
  }

  // Get learning paths by teacher
  Future<List<LearningPath>> getLearningPathsByTeacher(String teacherId) async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('learning_paths')
            .where('teacherId', isEqualTo: teacherId)
            .orderBy('createdAt', descending: true)
            .get();

        final paths = querySnapshot.docs
            .map((doc) => LearningPath.fromFirestore(doc))
            .toList();

        // Cache locally
        for (final path in paths) {
          await _cacheLearningPathLocally(path);
        }

        return paths;
      } else {
        // Use cached data
        return await _getCachedLearningPaths(teacherId);
      }
    } catch (e) {
      print('Error getting learning paths: $e');
      // Fallback to cached data
      return await _getCachedLearningPaths(teacherId);
    }
  }

  // Get all learning paths (for assignment)
  Future<List<LearningPath>> getAllLearningPaths() async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('learning_paths')
            .where('isPublished', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        final paths = querySnapshot.docs
            .map((doc) => LearningPath.fromFirestore(doc))
            .toList();

        // Cache locally
        for (final path in paths) {
          await _cacheLearningPathLocally(path);
        }

        return paths;
      } else {
        // Use cached data
        return await _getCachedLearningPaths(null);
      }
    } catch (e) {
      print('Error getting all learning paths: $e');
      return await _getCachedLearningPaths(null);
    }
  }

  // Update learning path
  Future<void> updateLearningPath(LearningPath learningPath) async {
    try {
      if (_connectivityService.isConnected) {
        // Update in Firestore
        await _firestore
            .collection('learning_paths')
            .doc(learningPath.id)
            .update(learningPath.toFirestore());

        // Update in Realtime Database
        await _database.ref('learning_paths/${learningPath.id}').update(learningPath.toRealtimeDatabase());

        // Update local cache
        await _cacheLearningPathLocally(learningPath);
      } else {
        // Offline mode - update local cache and queue for sync
        await _cacheLearningPathLocally(learningPath);
        await _queueLearningPathForSync(learningPath);
      }
    } catch (e) {
      print('Error updating learning path: $e');
      rethrow;
    }
  }

  // Delete learning path
  Future<void> deleteLearningPath(String pathId) async {
    try {
      if (_connectivityService.isConnected) {
        // Delete from Firestore
        await _firestore.collection('learning_paths').doc(pathId).delete();

        // Delete from Realtime Database
        await _database.ref('learning_paths/$pathId').remove();

        // Remove from local cache
        await _removeLearningPathFromCache(pathId);
      } else {
        // Offline mode - mark for deletion and queue
        await _markLearningPathForDeletion(pathId);
      }
    } catch (e) {
      print('Error deleting learning path: $e');
      rethrow;
    }
  }

  // Assign learning path to student
  Future<String> assignLearningPathToStudent(
    String studentId,
    String studentName,
    String learningPathId,
    String learningPathTitle,
    Map<String, dynamic> customizations,
  ) async {
    try {
      final assignment = StudentLearningPath(
        id: '',
        studentId: studentId,
        studentName: studentName,
        learningPathId: learningPathId,
        learningPathTitle: learningPathTitle,
        teacherId: _auth.currentUser?.uid ?? '',
        assignedAt: DateTime.now(),
        stepProgress: [],
        status: 'assigned',
        customizations: customizations,
      );

      if (_connectivityService.isConnected) {
        // Save to Firestore
        final docRef = await _firestore
            .collection('student_learning_paths')
            .add(assignment.toFirestore());

        // Save to Realtime Database
        await _database
            .ref('student_learning_paths/${docRef.id}')
            .set(assignment.toRealtimeDatabase());

        // Cache locally
        await _cacheStudentLearningPathLocally(assignment.copyWith(id: docRef.id));

        return docRef.id;
      } else {
        // Offline mode
        final tempId = 'temp_assignment_${DateTime.now().millisecondsSinceEpoch}';
        final assignmentWithId = assignment.copyWith(id: tempId);

        await _cacheStudentLearningPathLocally(assignmentWithId);
        await _queueAssignmentForSync(assignmentWithId);

        return tempId;
      }
    } catch (e) {
      print('Error assigning learning path: $e');
      rethrow;
    }
  }

  // Get student learning paths
  Future<List<StudentLearningPath>> getStudentLearningPaths(String studentId) async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('student_learning_paths')
            .where('studentId', isEqualTo: studentId)
            .orderBy('assignedAt', descending: true)
            .get();

        final assignments = querySnapshot.docs
            .map((doc) => StudentLearningPath.fromFirestore(doc))
            .toList();

        // Cache locally
        for (final assignment in assignments) {
          await _cacheStudentLearningPathLocally(assignment);
        }

        return assignments;
      } else {
        // Use cached data
        return await _getCachedStudentLearningPaths(studentId);
      }
    } catch (e) {
      print('Error getting student learning paths: $e');
      return await _getCachedStudentLearningPaths(studentId);
    }
  }

  // Get learning paths assigned by teacher
  Future<List<StudentLearningPath>> getLearningPathsAssignedByTeacher(String teacherId) async {
    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('student_learning_paths')
            .where('teacherId', isEqualTo: teacherId)
            .orderBy('assignedAt', descending: true)
            .get();

        final assignments = querySnapshot.docs
            .map((doc) => StudentLearningPath.fromFirestore(doc))
            .toList();

        // Cache locally
        for (final assignment in assignments) {
          await _cacheStudentLearningPathLocally(assignment);
        }

        return assignments;
      } else {
        // Use cached data
        return await _getCachedStudentLearningPathsByTeacher(teacherId);
      }
    } catch (e) {
      print('Error getting teacher assignments: $e');
      return await _getCachedStudentLearningPathsByTeacher(teacherId);
    }
  }

  // Update student learning path progress
  Future<void> updateStudentPathProgress(
    String assignmentId,
    List<StudentPathProgress> stepProgress,
    String status,
  ) async {
    try {
      if (_connectivityService.isConnected) {
        // Update in Firestore
        await _firestore
            .collection('student_learning_paths')
            .doc(assignmentId)
            .update({
          'stepProgress': stepProgress.map((step) => step.toMap()).toList(),
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update in Realtime Database
        await _database.ref('student_learning_paths/$assignmentId').update({
          'stepProgress': stepProgress.map((step) => step.toMap()).toList(),
          'status': status,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });

        // Update local cache
        await _updateCachedStudentLearningPath(assignmentId, stepProgress, status);
      } else {
        // Offline mode - update local cache and queue for sync
        await _updateCachedStudentLearningPath(assignmentId, stepProgress, status);
        await _queueProgressUpdateForSync(assignmentId, stepProgress, status);
      }
    } catch (e) {
      print('Error updating student path progress: $e');
      rethrow;
    }
  }

  // Get available content for learning path steps
  Future<Map<String, List<dynamic>>> getAvailableContent() async {
    try {
      if (_connectivityService.isConnected) {
        // Get lessons
        final lessonsSnapshot = await _firestore
            .collection('lessons')
            .where('isPublished', isEqualTo: true)
            .get();
        final lessons = lessonsSnapshot.docs
            .map((doc) => {'id': doc.id, 'title': doc.data()['title'], 'type': 'lesson'})
            .toList();

        // Get assessments
        final assessmentsSnapshot = await _firestore
            .collection('assessments')
            .where('isPublished', isEqualTo: true)
            .get();
        final assessments = assessmentsSnapshot.docs
            .map((doc) => {'id': doc.id, 'title': doc.data()['title'], 'type': 'assessment'})
            .toList();

        return {
          'lessons': lessons,
          'assessments': assessments,
        };
      } else {
        // Use cached content
        return await _getCachedAvailableContent();
      }
    } catch (e) {
      print('Error getting available content: $e');
      return await _getCachedAvailableContent();
    }
  }

  // Customize learning path for student
  Future<void> customizeLearningPathForStudent(
    String assignmentId,
    Map<String, dynamic> customizations,
  ) async {
    try {
      if (_connectivityService.isConnected) {
        // Update in Firestore
        await _firestore
            .collection('student_learning_paths')
            .doc(assignmentId)
            .update({
          'customizations': customizations,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update in Realtime Database
        await _database.ref('student_learning_paths/$assignmentId').update({
          'customizations': customizations,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });

        // Update local cache
        await _updateCachedCustomizations(assignmentId, customizations);
      } else {
        // Offline mode
        await _updateCachedCustomizations(assignmentId, customizations);
        await _queueCustomizationForSync(assignmentId, customizations);
      }
    } catch (e) {
      print('Error customizing learning path: $e');
      rethrow;
    }
  }

  // Offline caching methods
  Future<void> _cacheLearningPathLocally(LearningPath learningPath) async {
    try {
      await OfflineService.cacheLearningPath(learningPath.toRealtimeDatabase());
    } catch (e) {
      print('Error caching learning path locally: $e');
    }
  }

  Future<List<LearningPath>> _getCachedLearningPaths(String? teacherId) async {
    try {
      final cachedPaths = await OfflineService.getCachedLearningPaths();
      final paths = cachedPaths.map((data) => 
        LearningPath.fromRealtimeDatabase(data, data['id'] ?? '')
      ).toList();

      if (teacherId != null) {
        return paths.where((path) => path.teacherId == teacherId).toList();
      }
      return paths;
    } catch (e) {
      print('Error getting cached learning paths: $e');
      return [];
    }
  }

  Future<void> _cacheStudentLearningPathLocally(StudentLearningPath assignment) async {
    try {
      await OfflineService.cacheStudentLearningPath(assignment.toRealtimeDatabase());
    } catch (e) {
      print('Error caching student learning path locally: $e');
    }
  }

  Future<List<StudentLearningPath>> _getCachedStudentLearningPaths(String studentId) async {
    try {
      final cachedAssignments = await OfflineService.getCachedStudentLearningPaths();
      return cachedAssignments
          .where((data) => data['studentId'] == studentId)
          .map((data) => StudentLearningPath.fromRealtimeDatabase(data, data['id'] ?? ''))
          .toList();
    } catch (e) {
      print('Error getting cached student learning paths: $e');
      return [];
    }
  }

  Future<List<StudentLearningPath>> _getCachedStudentLearningPathsByTeacher(String teacherId) async {
    try {
      final cachedAssignments = await OfflineService.getCachedStudentLearningPaths();
      return cachedAssignments
          .where((data) => data['teacherId'] == teacherId)
          .map((data) => StudentLearningPath.fromRealtimeDatabase(data, data['id'] ?? ''))
          .toList();
    } catch (e) {
      print('Error getting cached teacher assignments: $e');
      return [];
    }
  }

  // Queue methods for offline sync
  Future<void> _queueLearningPathForSync(LearningPath learningPath) async {
    try {
      await OfflineService.queueLearningPathForSync(learningPath.toRealtimeDatabase());
    } catch (e) {
      print('Error queuing learning path for sync: $e');
    }
  }

  Future<void> _queueAssignmentForSync(StudentLearningPath assignment) async {
    try {
      await OfflineService.queueAssignmentForSync(assignment.toRealtimeDatabase());
    } catch (e) {
      print('Error queuing assignment for sync: $e');
    }
  }

  Future<void> _queueProgressUpdateForSync(
    String assignmentId,
    List<StudentPathProgress> stepProgress,
    String status,
  ) async {
    try {
      await OfflineService.queueProgressUpdateForSync({
        'assignmentId': assignmentId,
        'stepProgress': stepProgress.map((step) => step.toMap()).toList(),
        'status': status,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error queuing progress update for sync: $e');
    }
  }

  Future<void> _queueCustomizationForSync(
    String assignmentId,
    Map<String, dynamic> customizations,
  ) async {
    try {
      await OfflineService.queueCustomizationForSync({
        'assignmentId': assignmentId,
        'customizations': customizations,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error queuing customization for sync: $e');
    }
  }

  // Other helper methods
  Future<void> _removeLearningPathFromCache(String pathId) async {
    try {
      await OfflineService.removeLearningPathFromCache(pathId);
    } catch (e) {
      print('Error removing learning path from cache: $e');
    }
  }

  Future<void> _markLearningPathForDeletion(String pathId) async {
    try {
      await OfflineService.markLearningPathForDeletion(pathId);
    } catch (e) {
      print('Error marking learning path for deletion: $e');
    }
  }

  Future<void> _updateCachedStudentLearningPath(
    String assignmentId,
    List<StudentPathProgress> stepProgress,
    String status,
  ) async {
    try {
      await OfflineService.updateCachedStudentLearningPath(
        assignmentId, 
        stepProgress.map((step) => step.toMap()).toList(), 
        status
      );
    } catch (e) {
      print('Error updating cached student learning path: $e');
    }
  }

  Future<void> _updateCachedCustomizations(
    String assignmentId,
    Map<String, dynamic> customizations,
  ) async {
    try {
      await OfflineService.updateCachedCustomizations(assignmentId, customizations);
    } catch (e) {
      print('Error updating cached customizations: $e');
    }
  }

  Future<Map<String, List<dynamic>>> _getCachedAvailableContent() async {
    try {
      return await OfflineService.getCachedAvailableContent();
    } catch (e) {
      print('Error getting cached available content: $e');
      return {'lessons': [], 'assessments': []};
    }
  }
}
