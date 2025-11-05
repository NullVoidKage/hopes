import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_progress.dart';
import 'connectivity_service.dart';
import 'package:flutter/foundation.dart';

class LessonProgressService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Track lesson start (create or update progress)
  Future<void> trackLessonStart({
    required String studentId,
    required String studentName,
    required String lessonId,
    required String lessonTitle,
    required String subject,
    required String teacherId,
    required String teacherName,
    String? section,
    String? classId,
  }) async {
    try {
      if (!_connectivityService.isConnected) {
        // Queue for sync when online
        await _queueProgressForSync(studentId, lessonId, subject);
        return;
      }

      // Check if progress already exists
      final progressRef = _database
          .ref()
          .child('lesson_progress')
          .orderByChild('studentId')
          .equalTo(studentId);
      
      final snapshot = await progressRef.get();
      LessonProgress? existingProgress;
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map && value['lessonId'] == lessonId) {
            existingProgress = LessonProgress.fromRealtimeDatabase(key, value);
          }
        });
      }

      if (existingProgress != null) {
        // Update existing progress
        await _database
            .ref()
            .child('lesson_progress')
            .child(existingProgress!.id)
            .update({
          'lastActivity': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        });
      } else {
        // Create new progress
        final progressRef = _database.ref().child('lesson_progress').push();
        final progressId = progressRef.key!;
        
        final progressData = {
          'studentId': studentId,
          'studentName': studentName,
          'lessonId': lessonId,
          'lessonTitle': lessonTitle,
          'subject': subject,
          'teacherId': teacherId,
          'teacherName': teacherName,
          'startedAt': ServerValue.timestamp,
          'lastActivity': ServerValue.timestamp,
          'isCompleted': false,
          'progressPercentage': 0.0,
          'timeSpent': 0,
          'section': section,
          'classId': classId,
        };

        await progressRef.set(progressData);
        
        // Also save to Firestore
        await _firestore.collection('lesson_progress').doc(progressId).set({
          'studentId': studentId,
          'studentName': studentName,
          'lessonId': lessonId,
          'lessonTitle': lessonTitle,
          'subject': subject,
          'teacherId': teacherId,
          'teacherName': teacherName,
          'startedAt': FieldValue.serverTimestamp(),
          'lastActivity': FieldValue.serverTimestamp(),
          'isCompleted': false,
          'progressPercentage': 0.0,
          'timeSpent': 0,
          'section': section,
          'classId': classId,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking lesson start: $e');
      }
      rethrow;
    }
  }

  // Update lesson progress
  Future<void> updateLessonProgress({
    required String studentId,
    required String lessonId,
    required double progressPercentage,
    required int timeSpent,
    bool isCompleted = false,
  }) async {
    try {
      if (!_connectivityService.isConnected) {
        await _queueProgressForSync(studentId, lessonId, '');
        return;
      }

      // Find progress record
      final progressRef = _database
          .ref()
          .child('lesson_progress')
          .orderByChild('studentId')
          .equalTo(studentId);
      
      final snapshot = await progressRef.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        String? progressId;
        
        data.forEach((key, value) {
          if (value is Map && value['lessonId'] == lessonId) {
            progressId = key;
          }
        });

        if (progressId != null) {
          final updates = {
            'progressPercentage': progressPercentage,
            'timeSpent': timeSpent,
            'isCompleted': isCompleted,
            'lastActivity': ServerValue.timestamp,
            if (isCompleted) 'completedAt': ServerValue.timestamp,
          };

          await _database
              .ref()
              .child('lesson_progress')
              .child(progressId!)
              .update(updates);
          
          // Also update Firestore
          await _firestore.collection('lesson_progress').doc(progressId).update({
            'progressPercentage': progressPercentage,
            'timeSpent': timeSpent,
            'isCompleted': isCompleted,
            'lastActivity': FieldValue.serverTimestamp(),
            if (isCompleted) 'completedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating lesson progress: $e');
      }
      rethrow;
    }
  }

  // Get lesson progress for a specific student
  Future<List<LessonProgress>> getStudentLessonProgress({
    required String studentId,
    String? subject,
  }) async {
    try {
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedStudentProgress(studentId, subject: subject);
      }

      final query = _database
          .ref()
          .child('lesson_progress')
          .orderByChild('studentId')
          .equalTo(studentId);

      final snapshot = await query.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final progressList = <LessonProgress>[];
        
        data.forEach((key, value) {
          if (value is Map) {
            final progress = LessonProgress.fromRealtimeDatabase(key, value);
            if (subject == null || progress.subject == subject) {
              progressList.add(progress);
            }
          }
        });

        return progressList;
      }

      return [];
    } catch (e) {
      return await _getCachedStudentProgress(studentId, subject: subject);
    }
  }

  // Get lesson progress for a teacher (all students)
  Future<List<LessonProgress>> getTeacherLessonProgress({
    required String teacherId,
    String? studentId,
    String? section,
    String? subject,
  }) async {
    try {
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedTeacherProgress(teacherId, studentId: studentId, section: section, subject: subject);
      }

      final query = _database
          .ref()
          .child('lesson_progress')
          .orderByChild('teacherId')
          .equalTo(teacherId);

      final snapshot = await query.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final progressList = <LessonProgress>[];
        
        data.forEach((key, value) {
          if (value is Map) {
            final progress = LessonProgress.fromRealtimeDatabase(key, value);
            
            // Apply filters
            if (studentId != null && progress.studentId != studentId) return;
            if (section != null && progress.section != section) return;
            if (subject != null && progress.subject != subject) return;
            
            progressList.add(progress);
          }
        });

        return progressList;
      }

      return [];
    } catch (e) {
      return await _getCachedTeacherProgress(teacherId, studentId: studentId, section: section, subject: subject);
    }
  }

  // Get cached student progress
  Future<List<LessonProgress>> _getCachedStudentProgress(String studentId, {String? subject}) async {
    // Implementation for offline cache
    return [];
  }

  // Get cached teacher progress
  Future<List<LessonProgress>> _getCachedTeacherProgress(String teacherId, {String? studentId, String? section, String? subject}) async {
    // Implementation for offline cache
    return [];
  }

  // Queue progress for sync when online
  Future<void> _queueProgressForSync(String studentId, String lessonId, String subject) async {
    // Implementation for offline queue
  }
}

