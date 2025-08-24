import 'package:flutter/material.dart';
import '../models/assessment_submission.dart';
import '../services/submission_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/offline_indicator.dart';

class StudentSubmissionHistoryScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentSubmissionHistoryScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<StudentSubmissionHistoryScreen> createState() => _StudentSubmissionHistoryScreenState();
}

class _StudentSubmissionHistoryScreenState extends State<StudentSubmissionHistoryScreen> {
  final SubmissionService _submissionService = SubmissionService();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  List<AssessmentSubmission> _submissions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedFilter = 'All';
  String _searchQuery = '';

           final List<String> _filterOptions = ['All', 'High Accuracy', 'Medium Accuracy', 'Low Accuracy'];

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
      // Add timeout to prevent infinite loading
      final submissions = await _submissionService.getStudentSubmissions(widget.studentId)
          .timeout(const Duration(seconds: 30));
      
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
      
      String errorMessage = 'Error loading submissions';
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Loading took too long. Please try again.';
      } else {
        errorMessage = 'Error: $e';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadSubmissions,
          ),
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
        // Note: We'd need assessment details to search by name
        return submission.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               submission.assessmentId.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

               // Apply accuracy filter
           switch (_selectedFilter) {
             case 'High Accuracy':
               filtered = filtered.where((submission) => submission.accuracy >= 80).toList();
               break;
             case 'Medium Accuracy':
               filtered = filtered.where((submission) =>
                 submission.accuracy >= 60 && submission.accuracy < 80).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Submissions',
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
          
          // Header with student info and stats
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
                  widget.studentName.isNotEmpty 
                      ? widget.studentName[0].toUpperCase() 
                      : 'S',
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
                      widget.studentName.isNotEmpty ? widget.studentName : 'Student',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    Text(
                      'Assessment History',
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
                         'Average',
                         _submissions.isNotEmpty
                             ? '${(_submissions.map((s) => s.accuracy).reduce((a, b) => a + b) / _submissions.length).round()}%'
                             : '0%',
                         Icons.trending_up,
                         const Color(0xFF34C759),
                       ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: _buildStatCard(
                         'Best',
                         _submissions.isNotEmpty
                             ? '${_submissions.map((s) => s.accuracy).reduce((a, b) => a > b ? a : b).round()}%'
                             : '0%',
                         Icons.star,
                         const Color(0xFFFF9500),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E7)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D1D1F),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF86868B),
            ),
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
                hintText: 'Search submissions...',
                prefixIcon: Icon(Icons.search, color: const Color(0xFF86868B)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF007AFF),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1D1D1F),
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5E7),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF007AFF),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your submissions...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF86868B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF86868B),
              ),
            ),
          ],
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
                  ? 'Complete your first assessment to see it here!'
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
                               submission.assessmentTitle.isNotEmpty ? submission.assessmentTitle : 'Assessment ${submission.assessmentId.substring(0, 8)}...',
                               style: const TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.w600,
                                 color: Color(0xFF1D1D1F),
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
                          fontSize: 14,
                          color: const Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),
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
                    onPressed: () => _retakeAssessment(submission),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Retake',
                      style: TextStyle(
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

  void _retakeAssessment(AssessmentSubmission submission) {
    // TODO: Navigate to assessment taker screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Retaking assessment: ${submission.assessmentId}'),
        backgroundColor: const Color(0xFF007AFF),
      ),
    );
  }
}
