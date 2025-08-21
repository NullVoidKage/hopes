import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../data/db/database.dart';
import '../../../data/models/user.dart';
import '../../../data/models/subject.dart';
import '../../../data/models/module.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/progress.dart';
import '../../../data/models/points.dart';
import '../../../data/models/badge.dart';
import '../../../data/models/classroom.dart';
import '../../../data/models/content_version.dart';
import '../../../data/models/sync_queue.dart';
import '../../auth/role_select_screen.dart';
import '../lesson_reader/lesson_reader_screen.dart';
import '../quiz/quiz_screen.dart';
import '../progress/progress_screen.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(currentUserProvider);
    final database = ref.read(databaseProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text('HOPES Dashboard'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _showProfileDialog(context, userState.value),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleSignOut(),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
                  children: [
          _buildHomeTab(database),
          _buildSubjectsTab(database),
          _buildProgressTab(database),
          _buildProfileTab(database),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.neutralGray,
        backgroundColor: AppTheme.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Subjects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(Database database) {
    return FutureBuilder<List<Subject>>(
      future: database.getSubjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
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
                  'Error loading subjects',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your connection and try again',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.neutralGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
                    ),
                  );
                }

        final subjects = snapshot.data ?? [];

        if (subjects.isEmpty) {
          return Center(
      child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: AppTheme.neutralGray,
                ),
                const SizedBox(height: 16),
              Text(
                  'No subjects available',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Subjects will appear here once they are added',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.neutralGray,
                  ),
                  textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                        color: AppTheme.darkGray,
                      ),
                    ),
              const SizedBox(height: 8),
                    Text(
                'Continue your learning journey',
                      style: TextStyle(
                  fontSize: 16,
                        color: AppTheme.neutralGray,
                      ),
                    ),
              const SizedBox(height: 24),
              
              // Quick Stats
              _buildQuickStats(database),
              const SizedBox(height: 24),
              
              // Recent Subjects
              Text(
                'Your Subjects',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 16),
              
              // Subjects Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return _buildSubjectCard(subject, database);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(Database database) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Points',
            '0',
            Icons.stars,
            AppTheme.accentOrange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Lessons',
            '0',
            Icons.book,
            AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Badges',
            '0',
            Icons.emoji_events,
            AppTheme.accentPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
              Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutralGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject, Database database) {
    return GestureDetector(
      onTap: () => _navigateToSubject(subject, database),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.school,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subject.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGray,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Grade ${subject.gradeLevel}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutralGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectsTab(Database database) {
    return FutureBuilder<List<Subject>>(
      future: database.getSubjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
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
                  'Error loading subjects',
                style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        final subjects = snapshot.data ?? [];

        if (subjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: AppTheme.neutralGray,
                ),
                const SizedBox(height: 16),
                Text(
                  'No subjects available',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return _buildSubjectListItem(subject, database);
          },
        );
      },
    );
  }

  Widget _buildSubjectListItem(Subject subject, Database database) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.school,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
        ),
        title: Text(
          subject.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGray,
          ),
        ),
        subtitle: Text(
          'Grade ${subject.gradeLevel}',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.neutralGray,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.neutralGray,
          size: 16,
        ),
        onTap: () => _navigateToSubject(subject, database),
      ),
    );
  }

  Widget _buildProgressTab(Database database) {
    return const Center(
      child: Text(
        'Progress Tab - Coming Soon',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildProfileTab(Database database) {
    return const Center(
      child: Text(
        'Profile Tab - Coming Soon',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  void _navigateToSubject(Subject subject, Database database) {
    // Navigate to subject detail page
    // This would show modules and lessons for the subject
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${subject.name}...'),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, User? user) {
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${user.name}'),
            Text('Email: ${user.email}'),
            Text('Role: ${user.role.toString().split('.').last}'),
            Text('Section: ${user.section}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleSignOut() async {
    try {
      await ref.read(currentUserProvider.notifier).signOut();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }
} 