import 'package:firebase_database/firebase_database.dart';
import '../models/assessment.dart';
import '../models/assessment_submission.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';

class AssessmentService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ConnectivityService _connectivityService = ConnectivityService();
  final AuthService _authService = AuthService();

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
              print('Error parsing assessment: $e');
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
      print('Error getting assessments: $e');
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
      print('Error getting cached assessments: $e');
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
      print('Error caching assessments: $e');
    }
  }

  // Get all published assessments (for students)
  Future<List<Assessment>> getAllPublishedAssessments() async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        print('🔌 Offline mode, using cached assessments');
        return await _getCachedAllPublishedAssessments();
      }

      print('🌐 Online mode, fetching from Firebase');
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
              print('Error parsing assessment: $e');
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
      print('Firebase error, trying cached data: $e');
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
      print('Error getting cached assessments: $e');
      return [];
    }
  }

  // Get assessments by subject
  Future<List<Assessment>> getAssessmentsBySubject(String subject) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        print('🔌 Offline mode, using cached assessments for subject: $subject');
        return await _getCachedAssessmentsBySubject(subject);
      }

      print('🌐 Online mode, fetching from Firebase for subject: $subject');
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
              print('Error parsing assessment: $e');
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
      print('Firebase error, trying cached data: $e');
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
      print('Error getting cached assessments: $e');
      return [];
    }
  }

  // Get a specific assessment by ID
  Future<Assessment?> getAssessmentById(String assessmentId) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        print('🔌 Offline mode, using cached assessment: $assessmentId');
        return await _getCachedAssessmentById(assessmentId);
      }

      print('🌐 Online mode, fetching from Firebase: $assessmentId');
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
      print('Firebase error, trying cached data: $e');
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
        print('🔌 Offline mode, using cached assessment stats');
        return await _getCachedAssessmentStats(teacherId);
      }

      print('🌐 Online mode, calculating stats from Firebase');
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
      print('Firebase error, trying cached stats: $e');
      // If Firebase fails, try to return cached data
      return await _getCachedAssessmentStats(teacherId);
    }
  }

  // Get assessment questions for students
  Future<List<AssessmentQuestion>> getAssessmentQuestions(String assessmentId) async {
    try {
      // Check if we should use cached data
      if (!_connectivityService.isConnected) {
        print('🔌 Offline mode, using cached questions');
        return await _getCachedAssessmentQuestions(assessmentId);
      }

      print('🌐 Online mode, fetching from Firebase');
      // If online, fetch from Firebase and cache
      final snapshot = await _database
          .ref('assessments')
          .child(assessmentId)
          .child('questions')
          .get();

      if (snapshot.exists) {
        final questions = <AssessmentQuestion>[];
        final data = snapshot.value;
        
        print('📊 Raw question data from Firebase: $data');
        print('📊 Data type: ${data.runtimeType}');
        
        if (data is List) {
          // Questions are stored as an array
          print('📊 Found ${data.length} questions in Firebase array');
          
          for (int i = 0; i < data.length; i++) {
            final questionData = data[i];
            if (questionData is Map) {
              try {
                print('🔍 Parsing question $i: $questionData');
                final question = AssessmentQuestion.fromMap(questionData);
                questions.add(question);
                print('✅ Successfully parsed question: ${question.question}');
              } catch (e) {
                print('❌ Error parsing question $i: $e');
                print('❌ Question data: $questionData');
              }
            }
          }
        } else if (data is Map) {
          // Questions are stored as a map (fallback)
          print('📊 Found ${data.length} questions in Firebase map');
          
          data.forEach((key, questionData) {
            if (questionData is Map) {
              try {
                print('🔍 Parsing question $key: $questionData');
                final question = AssessmentQuestion.fromMap(questionData);
                questions.add(question);
                print('✅ Successfully parsed question: ${question.question}');
              } catch (e) {
                print('❌ Error parsing question $key: $e');
                print('❌ Question data: $questionData');
              }
            }
          });
        } else {
          print('⚠️ Unexpected data type for questions: ${data.runtimeType}');
        }

        print('📝 Total questions parsed: ${questions.length}');
        
        // Cache the questions for offline use
        if (questions.isNotEmpty) {
          await _cacheAssessmentQuestionsLocally(assessmentId, questions);
        }
        
        return questions;
      }
      
      print('⚠️ No questions found in Firebase');
      return [];
    } catch (e) {
      print('❌ Error getting assessment questions: $e');
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
      print('Error getting cached questions: $e');
      return [];
    }
  }

  // Cache assessment questions locally
  Future<void> _cacheAssessmentQuestionsLocally(String assessmentId, List<AssessmentQuestion> questions) async {
    try {
      await OfflineService.cacheAssessmentQuestions(assessmentId, questions);
    } catch (e) {
      print('Error caching assessment questions: $e');
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
  }) async {
    try {
      // Only allow submission when online
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot submit assessment while offline. Please connect to the internet.');
      }

      // Check if student has already submitted this assessment
      final currentStudentId = _getCurrentStudentId();
      print('🔍 Checking for duplicate submissions - Student ID: $currentStudentId, Assessment ID: $assessmentId');
      
      final existingSubmissionsRef = _database
          .ref('assessment_submissions')
          .orderByChild('studentId')
          .equalTo(currentStudentId);
      
      final existingSubmissionsSnapshot = await existingSubmissionsRef.get();
      print('📊 Found ${existingSubmissionsSnapshot.children.length} existing submissions for student');
      
      if (existingSubmissionsSnapshot.exists) {
        // Check if any existing submission is for this assessment
        for (var child in existingSubmissionsSnapshot.children) {
          final submissionData = child.value as Map<dynamic, dynamic>?;
          if (submissionData != null && submissionData['assessmentId'] == assessmentId) {
            print('❌ DUPLICATE SUBMISSION DETECTED! Student $currentStudentId already submitted assessment $assessmentId');
            throw Exception('You have already submitted this assessment. Duplicate submissions are not allowed.');
          }
        }
      }
      
      print('✅ No duplicate submissions found, proceeding with submission');

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
        print('👤 Fetched student profile: ${studentProfile?.displayName ?? 'Unknown'}');
      } catch (e) {
        print('⚠️ Could not fetch student profile: $e');
      }

      final submissionData = {
        'assessmentId': assessmentId,
        'studentId': currentStudentId,
        'teacherId': teacherId, // Include teacherId for security rules
        
        // Enhanced Student Information from Firestore
        'studentName': studentProfile?.displayName ?? 'Unknown Student',
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
      
      print('✅ Enhanced assessment submission created successfully');
      print('📊 Submission data: $submissionData');
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
        print('🔐 Using Firebase Auth UID: ${currentUser.uid}');
        return currentUser.uid; // This is the UNIQUE Firebase UID
      }
      
      // Last resort - this should never happen if user is authenticated
      print('⚠️ No valid user ID found, using fallback');
      return 'unknown_student_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('❌ Error getting student ID: $e');
      return 'unknown_student_${DateTime.now().millisecondsSinceEpoch}';
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
      print('Error getting cached assessment: $e');
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
      print('Error caching assessment locally: $e');
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
      print('Error caching assessment stats: $e');
    }
  }

  // Get cached assessment stats
  Future<Map<String, dynamic>> _getCachedAssessmentStats(String teacherId) async {
    try {
      final cachedStats = await OfflineService.getCachedAssessmentStats(teacherId);
      return cachedStats;
    } catch (e) {
      print('Error getting cached assessment stats: $e');
      return {};
    }
  }
}
