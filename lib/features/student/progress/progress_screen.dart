import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../data/models/user.dart';
import '../../../data/models/progress.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/attempt.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentUserProvider);
    final progressRepo = ref.watch(progressRepositoryProvider);
    final assessmentRepo = ref.watch(assessmentRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student/dashboard'),
        ),
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user found'));
          }

          return FutureBuilder<List<Progress>>(
            future: progressRepo.getProgressByUser(user.id),
            builder: (context, progressSnapshot) {
              if (progressSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (progressSnapshot.hasError) {
                return Center(child: Text('Error: ${progressSnapshot.error}'));
              }

              final progressList = progressSnapshot.data ?? [];

              return FutureBuilder<List<Attempt>>(
                future: assessmentRepo.getAttemptsByUser(user.id),
                builder: (context, attemptsSnapshot) {
                  final attempts = attemptsSnapshot.data ?? [];
                  final totalAttempts = attempts.length;
                  final averageScore = attempts.isNotEmpty
                      ? attempts.map((a) => a.score).reduce((a, b) => a + b) / attempts.length
                      : 0.0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress Overview
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progress Overview',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        context,
                                        'Total Attempts',
                                        totalAttempts.toString(),
                                        Icons.quiz,
                                        Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatCard(
                                        context,
                                        'Average Score',
                                        '${averageScore.round()}%',
                                        Icons.trending_up,
                                        Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Progress Details
                        Text(
                          'Lesson Progress',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (progressList.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No progress data available. Start learning to see your progress!'),
                            ),
                          )
                        else
                          ...progressList.map((progress) => _buildProgressCard(context, progress)),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, Progress progress) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getStatusIcon(progress.status),
        title: Text('Lesson ${progress.lessonId}'), // In a real app, you'd fetch the lesson title
        subtitle: progress.lastScore != null
            ? Text('Last Score: ${progress.lastScore!.round()}%')
            : null,
        trailing: _getStatusChip(progress.status),
      ),
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