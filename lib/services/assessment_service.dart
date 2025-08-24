import 'package:firebase_database/firebase_database.dart';
import '../models/assessment.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';

class AssessmentService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

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
        return assessments;
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get all assessments: ${e.toString()}');
    }
  }

  // Get assessments by subject
  Future<List<Assessment>> getAssessmentsBySubject(String subject) async {
    try {
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
        return assessments;
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get assessments by subject: ${e.toString()}');
    }
  }

  // Get a specific assessment by ID
  Future<Assessment?> getAssessmentById(String assessmentId) async {
    try {
      final snapshot = await _database
          .ref('assessments')
          .child(assessmentId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return Assessment.fromRealtimeDatabase(assessmentId, data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get assessment: ${e.toString()}');
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
      final assessments = await getAssessmentsByTeacher(teacherId);
      
      int totalAssessments = assessments.length;
      int publishedAssessments = assessments.where((a) => a.isPublished).length;
      int draftAssessments = totalAssessments - publishedAssessments;
      
      // Count assessments by subject
      Map<String, int> subjectCounts = {};
      for (var assessment in assessments) {
        subjectCounts[assessment.subject] = (subjectCounts[assessment.subject] ?? 0) + 1;
      }
      
      return {
        'totalAssessments': totalAssessments,
        'publishedAssessments': publishedAssessments,
        'draftAssessments': draftAssessments,
        'subjectCounts': subjectCounts,
      };
    } catch (e) {
      throw Exception('Failed to get assessment stats: ${e.toString()}');
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

  // Submit assessment answers
  Future<void> submitAssessment({
    required String assessmentId,
    required Map<int, String> answers,
    required int timeSpent,
  }) async {
    try {
      // Only allow submission when online
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot submit assessment while offline. Please connect to the internet.');
      }

      // Get the assessment to include teacherId
      final assessmentSnapshot = await _database
          .ref('assessments')
          .child(assessmentId)
          .get();
      
      if (!assessmentSnapshot.exists) {
        throw Exception('Assessment not found');
      }
      
      final assessmentData = assessmentSnapshot.value as Map<dynamic, dynamic>;
      final teacherId = assessmentData['teacherId']?.toString() ?? '';
      
      final submissionData = {
        'assessmentId': assessmentId,
        'studentId': _getCurrentStudentId(),
        'teacherId': teacherId, // Include teacherId for security rules
        'answers': answers,
        'timeSpent': timeSpent,
        'submittedAt': ServerValue.timestamp,
        'score': 0, // Will be calculated by the system
      };

      final ref = _database.ref('assessment_submissions').push();
      await ref.set(submissionData);
    } catch (e) {
      throw Exception('Failed to submit assessment: ${e.toString()}');
    }
  }

  // Get current student ID from auth service
  String _getCurrentStudentId() {
    try {
      // Import and use the auth service to get current user ID
      // For now, we'll use a more descriptive placeholder
      // TODO: Replace with actual auth service call
      return 'student_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('❌ Error getting student ID: $e');
      return 'unknown_student';
    }
  }
}
