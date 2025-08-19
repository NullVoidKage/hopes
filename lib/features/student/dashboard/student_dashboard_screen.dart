import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../data/models/user.dart';
import '../../../data/models/subject.dart';
import '../../../data/models/module.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/progress.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentUserProvider);
    final contentRepo = ref.watch(contentRepositoryProvider);
    final progressRepo = ref.watch(progressRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/student/progress'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'switch_role') {
                await ref.read(currentUserProvider.notifier).updateRole(UserRole.teacher);
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
                    Text('Switch to Teacher'),
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
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user found'));
          }

          return FutureBuilder<List<Subject>>(
            future: contentRepo.getSubjects(),
            builder: (context, subjectsSnapshot) {
              if (subjectsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (subjectsSnapshot.hasError) {
                return Center(child: Text('Error: ${subjectsSnapshot.error}'));
              }

              final subjects = subjectsSnapshot.data ?? [];
              if (subjects.isEmpty) {
                return const Center(child: Text('No subjects available'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${user.name}!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ready to learn? Let\'s get started with your lessons.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pre-assessment Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.quiz,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pre-Assessment',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Take the pre-assessment to determine your learning track',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => context.go('/student/quiz/pretest'),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Pre-Assessment'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subjects Section
                    Text(
                      'Available Subjects',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...subjects.map((subject) => _buildSubjectCard(context, ref, subject, user)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, WidgetRef ref, Subject subject, User user) {
    final contentRepo = ref.watch(contentRepositoryProvider);
    final progressRepo = ref.watch(progressRepositoryProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subject.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<Module>>(
              future: contentRepo.getModulesBySubject(subject.id),
              builder: (context, modulesSnapshot) {
                if (modulesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final modules = modulesSnapshot.data ?? [];
                if (modules.isEmpty) {
                  return const Text('No modules available');
                }

                return Column(
                  children: modules.map((module) => _buildModuleCard(context, ref, module, user)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, WidgetRef ref, Module module, User user) {
    final contentRepo = ref.watch(contentRepositoryProvider);
    final progressRepo = ref.watch(progressRepositoryProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              module.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            FutureBuilder<List<Lesson>>(
              future: contentRepo.getLessonsByModule(module.id),
              builder: (context, lessonsSnapshot) {
                if (lessonsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final lessons = lessonsSnapshot.data ?? [];
                if (lessons.isEmpty) {
                  return const Text('No lessons available');
                }

                return Column(
                  children: lessons.map((lesson) => _buildLessonTile(context, ref, lesson, user)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonTile(BuildContext context, WidgetRef ref, Lesson lesson, User user) {
    final progressRepo = ref.watch(progressRepositoryProvider);

    return FutureBuilder<Progress?>(
      future: progressRepo.getProgress(user.id, lesson.id),
      builder: (context, progressSnapshot) {
        final progress = progressSnapshot.data;
        final status = progress?.status ?? ProgressStatus.locked;

        return ListTile(
          leading: _getStatusIcon(status),
          title: Text(lesson.title),
          subtitle: Text('${lesson.estMins} minutes'),
          trailing: _getStatusChip(status),
          onTap: status != ProgressStatus.locked
              ? () => context.go('/student/lesson/${lesson.id}')
              : null,
        );
      },
    );
  }

  Widget _getStatusIcon(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.locked:
        return const Icon(Icons.lock, color: Colors.grey);
      case ProgressStatus.inProgress:
        return const Icon(Icons.play_circle, color: Colors.blue);
      case ProgressStatus.mastered:
        return const Icon(Icons.check_circle, color: Colors.green);
    }
  }

  Widget _getStatusChip(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.locked:
        return const Chip(
          label: Text('Locked'),
          backgroundColor: Colors.grey,
          labelStyle: TextStyle(color: Colors.white),
        );
      case ProgressStatus.inProgress:
        return const Chip(
          label: Text('In Progress'),
          backgroundColor: Colors.blue,
          labelStyle: TextStyle(color: Colors.white),
        );
      case ProgressStatus.mastered:
        return const Chip(
          label: Text('Mastered'),
          backgroundColor: Colors.green,
          labelStyle: TextStyle(color: Colors.white),
        );
    }
  }
} 