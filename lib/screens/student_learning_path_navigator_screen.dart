import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/learning_path.dart';
import '../services/learning_path_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/offline_indicator.dart';

class StudentLearningPathNavigatorScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentLearningPathNavigatorScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<StudentLearningPathNavigatorScreen> createState() => _StudentLearningPathNavigatorScreenState();
}

class _StudentLearningPathNavigatorScreenState extends State<StudentLearningPathNavigatorScreen> {
  final LearningPathService _learningPathService = LearningPathService();
  final ConnectivityService _connectivityService = ConnectivityService();

  List<StudentLearningPath> _assignedPaths = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filterOptions = ['All', 'In Progress', 'Completed', 'Not Started'];

  @override
  void initState() {
    super.initState();
    _loadAssignedLearningPaths();
  }

  Future<void> _loadAssignedLearningPaths() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final paths = await _learningPathService.getStudentLearningPaths(widget.studentId);

      if (!mounted) return;

      setState(() {
        _assignedPaths = paths;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading learning paths: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    await _loadAssignedLearningPaths();

    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
    });
  }

  List<StudentLearningPath> get _filteredPaths {
    List<StudentLearningPath> filtered = _assignedPaths;

    // Apply status filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((path) => _getPathStatus(path) == _selectedFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((path) =>
          path.learningPathTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          path.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          path.teacherId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }

  String _getPathStatus(StudentLearningPath path) {
    if (path.status == 'completed') {
      return 'Completed';
    } else if (path.status == 'in_progress') {
      return 'In Progress';
    } else {
      return 'Not Started';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF34C759);
      case 'In Progress':
        return const Color(0xFFFF9500);
      case 'Not Started':
        return const Color(0xFF86868B);
      default:
        return const Color(0xFF86868B);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'In Progress':
        return Icons.play_circle;
      case 'Not Started':
        return Icons.schedule;
      default:
        return Icons.schedule;
    }
  }

  double _calculateProgress(StudentLearningPath path) {
    if (path.stepProgress.isEmpty) return 0.0;
    final completedSteps = path.stepProgress.where((step) => step.status == 'completed').length;
    return completedSteps / path.stepProgress.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSearchAndFilters(),
                const SizedBox(height: 24),
                _buildLearningPathsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1D1D1F)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isRefreshing ? Icons.refresh : Icons.refresh_outlined,
            color: const Color(0xFF007AFF),
          ),
          onPressed: _isRefreshing ? null : _refreshData,
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Learning Paths',
          style: TextStyle(
            color: const Color(0xFF1D1D1F),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.route,
                  size: 32,
                  color: Color(0xFF007AFF),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.studentName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Learning Journey',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF86868B),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5E7)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: const Color(0xFF86868B),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search learning paths...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Color(0xFF86868B),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF007AFF).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF86868B),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5E7),
                      width: isSelected ? 2 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPathsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading your learning paths...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF86868B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_assignedPaths.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredPaths.isEmpty) {
      return _buildNoResultsState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _filteredPaths.map((path) => _buildLearningPathCard(path)).toList(),
      ),
    );
  }

  Widget _buildLearningPathCard(StudentLearningPath path) {
    final status = _getPathStatus(path);
    final progress = _calculateProgress(path);
    final totalSteps = path.stepProgress.length;
    final completedSteps = path.stepProgress.where((step) => step.status == 'completed').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
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
                      path.learningPathTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                                         Text(
                       'Learning Path',
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
                  color: _getStatusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
                     Text(
             'Personalized learning journey assigned by your teacher',
             style: const TextStyle(
               fontSize: 14,
               color: Color(0xFF1D1D1F),
             ),
             maxLines: 2,
             overflow: TextOverflow.ellipsis,
           ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF86868B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedSteps of $totalSteps steps',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completion',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF86868B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE5E5E7),
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(status)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewLearningPathDetails(path),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF007AFF),
                    side: const BorderSide(color: Color(0xFF007AFF)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _continueLearningPath(path),
                  icon: Icon(
                    status == 'Completed' ? Icons.refresh : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(status == 'Completed' ? 'Review' : 'Continue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.route,
                size: 48,
                color: Color(0xFF007AFF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Learning Paths Assigned',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your teachers will assign learning paths to help guide your studies. Check back soon!',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF86868B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF86868B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 48,
                color: Color(0xFF86868B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Results Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search or filter to find learning paths.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF86868B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _viewLearningPathDetails(StudentLearningPath path) {
    // TODO: Navigate to learning path detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for: ${path.learningPathTitle}'),
        backgroundColor: const Color(0xFF007AFF),
      ),
    );
  }

  void _continueLearningPath(StudentLearningPath path) {
    // TODO: Navigate to learning path continuation screen
    final status = _getPathStatus(path);
    final action = status == 'Completed' ? 'Reviewing' : 'Continuing';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action: ${path.learningPathTitle}'),
        backgroundColor: const Color(0xFF007AFF),
      ),
    );
  }
}
