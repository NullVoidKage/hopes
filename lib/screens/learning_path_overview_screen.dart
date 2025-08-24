import 'package:flutter/material.dart';
import '../models/learning_path.dart';
import '../models/user_model.dart';
import '../services/learning_path_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/offline_indicator.dart';
import 'learning_path_assignment_screen.dart';

class LearningPathOverviewScreen extends StatefulWidget {
  final UserModel teacherProfile;
  
  const LearningPathOverviewScreen({
    super.key,
    required this.teacherProfile,
  });

  @override
  State<LearningPathOverviewScreen> createState() => _LearningPathOverviewScreenState();
}

class _LearningPathOverviewScreenState extends State<LearningPathOverviewScreen>
    with TickerProviderStateMixin {
  final LearningPathService _learningPathService = LearningPathService();
  
  List<StudentLearningPath> _assignments = [];
  bool _isLoading = true;
  String? _error;
  
  String _selectedStatus = 'All';
  String _selectedSubject = 'All';
  
  late TabController _tabController;
  
  final List<String> _statusOptions = ['All', 'assigned', 'in_progress', 'completed', 'paused'];
  final List<String> _subjects = [
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAssignments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assignments = await _learningPathService.getLearningPathsAssignedByTeacher(widget.teacherProfile.uid);
      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<StudentLearningPath> get _filteredAssignments {
    List<StudentLearningPath> filtered = _assignments;
    
    // Filter by status
    if (_selectedStatus != 'All') {
      filtered = filtered.where((assignment) => assignment.status == _selectedStatus).toList();
    }
    
    // Filter by subject (this would need to be implemented based on the learning path data)
    // For now, we'll show all assignments
    
    return filtered;
  }

  Map<String, dynamic> get _statistics {
    final total = _assignments.length;
    final assigned = _assignments.where((a) => a.status == 'assigned').length;
    final inProgress = _assignments.where((a) => a.status == 'in_progress').length;
    final completed = _assignments.where((a) => a.status == 'completed').length;
    final paused = _assignments.where((a) => a.status == 'paused').length;
    
    return {
      'total': total,
      'assigned': assigned,
      'inProgress': inProgress,
      'completed': completed,
      'paused': paused,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Learning Path Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        elevation: 0,
        shadowColor: const Color(0xFF000000).withValues(alpha: 0.04),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!ConnectivityService().isConnected)
            const OfflineIndicator(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAssignments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Header with Assign Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5E5E7)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Learning Path Assignments',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_filteredAssignments.length} assignments',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF86868B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToAssignment(),
                            icon: const Icon(Icons.add),
                            label: const Text('Assign New'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Statistics
                    _buildStatistics(),
                    
                    // Filters
                    _buildFilters(),
                    
                    // Tab Bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E5E7)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF007AFF),
                        unselectedLabelColor: const Color(0xFF86868B),
                        indicatorColor: const Color(0xFF007AFF),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Assignments'),
                          Tab(text: 'Progress'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildAssignmentsTab(),
                          _buildProgressTab(),
                        ],
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
            Icons.error_outline,
            size: 64,
            color: Color(0xFFFF3B30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading assignments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: const TextStyle(color: Color(0xFF86868B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAssignments,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final stats = _statistics;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Total', '${stats['total']}', Icons.assignment, const Color(0xFF007AFF))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('In Progress', '${stats['inProgress']}', Icons.play_circle, const Color(0xFF34C759))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Completed', '${stats['completed']}', Icons.check_circle, const Color(0xFFFF9500))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          Text(
            title,
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

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E7)),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                  hintText: 'Status',
                ),
                items: _statusOptions.map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status == 'All' ? 'All Status' : status.replaceAll('_', ' ').toUpperCase()),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E7)),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                  hintText: 'Subject',
                ),
                items: _subjects.map((subject) => DropdownMenuItem(
                  value: subject,
                  child: Text(subject),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedSubject = value!);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          
          // Status Distribution Chart
          _buildStatusDistributionChart(),
          const SizedBox(height: 24),
          
          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildStatusDistributionChart() {
    final stats = _statistics;
    final total = stats['total'];
    
    if (total == 0) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_rounded, size: 48, color: Color(0xFF86868B)),
              SizedBox(height: 16),
              Text(
                'No assignments available',
                style: TextStyle(color: Color(0xFF86868B)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
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
          const Text(
            'Assignment Status Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildChartBar('Assigned', stats['assigned'], total, const Color(0xFF007AFF)),
                const SizedBox(width: 8),
                _buildChartBar('In Progress', stats['inProgress'], total, const Color(0xFF34C759)),
                const SizedBox(width: 8),
                _buildChartBar('Completed', stats['completed'], total, const Color(0xFFFF9500)),
                const SizedBox(width: 8),
                _buildChartBar('Paused', stats['paused'], total, const Color(0xFFFF3B30)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) : 0.0;
    final barHeight = (percentage * 100).clamp(10.0, 100.0);
    
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              height: barHeight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label.substring(0, 3),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF86868B),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentAssignments = _assignments
        .take(5)
        .toList();

    return Container(
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
          const Text(
            'Recent Assignments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          if (recentAssignments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No recent assignments',
                  style: TextStyle(color: Color(0xFF86868B)),
                ),
              ),
            )
          else
            ...recentAssignments.map((assignment) => _buildRecentActivityItem(assignment)),
        ],
      ),
    );
  }

  Widget _buildRecentActivityItem(StudentLearningPath assignment) {
    final statusColor = _getStatusColor(assignment.status);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${assignment.studentName} - ${assignment.learningPathTitle}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                Text(
                  'Assigned ${_formatDate(assignment.assignedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              assignment.status.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return _filteredAssignments.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredAssignments.length,
            itemBuilder: (context, index) {
              return _buildAssignmentCard(_filteredAssignments[index]);
            },
          );
  }

  Widget _buildProgressTab() {
    final inProgressAssignments = _assignments
        .where((a) => a.status == 'in_progress' || a.status == 'completed')
        .toList();

    return inProgressAssignments.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inProgressAssignments.length,
            itemBuilder: (context, index) {
              return _buildProgressCard(inProgressAssignments[index]);
            },
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Color(0xFF86868B),
          ),
          const SizedBox(height: 16),
          const Text(
            'No assignments found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Assign learning paths to students to get started',
            style: TextStyle(color: Color(0xFF86868B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToAssignment(),
            icon: const Icon(Icons.add),
            label: const Text('Assign Learning Path'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(StudentLearningPath assignment) {
    final statusColor = _getStatusColor(assignment.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF007AFF),
                  child: Text(
                    assignment.studentName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      Text(
                        assignment.learningPathTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    assignment.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress info
                Row(
                  children: [
                    _buildProgressInfo('Assigned', _formatDate(assignment.assignedAt)),
                    const SizedBox(width: 16),
                    if (assignment.startedAt != null)
                      _buildProgressInfo('Started', _formatDate(assignment.startedAt!)),
                    if (assignment.completedAt != null) ...[
                      const SizedBox(width: 16),
                      _buildProgressInfo('Completed', _formatDate(assignment.completedAt!)),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Customizations
                if (assignment.customizations.isNotEmpty) ...[
                  const Text(
                    'Customizations:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: assignment.customizations.entries.map((entry) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewProgress(assignment),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Progress'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF007AFF),
                          side: const BorderSide(color: Color(0xFF007AFF)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _customizeAssignment(assignment),
                        icon: const Icon(Icons.edit),
                        label: const Text('Customize'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF9500),
                          side: const BorderSide(color: Color(0xFFFF9500)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(StudentLearningPath assignment) {
    final completedSteps = assignment.stepProgress
        .where((step) => step.status == 'completed')
        .length;
    final totalSteps = assignment.stepProgress.length;
    final progressPercentage = totalSteps > 0 ? (completedSteps / totalSteps) * 100 : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    Text(
                      assignment.learningPathTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF86868B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${progressPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF007AFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress bar
          LinearProgressIndicator(
            value: progressPercentage / 100,
            backgroundColor: const Color(0xFFE5E5E7),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
          ),
          const SizedBox(height: 8),
          
          Text(
            '$completedSteps of $totalSteps steps completed',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInfo(String label, String value) {
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return const Color(0xFF007AFF);
      case 'in_progress':
        return const Color(0xFF34C759);
      case 'completed':
        return const Color(0xFFFF9500);
      case 'paused':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF86868B);
    }
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

  Future<void> _navigateToAssignment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningPathAssignmentScreen(
          teacherProfile: widget.teacherProfile,
        ),
      ),
    );

    if (result == true) {
      _loadAssignments();
    }
  }

  void _viewProgress(StudentLearningPath assignment) {
    // TODO: Navigate to detailed progress view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View progress for ${assignment.studentName}')),
    );
  }

  void _customizeAssignment(StudentLearningPath assignment) {
    // TODO: Navigate to customization screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Customize assignment for ${assignment.studentName}')),
    );
  }
}
