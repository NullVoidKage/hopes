import 'package:flutter/material.dart';
import '../models/learning_path.dart';
import '../models/user_model.dart';
import '../services/learning_path_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/offline_indicator.dart';
import 'learning_path_creation_screen.dart';

class LearningPathManagementScreen extends StatefulWidget {
  final UserModel teacherProfile;
  
  const LearningPathManagementScreen({
    super.key,
    required this.teacherProfile,
  });

  @override
  State<LearningPathManagementScreen> createState() => _LearningPathManagementScreenState();
}

class _LearningPathManagementScreenState extends State<LearningPathManagementScreen> {
  final LearningPathService _learningPathService = LearningPathService();
  List<LearningPath> _learningPaths = [];
  bool _isLoading = true;
  String? _error;
  
  String? _selectedSubject;
  String? _selectedStatus;
  final List<String> _statusOptions = ['All', 'Published', 'Draft'];

  @override
  void initState() {
    super.initState();
    _loadLearningPaths();
  }

  Future<void> _loadLearningPaths() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final paths = await _learningPathService.getLearningPathsByTeacher(widget.teacherProfile.uid);
      setState(() {
        _learningPaths = paths;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<LearningPath> get _filteredLearningPaths {
    List<LearningPath> filtered = _learningPaths;
    
    // Filter by subject
    if (_selectedSubject != null && _selectedSubject != 'All') {
      filtered = filtered.where((path) => path.subjects.contains(_selectedSubject!)).toList();
    }
    
    // Filter by status
    if (_selectedStatus != null && _selectedStatus != 'All') {
      final isPublished = _selectedStatus == 'Published';
      filtered = filtered.where((path) => path.isPublished == isPublished).toList();
    }
    
    return filtered;
  }

  Future<void> _deleteLearningPath(LearningPath learningPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Learning Path'),
        content: Text('Are you sure you want to delete "${learningPath.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _learningPathService.deleteLearningPath(learningPath.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Learning path deleted successfully')),
        );
        _loadLearningPaths();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting learning path: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _togglePublishStatus(LearningPath learningPath) async {
    try {
      final updatedPath = learningPath.copyWith(isPublished: !learningPath.isPublished);
      await _learningPathService.updateLearningPath(updatedPath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedPath.isPublished 
                ? 'Learning path published successfully'
                : 'Learning path unpublished successfully'
          ),
        ),
      );
      
      _loadLearningPaths();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating learning path: ${e.toString()}')),
      );
    }
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
          'My Learning Paths',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!ConnectivityService().isConnected)
            const OfflineIndicator(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLearningPaths,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with Create Button
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
                        'Learning Paths',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_filteredLearningPaths.length} learning paths',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _navigateToCreation(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create New'),
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

          // Filters
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E5E7)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        hintText: 'All Subjects',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Subjects')),
                        ...widget.teacherProfile.subjects?.map((subject) => DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        )) ?? [],
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSubject = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E5E7)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        hintText: 'All Status',
                      ),
                      items: _statusOptions.map((status) => DropdownMenuItem(
                        value: status == 'All' ? null : status,
                        child: Text(status),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => _selectedStatus = value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredLearningPaths.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredLearningPaths.length,
                            itemBuilder: (context, index) {
                              return _buildLearningPathCard(_filteredLearningPaths[index]);
                            },
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
          Text(
            'Error loading learning paths',
            style: const TextStyle(
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
            onPressed: _loadLearningPaths,
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
            Icons.layers_outlined,
            size: 64,
            color: Color(0xFF86868B),
          ),
          const SizedBox(height: 16),
          const Text(
            'No learning paths found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first learning path to get started',
            style: TextStyle(color: Color(0xFF86868B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreation(),
            icon: const Icon(Icons.add),
            label: const Text('Create Learning Path'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPathCard(LearningPath learningPath) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.layers_rounded,
                    color: Color(0xFF007AFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        learningPath.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      if (learningPath.subjects.isNotEmpty)
                        Text(
                          learningPath.subjects.first,
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
                    color: learningPath.isPublished 
                        ? const Color(0xFF34C759).withOpacity(0.1)
                        : const Color(0xFFFF9500).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    learningPath.isPublished ? 'Published' : 'Draft',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: learningPath.isPublished 
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF9500),
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
                Text(
                  learningPath.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Steps info
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.format_list_numbered,
                      '${learningPath.steps.length} steps',
                    ),
                    const SizedBox(width: 16),
                    _buildInfoItem(
                      Icons.schedule,
                      '${learningPath.steps.fold<int>(0, (sum, step) => sum + step.estimatedDuration)} min',
                    ),
                    const SizedBox(width: 16),
                    _buildInfoItem(
                      Icons.label,
                      '${learningPath.tags.length} tags',
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Tags
                if (learningPath.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: learningPath.tags.take(3).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    )).toList(),
                  ),
                
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToCreation(learningPath: learningPath),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF007AFF),
                          side: const BorderSide(color: Color(0xFF007AFF)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _togglePublishStatus(learningPath),
                        icon: Icon(
                          learningPath.isPublished ? Icons.visibility_off : Icons.publish,
                        ),
                        label: Text(learningPath.isPublished ? 'Unpublish' : 'Publish'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: learningPath.isPublished 
                              ? const Color(0xFFFF9500)
                              : const Color(0xFF34C759),
                          side: BorderSide(
                            color: learningPath.isPublished 
                                ? const Color(0xFFFF9500)
                                : const Color(0xFF34C759),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteLearningPath(learningPath),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
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

  Widget _buildInfoItem(IconData icon, String text) {
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
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86868B),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToCreation({LearningPath? learningPath}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningPathCreationScreen(
          teacherProfile: widget.teacherProfile,
          learningPath: learningPath,
        ),
      ),
    );

    if (result == true) {
      _loadLearningPaths();
    }
  }
}
