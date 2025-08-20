import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
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
                        Container(
                          width: double.infinity,
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.trending_up,
                                      color: AppTheme.primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Progress Overview',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkGray,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      'Total Attempts',
                                      totalAttempts.toString(),
                                      Icons.quiz,
                                      AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      'Average Score',
                                      '${averageScore.round()}%',
                                      Icons.trending_up,
                                      AppTheme.accentGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGray,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.lightGray,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.neutralGray,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No progress data available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start learning to see your progress!',
                                  style: TextStyle(
                                    color: AppTheme.neutralGray,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.neutralGray,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, Progress progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(progress.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _getStatusIcon(progress.status),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesson ${progress.lessonId}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
                if (progress.lastScore != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last Score: ${progress.lastScore!.round()}%',
                    style: TextStyle(
                      color: AppTheme.neutralGray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _getStatusChip(progress.status),
        ],
      ),
    );
  }

  Widget _getStatusIcon(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.locked:
        return const Icon(Icons.lock, color: AppTheme.neutralGray);
      case ProgressStatus.inProgress:
        return const Icon(Icons.play_circle, color: AppTheme.primaryBlue);
      case ProgressStatus.mastered:
        return const Icon(Icons.check_circle, color: AppTheme.accentGreen);
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

  Widget _getStatusChip(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.locked:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.neutralGray.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.neutralGray.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Locked',
            style: TextStyle(
              color: AppTheme.neutralGray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case ProgressStatus.inProgress:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'In Progress',
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case ProgressStatus.mastered:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Mastered',
            style: TextStyle(
              color: AppTheme.accentGreen,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }
} 