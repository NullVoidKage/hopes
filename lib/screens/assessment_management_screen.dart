import 'package:flutter/material.dart';
import '../models/assessment.dart';
import '../models/user_model.dart';
import '../services/assessment_service.dart';
import 'assessment_creation_screen.dart';
import 'assessment_edit_screen.dart';

class AssessmentManagementScreen extends StatefulWidget {
  final UserModel teacherProfile;

  const AssessmentManagementScreen({
    super.key,
    required this.teacherProfile,
  });

  @override
  State<AssessmentManagementScreen> createState() => _AssessmentManagementScreenState();
}

class _AssessmentManagementScreenState extends State<AssessmentManagementScreen> {
  final AssessmentService _assessmentService = AssessmentService();
  List<Assessment> _assessments = [];
  bool _isLoading = true;
  String? _error;
  
  String? _selectedSubject;
  String? _selectedStatus;
  final List<String> _statusOptions = ['All', 'Published', 'Draft'];

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assessments = await _assessmentService.getAssessmentsByTeacher(widget.teacherProfile.uid);
      setState(() {
        _assessments = assessments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Assessment> get _filteredAssessments {
    List<Assessment> filtered = _assessments;
    
    // Filter by subject
    if (_selectedSubject != null && _selectedSubject != 'All') {
      filtered = filtered.where((a) => a.subject == _selectedSubject).toList();
    }
    
    // Filter by status
    if (_selectedStatus != null && _selectedStatus != 'All') {
      final isPublished = _selectedStatus == 'Published';
      filtered = filtered.where((a) => a.isPublished == isPublished).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Assessments',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAssessments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with Create Button
          _buildHeader(),
          
          // Filters
          _buildFilters(),
          
          // Assessments List
          Expanded(
            child: _buildAssessmentsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewAssessment(),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Assessment'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            child: const Icon(
              Icons.quiz_rounded,
              size: 32,
              color: Color(0xFFFF9500),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_assessments.length} Assessment${_assessments.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your quizzes, tests, and assignments',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF86868B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    // Use the full list of 11 subjects plus 'All' option
    final subjects = [
      'All',
      'Mathematics',
      'GMRC',
      'Values Education',
      'Araling Panlipunan',
      'English',
      'Filipino',
      'Music & Arts',
      'Science',
      'Physical Education & Health',
      'EPP',
      'TLE'
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Subject Filter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subject',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    border: Border.all(
                      color: const Color(0xFFE5E5E7),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubject ?? 'All',
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: InputBorder.none,
                    ),
                    items: subjects.map((subject) => DropdownMenuItem<String>(
                      value: subject,
                      child: Text(subject),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Status Filter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    border: Border.all(
                      color: const Color(0xFFE5E5E7),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus ?? 'All',
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: InputBorder.none,
                    ),
                    items: _statusOptions.map((status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentsList() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_filteredAssessments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredAssessments.length,
      itemBuilder: (context, index) {
        final assessment = _filteredAssessments[index];
        return _buildAssessmentCard(assessment);
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading assessments...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Color(0xFFFF3B30),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading assessments',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAssessments,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.quiz_rounded,
            size: 64,
            color: Color(0xFF86868B),
          ),
          const SizedBox(height: 16),
          const Text(
            'No assessments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first assessment to get started',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _createNewAssessment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Assessment'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(Assessment assessment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and actions
          Row(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: assessment.isPublished 
                      ? const Color(0xFF34C759).withValues(alpha: 0.1)
                      : const Color(0xFFFF9500).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(
                    color: assessment.isPublished 
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF9500),
                    width: 1,
                  ),
                ),
                child: Text(
                  assessment.isPublished ? 'Published' : 'Draft',
                  style: TextStyle(
                    color: assessment.isPublished 
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF9500),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Action buttons
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editAssessment(assessment),
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF007AFF),
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _togglePublishStatus(assessment),
                      icon: Icon(
                        assessment.isPublished 
                            ? Icons.visibility_off_rounded
                            : Icons.publish_rounded,
                        color: assessment.isPublished 
                            ? const Color(0xFFFF9500)
                            : const Color(0xFF34C759),
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteAssessment(assessment),
                      icon: const Icon(
                        Icons.delete_rounded,
                        color: Color(0xFFFF3B30),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Assessment title and subject
          Text(
            assessment.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Text(
                    assessment.subject,
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (assessment.timeLimit > 0)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          color: Color(0xFFFF9500),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${assessment.timeLimit} min',
                            style: const TextStyle(
                              color: Color(0xFFFF9500),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Description
          if (assessment.description.isNotEmpty)
            Text(
              assessment.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF86868B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            children: [
              Flexible(
                child: _buildStatItem(
                  Icons.quiz_rounded,
                  '${assessment.questions.length}',
                  'Questions',
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: _buildStatItem(
                  Icons.stars_rounded,
                  '${assessment.totalPoints}',
                  'Points',
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: _buildStatItem(
                  Icons.calendar_today_rounded,
                  _formatDate(assessment.createdAt),
                  'Created',
                ),
              ),
            ],
          ),
          
          // Tags
          if (assessment.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: assessment.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF86868B),
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF86868B),
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86868B),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Action methods
  void _createNewAssessment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssessmentCreationScreen(
          teacherProfile: widget.teacherProfile,
        ),
      ),
    ).then((_) {
      // Refresh the list when returning from creation
      _loadAssessments();
    });
  }

  void _editAssessment(Assessment assessment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssessmentEditScreen(
          assessment: assessment,
          teacherProfile: widget.teacherProfile,
        ),
      ),
    ).then((_) {
      // Refresh the list when returning from editing
      _loadAssessments();
    });
  }

  Future<void> _togglePublishStatus(Assessment assessment) async {
    try {
      final newStatus = !assessment.isPublished;
      await _assessmentService.toggleAssessmentPublish(assessment.id, newStatus);
      
      // Refresh the list
      _loadAssessments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assessment ${newStatus ? 'published' : 'unpublished'} successfully!'),
            backgroundColor: const Color(0xFF34C759),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating assessment status: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  Future<void> _deleteAssessment(Assessment assessment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: Text('Are you sure you want to delete "${assessment.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _assessmentService.deleteAssessment(assessment.id);
        
        // Refresh the list
        _loadAssessments();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assessment deleted successfully!'),
              backgroundColor: Color(0xFF34C759),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting assessment: ${e.toString()}'),
              backgroundColor: const Color(0xFFFF3B30),
            ),
          );
        }
      }
    }
  }
}
