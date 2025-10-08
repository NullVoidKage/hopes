import 'package:flutter/material.dart';
import '../models/assessment_submission.dart';
import '../models/assessment.dart';
import '../services/assessment_service.dart';

class AssessmentGradingScreen extends StatefulWidget {
  final AssessmentSubmission submission;
  final Assessment assessment;

  const AssessmentGradingScreen({
    Key? key,
    required this.submission,
    required this.assessment,
  }) : super(key: key);

  @override
  State<AssessmentGradingScreen> createState() => _AssessmentGradingScreenState();
}

class _AssessmentGradingScreenState extends State<AssessmentGradingScreen> {
  final AssessmentService _assessmentService = AssessmentService();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  bool _isGrading = false;

  @override
  void initState() {
    super.initState();
    _gradeController.text = widget.submission.score.toString();
    _feedbackController.text = widget.submission.feedback ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Assessment'),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isGrading ? null : _submitGrade,
            child: Text(
              'Submit Grade',
              style: TextStyle(
                color: _isGrading ? Colors.white54 : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Information',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Name', widget.submission.studentName),
                        ),
                        Expanded(
                          child: _buildInfoItem('Email', widget.submission.studentEmail),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Grade', widget.submission.studentGrade),
                        ),
                        Expanded(
                          child: _buildInfoItem('Section', widget.submission.studentSection),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Assessment Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment Information',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem('Title', widget.assessment.title),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Subject', widget.assessment.subject),
                        ),
                        Expanded(
                          child: _buildInfoItem('Questions', '${widget.assessment.questions.length}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Time Spent', '${widget.submission.timeSpent} seconds'),
                        ),
                        Expanded(
                          child: _buildInfoItem('Submitted', _formatDate(widget.submission.submittedAt)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current Score Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Score',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreItem(
                            'Score',
                            '${widget.submission.score}/${widget.submission.maxPossibleScore}',
                            _getScoreColor(widget.submission.score / widget.submission.maxPossibleScore),
                          ),
                        ),
                        Expanded(
                          child: _buildScoreItem(
                            'Accuracy',
                            '${widget.submission.accuracy.toStringAsFixed(1)}%',
                            _getScoreColor(widget.submission.accuracy / 100),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreItem(
                            'Correct',
                            '${widget.submission.correctAnswers}',
                            const Color(0xFF34C759),
                          ),
                        ),
                        Expanded(
                          child: _buildScoreItem(
                            'Incorrect',
                            '${widget.submission.incorrectAnswers}',
                            const Color(0xFFFF3B30),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Grading Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grade Assessment',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _gradeController,
                      decoration: InputDecoration(
                        labelText: 'Grade (0-${widget.submission.maxPossibleScore})',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.grade),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a grade';
                        }
                        final grade = int.tryParse(value);
                        if (grade == null || grade < 0 || grade > widget.submission.maxPossibleScore) {
                          return 'Grade must be between 0 and ${widget.submission.maxPossibleScore}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _feedbackController,
                      decoration: const InputDecoration(
                        labelText: 'Feedback (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.feedback),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Answers
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed Answers',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.assessment.questions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final question = entry.value;
                      final answer = widget.submission.detailedAnswers[index];
                      
                      
                      return _buildQuestionCard(index + 1, question, answer);
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86868B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86868B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int questionNumber, AssessmentQuestion question, DetailedAnswer? answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: answer?.isCorrect == true 
              ? const Color(0xFF34C759)
              : answer?.isCorrect == false
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFFE5E5E7),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: answer?.isCorrect == true 
            ? const Color(0xFF34C759).withOpacity(0.1)
            : answer?.isCorrect == false
                ? const Color(0xFFFF3B30).withOpacity(0.1)
                : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: answer?.isCorrect == true 
                      ? const Color(0xFF34C759)
                      : answer?.isCorrect == false
                          ? const Color(0xFFFF3B30)
                          : const Color(0xFF86868B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (answer != null) ...[
            _buildAnswerRow('Student Answer', answer.answer),
            const SizedBox(height: 8),
            _buildAnswerRow('Correct Answer', answer.correctAnswer),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildAnswerRow('Points', '${answer.points}'),
                ),
                Expanded(
                  child: _buildAnswerRow('Status', answer.isCorrect ? 'Correct' : 'Incorrect'),
                ),
              ],
            ),
            if (answer.explanation != null && answer.explanation!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildAnswerRow('Explanation', answer.explanation!),
            ],
          ] else ...[
            const Text(
              'No answer provided',
              style: TextStyle(
                color: Color(0xFF86868B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86868B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1D1F),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 0.8) return const Color(0xFF34C759); // Green
    if (percentage >= 0.6) return const Color(0xFFFF9500); // Orange
    return const Color(0xFFFF3B30); // Red
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitGrade() async {
    if (_gradeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a grade'),
          backgroundColor: Color(0xFFFF3B30),
        ),
      );
      return;
    }

    final grade = int.tryParse(_gradeController.text);
    if (grade == null || grade < 0 || grade > widget.submission.maxPossibleScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grade must be between 0 and ${widget.submission.maxPossibleScore}'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
      return;
    }

    setState(() {
      _isGrading = true;
    });

    try {
      // Update the submission with the new grade
      await _assessmentService.updateSubmissionGrade(
        widget.submission.id,
        grade,
        _feedbackController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grade submitted successfully!'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit grade: $e'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGrading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }
}
