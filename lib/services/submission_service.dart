import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import '../models/assessment_submission.dart';
import '../models/assessment.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';

class SubmissionService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get all submissions for a specific student (with offline caching)
  Future<List<AssessmentSubmission>> getStudentSubmissions(String studentId) async {
    try {
      if (_connectivityService.isConnected) {
        // Try to get from Firebase
        print('🌐 Fetching student submissions from Firebase for student: $studentId');
        final ref = _database.ref('assessment_submissions');
        final query = ref.orderByChild('studentId').equalTo(studentId);
        final snapshot = await query.get();
        
        if (snapshot.exists) {
          List<AssessmentSubmission> submissions = [];
          int processedCount = 0;
          int errorCount = 0;
          
          for (var child in snapshot.children) {
            try {
              processedCount++;
              print('🔍 Processing submission ${child.key} (${processedCount}/${snapshot.children.length})');
              
              final submission = AssessmentSubmission.fromRealtimeDatabase(
                child.value as Map<Object?, Object?>,
                child.key!,
              );
              submissions.add(submission);
            } catch (e) {
              errorCount++;
              print('⚠️ Error parsing submission ${child.key}: $e');
              // Continue processing other submissions instead of failing completely
            }
          }
          
          print('📊 Processed $processedCount submissions, $errorCount errors');
          
          // Sort by submission date (newest first)
          submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          
          print('📊 Loaded ${submissions.length} valid submissions from Firebase');
          
          // Cache submissions offline
          await OfflineService.cacheStudentSubmissions(studentId, submissions);
          
          return submissions;
        } else {
          print('📭 No submissions found in Firebase for student: $studentId');
          return [];
        }
      } else {
        // Use cached data when offline
        print('📱 Using cached submissions for student: $studentId');
        final cachedData = await OfflineService.getCachedStudentSubmissions(studentId);
        return cachedData.map((data) => AssessmentSubmission.fromRealtimeDatabase(
          data as Map<Object?, Object?>,
          (data['id'] ?? '').toString(),
        )).toList();
      }
    } catch (e) {
      print('❌ Error fetching student submissions: $e');
      
      // Fallback to cached data
      try {
        final cachedData = await OfflineService.getCachedStudentSubmissions(studentId);
        return cachedData.map((data) => AssessmentSubmission.fromRealtimeDatabase(
          data as Map<Object?, Object?>,
          (data['id'] ?? '').toString(),
        )).toList();
      } catch (cacheError) {
        print('❌ Error accessing cached submissions: $cacheError');
        return [];
      }
    }
  }

  // Get all submissions for a specific assessment (with offline caching)
  Future<List<AssessmentSubmission>> getAssessmentSubmissions(String assessmentId) async {
    try {
      if (_connectivityService.isConnected) {
        // Try to get from Firebase
        print('🌐 Fetching assessment submissions from Firebase for assessment: $assessmentId');
        final ref = _database.ref('assessment_submissions');
        final query = ref.orderByChild('assessmentId').equalTo(assessmentId);
        final snapshot = await query.get();
        
        if (snapshot.exists) {
          List<AssessmentSubmission> submissions = [];
          for (var child in snapshot.children) {
            try {
              final submission = AssessmentSubmission.fromRealtimeDatabase(
                child.value as Map<Object?, Object?>,
                child.key!,
              );
              submissions.add(submission);
            } catch (e) {
              print('⚠️ Error parsing submission ${child.key}: $e');
            }
          }
          
          // Sort by submission date (newest first)
          submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          
          print('📊 Loaded ${submissions.length} submissions from Firebase for assessment: $assessmentId');
          
          // Cache submissions offline
          await OfflineService.cacheAssessmentSubmissions(assessmentId, submissions);
          
          return submissions;
        } else {
          print('📭 No submissions found in Firebase for assessment: $assessmentId');
          return [];
        }
      } else {
        // Use cached data when offline
        print('📱 Using cached submissions for assessment: $assessmentId');
        final cachedData = await OfflineService.getCachedAssessmentSubmissions(assessmentId);
        return cachedData.map((data) => AssessmentSubmission.fromRealtimeDatabase(
          data as Map<Object?, Object?>,
          (data['id'] ?? '').toString(),
        )).toList();
      }
    } catch (e) {
      print('❌ Error fetching assessment submissions: $e');
      
      // Fallback to cached data
      try {
        final cachedData = await OfflineService.getCachedAssessmentSubmissions(assessmentId);
        return cachedData.map((data) => AssessmentSubmission.fromRealtimeDatabase(
          data as Map<Object?, Object?>,
          (data['id'] ?? '').toString(),
        )).toList();
      } catch (cacheError) {
        print('❌ Error accessing cached submissions: $cacheError');
        return [];
      }
    }
  }

  // Get all submissions for a teacher (with offline caching)
  Future<List<AssessmentSubmission>> getTeacherSubmissions(String teacherId) async {
    try {
      if (_connectivityService.isConnected) {
        // Try to get from Firebase
        print('🌐 Fetching teacher submissions from Firebase for teacher: $teacherId');
        final ref = _database.ref('assessment_submissions');
        
        // First, let's see ALL submissions to debug
        final allSnapshot = await ref.get();
        print('🔍 Total submissions in database: ${allSnapshot.children.length}');
        
        if (allSnapshot.exists) {
          print('📋 All submission keys: ${allSnapshot.children.map((c) => c.key).toList()}');
          for (var child in allSnapshot.children.take(3)) { // Show first 3 for debugging
            print('📄 Submission ${child.key}: ${child.value}');
          }
        }
        
        // Now try the specific teacher query
        final query = ref.orderByChild('teacherId').equalTo(teacherId);
        final snapshot = await query.get();
        
        if (snapshot.exists) {
          List<AssessmentSubmission> submissions = [];
          for (var child in snapshot.children) {
            try {
              final submission = AssessmentSubmission.fromRealtimeDatabase(
                child.value as Map<Object?, Object?>,
                child.key!,
              );
              submissions.add(submission);
            } catch (e) {
              print('⚠️ Error parsing submission ${child.key}: $e');
            }
          }
          
          // Sort by submission date (newest first)
          submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          
          print('📊 Loaded ${submissions.length} submissions from Firebase for teacher: $teacherId');
          
          // Cache submissions offline
          await OfflineService.cacheTeacherSubmissions(teacherId, submissions);
          
          return submissions;
        } else {
          print('📭 No submissions found in Firebase for teacher: $teacherId');
          print('🔍 This might mean:');
          print('   1. No submissions exist yet');
          print('   2. Teacher ID mismatch: looking for "$teacherId"');
          print('   3. Data structure is different');
          return [];
        }
      } else {
        // Use cached data when offline
        print('📱 Using cached submissions for teacher: $teacherId');
        final cachedData = await OfflineService.getCachedTeacherSubmissions(teacherId);
        return cachedData.map((data) => AssessmentSubmission.fromRealtimeDatabase(
          data as Map<Object?, Object?>,
          (data['id'] ?? '').toString(),
        )).toList();
      }
    } catch (e) {
      print('❌ Error fetching teacher submissions: $e');
      
      // Fallback to cached data
      try {
        final cachedData = await OfflineService.getCachedTeacherSubmissions(teacherId);
        return cachedData.map((data) => AssessmentSubmission.fromRealtimeDatabase(
          data as Map<Object?, Object?>,
          (data['id'] ?? '').toString(),
        )).toList();
      } catch (cacheError) {
        print('❌ Error accessing cached submissions: $cacheError');
        return [];
      }
    }
  }

  // Get a specific submission by ID (with offline caching)
  Future<AssessmentSubmission?> getSubmissionById(String submissionId) async {
    try {
      if (_connectivityService.isConnected) {
        // Try to get from Firebase
        print('🌐 Fetching submission from Firebase: $submissionId');
        final ref = _database.ref('assessment_submissions/$submissionId');
        final snapshot = await ref.get();
        
        if (snapshot.exists) {
          final submission = AssessmentSubmission.fromRealtimeDatabase(
            snapshot.value as Map<Object?, Object?>,
            submissionId,
          );
          
          print('📊 Loaded submission: ${submission.id}');
          
          // Cache submission offline
          await OfflineService.cacheSubmission(submissionId, submission);
          
          return submission;
        } else {
          print('📭 Submission not found: $submissionId');
          return null;
        }
      } else {
        // Use cached data when offline
        print('📱 Using cached submission: $submissionId');
        final cachedData = await OfflineService.getCachedSubmission(submissionId);
        if (cachedData != null) {
          return AssessmentSubmission.fromRealtimeDatabase(
            cachedData as Map<Object?, Object?>,
            submissionId,
          );
        }
        return null;
      }
    } catch (e) {
      print('❌ Error fetching submission: $e');
      
      // Fallback to cached data
      try {
        final cachedData = await OfflineService.getCachedSubmission(submissionId);
        if (cachedData != null) {
          return AssessmentSubmission.fromRealtimeDatabase(
            cachedData as Map<Object?, Object?>,
            submissionId,
          );
        }
        return null;
      } catch (cacheError) {
        print('❌ Error accessing cached submission: $cacheError');
        return null;
      }
    }
  }

  // Update submission (e.g., add feedback, change score)
  Future<bool> updateSubmission(AssessmentSubmission submission) async {
    try {
      if (_connectivityService.isConnected) {
        // Update in Firebase
        print('🌐 Updating submission in Firebase: ${submission.id}');
        final ref = _database.ref('assessment_submissions/${submission.id}');
        await ref.update(submission.toMap());
        
        print('✅ Submission updated successfully');
        
        // Update cache
        await OfflineService.cacheSubmission(submission.id, submission);
        
        return true;
      } else {
        // Queue update for when online
        print('📱 Queuing submission update for when online: ${submission.id}');
        await OfflineService.queueSubmissionUpdate(submission);
        
        // Update cache immediately for offline use
        await OfflineService.cacheSubmission(submission.id, submission);
        
        return true;
      }
    } catch (e) {
      print('❌ Error updating submission: $e');
      return false;
    }
  }

  // Delete submission
  Future<bool> deleteSubmission(String submissionId) async {
    try {
      if (_connectivityService.isConnected) {
        // Delete from Firebase
        print('🌐 Deleting submission from Firebase: $submissionId');
        final ref = _database.ref('assessment_submissions/$submissionId');
        await ref.remove();
        
        print('✅ Submission deleted successfully');
        
        // Remove from cache
        await OfflineService.removeCachedSubmission(submissionId);
        
        return true;
      } else {
        // Queue deletion for when online
        print('📱 Queuing submission deletion for when online: $submissionId');
        await OfflineService.queueSubmissionDeletion(submissionId);
        
        // Remove from cache immediately for offline use
        await OfflineService.removeCachedSubmission(submissionId);
        
        return true;
      }
    } catch (e) {
      print('❌ Error deleting submission: $e');
      return false;
    }
  }



  // Get submission statistics for a student
  Future<Map<String, dynamic>> getStudentSubmissionStats(String studentId) async {
    try {
      final submissions = await getStudentSubmissions(studentId);
      
      if (submissions.isEmpty) {
        return {
          'totalSubmissions': 0,
          'averageScore': 0.0,
          'highestScore': 0,
          'lowestScore': 0,
          'totalTimeSpent': 0,
          'subjects': <String>[],
        };
      }

      int totalScore = 0;
      int highestScore = 0;
      int lowestScore = 100;
      int totalTimeSpent = 0;
      Set<String> subjects = {};

      for (var submission in submissions) {
        totalScore += submission.score;
        if (submission.score > highestScore) highestScore = submission.score;
        if (submission.score < lowestScore) lowestScore = submission.score;
        totalTimeSpent += submission.timeSpent;
        // Note: We'd need to fetch assessment details to get subjects
      }

      return {
        'totalSubmissions': submissions.length,
        'averageScore': totalScore / submissions.length,
        'highestScore': highestScore,
        'lowestScore': lowestScore,
        'totalTimeSpent': totalTimeSpent,
        'subjects': subjects.toList(),
      };
    } catch (e) {
      print('❌ Error getting student submission stats: $e');
      return {
        'totalSubmissions': 0,
        'averageScore': 0.0,
        'highestScore': 0,
        'lowestScore': 0,
        'totalTimeSpent': 0,
        'subjects': <String>[],
      };
    }
  }
}
