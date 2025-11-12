import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/assessment.dart';
import '../models/assessment_submission.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';
import 'achievements_service.dart';
class AssessmentService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ConnectivityService _connectivityService = ConnectivityService();
  final AuthService _authService = AuthService();
  final AchievementsService _achievementsService = AchievementsService();

  // Create a new assessment
  Future<String> createAssessment(Assessment assessment) async {
    try {
      // Only allow creation when online
      if (_connectivityService.shouldUseCachedData) {
        throw Exception('Cannot create assessment while offline. Please connect to the internet.');
      }

      final ref = _database.ref('assessments').push();
      await ref.set(assessment.toRealtimeDatabase());
      return ref.key!;
    } catch (e) {
      throw Exception('Failed to create assessment: ${e.toString()}');
    }
  }

  // Get assessments by teacher
  Future<List<Assessment>> getAssessmentsByTeacher(String teacherId) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedAssessmentsByTeacher(teacherId);
      }

      // If online, fetch from Firebase and cache
      final snapshot = await _database
          .ref('assessments')
          .orderByChild('teacherId')
          .equalTo(teacherId)
          .get();

      if (snapshot.exists) {
        final assessments = <Assessment>[];
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map) {
            try {
              final assessment = Assessment.fromRealtimeDatabase(key, value);
              assessments.add(assessment);
            } catch (e) {
            }
          }
        });

        // Sort by creation date (newest first)
        assessments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Cache the data for offline use
        await _cacheAssessmentsLocally(assessments);
        
        return assessments;
      }
      
      return [];
    } catch (e) {
      // If Firebase fails, try to return cached data
      return await _getCachedAssessmentsByTeacher(teacherId);
    }
  }

  // Get cached assessments by teacher
  Future<List<Assessment>> _getCachedAssessmentsByTeacher(String teacherId) async {
    try {
      final cachedAssessments = await OfflineService.getCachedAssessments();
      
      // Filter by teacher ID
      final teacherAssessments = cachedAssessments.where((data) => 
        data['teacherId'] == teacherId
      ).toList();
      
      return teacherAssessments.map((data) => 
        Assessment.fromRealtimeDatabase(data['id'] ?? '', data)
      ).toList();
    } catch (e) {
      return [];
    }
  }

  // Cache assessments locally
  Future<void> _cacheAssessmentsLocally(List<Assessment> assessments) async {
    try {
      final assessmentData = assessments.map((assessment) => {
        'id': assessment.id,
        ...assessment.toRealtimeDatabase(),
      }).toList();
      await OfflineService.cacheAssessments(assessmentData);
    } catch (e) {
    }
  }

  // Get all published assessments (for students)
  Future<List<Assessment>> getAllPublishedAssessments() async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedAllPublishedAssessments();
      }

      // If online, fetch from Firebase and cache
      final snapshot = await _database
          .ref('assessments')
          .get();

      if (snapshot.exists) {
        final assessments = <Assessment>[];
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map) {
            try {
              final assessment = Assessment.fromRealtimeDatabase(key, value);
              // Only return published assessments
              if (assessment.isPublished) {
                assessments.add(assessment);
              }
            } catch (e) {
            }
          }
        });

        // Sort by creation date (newest first)
        assessments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Cache the data for offline use
        await _cacheAssessmentsLocally(assessments);
        
        return assessments;
      }
      
      return [];
    } catch (e) {
      // If Firebase fails, try to return cached data
      return await _getCachedAllPublishedAssessments();
    }
  }

  // Get cached assessments by teacher
  Future<List<Assessment>> _getCachedAllPublishedAssessments() async {
    try {
      final cachedAssessments = await OfflineService.getCachedAssessments();
      return cachedAssessments
          .where((data) => (data['isPublished'] as bool?) ?? false)
          .map((data) => Assessment.fromRealtimeDatabase(data['id'] ?? '', data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get assessments by subject
  Future<List<Assessment>> getAssessmentsBySubject(String subject) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedAssessmentsBySubject(subject);
      }

      // If online, fetch from Firebase and cache
      final snapshot = await _database
          .ref('assessments')
          .orderByChild('subject')
          .equalTo(subject)
          .get();

      if (snapshot.exists) {
        final assessments = <Assessment>[];
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map) {
            try {
              final assessment = Assessment.fromRealtimeDatabase(key, value);
              // Only return published assessments
              if (assessment.isPublished) {
                assessments.add(assessment);
              }
            } catch (e) {
            }
          }
        });

        // Sort by creation date (newest first)
        assessments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Cache the data for offline use
        await _cacheAssessmentsLocally(assessments);
        
        return assessments;
      }
      
      return [];
    } catch (e) {
      // If Firebase fails, try to return cached data
      return await _getCachedAssessmentsBySubject(subject);
    }
  }

  // Get cached assessments by subject
  Future<List<Assessment>> _getCachedAssessmentsBySubject(String subject) async {
    try {
      final cachedAssessments = await OfflineService.getCachedAssessments();
      return cachedAssessments
          .where((data) => (data['subject'] as String?) == subject)
          .map((data) => Assessment.fromRealtimeDatabase(data['id'] ?? '', data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get a specific assessment by ID
  Future<Assessment?> getAssessmentById(String assessmentId) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedAssessmentById(assessmentId);
      }

      // If online, fetch from Firebase and cache
      final snapshot = await _database
          .ref('assessments')
          .child(assessmentId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final assessment = Assessment.fromRealtimeDatabase(assessmentId, data);
        
        // Cache the assessment for offline use
        await _cacheAssessmentLocally(assessment);
        
        return assessment;
      }
      return null;
    } catch (e) {
      // If Firebase fails, try to return cached data
      return await _getCachedAssessmentById(assessmentId);
    }
  }

  // Update an assessment
  Future<void> updateAssessment(Assessment assessment) async {
    try {
      await _database
          .ref('assessments')
          .child(assessment.id)
          .update(assessment.toRealtimeDatabase());
    } catch (e) {
      throw Exception('Failed to update assessment: ${e.toString()}');
    }
  }

  // Delete an assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _database
          .ref('assessments')
          .child(assessmentId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete assessment: ${e.toString()}');
    }
  }

  // Toggle assessment publish status
  Future<void> toggleAssessmentPublish(String assessmentId, bool isPublished) async {
    try {
      await _database
          .ref('assessments')
          .child(assessmentId)
          .update({
        'isPublished': isPublished,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to toggle assessment publish status: ${e.toString()}');
    }
  }

  // Get assessment statistics
  Future<Map<String, dynamic>> getAssessmentStats(String teacherId) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedAssessmentStats(teacherId);
      }

      // If online, fetch from Firebase and calculate
      final assessments = await getAssessmentsByTeacher(teacherId);
      
      int totalAssessments = assessments.length;
      int publishedAssessments = assessments.where((a) => a.isPublished).length;
      int draftAssessments = totalAssessments - publishedAssessments;
      
      // Count assessments by subject
      Map<String, int> subjectCounts = {};
      for (var assessment in assessments) {
        subjectCounts[assessment.subject] = (subjectCounts[assessment.subject] ?? 0) + 1;
      }
      
      final stats = {
        'totalAssessments': totalAssessments,
        'publishedAssessments': publishedAssessments,
        'draftAssessments': draftAssessments,
        'subjectCounts': subjectCounts,
      };
      
      // Cache the stats for offline use
      await _cacheAssessmentStats(teacherId, stats);
      
      return stats;
    } catch (e) {
      // If Firebase fails, try to return cached data
      return await _getCachedAssessmentStats(teacherId);
    }
  }

  // Get assessment questions for students
  Future<List<AssessmentQuestion>> getAssessmentQuestions(String assessmentId) async {
    try {
      // Check if we should use cached data
      if (!_connectivityService.isConnected) {
        return await _getCachedAssessmentQuestions(assessmentId);
      }

      // If online, fetch from Firebase and cache
      final snapshot = await _database
          .ref('assessments')
          .child(assessmentId)
          .child('questions')
          .get();

      if (snapshot.exists) {
        final questions = <AssessmentQuestion>[];
        final data = snapshot.value;
        
        
        if (data is List) {
          // Questions are stored as an array
          
          for (int i = 0; i < data.length; i++) {
            final questionData = data[i];
            if (questionData is Map) {
              try {
                final question = AssessmentQuestion.fromMap(questionData);
                questions.add(question);
              } catch (e) {
              }
            }
          }
        } else if (data is Map) {
          // Questions are stored as a map (fallback)
          
          data.forEach((key, questionData) {
            if (questionData is Map) {
              try {
                final question = AssessmentQuestion.fromMap(questionData);
                questions.add(question);
              } catch (e) {
              }
            }
          });
        } else {
        }

        
        // Cache the questions for offline use
        if (questions.isNotEmpty) {
          await _cacheAssessmentQuestionsLocally(assessmentId, questions);
        }
        
        return questions;
      }
      
      return [];
    } catch (e) {
      // If Firebase fails, try to return cached data
      return await _getCachedAssessmentQuestions(assessmentId);
    }
  }

  // Get cached assessment questions
  Future<List<AssessmentQuestion>> _getCachedAssessmentQuestions(String assessmentId) async {
    try {
      final cachedQuestions = await OfflineService.getCachedAssessmentQuestions(assessmentId);
      return cachedQuestions.map((q) => AssessmentQuestion.fromMap(q as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  // Cache assessment questions locally
  Future<void> _cacheAssessmentQuestionsLocally(String assessmentId, List<AssessmentQuestion> questions) async {
    try {
      await OfflineService.cacheAssessmentQuestions(assessmentId, questions);
    } catch (e) {
    }
  }

  // Submit assessment answers with enhanced data
  Future<void> submitAssessment({
    required String assessmentId,
    required Map<int, String> answers,
    required int timeSpent,
    // Enhanced submission data
    Map<int, DetailedAnswer>? detailedAnswers,
    String? assessmentTitle,
    String? assessmentSubject,
    String? assessmentType,
    String? assessmentGradeLevel,
    int? totalQuestions,
    int? maxPossibleScore,
    double? accuracy,
    int? correctAnswers,
    int? incorrectAnswers,
    int? unansweredQuestions,
    DateTime? startedAt,
    double? averageTimePerQuestion,
    bool? isAutoGraded,
    bool isRetake = false,
  }) async {
    try {
      // Only allow submission when online
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot submit assessment while offline. Please connect to the internet.');
      }

      // Get current student ID (needed for submission)
      final currentStudentId = _getCurrentStudentId();

      // Check if student has already submitted this assessment (skip if retake)
      if (!isRetake) {
        final existingSubmissionsRef = _database
            .ref('assessment_submissions')
            .orderByChild('studentId')
            .equalTo(currentStudentId);
        
        final existingSubmissionsSnapshot = await existingSubmissionsRef.get();
        
        if (existingSubmissionsSnapshot.exists) {
          // Check if any existing submission is for this assessment
          for (var child in existingSubmissionsSnapshot.children) {
            final submissionData = child.value as Map<dynamic, dynamic>?;
            if (submissionData != null && submissionData['assessmentId'] == assessmentId) {
              throw Exception('You have already submitted this assessment. Duplicate submissions are not allowed.');
            }
          }
        }
      }
      

      // Get the assessment to include teacherId and other details
      final assessmentSnapshot = await _database
          .ref('assessments')
          .child(assessmentId)
          .get();
      
      if (!assessmentSnapshot.exists) {
        throw Exception('Assessment not found');
      }
      
      final assessmentData = assessmentSnapshot.value as Map<dynamic, dynamic>;
      final teacherId = assessmentData['teacherId']?.toString() ?? '';
      
      // Calculate score if not provided
      int finalScore = 0;
      if (detailedAnswers != null) {
        finalScore = detailedAnswers.values.fold(0, (sum, answer) => sum + (answer?.points ?? 0));
      }
      
      // Get current student profile from Firestore
      UserModel? studentProfile;
      try {
        studentProfile = await _authService.getUserProfile(currentStudentId);
        print('📝 ASSESSMENT DEBUG: Student profile loaded - displayName: ${studentProfile?.displayName}');
      } catch (e) {
        print('⚠️ ASSESSMENT DEBUG: Failed to load student profile: $e');
      }

      // Determine student name with logging
      String finalStudentName;
      if (studentProfile?.displayName?.isNotEmpty == true) {
        finalStudentName = studentProfile!.displayName;
        print('✅ ASSESSMENT DEBUG: Using profile displayName: $finalStudentName');
      } else if (FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true) {
        finalStudentName = FirebaseAuth.instance.currentUser!.displayName!;
        print('✅ ASSESSMENT DEBUG: Using Firebase displayName: $finalStudentName');
      } else if (FirebaseAuth.instance.currentUser?.email?.isNotEmpty == true) {
        finalStudentName = FirebaseAuth.instance.currentUser!.email!.split('@').first;
        print('✅ ASSESSMENT DEBUG: Using email prefix: $finalStudentName');
      } else {
        finalStudentName = 'Student';
        print('⚠️ ASSESSMENT DEBUG: Using default name: $finalStudentName');
      }

      print('📝 ASSESSMENT DEBUG: Final student name for submission: $finalStudentName');

      final submissionData = {
        'assessmentId': assessmentId,
        'studentId': currentStudentId,
        'teacherId': teacherId, // Include teacherId for security rules
        
        // Enhanced Student Information from Firestore
        'studentName': finalStudentName,
        'studentEmail': studentProfile?.email ?? '',
        'studentGrade': studentProfile?.grade ?? 'Grade 7',
        'studentSection': 'Section A', // Default section since UserModel doesn't have this field
        
        // Enhanced Assessment Context
        'assessmentTitle': assessmentTitle ?? assessmentData['title'] ?? 'Assessment',
        'assessmentSubject': assessmentSubject ?? assessmentData['subject'] ?? 'General',
        'assessmentType': assessmentType ?? 'Quiz',
        'assessmentGradeLevel': assessmentGradeLevel ?? 'Grade 7',
        'totalQuestions': totalQuestions ?? answers.length,
        'maxPossibleScore': maxPossibleScore ?? 100,
        
        // Enhanced Answer Analysis
        'detailedAnswers': detailedAnswers?.map((key, value) => MapEntry(key.toString(), value?.toMap() ?? {})),
        'answers': answers, // Keep for backward compatibility
        
        // Scoring and Performance
        'score': finalScore,
        'accuracy': accuracy ?? 0.0,
        'correctAnswers': correctAnswers ?? 0,
        'incorrectAnswers': incorrectAnswers ?? 0,
        'unansweredQuestions': unansweredQuestions ?? 0,
        
        // Timing and Context
        'submittedAt': ServerValue.timestamp,
        'startedAt': startedAt?.millisecondsSinceEpoch,
        'timeSpent': timeSpent,
        'averageTimePerQuestion': averageTimePerQuestion ?? 0.0,
        
        // Grading Information
        'isGraded': false,
        'isAutoGraded': isAutoGraded ?? true,
      };

      final ref = _database.ref('assessment_submissions').push();
      await ref.set(submissionData);
      
      // Update leaderboard with points earned (including participation points)
      int pointsToAdd = finalScore;
      if (pointsToAdd == 0 && answers.isNotEmpty) {
        // Give participation points for attempting assessment
        pointsToAdd = 1; // 1 point for attempting
      }
      
      if (pointsToAdd > 0) {
        try {
          await _achievementsService.updateLeaderboardWithPoints(
            currentStudentId,
            studentProfile?.displayName ?? 'Student',
            pointsToAdd,
          );
          
          // Check and award achievements
          final newAchievements = await _achievementsService.checkAndAwardAchievements(currentStudentId);
          if (newAchievements.isNotEmpty) {
            for (final achievement in newAchievements) {
            }
          }
        } catch (e) {
        }
      }
      
    } catch (e) {
      throw Exception('Failed to submit assessment: ${e.toString()}');
    }
  }

  // Get current student ID from Firebase Auth
  String _getCurrentStudentId() {
    try {
      // Get the current Firebase Auth user
      final currentUser = _authService.currentUser;
      if (currentUser != null && currentUser.uid.isNotEmpty) {
        return currentUser.uid; // This is the UNIQUE Firebase UID
      }
      
      // Last resort - this should never happen if user is authenticated
      return 'unknown_student_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'unknown_student_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Update submission grade
  Future<void> updateSubmissionGrade(String submissionId, int grade, String feedback) async {
    try {
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot update grade while offline. Please connect to the internet.');
      }

      // Update in Realtime Database
      await _database
          .ref('assessment_submissions')
          .child(submissionId)
          .update({
        'score': grade,
        'feedback': feedback,
        'isGraded': true,
        'gradedAt': ServerValue.timestamp,
      });

    } catch (e) {
      throw Exception('Failed to update grade: ${e.toString()}');
    }
  }

  // Get cached assessment by ID
  Future<Assessment?> _getCachedAssessmentById(String assessmentId) async {
    try {
      final cachedAssessments = await OfflineService.getCachedAssessments();
      final assessmentData = cachedAssessments.firstWhere(
        (data) => (data['id'] as String?) == assessmentId,
        orElse: () => {},
      );
      
      if (assessmentData.isNotEmpty) {
        return Assessment.fromRealtimeDatabase(assessmentId, assessmentData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Cache a single assessment locally
  Future<void> _cacheAssessmentLocally(Assessment assessment) async {
    try {
      final existingAssessments = await OfflineService.getCachedAssessments();
      
      // Update existing assessment or add new one
      bool found = false;
      for (int i = 0; i < existingAssessments.length; i++) {
        if (existingAssessments[i]['id'] == assessment.id) {
          existingAssessments[i] = {
            'id': assessment.id,
            ...assessment.toRealtimeDatabase(),
          };
          found = true;
          break;
        }
      }
      
      if (!found) {
        existingAssessments.add({
          'id': assessment.id,
          ...assessment.toRealtimeDatabase(),
        });
      }
      
      await OfflineService.cacheAssessments(existingAssessments);
    } catch (e) {
    }
  }

  // Cache assessment stats locally
  Future<void> _cacheAssessmentStats(String teacherId, Map<String, dynamic> stats) async {
    try {
      final cachedStats = await OfflineService.getCachedAssessmentStats(teacherId);
      if (cachedStats.isNotEmpty) {
        // Update existing stats
        cachedStats['totalAssessments'] = stats['totalAssessments'];
        cachedStats['publishedAssessments'] = stats['publishedAssessments'];
        cachedStats['draftAssessments'] = stats['draftAssessments'];
        cachedStats['subjectCounts'] = stats['subjectCounts'];
      } else {
        // Add new stats
        cachedStats['teacherId'] = teacherId;
        cachedStats['totalAssessments'] = stats['totalAssessments'];
        cachedStats['publishedAssessments'] = stats['publishedAssessments'];
        cachedStats['draftAssessments'] = stats['draftAssessments'];
        cachedStats['subjectCounts'] = stats['subjectCounts'];
      }
      await OfflineService.cacheAssessmentStats(teacherId, cachedStats);
    } catch (e) {
    }
  }

  // Get cached assessment stats
  Future<Map<String, dynamic>> _getCachedAssessmentStats(String teacherId) async {
    try {
      final cachedStats = await OfflineService.getCachedAssessmentStats(teacherId);
      return cachedStats;
    } catch (e) {
      return {};
    }
  }
}
