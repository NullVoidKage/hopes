import 'package:flutter/material.dart';
import '../models/assessment.dart';
import '../services/assessment_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_service.dart';

class StudentAssessmentTakerScreen extends StatefulWidget {
  final Assessment assessment;

  const StudentAssessmentTakerScreen({
    super.key,
    required this.assessment,
  });

  @override
  State<StudentAssessmentTakerScreen> createState() => _StudentAssessmentTakerScreenState();
}

class _StudentAssessmentTakerScreenState extends State<StudentAssessmentTakerScreen> {
  final AssessmentService _assessmentService = AssessmentService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineService _offlineService = OfflineService();
  
  List<AssessmentQuestion> _questions = [];
  Map<int, String> _answers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _currentQuestionIndex = 0;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _loadAssessment();
    _startTime = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Timer removed - no time limit for assessments
  }

  Future<void> _loadAssessment() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      // Check connectivity and load questions
      final isOnline = _connectivityService.isConnected;
      
      if (isOnline) {
        // Load from online service
        print('🌐 Loading questions from Firebase for assessment: ${widget.assessment.id}');
        final questions = await _assessmentService.getAssessmentQuestions(widget.assessment.id);
        print('📊 Loaded ${questions.length} questions from Firebase');
        if (questions.isNotEmpty) {
          print('🔍 First question: ${questions.first.question} (Type: ${questions.first.type})');
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
        print('🔌 Loading questions from offline cache for assessment: ${widget.assessment.id}');
        final cachedQuestions = await OfflineService.getCachedAssessmentQuestions(widget.assessment.id);
        print('📊 Loaded ${cachedQuestions.length} questions from cache');
        
        if (!mounted) return;
        setState(() {
          _questions = cachedQuestions.map((q) => AssessmentQuestion.fromMap(q as Map)).toList();
        });
        
        if (_questions.isNotEmpty) {
          print('🔍 First question from cache: ${_questions.first.question} (Type: ${_questions.first.type})');
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
        print('🌐 Submitting assessment online...');
        await _assessmentService.submitAssessment(
          assessmentId: widget.assessment.id,
          answers: _answers,
          timeSpent: DateTime.now().difference(_startTime).inSeconds,
        );
        print('✅ Assessment submitted successfully online');
      } else {
        // Queue for offline submission
        print('🔌 Queuing assessment for offline submission...');
        await OfflineService.queueAssessmentSubmission(
          assessmentId: widget.assessment.id,
          answers: _answers,
          timeSpent: DateTime.now().difference(_startTime).inSeconds,
        );
        print('✅ Assessment queued for offline submission');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOnline ? 'Assessment submitted successfully!' : 'Assessment saved for submission when online'),
            backgroundColor: const Color(0xFF34C759),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error submitting assessment: $e');
      
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
          // Timer removed - no time limit for assessments
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

  Widget _buildShortAnswerInput() {
    return TextFormField(
      maxLines: 3,
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
    );
  }

  Widget _buildEssayInput() {
    return TextFormField(
      maxLines: 8,
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
    );
  }

  Widget _buildFillInTheBlankInput() {
    return TextFormField(
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
    );
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
}
