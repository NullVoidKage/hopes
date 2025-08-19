import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../data/models/user.dart';
import '../../../../data/models/progress.dart';
import '../../../../data/models/attempt.dart';
import '../../../../data/models/points.dart';
import '../../../../data/models/badge.dart';

class StudentProgressWidget extends ConsumerWidget {
  const StudentProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Progress'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Class Overview'),
              Tab(text: 'Individual Students'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ClassOverviewTab(),
            _IndividualStudentsTab(),
          ],
        ),
      ),
    );
  }
}

class _ClassOverviewTab extends ConsumerWidget {
  const _ClassOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<User>>(
      future: _getStudents(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final students = snapshot.data ?? [];
        if (students.isEmpty) {
          return const Center(child: Text('No students found'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildClassStats(context, ref, students),
            const SizedBox(height: 24),
            _buildSubjectProgress(context, ref),
          ],
        );
      },
    );
  }

  Future<List<User>> _getStudents(WidgetRef ref) async {
    // For demo purposes, create some dummy students
    return [
      const User(
        id: 'student1',
        name: 'Alice Johnson',
        email: 'alice@example.com',
        role: UserRole.student,
        section: '7A',
      ),
      const User(
        id: 'student2',
        name: 'Bob Smith',
        email: 'bob@example.com',
        role: UserRole.student,
        section: '7A',
      ),
      const User(
        id: 'student3',
        name: 'Carol Davis',
        email: 'carol@example.com',
        role: UserRole.student,
        section: '7A',
      ),
    ];
  }

  Widget _buildClassStats(BuildContext context, WidgetRef ref, List<User> students) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class Statistics',
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
                    'Total Students',
                    students.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Active Students',
                    '${(students.length * 0.85).round()}',
                    Icons.person,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Avg. Score',
                    '78%',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Lessons Completed',
                    '${(students.length * 12).round()}',
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
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
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgress(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSubjectProgressBar(context, 'Science', 0.75, Colors.green),
            const SizedBox(height: 8),
            _buildSubjectProgressBar(context, 'Mathematics', 0.60, Colors.blue),
            const SizedBox(height: 8),
            _buildSubjectProgressBar(context, 'English', 0.85, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectProgressBar(BuildContext context, String subject, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(subject),
            Text('${(progress * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}

class _IndividualStudentsTab extends ConsumerWidget {
  const _IndividualStudentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<User>>(
      future: _getStudents(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final students = snapshot.data ?? [];
        if (students.isEmpty) {
          return const Center(child: Text('No students found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            return _buildStudentCard(context, ref, students[index]);
          },
        );
      },
    );
  }

  Future<List<User>> _getStudents(WidgetRef ref) async {
    // Same dummy students as above
    return [
      const User(
        id: 'student1',
        name: 'Alice Johnson',
        email: 'alice@example.com',
        role: UserRole.student,
        section: '7A',
      ),
      const User(
        id: 'student2',
        name: 'Bob Smith',
        email: 'bob@example.com',
        role: UserRole.student,
        section: '7A',
      ),
      const User(
        id: 'student3',
        name: 'Carol Davis',
        email: 'carol@example.com',
        role: UserRole.student,
        section: '7A',
      ),
    ];
  }

  Widget _buildStudentCard(BuildContext context, WidgetRef ref, User student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(student.email),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStudentStats(context, student),
                const SizedBox(height: 16),
                _buildStudentBadges(context, student),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentStats(BuildContext context, User student) {
    return Row(
      children: [
        Expanded(
          child: _buildStudentStat(
            context,
            'Lessons Completed',
            '8/12',
            Icons.book,
          ),
        ),
        Expanded(
          child: _buildStudentStat(
            context,
            'Average Score',
            '82%',
            Icons.trending_up,
          ),
        ),
        Expanded(
          child: _buildStudentStat(
            context,
            'Points Earned',
            '450',
            Icons.stars,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentStat(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStudentBadges(BuildContext context, User student) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges Earned',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildBadgeChip(context, 'Starter Badge', Colors.green),
            _buildBadgeChip(context, 'Achiever Badge', Colors.blue),
            _buildBadgeChip(context, 'Consistency Badge', Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildBadgeChip(BuildContext context, String badgeName, Color color) {
    return Chip(
      label: Text(
        badgeName,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      avatar: Icon(Icons.emoji_events, color: Colors.white, size: 16),
    );
  }
} 