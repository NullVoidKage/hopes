import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/progress.dart';
import '../../../data/models/user.dart';

class LessonReaderScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonReaderScreen({super.key, required this.lessonId});

  @override
  ConsumerState<LessonReaderScreen> createState() => _LessonReaderScreenState();
}

class _LessonReaderScreenState extends ConsumerState<LessonReaderScreen> {
  @override
  Widget build(BuildContext context) {
    final contentRepo = ref.watch(contentRepositoryProvider);
    final authState = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz),
            onPressed: () => _navigateToQuiz(),
          ),
        ],
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user found'));
          }

          return FutureBuilder<Lesson?>(
            future: contentRepo.getLesson(widget.lessonId),
            builder: (context, lessonSnapshot) {
              if (lessonSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (lessonSnapshot.hasError) {
                return Center(child: Text('Error: ${lessonSnapshot.error}'));
              }

              final lesson = lessonSnapshot.data;
              if (lesson == null) {
                return const Center(child: Text('Lesson not found'));
              }

              return Column(
                children: [
                  // Lesson Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${lesson.estMins} minutes',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Lesson Content
                  Expanded(
                    child: Markdown(
                      data: lesson.bodyMarkdown,
                      padding: const EdgeInsets.all(16),
                      styleSheet: MarkdownStyleSheet(
                        h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        h2: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        h3: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        p: Theme.of(context).textTheme.bodyLarge,
                        listBullet: Theme.of(context).textTheme.bodyLarge,
                        strong: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _markAsInProgress(user),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Mark as In Progress'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToQuiz(),
                            icon: const Icon(Icons.quiz),
                            label: const Text('Take Quiz'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _markAsInProgress(User user) async {
    final progressRepo = ref.read(progressRepositoryProvider);
    
    try {
      await progressRepo.updateProgress(
        userId: user.id,
        lessonId: widget.lessonId,
        status: ProgressStatus.inProgress,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson marked as in progress'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToQuiz() {
    // Find the quiz for this lesson
    final assessmentRepo = ref.read(assessmentRepositoryProvider);
    assessmentRepo.getAssessmentsByLesson(widget.lessonId).then((assessments) {
      if (assessments.isNotEmpty) {
        final quiz = assessments.firstWhere(
          (a) => a.type.toString() == 'AssessmentType.quiz',
          orElse: () => assessments.first,
        );
        context.go('/student/quiz/${quiz.id}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No quiz available for this lesson'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }
} 