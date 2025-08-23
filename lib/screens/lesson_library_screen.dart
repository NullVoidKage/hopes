import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../services/lesson_service_realtime.dart';
import '../models/user_model.dart';

class LessonLibraryScreen extends StatefulWidget {
  final UserModel teacherProfile;
  
  const LessonLibraryScreen({
    super.key,
    required this.teacherProfile,
  });

  @override
  State<LessonLibraryScreen> createState() => _LessonLibraryScreenState();
}

class _LessonLibraryScreenState extends State<LessonLibraryScreen> {
  final LessonServiceRealtime _lessonService = LessonServiceRealtime();
  List<Lesson> _lessons = [];
  bool _isLoading = true;
  String? _error;
  String _selectedSubject = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final lessons = await _lessonService.getLessonsByTeacher(widget.teacherProfile.uid);
      
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Lesson> get _filteredLessons {
    return _lessons.where((lesson) {
      final subjectMatch = _selectedSubject == 'All' || lesson.subject == _selectedSubject;
      final statusMatch = _selectedStatus == 'All' || 
          (_selectedStatus == 'Published' && lesson.isPublished) ||
          (_selectedStatus == 'Draft' && !lesson.isPublished);
      return subjectMatch && statusMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'My Lessons',
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLessons,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filters
            _buildFilters(),
            
            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _lessons.isEmpty
                          ? _buildEmptyState()
                          : _buildLessonsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final List<String> subjects = [
      'All',
      if (widget.teacherProfile.subjects != null)
        ...widget.teacherProfile.subjects!.cast<String>()
    ];
    final statuses = ['All', 'Published', 'Draft'];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedSubject,
                  items: subjects,
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value!;
                    });
                  },
                  label: 'Subject',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  value: _selectedStatus,
                  items: statuses,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                  label: 'Status',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF86868B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: const Color(0xFFE5E5E7),
              width: 1,
            ),
            color: const Color(0xFFF5F5F7),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              dropdownColor: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              elevation: 8,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1D1D1F),
                fontWeight: FontWeight.w500,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(item),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsList() {
    final filteredLessons = _filteredLessons;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredLessons.length,
      itemBuilder: (context, index) {
        final lesson = filteredLessons[index];
        return _buildLessonCard(lesson);
      },
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        lesson.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lesson.subject,
                        style: const TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF007AFF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: lesson.isPublished 
                        ? const Color(0xFF34C759).withValues(alpha: 0.1)
                        : const Color(0xFFFF9500).withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    border: Border.all(
                      color: lesson.isPublished 
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF9500),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    lesson.isPublished ? 'Published' : 'Draft',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: lesson.isPublished 
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF9500),
                    ),
                  ),
                ),
              ],
            ),
            
            if (lesson.description?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                lesson.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF86868B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Tags
            if (lesson.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: lesson.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF86868B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // File attachment indicator
            if (lesson.fileUrl?.isNotEmpty == true) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(
                    color: const Color(0xFF007AFF),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.attach_file_rounded,
                      color: Color(0xFF007AFF),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'File attached',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF007AFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Footer
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: const Color(0xFF86868B),
                ),
                const SizedBox(width: 8),
                Text(
                  'Created ${_formatDate(lesson.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF86868B),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _editLesson(lesson),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _togglePublishStatus(lesson),
                  child: Text(
                    lesson.isPublished ? 'Unpublish' : 'Publish',
                    style: TextStyle(
                      color: lesson.isPublished 
                          ? const Color(0xFFFF9500)
                          : const Color(0xFF34C759),
                      fontWeight: FontWeight.w600,
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
            'Loading lessons...',
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF3B30),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading lessons',
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
            onPressed: _loadLessons,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
            ),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: const Icon(
              Icons.library_books_rounded,
              color: Color(0xFF007AFF),
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Lessons Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Start creating your first lesson to share knowledge with students',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Create Your First Lesson',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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

  void _editLesson(Lesson lesson) {
    // TODO: Navigate to lesson edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit lesson feature coming soon!'),
        backgroundColor: Color(0xFFFF9500),
      ),
    );
  }

  Future<void> _togglePublishStatus(Lesson lesson) async {
    try {
      await _lessonService.toggleLessonPublish(lesson.id, !lesson.isPublished);
      
      // Update local state
      setState(() {
        final index = _lessons.indexWhere((l) => l.id == lesson.id);
        if (index != -1) {
          _lessons[index] = lesson.copyWith(isPublished: !lesson.isPublished);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lesson.isPublished 
                ? 'Lesson unpublished successfully'
                : 'Lesson published successfully',
          ),
          backgroundColor: const Color(0xFF34C759),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating lesson: ${e.toString()}'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }
}
