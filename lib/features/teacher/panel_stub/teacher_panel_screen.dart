import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../data/models/user.dart';
import '../../../data/models/subject.dart';
import '../../../data/models/module.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/assessment.dart';
import '../../../data/models/points.dart';
import '../../../data/models/badge.dart';
import '../../../data/repos/assessment_repository.dart';
import '../../../services/sync/content_sync_service.dart';
import '../../../services/sync/progress_sync_service.dart';
import 'widgets/lesson_editor.dart';
import 'widgets/quiz_editor.dart';
import 'widgets/student_progress_widget.dart';

class TeacherPanelScreen extends ConsumerWidget {
  const TeacherPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentUserProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('No user found')),
          );
        }

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Teacher Panel'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Subjects'),
                  Tab(text: 'Lessons'),
                  Tab(text: 'Quizzes'),
                  Tab(text: 'Progress'),
                ],
              ),
              actions: [
                _buildSyncStatusIcon(ref),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'switch_role') {
                      await ref.read(currentUserProvider.notifier).updateRole(UserRole.student);
                    } else if (value == 'sign_out') {
                      await ref.read(currentUserProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go('/');
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'switch_role',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz),
                          SizedBox(width: 8),
                          Text('Switch to Student'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'sign_out',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: TabBarView(
              children: [
                _SubjectsTab(),
                _LessonsTab(),
                _QuizzesTab(),
                const StudentProgressWidget(),
              ],
            ),
            floatingActionButton: _buildFloatingActionButton(context, ref),
          ),
        );
      },
    );
  }

  Widget _buildSyncStatusIcon(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        // For now, show green sync status (simulating online)
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Icon(
            Icons.sync,
            color: Colors.green,
            size: 20,
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final tabController = DefaultTabController.of(context);
        final currentIndex = tabController?.index ?? 0;
        
        switch (currentIndex) {
          case 0: // Subjects
            return FloatingActionButton(
              onPressed: () => _showSubjectDialog(context, ref),
              child: const Icon(Icons.add),
            );
          case 1: // Lessons
            return FloatingActionButton(
              onPressed: () => _showLessonDialog(context, ref),
              child: const Icon(Icons.add),
            );
          case 2: // Quizzes
            return FloatingActionButton(
              onPressed: () => _showQuizDialog(context, ref),
              child: const Icon(Icons.add),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  void _showSubjectDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Subject'),
        content: const Text('Subject creation feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLessonDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Lesson'),
        content: const Text('Please select a module first to create a lesson.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showQuizDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Quiz'),
        content: const Text('Please select a lesson first to create a quiz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SubjectsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentRepo = ref.watch(contentRepositoryProvider);
    
    return FutureBuilder<List<Subject>>(
      future: contentRepo.getSubjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final subjects = snapshot.data ?? [];
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.science),
                title: Text(subject.name),
                subtitle: Text('Grade ${subject.gradeLevel}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    // Handle subject actions
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LessonsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentRepo = ref.watch(contentRepositoryProvider);
    
    return FutureBuilder<List<Subject>>(
      future: contentRepo.getSubjects(),
      builder: (context, subjectsSnapshot) {
        if (subjectsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final subjects = subjectsSnapshot.data ?? [];
        if (subjects.isEmpty) {
          return const Center(child: Text('No subjects available'));
        }

        return FutureBuilder<List<Module>>(
          future: contentRepo.getModulesBySubject(subjects.first.id),
          builder: (context, modulesSnapshot) {
            if (modulesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final modules = modulesSnapshot.data ?? [];
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                return Card(
                  child: ExpansionTile(
                    title: Text(module.title),
                    subtitle: Text('Version: ${module.version}'),
                    children: [
                      FutureBuilder<List<Lesson>>(
                        future: contentRepo.getLessonsByModule(module.id),
                        builder: (context, lessonsSnapshot) {
                          final lessons = lessonsSnapshot.data ?? [];
                          
                          return Column(
                            children: lessons.map((lesson) => ListTile(
                              title: Text(lesson.title),
                              subtitle: Text('${lesson.estMins} minutes'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editLesson(context, lesson),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteLesson(context, ref, lesson),
                                  ),
                                ],
                              ),
                            )).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _editLesson(BuildContext context, Lesson lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LessonEditor(lesson: lesson, moduleId: lesson.moduleId),
      ),
    );
  }

  void _deleteLesson(BuildContext context, WidgetRef ref, Lesson lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Are you sure you want to delete "${lesson.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // TODO: Implement delete lesson
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _QuizzesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentRepo = ref.watch(assessmentRepositoryProvider);
    
    return FutureBuilder<List<Assessment>>(
      future: _getAllQuizzes(assessmentRepo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final quizzes = snapshot.data ?? [];
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.quiz),
                title: Text('Quiz ${index + 1}'),
                subtitle: Text('${quiz.items.length} questions'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editQuiz(context, quiz),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteQuiz(context, ref, quiz),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Assessment>> _getAllQuizzes(AssessmentRepository assessmentRepo) async {
    // For demo purposes, return empty list
    return [];
  }

  void _editQuiz(BuildContext context, Assessment quiz) {
    // TODO: Implement edit quiz
  }

  void _deleteQuiz(BuildContext context, WidgetRef ref, Assessment quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: const Text('Are you sure you want to delete this quiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // TODO: Implement delete quiz
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 