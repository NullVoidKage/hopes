import 'package:flutter/material.dart';
import '../models/assessment_submission.dart';
import '../services/submission_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/offline_indicator.dart';

class TeacherSubmissionViewerScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherSubmissionViewerScreen({
    Key? key,
    required this.teacherId,
    required this.teacherName,
  }) : super(key: key);

  @override
  State<TeacherSubmissionViewerScreen> createState() => _TeacherSubmissionViewerScreenState();
}

class _TeacherSubmissionViewerScreenState extends State<TeacherSubmissionViewerScreen> {
  final SubmissionService _submissionService = SubmissionService();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  List<AssessmentSubmission> _submissions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String _selectedAssessment = 'All';

           final List<String> _filterOptions = ['All', 'Graded', 'Pending', 'High Accuracy', 'Low Accuracy'];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final submissions = await _submissionService.getTeacherSubmissions(widget.teacherId);
      
      if (!mounted) return;
      
      setState(() {
        _submissions = submissions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading submissions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshSubmissions() async {
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = true;
    });

    await _loadSubmissions();
    
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = false;
    });
  }

  List<AssessmentSubmission> get _filteredSubmissions {
    List<AssessmentSubmission> filtered = _submissions;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((submission) {
        return submission.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               submission.assessmentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               submission.studentId.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply assessment filter
    if (_selectedAssessment != 'All') {
      filtered = filtered.where((submission) => 
        submission.assessmentId == _selectedAssessment).toList();
    }

               // Apply status filter
           switch (_selectedFilter) {
             case 'Graded':
               filtered = filtered.where((submission) => submission.isGraded).toList();
               break;
             case 'Pending':
               filtered = filtered.where((submission) => !submission.isGraded).toList();
               break;
             case 'High Accuracy':
               filtered = filtered.where((submission) => submission.accuracy >= 80).toList();
               break;
             case 'Low Accuracy':
               filtered = filtered.where((submission) => submission.accuracy < 60).toList();
               break;
             default:
               // 'All' - no filtering
               break;
           }

    return filtered;
  }

  List<String> get _assessmentOptions {
    final assessments = _submissions.map((s) => s.assessmentId).toSet().toList();
    assessments.insert(0, 'All');
    return assessments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Student Submissions',
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: const Color(0xFF007AFF)),
            onPressed: _isRefreshing ? null : _refreshSubmissions,
          ),
          
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          if (!_connectivityService.isConnected)
            const OfflineIndicator(),
          
          
          
          // Header with teacher info and stats
          _buildHeader(),
          
          // Search and filter bar
          _buildSearchAndFilter(),
          
          // Submissions list
          Expanded(
            child: _buildSubmissionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pendingCount = _submissions.where((s) => !s.isGraded).length;
    final gradedCount = _submissions.where((s) => s.isGraded).length;
               final averageAccuracy = _submissions.isNotEmpty
               ? (_submissions.map((s) => s.accuracy).reduce((a, b) => a + b) / _submissions.length).round()
               : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF007AFF),
                child: Text(
                  widget.teacherName.isNotEmpty 
                      ? widget.teacherName[0].toUpperCase() 
                      : 'T',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.teacherName.isNotEmpty ? widget.teacherName : 'Teacher',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    Text(
                      'Submission Management',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF86868B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '${_submissions.length}',
                  Icons.assignment,
                  const Color(0xFF007AFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  '$pendingCount',
                  Icons.pending,
                  const Color(0xFFFF9500),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Graded',
                  '$gradedCount',
                  Icons.check_circle,
                  const Color(0xFF34C759),
                ),
              ),
              const SizedBox(width: 12),
                                   Expanded(
                       child: _buildStatCard(
                         'Avg Accuracy',
                         '${averageAccuracy}%',
                         Icons.trending_up,
                         const Color(0xFFAF52DE),
                       ),
                     ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E7)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D1D1F),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF86868B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by student, assessment, or ID...',
                prefixIcon: Icon(Icons.search, color: const Color(0xFF86868B)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter row
          Row(
            children: [
              // Assessment filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E5E7)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAssessment,
                      isExpanded: true,
                      items: _assessmentOptions.map((assessment) {
                        return DropdownMenuItem(
                          value: assessment,
                          child: Text(
                            assessment == 'All' ? 'All Assessments' : 'Assessment ${assessment.substring(0, 8)}...',
                            style: TextStyle(
                              color: const Color(0xFF1D1D1F),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAssessment = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Status filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E5E7)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      isExpanded: true,
                      items: _filterOptions.map((filter) {
                        return DropdownMenuItem(
                          value: filter,
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: const Color(0xFF1D1D1F),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF007AFF),
        ),
      );
    }

    if (_filteredSubmissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: const Color(0xFF86868B),
            ),
            const SizedBox(height: 16),
            Text(
              _submissions.isEmpty ? 'No submissions yet' : 'No submissions match your filter',
              style: TextStyle(
                fontSize: 18,
                color: const Color(0xFF86868B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _submissions.isEmpty 
                  ? 'Students need to complete assessments first!'
                  : 'Try adjusting your search or filter criteria.',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF86868B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSubmissions.length,
      itemBuilder: (context, index) {
        final submission = _filteredSubmissions[index];
        return _buildSubmissionCard(submission);
      },
    );
  }

  Widget _buildSubmissionCard(AssessmentSubmission submission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                                   Text(
                               submission.studentName.isNotEmpty ? submission.studentName : 'Student ${submission.studentId.substring(0, 8)}...',
                               style: const TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.w600,
                                 color: Color(0xFF1D1D1F),
                               ),
                             ),
                             Text(
                               submission.assessmentTitle.isNotEmpty ? submission.assessmentTitle : 'Assessment ${submission.assessmentId.substring(0, 8)}...',
                               style: TextStyle(
                                 fontSize: 14,
                                 color: const Color(0xFF86868B),
                               ),
                             ),
                             Text(
                               '${submission.assessmentSubject} • ${submission.assessmentGradeLevel}',
                               style: TextStyle(
                                 fontSize: 12,
                                 color: const Color(0xFF86868B),
                               ),
                             ),
                      Text(
                        'Submitted on ${submission.formattedDate} at ${submission.formattedTime}',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                                               Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                             decoration: BoxDecoration(
                               color: _getScoreColor(submission.accuracy).withOpacity(0.1),
                               borderRadius: BorderRadius.circular(16),
                               border: Border.all(
                                 color: _getScoreColor(submission.accuracy),
                               ),
                             ),
                             child: Text(
                               '${submission.accuracy.toStringAsFixed(1)}%',
                               style: TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.w600,
                                 color: _getScoreColor(submission.accuracy),
                               ),
                             ),
                           ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: submission.isGraded 
                            ? const Color(0xFF34C759).withOpacity(0.1)
                            : const Color(0xFFFF9500).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: submission.isGraded 
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF9500),
                        ),
                      ),
                      child: Text(
                        submission.isGraded ? 'Graded' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: submission.isGraded 
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF9500),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
                               // Details row
                   Row(
                     children: [
                       _buildDetailItem(
                         Icons.timer,
                         'Time Spent',
                         submission.formattedTimeSpent,
                       ),
                       const SizedBox(width: 24),
                       _buildDetailItem(
                         Icons.question_answer,
                         'Questions',
                         '${submission.totalQuestions}',
                       ),
                       const SizedBox(width: 24),
                       _buildDetailItem(
                         Icons.analytics,
                         'Accuracy',
                         '${submission.accuracy.toStringAsFixed(1)}%',
                       ),
                     ],
                   ),
                   
                   // Enhanced details row
                   const SizedBox(height: 12),
                   Row(
                     children: [
                       _buildDetailItem(
                         Icons.check_circle,
                         'Correct',
                         '${submission.correctAnswers}',
                       ),
                       const SizedBox(width: 24),
                       _buildDetailItem(
                         Icons.cancel,
                         'Incorrect',
                         '${submission.incorrectAnswers}',
                       ),
                       const SizedBox(width: 24),
                       _buildDetailItem(
                         Icons.help,
                         'Unanswered',
                         '${submission.unansweredQuestions}',
                       ),
                     ],
                   ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewSubmissionDetails(submission),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: const Color(0xFF007AFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        color: const Color(0xFF007AFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: submission.isGraded 
                        ? () => _editGrade(submission)
                        : () => _gradeSubmission(submission),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: submission.isGraded 
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF9500),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      submission.isGraded ? 'Edit Grade' : 'Grade Now',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF86868B), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF86868B),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF34C759); // Green
    if (percentage >= 60) return const Color(0xFFFF9500); // Orange
    return const Color(0xFFFF3B30); // Red
  }

  void _viewSubmissionDetails(AssessmentSubmission submission) {
    // TODO: Navigate to submission detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing submission: ${submission.id}'),
        backgroundColor: const Color(0xFF007AFF),
      ),
    );
  }

  void _gradeSubmission(AssessmentSubmission submission) {
    // TODO: Navigate to grading screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grading submission: ${submission.id}'),
        backgroundColor: const Color(0xFFFF9500),
      ),
    );
  }

  void _editGrade(AssessmentSubmission submission) {
    // TODO: Navigate to edit grade screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing grade for: ${submission.id}'),
        backgroundColor: const Color(0xFF34C759),
      ),
    );
  }
}
