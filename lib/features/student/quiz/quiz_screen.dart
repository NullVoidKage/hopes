import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../data/models/assessment.dart';
import '../../../data/models/attempt.dart';
import '../../../data/models/progress.dart';
import '../../../data/models/user.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String assessmentId;

  const QuizScreen({super.key, required this.assessmentId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  Map<String, int> _answers = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final assessmentRepo = ref.watch(assessmentRepositoryProvider);
    final authState = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        automaticallyImplyLeading: false,
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user found'));
          }

          return FutureBuilder<Assessment?>(
            future: assessmentRepo.getAssessment(widget.assessmentId),
            builder: (context, assessmentSnapshot) {
              if (assessmentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (assessmentSnapshot.hasError) {
                return Center(child: Text('Error: ${assessmentSnapshot.error}'));
              }

              final assessment = assessmentSnapshot.data;
              if (assessment == null) {
                return const Center(child: Text('Assessment not found'));
              }

              if (assessment.items.isEmpty) {
                return const Center(child: Text('No questions available'));
              }

              final currentQuestion = assessment.items[_currentQuestionIndex];
              final isLastQuestion = _currentQuestionIndex == assessment.items.length - 1;

              return Column(
                children: [
                  // Progress Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${_currentQuestionIndex + 1} of ${assessment.items.length}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            Text(
                              '${((_currentQuestionIndex + 1) / assessment.items.length * 100).round()}%',
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: (_currentQuestionIndex + 1) / assessment.items.length,
                          backgroundColor: AppTheme.lightGray,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),

                  // Question Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question Text
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.quiz,
                                        color: AppTheme.primaryBlue,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Question ${_currentQuestionIndex + 1}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.neutralGray,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  currentQuestion.text,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Answer Choices
                          ...currentQuestion.choices.asMap().entries.map((entry) {
                            final index = entry.key;
                            final choice = entry.value;
                            final isSelected = _answers[currentQuestion.id] == index;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () => _selectAnswer(currentQuestion.id, index),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? Border.all(
                                            color: AppTheme.primaryBlue,
                                            width: 2,
                                          )
                                        : Border.all(
                                            color: AppTheme.lightGray,
                                            width: 1,
                                          ),
                                    color: isSelected
                                        ? AppTheme.primaryBlue.withOpacity(0.05)
                                        : Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryBlue
                                                : AppTheme.neutralGray,
                                            width: 2,
                                          ),
                                          color: isSelected
                                              ? AppTheme.primaryBlue
                                              : Colors.transparent,
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
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            color: isSelected
                                                ? AppTheme.primaryBlue
                                                : AppTheme.darkGray,
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (_currentQuestionIndex > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousQuestion,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: AppTheme.primaryBlue, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Previous',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _nextQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    isLastQuestion ? 'Submit Quiz' : 'Next',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _selectAnswer(String questionId, int choiceIndex) {
    setState(() {
      _answers[questionId] = choiceIndex;
    });
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _nextQuestion() async {
    final assessmentRepo = ref.read(assessmentRepositoryProvider);
    final authState = ref.read(currentUserProvider);
    final assessment = await assessmentRepo.getAssessment(widget.assessmentId);

    if (assessment == null) return;

    final isLastQuestion = _currentQuestionIndex == assessment.items.length - 1;

    if (isLastQuestion) {
      // Submit the quiz
      _submitQuiz();
    } else {
      // Move to next question
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _submitQuiz() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final assessmentRepo = ref.read(assessmentRepositoryProvider);
      final authState = ref.read(currentUserProvider);
      final user = authState.value;

      if (user == null) return;

      final assessment = await assessmentRepo.getAssessment(widget.assessmentId);
      if (assessment == null) return;

      // Create attempt
      final attempt = await assessmentRepo.createAttempt(
        assessmentId: widget.assessmentId,
        userId: user.id,
        answers: _answers,
      );

      // Update progress if this is a lesson quiz
      if (assessment.lessonId != null) {
        final progressRepo = ref.read(progressRepositoryProvider);
        final status = attempt.score >= 80 ? ProgressStatus.mastered : ProgressStatus.inProgress;
        
        await progressRepo.updateProgress(
          userId: user.id,
          lessonId: assessment.lessonId!,
          status: status,
          lastScore: attempt.score,
        );
      }

      if (mounted) {
        // Show result dialog
        _showResultDialog(attempt);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showResultDialog(Attempt attempt) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          attempt.score >= 80 ? 'Excellent!' : 'Good Job!',
          style: TextStyle(
            color: attempt.score >= 80 ? Colors.green : Colors.orange,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Score: ${attempt.score.round()}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              attempt.score >= 80
                  ? 'You have mastered this content!'
                  : 'Keep practicing to improve your score.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/student/dashboard');
            },
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }
} 