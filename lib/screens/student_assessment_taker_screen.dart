import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/assessment.dart';
import '../models/assessment_submission.dart';
import '../services/assessment_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_service.dart';
import '../services/submission_service.dart';
import '../services/auth_service.dart';
import '../services/achievements_service.dart';
import '../widgets/badge_celebration.dart';
import 'assessment_result_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentAssessmentTakerScreen extends StatefulWidget {
  final Assessment assessment;
  final bool isRetake;

  const StudentAssessmentTakerScreen({
    super.key,
    required this.assessment,
    this.isRetake = false,
  });

  @override
  State<StudentAssessmentTakerScreen> createState() => _StudentAssessmentTakerScreenState();
}

class _StudentAssessmentTakerScreenState extends State<StudentAssessmentTakerScreen> {
  final AssessmentService _assessmentService = AssessmentService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final AuthService _authService = AuthService();
  final AchievementsService _achievementsService = AchievementsService();
  
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
  
  List<AssessmentQuestion> _questions = [];
  Map<int, String> _answers = {};
  Map<int, String?> _answerImages = {}; // Image URLs for answers
  Map<int, XFile?> _selectedImageFiles = {}; // Selected image files
  Map<int, TextEditingController> _textControllers = {}; // Controllers for text inputs
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _currentQuestionIndex = 0;
  late DateTime _startTime;
  Timer? _durationTimer;
  Duration _elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadAssessment();
    _startTime = DateTime.now();
    _startDurationTimer();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    // Dispose all text controllers
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    super.dispose();
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _loadAssessment() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      // Check if student has already submitted this assessment (skip if retake)
      if (!widget.isRetake) {
        final submissionService = SubmissionService();
        final currentStudentId = _getCurrentStudentId();
        
        try {
          final submissions = await submissionService.getStudentSubmissions(currentStudentId);
          final hasSubmitted = submissions.any((submission) => 
            submission.assessmentId == widget.assessment.id
          );
          
          if (hasSubmitted) {
            if (!mounted) return;
            // Show error and go back
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ You have already completed this assessment!'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pop(); // Go back to previous screen
            return;
          }
        } catch (e) {
          // Continue loading if we can't check status
        }
      }

      // Check connectivity and load questions
      final isOnline = _connectivityService.isConnected;
      
