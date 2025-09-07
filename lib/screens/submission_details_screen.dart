import 'package:flutter/material.dart';
import '../models/assessment_submission.dart';
import '../models/assessment.dart';
import '../services/assessment_service.dart';

class SubmissionDetailsScreen extends StatefulWidget {
  final AssessmentSubmission submission;
  final bool isTeacher;

  const SubmissionDetailsScreen({
    Key? key,
    required this.submission,
    this.isTeacher = false,
  }) : super(key: key);

  @override
  State<SubmissionDetailsScreen> createState() => _SubmissionDetailsScreenState();
}

class _SubmissionDetailsScreenState extends State<SubmissionDetailsScreen> {
  final AssessmentService _assessmentService = AssessmentService();
  Assessment? _assessment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssessmentDetails();
  }

  Future<void> _loadAssessmentDetails() async {
    try {
      final assessment = await _assessmentService.getAssessmentById(widget.submission.assessmentId);
      setState(() {
        _assessment = assessment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading assessment: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          'Submission Details',
          style: TextStyle(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: const Color(0xFF1D1D1F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assessment Info Card
                  _buildAssessmentInfoCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Performance Summary Card
                  _buildPerformanceSummaryCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Detailed Results Card
                  _buildDetailedResultsCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Feedback Card (if available)
                  if (widget.submission.feedback != null && widget.submission.feedback!.isNotEmpty)
                    _buildFeedbackCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildAssessmentInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: Color(0xFF007AFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _assessment?.title ?? 'Assessment',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _assessment?.subject ?? 'Subject',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF86868B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildInfoItem(Icons.person, 'Student', widget.submission.studentName),
              const SizedBox(width: 24),
              _buildInfoItem(Icons.schedule, 'Submitted', widget.submission.formattedDate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummaryCard() {
    final accuracy = widget.submission.accuracy;
    final scoreColor = _getScoreColor(accuracy);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Score',
                  '${accuracy.toStringAsFixed(1)}%',
                  Icons.assessment,
                  scoreColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Time Spent',
                  widget.submission.formattedTimeSpent,
                  Icons.timer,
                  const Color(0xFF007AFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Questions',
                  '${widget.submission.totalQuestions}',
                  Icons.quiz,
                  const Color(0xFF86868B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Correct',
                  '${widget.submission.correctAnswers}',
                  Icons.check_circle,
                  const Color(0xFF34C759),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedResultsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildResultItem(
                  'Correct Answers',
                  '${widget.submission.correctAnswers}',
                  const Color(0xFF34C759),
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildResultItem(
                  'Incorrect Answers',
                  '${widget.submission.incorrectAnswers}',
                  const Color(0xFFFF3B30),
                  Icons.cancel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildResultItem(
                  'Unanswered',
                  '${widget.submission.unansweredQuestions}',
                  const Color(0xFFFF9500),
                  Icons.help_outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildResultItem(
                  'Total Questions',
                  '${widget.submission.totalQuestions}',
                  const Color(0xFF86868B),
                  Icons.quiz,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.feedback,
                color: Color(0xFF007AFF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Teacher Feedback',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.submission.feedback!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1D1D1F),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF86868B), size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF86868B),
          ),
        ),
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

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF86868B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF34C759); // Green
    if (percentage >= 60) return const Color(0xFFFF9500); // Orange
    return const Color(0xFFFF3B30); // Red
  }
}
