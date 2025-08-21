import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../data/db/database.dart';
import '../../../data/models/assessment.dart';
import '../../../data/models/attempt.dart';
import '../../../data/models/progress.dart';
import '../../../data/models/user.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String assessmentId;

  const QuizScreen({
    super.key,
    required this.assessmentId,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _isLoading = true;
  Assessment? _assessment;
  User? _currentUser;
  int _currentQuestionIndex = 0;
  List<int> _userAnswers = [];
  bool _quizCompleted = false;
  int _score = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAssessment();
  }

  Future<void> _loadAssessment() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final database = ref.read(databaseProvider);
      final userState = ref.read(currentUserProvider);

      if (userState.value == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      _currentUser = userState.value;

      // Load assessment data
      // We need to search through all modules to find the assessment
      final subjects = await database.getSubjects();
      Assessment? foundAssessment;
      
      for (final subject in subjects) {
        final modules = await database.getModules(subject.id);
        for (final module in modules) {
          final assessments = await database.getAssessments(module.id);
          final assessment = assessments.where((a) => a.id == widget.assessmentId).firstOrNull;
          if (assessment != null) {
            foundAssessment = assessment;
            break;
          }
        }
        if (foundAssessment != null) break;
      }

      if (foundAssessment == null) {
        setState(() {
          _errorMessage = 'Assessment not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _assessment = foundAssessment;
        _userAnswers = List.filled(foundAssessment!.items.length, -1);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading assessment: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: Text(
          _assessment?.id ?? 'Quiz',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : _quizCompleted
                  ? _buildResultsWidget()
                  : _buildQuizWidget(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.accentRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutralGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAssessment,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizWidget() {
    if (_assessment == null) {
      return const Center(child: Text('Assessment not found'));
    }

    final currentQuestion = _assessment!.items[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _assessment!.items.length,
            backgroundColor: AppTheme.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
          const SizedBox(height: 16),
          
          // Question Counter
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_assessment!.items.length}',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutralGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Question
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentQuestion.text,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGray,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Answer Choices
                  ...currentQuestion.choices.asMap().entries.map((entry) {
                    final index = entry.key;
                    final choice = entry.value;
                    final isSelected = _userAnswers[_currentQuestionIndex] == index;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _userAnswers[_currentQuestionIndex] = index;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.lightGray,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppTheme.primaryBlue : AppTheme.lightGray,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  choice,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.darkGray,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousQuestion,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _userAnswers[_currentQuestionIndex] != -1
                      ? (_currentQuestionIndex < _assessment!.items.length - 1
                          ? _nextQuestion
                          : _completeQuiz)
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _currentQuestionIndex < _assessment!.items.length - 1 ? 'Next' : 'Finish',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsWidget() {
    final percentage = (_score / _assessment!.items.length * 100).round();
    final isPassing = percentage >= 70;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isPassing ? AppTheme.accentGreen : AppTheme.accentRed,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPassing ? Icons.check : Icons.close,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            isPassing ? 'Congratulations!' : 'Keep Trying!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'You scored $_score out of ${_assessment!.items.length}',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.neutralGray,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            '($percentage%)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isPassing ? AppTheme.accentGreen : AppTheme.accentRed,
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveResults,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Results'),
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/student/dashboard'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _assessment!.items.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _completeQuiz() {
    // Calculate score
    int correctAnswers = 0;
    for (int i = 0; i < _assessment!.items.length; i++) {
      if (_userAnswers[i] == _assessment!.items[i].correctIndex) {
        correctAnswers++;
      }
    }

    setState(() {
      _score = correctAnswers;
      _quizCompleted = true;
    });
  }

  Future<void> _saveResults() async {
    if (_currentUser == null || _assessment == null) return;

    try {
      final database = ref.read(databaseProvider);
      
      // Save attempt
      final attempt = Attempt(
        id: '${_currentUser!.id}_${_assessment!.id}_${DateTime.now().millisecondsSinceEpoch}',
        assessmentId: _assessment!.id,
        userId: _currentUser!.id,
        score: _score.toDouble() / _assessment!.items.length,
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)), // Approximate start time
        finishedAt: DateTime.now(),
        answersJson: Map.fromEntries(
          _assessment!.items.asMap().entries.map((entry) => 
            MapEntry(entry.value.id, _userAnswers[entry.key])
          ),
        ),
      );
      
      await database.saveAttempt(attempt);

      // Update progress
      final progress = Progress(
        userId: _currentUser!.id,
        lessonId: _assessment!.lessonId ?? '',
        status: _score >= (_assessment!.items.length * 0.7).round() 
            ? ProgressStatus.mastered 
            : ProgressStatus.inProgress,
        lastScore: _score.toDouble() / _assessment!.items.length,
        attemptCount: 1,
        updatedAt: DateTime.now(),
      );
      
      await database.saveProgress(progress);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Results saved successfully!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving results: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }
} 