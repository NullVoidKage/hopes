import 'package:flutter/material.dart';
import '../models/assessment_submission.dart';
import '../models/assessment.dart';
import '../services/assessment_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/offline_indicator.dart';

class TeacherSubmissionDetailScreen extends StatefulWidget {
  final AssessmentSubmission submission;

  const TeacherSubmissionDetailScreen({
    Key? key,
    required this.submission,
  }) : super(key: key);

  @override
  State<TeacherSubmissionDetailScreen> createState() => _TeacherSubmissionDetailScreenState();
}

class _TeacherSubmissionDetailScreenState extends State<TeacherSubmissionDetailScreen> {
  final AssessmentService _assessmentService = AssessmentService();
  final ConnectivityService _connectivityService = ConnectivityService();
  
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
            content: Text('Error loading assessment details: $e'),
            backgroundColor: Colors.red,
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
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1D1D1F)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_connectivityService.isConnected)
            const OfflineIndicator(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubmissionHeader(),
                  const SizedBox(height: 24),
                  _buildSubmissionOverview(),
                  const SizedBox(height: 24),
                  _buildPerformanceMetrics(),
                  const SizedBox(height: 24),
                  _buildAssessmentDetails(),
                  const SizedBox(height: 24),
                  _buildSubmissionTimeline(),
                ],
              ),
            ),
    );
  }

  Widget _buildSubmissionHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getScoreColor(widget.submission.score.toDouble()).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.quiz_rounded,
                  color: _getScoreColor(widget.submission.score.toDouble()),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.submission.assessmentTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.submission.assessmentSubject,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF86868B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getScoreColor(widget.submission.score.toDouble()).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.submission.score}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(widget.submission.score.toDouble()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeaderInfo('Student', widget.submission.studentName),
              const SizedBox(width: 32),
              _buildHeaderInfo('Status', widget.submission.isGraded ? 'Graded' : 'Pending'),
              const SizedBox(width: 32),
              _buildHeaderInfo('Date', _formatDate(widget.submission.submittedAt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86868B),
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

  Widget _buildSubmissionOverview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF007AFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverviewMetric(
                  'Total Questions',
                  '${widget.submission.totalQuestions}',
                  Icons.quiz_rounded,
                  const Color(0xFF007AFF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewMetric(
                  'Correct Answers',
                  '${widget.submission.correctAnswers}',
                  Icons.check_circle_rounded,
                  const Color(0xFF34C759),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewMetric(
                  'Incorrect Answers',
                  '${widget.submission.incorrectAnswers}',
                  Icons.cancel_rounded,
                  const Color(0xFFFF3B30),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewMetric(
                  'Unanswered',
                  '${widget.submission.unansweredQuestions}',
                  Icons.help_rounded,
                  const Color(0xFFFF9500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
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

  Widget _buildPerformanceMetrics() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: const Color(0xFF34C759).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF34C759),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Performance Metrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMetricRow('Accuracy', '${widget.submission.accuracy.toStringAsFixed(1)}%', _getScoreColor(widget.submission.accuracy)),
          const SizedBox(height: 16),
          _buildMetricRow('Time Spent', widget.submission.formattedTimeSpent, const Color(0xFF007AFF)),
          const SizedBox(height: 16),
          _buildMetricRow('Score', '${widget.submission.score}%', _getScoreColor(widget.submission.score.toDouble())),
          if (widget.submission.feedback != null && widget.submission.feedback!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildFeedbackSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF86868B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.feedback_rounded,
                color: Color(0xFF007AFF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Teacher Feedback',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.submission.feedback!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentDetails() {
    if (_assessment == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Color(0xFFFF9500),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Assessment Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Description', _assessment!.description),
          const SizedBox(height: 12),
          _buildDetailRow('Duration', '${_assessment!.timeLimit} minutes'),
          const SizedBox(height: 12),
          _buildDetailRow('Total Points', '${_assessment!.totalPoints} points'),
          const SizedBox(height: 12),
          _buildDetailRow('Created', _formatDate(_assessment!.createdAt)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionTimeline() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: const Color(0xFF86868B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFF86868B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Submission Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            'Assessment Started',
            _formatDate(widget.submission.submittedAt),
            Icons.play_circle_rounded,
            const Color(0xFF34C759),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            'Assessment Completed',
            _formatDate(widget.submission.submittedAt),
            Icons.check_circle_rounded,
            const Color(0xFF007AFF),
          ),
          if (widget.submission.isGraded) ...[
            const SizedBox(height: 16),
            _buildTimelineItem(
              'Graded',
              _formatDate(widget.submission.gradedAt ?? widget.submission.submittedAt),
              Icons.grade_rounded,
              const Color(0xFFFF9500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF86868B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF34C759);
    if (percentage >= 60) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