      if (isOnline) {
        // Load from online service
        final questions = await _assessmentService.getAssessmentQuestions(widget.assessment.id);
        
        // Debug: Check if questions have imageUrl
        for (var q in questions) {
          if (q.imageUrl != null && q.imageUrl!.isNotEmpty) {
            print('Question ${q.id} has imageUrl: ${q.imageUrl}');
          }
        }
        
        if (!mounted) return;
        setState(() {
          _questions = questions;
        });
        
        // Cache questions offline
        if (mounted) {
          await OfflineService.cacheAssessmentQuestions(widget.assessment.id, questions);
        }
      } else {
        // Load from offline cache
        final cachedQuestions = await OfflineService.getCachedAssessmentQuestions(widget.assessment.id);
        
        if (!mounted) return;
        setState(() {
          _questions = cachedQuestions.map((q) => AssessmentQuestion.fromMap(q as Map)).toList();
        });
        
        if (_questions.isNotEmpty) {
        }
      }
    } catch (e) {
      if (!mounted) return;
      // Show error and try to load from cache
      final cachedQuestions = await OfflineService.getCachedAssessmentQuestions(widget.assessment.id);
      if (!mounted) return;
      setState(() {
        _questions = cachedQuestions.map((q) => AssessmentQuestion.fromMap(q as Map)).toList();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Timer functionality removed - no time limit for assessments

  void _selectAnswer(int questionIndex, String answer) {
    if (mounted) {
      setState(() {
        _answers[questionIndex] = answer;
        // Update controller text if it exists and is different
        if (_textControllers.containsKey(questionIndex)) {
          final controller = _textControllers[questionIndex]!;
          if (controller.text != answer) {
            // Remove listener temporarily to avoid infinite loop
            controller.removeListener(() {});
            controller.text = answer;
            // Re-add listener
            controller.addListener(() {
              _selectAnswer(questionIndex, controller.text);
            });
          }
        }
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1 && mounted) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0 && mounted) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _goToQuestion(int index) {
    if (mounted) {
      setState(() {
        _currentQuestionIndex = index;
      });
    }
  }

  bool _isAssessmentDue() {
    if (widget.assessment.dueDate == null) return false;
    return DateTime.now().isAfter(widget.assessment.dueDate!);
  }

  Future<void> _submitAssessment() async {
    // Always show confirmation dialog before submitting
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Assessment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to submit your assessment?',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF007AFF).withOpacity(0.3),
                ),
              ),
              child: Text(
                'Progress: ${_answers.length}/${_questions.length} questions answered',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_answers.length < _questions.length) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF9500).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFFF9500),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have ${_questions.length - _answers.length} unanswered question${_questions.length - _answers.length == 1 ? '' : 's'}.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFF9500),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Once submitted, you cannot change your answers.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF86868B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF86868B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Assessment'),
          ),
        ],
      ),
    );
    
    if (shouldSubmit != true) return;

    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      final isOnline = _connectivityService.isConnected;
      
      if (isOnline) {
        // Submit online
        // Calculate score and create detailed answers
        int totalScore = 0;
        int correctAnswers = 0;
        int incorrectAnswers = 0;
        Map<int, DetailedAnswer> detailedAnswers = {};

        for (int i = 0; i < _questions.length; i++) {
          final question = _questions[i];
          final answer = _answers[i];
          
          if (answer != null && answer.isNotEmpty) {
            // Enhanced scoring logic with detailed analysis
            bool isCorrect = false;
            int points = 0;
            String correctAnswer = '';
            
            switch (question.type) {
              case QuestionType.trueFalse:
                correctAnswer = question.correctAnswer ?? 'True';
                isCorrect = answer.toLowerCase() == correctAnswer.toLowerCase();
                // Use optionPoints if available, otherwise default to 10 for correct, 2 for incorrect
                if (question.optionPoints.isNotEmpty) {
                  final answerKey = answer.toLowerCase();
                  points = question.optionPoints[answerKey] ?? 
                           question.optionPoints[answer] ?? 
                           (isCorrect ? (question.points > 0 ? question.points : 10) : 2);
                } else {
                  // Ensure points are always > 0 for correct answers
                  points = isCorrect ? (question.points > 0 ? question.points : 10) : 2; // Give 2 points for attempting
                }
                break;
              case QuestionType.multipleChoice:
                correctAnswer = question.correctAnswer ?? 'A';
                // Normalize both answers for comparison (trim whitespace and case-insensitive)
                final normalizedAnswer = answer.trim();
                final normalizedCorrectAnswer = correctAnswer.trim();
                isCorrect = normalizedAnswer.toLowerCase() == normalizedCorrectAnswer.toLowerCase();
                // Use optionPoints if available, otherwise default to points for correct, 2 for incorrect
                if (question.optionPoints.isNotEmpty) {
                  points = question.optionPoints[answer] ?? 
                           (isCorrect ? (question.points > 0 ? question.points : 10) : 2);
                } else {
                  // Ensure points are always > 0 for correct answers
                  points = isCorrect ? (question.points > 0 ? question.points : 10) : 2; // Give 2 points for attempting
                }
                break;
              case QuestionType.shortAnswer:
              case QuestionType.fillInTheBlank:
                // For subjective questions, no automatic points - teacher will review
                points = 0; // No automatic points - teacher will assign manually
                isCorrect = false; // Mark as needing review
                correctAnswer = 'Teacher Review Required';
                break;
              case QuestionType.essay:
                // Essay questions are EXCLUDED from auto-grading and require manual teacher review
                points = 0; // No automatic points - teacher will assign manually
                isCorrect = false; // Mark as needing review
                correctAnswer = 'Essay - Manual Grading Required';
                break;
            }
            
            totalScore += points;
            if (isCorrect) correctAnswers++;
            else if (points == 0 && (question.type == QuestionType.essay || question.type == QuestionType.shortAnswer || question.type == QuestionType.fillInTheBlank)) {
              // Don't count as incorrect if it needs teacher review
            } else {
              incorrectAnswers++;
            }

            // Create detailed answer
            detailedAnswers[i] = DetailedAnswer(
              answer: answer,
              correctAnswer: correctAnswer,
              isCorrect: isCorrect,
              points: points,
              questionType: _getQuestionTypeDisplayName(question.type),
              timeSpent: DateTime.now().difference(_startTime).inSeconds ~/ _questions.length, // Approximate time per question
              explanation: question.explanation,
            );
          }
        }

        // Calculate accuracy
        double accuracy = _questions.length > 0 ? (correctAnswers / _questions.length) * 100 : 0.0;
        double averageTimePerQuestion = _questions.length > 0 ? DateTime.now().difference(_startTime).inSeconds / _questions.length : 0.0;

        await _assessmentService.submitAssessment(
          assessmentId: widget.assessment.id,
          answers: _answers,
          timeSpent: DateTime.now().difference(_startTime).inSeconds,
          // Enhanced submission data
          detailedAnswers: detailedAnswers,
          assessmentTitle: widget.assessment.title,
          assessmentSubject: widget.assessment.subject,
          assessmentType: 'Quiz', // TODO: Get from assessment
          assessmentGradeLevel: 'Grade 7', // TODO: Get from assessment
          totalQuestions: _questions.length,
          maxPossibleScore: _questions.fold<int>(0, (sum, q) => sum + q.points), // Sum of all question points
          accuracy: accuracy,
          correctAnswers: correctAnswers,
          incorrectAnswers: incorrectAnswers,
          unansweredQuestions: _questions.length - _answers.length,
          startedAt: _startTime,
          averageTimePerQuestion: averageTimePerQuestion,
          isAutoGraded: true,
          isRetake: widget.isRetake,
        );
      } else {
        // Queue for offline submission with enhanced data
        
        // Calculate score and create detailed answers for offline submission
        int totalScore = 0;
        int correctAnswers = 0;
        int incorrectAnswers = 0;
        Map<int, DetailedAnswer> detailedAnswers = {};

        for (int i = 0; i < _questions.length; i++) {
          final question = _questions[i];
          final answer = _answers[i];
          
          if (answer != null && answer.isNotEmpty) {
            // Enhanced scoring logic with detailed analysis
            bool isCorrect = false;
            int points = 0;
            String correctAnswer = '';
            
            switch (question.type) {
              case QuestionType.trueFalse:
                correctAnswer = question.correctAnswer ?? 'True';
                isCorrect = answer.toLowerCase() == correctAnswer.toLowerCase();
                // Use optionPoints if available, otherwise default to 10 for correct, 2 for incorrect
                if (question.optionPoints.isNotEmpty) {
                  final answerKey = answer.toLowerCase();
                  points = question.optionPoints[answerKey] ?? 
                           question.optionPoints[answer] ?? 
                           (isCorrect ? (question.points > 0 ? question.points : 10) : 2);
                } else {
                  // Ensure points are always > 0 for correct answers
                  points = isCorrect ? (question.points > 0 ? question.points : 10) : 2; // Give 2 points for attempting
                }
                break;
              case QuestionType.multipleChoice:
                correctAnswer = question.correctAnswer ?? 'A';
                // Normalize both answers for comparison (trim whitespace and case-insensitive)
                final normalizedAnswer = answer.trim();
                final normalizedCorrectAnswer = correctAnswer.trim();
                isCorrect = normalizedAnswer.toLowerCase() == normalizedCorrectAnswer.toLowerCase();
                // Use optionPoints if available, otherwise default to points for correct, 2 for incorrect
                if (question.optionPoints.isNotEmpty) {
                  points = question.optionPoints[answer] ?? 
                           (isCorrect ? (question.points > 0 ? question.points : 10) : 2);
                } else {
                  // Ensure points are always > 0 for correct answers
                  points = isCorrect ? (question.points > 0 ? question.points : 10) : 2; // Give 2 points for attempting
                }
                break;
              case QuestionType.shortAnswer:
              case QuestionType.fillInTheBlank:
                // For subjective questions, no automatic points - teacher will review
                points = 0; // No automatic points - teacher will assign manually
                isCorrect = false; // Mark as needing review
                correctAnswer = 'Teacher Review Required';
                break;
              case QuestionType.essay:
                // Essay questions are EXCLUDED from auto-grading and require manual teacher review
                points = 0; // No automatic points - teacher will assign manually
                isCorrect = false; // Mark as needing review
                correctAnswer = 'Essay - Manual Grading Required';
                break;
            }
            
            totalScore += points;
            if (isCorrect) correctAnswers++;
            else if (points == 0 && (question.type == QuestionType.essay || question.type == QuestionType.shortAnswer || question.type == QuestionType.fillInTheBlank)) {
              // Don't count as incorrect if it needs teacher review
            } else {
              incorrectAnswers++;
            }

            // Create detailed answer with image URL if available
            detailedAnswers[i] = DetailedAnswer(
              answer: answer,
              correctAnswer: correctAnswer,
              isCorrect: isCorrect,
              points: points,
              questionType: _getQuestionTypeDisplayName(question.type),
              timeSpent: DateTime.now().difference(_startTime).inSeconds ~/ _questions.length,
              explanation: question.explanation,
              imageUrl: _answerImages[i],
            );
          }
        }

        // Calculate accuracy
        double accuracy = _questions.length > 0 ? (correctAnswers / _questions.length) * 100 : 0.0;
        double averageTimePerQuestion = _questions.length > 0 ? DateTime.now().difference(_startTime).inSeconds / _questions.length : 0.0;

        await OfflineService.queueAssessmentSubmission(
          assessmentId: widget.assessment.id,
          answers: _answers,
          timeSpent: DateTime.now().difference(_startTime).inSeconds,
          // Enhanced submission data
          detailedAnswers: detailedAnswers,
          assessmentTitle: widget.assessment.title,
          assessmentSubject: widget.assessment.subject,
          assessmentType: 'Quiz', // TODO: Get from assessment
          assessmentGradeLevel: 'Grade 7', // TODO: Get from assessment
          totalQuestions: _questions.length,
          maxPossibleScore: _questions.fold<int>(0, (sum, q) => sum + q.points), // Sum of all question points
          accuracy: accuracy,
          correctAnswers: correctAnswers,
          incorrectAnswers: incorrectAnswers,
          unansweredQuestions: _questions.length - _answers.length,
          startedAt: _startTime,
          averageTimePerQuestion: averageTimePerQuestion,
          isAutoGraded: true,
        );
      }

      if (mounted) {
        // Get the submitted submission to show results
        final submissionService = SubmissionService();
        final currentStudentId = _getCurrentStudentId();
        
        try {
          // Get the latest submission
          final submissions = await submissionService.getStudentSubmissions(currentStudentId);
          final latestSubmission = submissions.firstWhere(
            (s) => s.assessmentId == widget.assessment.id,
            orElse: () => submissions.isNotEmpty ? submissions.first : throw Exception('Submission not found'),
          );
          
          // Navigate to result page
          _durationTimer?.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AssessmentResultScreen(submission: latestSubmission),
            ),
          );
        } catch (e) {
          // If we can't get submission, just pop and show success
          _durationTimer?.cancel();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isOnline ? 'Assessment submitted successfully!' : 'Assessment saved for submission when online'),
              backgroundColor: const Color(0xFF34C759),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        // Check for new achievements and show celebration
        await _checkAndShowCelebration();
      }
    } catch (e) {
      
      if (mounted) {
        // Show more specific error messages
        String errorMessage = 'Error submitting assessment';
        if (e.toString().contains('permission') || e.toString().contains('Permission denied')) {
          errorMessage = 'Permission denied. Please contact your teacher or administrator.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        } else {
          errorMessage = 'Error submitting assessment: ${e.toString().split(':').last.trim()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFFF3B30),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                // Retry submission
                _submitAssessment();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Time formatting removed - no timer functionality

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Assessment...',
                style: TextStyle(
                  fontSize: 18,
                  color: const Color(0xFF86868B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1D1D1F),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.assessment.title,
              style: const TextStyle(
                color: Color(0xFF1D1D1F),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_questions.isNotEmpty)
              Text(
                '${_questions.length} Question${_questions.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Color(0xFF86868B),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        centerTitle: true,
        bottom: _isAssessmentDue() ? PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: const Color(0xFFFF3B30),
            child: const Text(
              '⚠️ Assessment is overdue!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ) : null,
        actions: [
          // Duration display at top right
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF007AFF).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Color(0xFF007AFF),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_elapsedTime),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          if (_questions.isNotEmpty)
            Container(
              width: double.infinity,
              height: 4,
              color: const Color(0xFFE5E5E7),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_currentQuestionIndex + 1) / _questions.length,
                child: Container(
                  color: const Color(0xFF007AFF),
                ),
              ),
            ),
          
          // Assessment Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE5E5E7),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assessment details
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF007AFF).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${widget.assessment.totalPoints} Points',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF34C759).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        widget.assessment.subject,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF34C759),
                        ),
                      ),
                    ),
                    if (widget.assessment.tags.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9500).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFF9500).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.assessment.tags.first,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF9500),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                
                // Question Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    Text(
                      '${_questions.isEmpty ? 0 : ((_currentQuestionIndex + 1) / _questions.length * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ],
                ),
                if (_questions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_questions.length, (index) {
                        final isAnswered = _answers.containsKey(index);
                        final isCurrent = index == _currentQuestionIndex;
                        
                        return GestureDetector(
                          onTap: () => _goToQuestion(index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCurrent 
                                  ? const Color(0xFF007AFF)
                                  : isAnswered 
                                      ? const Color(0xFF34C759)
                                      : const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCurrent 
                                    ? const Color(0xFF007AFF)
                                    : const Color(0xFFE5E5E7),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent || isAnswered 
                                      ? Colors.white 
                                      : const Color(0xFF86868B),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Question Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.quiz_rounded,
                                size: 20,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Question ${_currentQuestionIndex + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF86868B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_questions.isNotEmpty && _currentQuestionIndex < _questions.length) ...[
                          // Question Type Badge
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getQuestionTypeColor(_questions[_currentQuestionIndex].type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getQuestionTypeColor(_questions[_currentQuestionIndex].type).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _getQuestionTypeDisplayName(_questions[_currentQuestionIndex].type),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getQuestionTypeColor(_questions[_currentQuestionIndex].type),
                              ),
                            ),
                          ),
                          // Question Text
                          Text(
                            _questions[_currentQuestionIndex].question,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D1D1F),
                              height: 1.6,
                            ),
                          ),
                          // Question Image (if available)
                          if (_questions[_currentQuestionIndex].imageUrl != null &&
                              _questions[_currentQuestionIndex].imageUrl!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _questions[_currentQuestionIndex].imageUrl!,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                headers: kIsWeb ? {
                                  'Access-Control-Allow-Origin': '*',
                                } : null,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.broken_image, color: Color(0xFF86868B), size: 48),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Failed to load image',
                                          style: TextStyle(color: Color(0xFF86868B)),
                                        ),
                                        const SizedBox(height: 8),
                                        if (kIsWeb)
                                          TextButton.icon(
                                            onPressed: () async {
                                              // Open image in new tab
                                              final url = _questions[_currentQuestionIndex].imageUrl!;
                                              final uri = Uri.parse(url);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                              }
                                            },
                                            icon: const Icon(Icons.open_in_new, size: 16),
                                            label: const Text('Open in new tab'),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          // Question Points
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9500).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_questions[_currentQuestionIndex].points} points',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF9500),
                              ),
                            ),
                          ),
                        ] else
                          const Text(
                            'No questions available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF86868B),
                              height: 1.6,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Answer Options
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34C759).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: Color(0xFF34C759),
                              ),
                            ),
                            const SizedBox(width: 12),
                                                    Text(
                          _getAnswerSectionTitle(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF86868B),
                            letterSpacing: 0.5,
                          ),
                        ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_questions.isNotEmpty && _currentQuestionIndex < _questions.length)
                          _buildAnswerInput()
                        else
                          const Text(
                            'No answer options available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF86868B),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Navigation Buttons
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Color(0xFFE5E5E7),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_questions.isNotEmpty && _currentQuestionIndex > 0) ? _previousQuestion : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF007AFF),
                      side: const BorderSide(color: Color(0xFF007AFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Previous',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _questions.isEmpty 
                      ? ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF86868B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'No Questions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : _currentQuestionIndex < _questions.length - 1
                          ? ElevatedButton(
                              onPressed: _nextQuestion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007AFF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitAssessment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF34C759),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Submit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }

  String _getAnswerSectionTitle() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return 'Answer';
    }
    
    final questionType = _questions[_currentQuestionIndex].type;
    switch (questionType) {
      case QuestionType.multipleChoice:
        return 'Select Answer';
      case QuestionType.trueFalse:
        return 'Select True or False';
      case QuestionType.shortAnswer:
        return 'Enter Your Answer';
      case QuestionType.essay:
        return 'Write Your Essay';
      case QuestionType.fillInTheBlank:
        return 'Fill in the Blank';
      default:
        return 'Answer';
    }
  }

  Widget _buildAnswerInput() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return const Text(
        'No question available',
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF86868B),
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    final questionType = _questions[_currentQuestionIndex].type;
    
    switch (questionType) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceInput();
      case QuestionType.trueFalse:
        return _buildTrueFalseInput();
      case QuestionType.shortAnswer:
        return _buildShortAnswerInput();
      case QuestionType.essay:
        return _buildEssayInput();
      case QuestionType.fillInTheBlank:
        return _buildFillInTheBlankInput();
      default:
        return _buildMultipleChoiceInput();
    }
  }

  Widget _buildMultipleChoiceInput() {
    final options = _questions[_currentQuestionIndex].options;
    if (options.isEmpty) {
      return const Text(
        'No options available for this question',
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF86868B),
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    return Column(
      children: List.generate(
        options.length,
        (index) => _buildAnswerOption(
          options[index],
          index,
        ),
      ),
    );
  }

  Widget _buildTrueFalseInput() {
    // For True/False questions, always show True and False options
    // regardless of what's stored in the options field
    return Column(
      children: [
        _buildAnswerOption('True', 0),
        _buildAnswerOption('False', 1),
      ],
    );
  }

  TextEditingController _getTextController(int questionIndex) {
    if (!_textControllers.containsKey(questionIndex)) {
      _textControllers[questionIndex] = TextEditingController(
        text: _answers[questionIndex] ?? '',
      );
      // Update controller when answer changes externally
      _textControllers[questionIndex]!.addListener(() {
        _selectAnswer(questionIndex, _textControllers[questionIndex]!.text);
      });
    }
    return _textControllers[questionIndex]!;
  }

  Widget _buildShortAnswerInput() {
    return Column(
      children: [
        TextFormField(
          maxLines: 3,
          controller: _getTextController(_currentQuestionIndex),
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) => _selectAnswer(_currentQuestionIndex, value),
        ),
        const SizedBox(height: 12),
        _buildImageUploadSection(),
      ],
    );
  }

  Widget _buildEssayInput() {
    return Column(
      children: [
        TextFormField(
          maxLines: 8,
          controller: _getTextController(_currentQuestionIndex),
          decoration: InputDecoration(
            hintText: 'Write your essay here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) => _selectAnswer(_currentQuestionIndex, value),
        ),
        const SizedBox(height: 12),
        _buildImageUploadSection(),
      ],
    );
  }

  Widget _buildFillInTheBlankInput() {
    return Column(
      children: [
        TextFormField(
          controller: _getTextController(_currentQuestionIndex),
          decoration: InputDecoration(
            hintText: 'Fill in the blank...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) => _selectAnswer(_currentQuestionIndex, value),
        ),
        const SizedBox(height: 12),
        _buildImageUploadSection(),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    final hasImage = _answerImages[_currentQuestionIndex] != null;
    final selectedFile = _selectedImageFiles[_currentQuestionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image, size: 20),
                label: const Text('Upload Image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF007AFF),
                  side: const BorderSide(color: Color(0xFF007AFF)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (hasImage || selectedFile != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete, color: Color(0xFFFF3B30)),
                tooltip: 'Remove image',
              ),
            ],
          ],
        ),
        if (hasImage && _answerImages[_currentQuestionIndex] != null) ...[
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5E7)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.network(_answerImages[_currentQuestionIndex]!)
                  : Image.network(_answerImages[_currentQuestionIndex]!)
            ),
          ),
        ] else if (selectedFile != null) ...[
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5E7)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<Uint8List>(
                future: selectedFile.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                    return Image.memory(snapshot.data!);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      XFile? image;
      
      if (kIsWeb) {
        // Use file_picker for web
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          if (file.bytes != null) {
            // Convert PlatformFile to XFile for web
            image = XFile.fromData(
              file.bytes!,
              name: file.name,
              mimeType: file.extension != null ? 'image/${file.extension}' : 'image/jpeg',
            );
          }
        }
      } else {
        // Use image_picker for mobile
        final ImagePicker picker = ImagePicker();
        image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
      }

      if (image != null && mounted) {
        setState(() {
          _selectedImageFiles[_currentQuestionIndex] = image;
        });
        // Upload image immediately
        await _uploadAnswerImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  Future<void> _uploadAnswerImage(XFile imageFile) async {
    try {
      final storage = FirebaseStorage.instance;
      final studentId = _getCurrentStudentId();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final ref = storage.ref().child('assessment_answers/$studentId/$fileName');

      // Read image data - works on all platforms
      final Uint8List imageData = await imageFile.readAsBytes();

      final uploadTask = ref.putData(imageData);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _answerImages[_currentQuestionIndex] = downloadUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFiles.remove(_currentQuestionIndex);
      _answerImages.remove(_currentQuestionIndex);
    });
  }

  Widget _buildAnswerOption(String option, int index) {
    final isSelected = _answers[_currentQuestionIndex] == option;
    final optionLetter = String.fromCharCode(65 + index); // A, B, C, D...
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _selectAnswer(_currentQuestionIndex, option),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF007AFF).withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF007AFF)
                  : const Color(0xFFE5E5E7),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF007AFF)
                      : const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF007AFF)
                        : const Color(0xFFE5E5E7),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    optionLetter,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? Colors.white 
                          : const Color(0xFF86868B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected 
                        ? const Color(0xFF007AFF)
                        : const Color(0xFF1D1D1F),
                    fontWeight: isSelected 
                        ? FontWeight.w600 
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF007AFF),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for question type styling
  Color _getQuestionTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return const Color(0xFF007AFF); // Blue
      case QuestionType.trueFalse:
        return const Color(0xFF34C759); // Green
      case QuestionType.shortAnswer:
        return const Color(0xFFFF9500); // Orange
      case QuestionType.essay:
        return const Color(0xFFAF52DE); // Purple
      case QuestionType.fillInTheBlank:
        return const Color(0xFFFF3B30); // Red
      default:
        return const Color(0xFF86868B); // Grey
    }
  }

  String _getQuestionTypeDisplayName(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True or False';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.essay:
        return 'Essay';
      case QuestionType.fillInTheBlank:
        return 'Fill in the Blank';
      default:
        return 'Question';
    }
  }

  Future<void> _checkAndShowCelebration() async {
    try {
      final studentId = _getCurrentStudentId();
      
      // Check for new achievements
      final newAchievements = await _achievementsService.checkAndAwardAchievements(studentId);
      
      // Show celebration for the first new achievement
      if (newAchievements.isNotEmpty && mounted) {
        final latestAchievement = newAchievements.first;
        
        // Get achievement details
        final allAchievements = await _achievementsService.getAllAchievements();
        final achievement = allAchievements.firstWhere(
          (a) => a.id == latestAchievement.achievementId,
          orElse: () => allAchievements.first,
        );
        
        // Show celebration dialog
        _showBadgeCelebration(achievement);
      }
    } catch (e) {
    }
  }

  void _showBadgeCelebration(achievement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BadgeCelebration(
        badgeTitle: achievement.title,
        badgeDescription: achievement.description,
        points: achievement.points,
        iconName: achievement.iconName,
        colorHex: achievement.colorHex,
        onAnimationComplete: () => Navigator.of(context).pop(),
      ),
    );
  }
}
