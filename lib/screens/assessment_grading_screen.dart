import 'package:flutter/material.dart';
import '../models/assessment_submission.dart';
import '../models/assessment.dart';
import '../services/assessment_service.dart';
import '../services/submission_service.dart';

class AssessmentGradingScreen extends StatefulWidget {
  final AssessmentSubmission submission;
  final bool isEditing;

  const AssessmentGradingScreen({
    Key? key,
    required this.submission,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<AssessmentGradingScreen> createState() => _AssessmentGradingScreenState();
}

class _AssessmentGradingScreenState extends State<AssessmentGradingScreen> {
  final AssessmentService _assessmentService = AssessmentService();
  final SubmissionService _submissionService = SubmissionService();
  
  Assessment? _assessment;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Grading data
  Map<String, double> _questionScores = {};
  double _overallScore = 0.0;
  String _teacherComments = '';
  String _grade = '';

  @override
  void initState() {
    super.initState();
    _loadAssessmentDetails();
    _initializeGradingData();
  }

  Future<void> _loadAssessmentDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final assessment = await _assessmentService.getAssessmentById(widget.submission.assessmentId);
      
      if (mounted) {
        setState(() {
          _assessment = assessment;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading assessment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initializeGradingData() {
    if (widget.isEditing && widget.submission.isGraded) {
      _overallScore = widget.submission.accuracy;
      _teacherComments = widget.submission.teacherComments ?? '';
      _grade = widget.submission.grade ?? '';
      
      // Initialize question scores if available
      if (widget.submission.questionScores != null) {
        _questionScores = Map<String, double>.from(widget.submission.questionScores!);
      }
    } else {
      // Initialize with default values
      _teacherComments = '';
      _grade = '';
      _overallScore = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Grade' : 'Grade Assessment'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assessment == null
              ? const Center(child: Text('Assessment not found'))
              : _buildGradingContent(),
    );
  }

  Widget _buildGradingContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubmissionInfo(),
          const SizedBox(height: 20),
          _buildOverallScoreSection(),
          const SizedBox(height: 20),
          _buildQuestionGradingSection(),
          const SizedBox(height: 20),
          _buildCommentsSection(),
          const SizedBox(height: 20),
          _buildGradeSection(),
          const SizedBox(height: 30),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSubmissionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Submission Information',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Student', widget.submission.studentName),
              ),
              Expanded(
                child: _buildInfoItem('Assessment', _assessment?.title ?? 'Unknown'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Submitted', _formatDate(widget.submission.submittedAt)),
              ),
              Expanded(
                child: _buildInfoItem('Time Spent', '${widget.submission.timeSpent}s'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF86868B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
      ],
    );
  }

  Widget _buildOverallScoreSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Overall Score',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score (%)',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF86868B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _overallScore,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${_overallScore.round()}%',
                      onChanged: (value) {
                        setState(() {
                          _overallScore = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getScoreColor(_overallScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_overallScore.round()}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(_overallScore),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionGradingSection() {
    if (_assessment?.questions == null || _assessment!.questions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'No questions available for individual grading.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF86868B),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Question-by-Question Grading',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          ...(_assessment!.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final questionId = question.id;
            final currentScore = _questionScores[questionId] ?? 0.0;
            
            return _buildQuestionGradingItem(
              index + 1,
              questionId,
              question.question,
              currentScore,
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildQuestionGradingItem(int questionNumber, String questionId, String questionText, double currentScore) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question $questionNumber',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            questionText,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: currentScore,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${currentScore.round()}%',
                  onChanged: (value) {
                    setState(() {
                      _questionScores[questionId] = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(currentScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${currentScore.round()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getScoreColor(currentScore),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Teacher Comments',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: _teacherComments),
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Add your feedback and comments here...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF5F5F7),
            ),
            onChanged: (value) {
              _teacherComments = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGradeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Final Grade',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: _grade),
            decoration: const InputDecoration(
              hintText: 'Enter final grade (e.g., A+, B-, 85)',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF5F5F7),
            ),
            onChanged: (value) {
              _grade = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF007AFF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveGrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.isEditing ? 'Update Grade' : 'Save Grade',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveGrade() async {
    if (_overallScore < 0 || _overallScore > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid score between 0 and 100'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create updated submission with grading data
      final updatedSubmission = widget.submission.copyWith(
        accuracy: _overallScore,
        isGraded: true,
        gradedAt: DateTime.now(),
        teacherComments: _teacherComments.isNotEmpty ? _teacherComments : null,
        grade: _grade.isNotEmpty ? _grade : null,
        questionScores: _questionScores.isNotEmpty ? _questionScores : null,
      );

      // Save the graded submission
      await _submissionService.updateSubmission(updatedSubmission);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Grade updated successfully!' : 'Grade saved successfully!'),
            backgroundColor: const Color(0xFF34C759),
          ),
        );
        
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving grade: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF34C759); // Green
    if (percentage >= 60) return const Color(0xFFFF9500); // Orange
    return const Color(0xFFFF3B30); // Red
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
