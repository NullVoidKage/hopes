import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../data/models/user.dart';
import '../../../data/models/subject.dart';
import '../../../data/models/module.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/progress.dart';
import '../../../data/models/points.dart';
import '../../../data/models/badge.dart' as models;
import '../../../services/sync/progress_sync_service.dart';

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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.1),
                            AppTheme.secondaryBlue.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.school,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back,',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.neutralGray,
                                      ),
                                    ),
                                    Text(
                                      user.name,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ready to continue your learning journey?',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.neutralGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pre-assessment Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.accentGreen.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.quiz,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Pre-Assessment',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Take the pre-assessment to determine your learning track',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.neutralGray,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/student/quiz/pretest'),
                              icon: const Icon(Icons.play_arrow, size: 20),
                              label: const Text('Start Pre-Assessment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gamification Section
                    _buildGamificationCard(context, ref, user),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    Icons.science,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subject.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGray,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<Module>>(
              future: contentRepo.getModulesBySubject(subject.id),
              builder: (context, modulesSnapshot) {
                if (modulesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final modules = modulesSnapshot.data ?? [];
                if (modules.isEmpty) {
                  return Text(
                    'No modules available',
                    style: TextStyle(
                      color: AppTheme.neutralGray,
                      fontStyle: FontStyle.italic,
                    ),
                  );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder,
                color: AppTheme.primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                module.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<Lesson>>(
            future: contentRepo.getLessonsByModule(module.id),
            builder: (context, lessonsSnapshot) {
              if (lessonsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final lessons = lessonsSnapshot.data ?? [];
              if (lessons.isEmpty) {
                return Text(
                  'No lessons available',
                  style: TextStyle(
                    color: AppTheme.neutralGray,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                );
              }

              return Column(
                children: lessons.map((lesson) => _buildLessonTile(context, ref, lesson, user)).toList(),
              );
            },
          ),
        ],
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

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _getStatusColor(status).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _getStatusIcon(status),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lesson.estMins} minutes',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutralGray,
                      ),
                    ),
                  ],
                ),
              ),
              _getStatusChip(status),
            ],
          ),
        );
      },
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

  Widget _buildGamificationCard(BuildContext context, WidgetRef ref, User user) {
    return Container(
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
                  color: AppTheme.accentPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.stars,
                  color: AppTheme.accentPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'My Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                child: _buildPointsWidget(context, ref, user),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBadgesWidget(context, ref, user),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointsWidget(BuildContext context, WidgetRef ref, User user) {
    return FutureBuilder<Points?>(
      future: _getUserPoints(ref, user.id),
      builder: (context, snapshot) {
        final points = snapshot.data?.totalPoints ?? 0;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentOrange.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                points.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentOrange,
                ),
              ),
              Text(
                'Points',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.neutralGray,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadgesWidget(BuildContext context, WidgetRef ref, User user) {
    return FutureBuilder<List<models.Badge>>(
      future: _getUserBadges(ref, user.id),
      builder: (context, snapshot) {
        final badges = snapshot.data ?? [];
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentPurple.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badges.length.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentPurple,
                ),
              ),
              Text(
                'Badges',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.neutralGray,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Points?> _getUserPoints(WidgetRef ref, String userId) async {
    try {
      final database = ref.read(databaseProvider);
      final points = await (database.select(database.points)
            ..where((tbl) => tbl.userId.equals(userId)))
          .getSingleOrNull();
      
      if (points != null) {
        return Points(
          userId: points.userId,
          totalPoints: points.totalPoints,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<models.Badge>> _getUserBadges(WidgetRef ref, String userId) async {
    try {
      final database = ref.read(databaseProvider);
      final userBadges = await (database.select(database.userBadges)
            ..where((tbl) => tbl.userId.equals(userId)))
          .get();
      
      final badgeIds = userBadges.map((ub) => ub.badgeId).toList();
      if (badgeIds.isEmpty) return [];
      
      final badges = await (database.select(database.badges)
            ..where((tbl) => tbl.id.isIn(badgeIds)))
          .get();
      
      return badges.map((b) => models.Badge(
        id: b.id,
        name: b.name,
        ruleJson: jsonDecode(b.ruleJson),
      )).toList();
    } catch (e) {
      return [];
    }
  }
} 