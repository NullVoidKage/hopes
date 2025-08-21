import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../data/db/database.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/module.dart';
import '../../../data/models/assessment.dart';
import '../../../data/models/progress.dart';
import '../../../data/models/user.dart';
import '../quiz/quiz_screen.dart';

class LessonReaderScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const LessonReaderScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  ConsumerState<LessonReaderScreen> createState() => _LessonReaderScreenState();
}

class _LessonReaderScreenState extends ConsumerState<LessonReaderScreen> {
  bool _isLoading = true;
  Lesson? _lesson;
  Module? _module;
  List<Assessment> _assessments = [];
  Progress? _userProgress;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  Future<void> _loadLessonData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final database = ref.read(databaseProvider);
      final user = ref.read(currentUserProvider).value;

      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Load lesson data
      final lesson = await database.getLesson(widget.lessonId);
      if (lesson == null) {
        setState(() {
          _errorMessage = 'Lesson not found';
          _isLoading = false;
        });
        return;
      }

      // Load module data - we need to get it from the subject first
      Module? module;
      try {
        final subjects = await database.getSubjects();
        for (final subject in subjects) {
          final modules = await database.getModules(subject.id);
          final foundModule = modules.where((m) => m.id == lesson.moduleId).firstOrNull;
          if (foundModule != null) {
            module = foundModule;
            break;
          }
        }
      } catch (e) {
        // Module not found, continue without it
      }
      
      // Load assessments for this lesson - we need to get them from the module
      List<Assessment> assessments = [];
      if (module != null) {
        try {
          final moduleAssessments = await database.getAssessments(module.id);
          assessments = moduleAssessments.where((a) => a.lessonId == widget.lessonId).toList();
        } catch (e) {
          // Assessments not found, continue without them
        }
      }
      
      // Load user progress
      final progress = await database.getProgress(user.id, widget.lessonId);

      setState(() {
        _lesson = lesson;
        _module = module;
        _assessments = assessments;
        _userProgress = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading lesson: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz),
            onPressed: _assessments.isNotEmpty ? _startQuiz : null,
            tooltip: 'Take Quiz',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : _buildLessonContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.accentRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutralGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadLessonData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent() {
    if (_lesson == null) {
      return const Center(child: Text('Lesson not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.book,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lesson!.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkGray,
                            ),
                          ),
                          if (_module != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _module!.title,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.neutralGray,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.schedule,
                      '${_lesson!.estMins} min',
                      AppTheme.accentOrange,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.assessment,
                      '${_assessments.length} quizzes',
                      AppTheme.accentGreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lesson Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesson Content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _lesson!.bodyMarkdown ?? 'No content available for this lesson.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.darkGray,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Progress Section
          if (_userProgress != null) _buildProgressSection(),
          
          // Assessment Section
          if (_assessments.isNotEmpty) _buildAssessmentSection(),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    if (_userProgress == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                  'Status',
                  _getStatusText(_userProgress!.status),
                  _getStatusColor(_userProgress!.status),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressItem(
                  'Score',
                  '${_userProgress!.lastScore ?? 0}%',
                  AppTheme.accentGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutralGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Quizzes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          ..._assessments.map((assessment) => _buildAssessmentCard(assessment)),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(Assessment assessment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightGray,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.quiz,
              color: AppTheme.accentGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assessment ${assessment.id}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${assessment.items.length} questions',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.neutralGray,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.neutralGray,
            size: 16,
          ),
        ],
      ),
    );
  }

  String _getStatusText(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.locked:
        return 'Locked';
      case ProgressStatus.inProgress:
        return 'In Progress';
      case ProgressStatus.mastered:
        return 'Mastered';
    }
  }

  Color _getStatusColor(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.locked:
        return AppTheme.neutralGray;
      case ProgressStatus.inProgress:
        return AppTheme.primaryBlue;
      case ProgressStatus.mastered:
        return AppTheme.accentGreen;
    }
  }

  void _startQuiz() {
    if (_assessments.isNotEmpty) {
      final assessment = _assessments.first;
      context.push('/student/quiz/${assessment.id}');
    }
  }
} 