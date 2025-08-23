import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/teacher_dashboard_service.dart';
import 'lesson_upload_screen.dart';
import 'lesson_library_screen.dart';

class TeacherPanel extends StatefulWidget {
  const TeacherPanel({super.key});

  @override
  State<TeacherPanel> createState() => _TeacherPanelState();
}

class _TeacherPanelState extends State<TeacherPanel> {
  final AuthService _authService = AuthService();
  final TeacherDashboardService _dashboardService = TeacherDashboardService();
  UserModel? _userProfile;
  TeacherDashboardData? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final profile = await _authService.getUserProfile(user.uid);
        if (profile != null) {
          final dashboardData = await _dashboardService.getDashboardData(
            user.uid,
            profile.subjects ?? [],
          );
          setState(() {
            _userProfile = profile;
            _dashboardData = dashboardData;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Apple's light gray background
      appBar: AppBar(
        title: const Text(
          'Teacher Dashboard',
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF007AFF),
              ),
              onPressed: () {
                final navigator = Navigator.of(context);
                _authService.signOut().then((_) {
                  if (mounted) {
                    navigator.pushReplacementNamed('/');
                  }
                });
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                _buildWelcomeHeader(),
                
                const SizedBox(height: 32),
                
                // Quick Actions Grid
                _buildQuickActions(),
                
                const SizedBox(height: 32),
                
                // Student Progress Overview
                _buildStudentProgressOverview(),
                
                const SizedBox(height: 30),
                
                // Recent Activities
                _buildRecentActivities(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: _userProfile?.photoURL != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    child: Image.network(
                      _userProfile!.photoURL!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.school_rounded,
                    size: 40,
                    color: Color(0xFF007AFF),
                  ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${_userProfile?.displayName ?? 'Teacher'}!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to inspire your students today?',
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF86868B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    border: Border.all(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Subjects: ${_userProfile?.subjects?.join(', ') ?? 'Not specified'}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildActionCard(
              'Upload Lessons',
              Icons.upload_file_rounded,
              'Add new learning content',
              () => _navigateToLessonUpload(),
            ),
            _buildActionCard(
              'My Lessons',
              Icons.library_books_rounded,
              'View and manage lessons',
              () => _navigateToLessonLibrary(),
            ),
            _buildActionCard(
              'Monitor Progress',
              Icons.analytics_rounded,
              'Track student performance',
              () => _navigateToProgressMonitoring(),
            ),
            _buildActionCard(
              'Create Assessments',
              Icons.quiz_rounded,
              'Design tests and quizzes',
              () => _navigateToAssessmentCreation(),
            ),
            _buildActionCard(
              'Student Management',
              Icons.people_rounded,
              'Manage your students',
              () => _navigateToStudentManagement(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, String description, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: Icon(
                icon,
                size: 32,
                color: const Color(0xFF007AFF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF86868B),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentProgressOverview() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF007AFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Student Progress Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildProgressStat(
                  'Total Students', 
                  '${_dashboardData?.totalStudents ?? 0}', 
                  Icons.people_rounded
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  'Active Students', 
                  '${_dashboardData?.activeStudents ?? 0}', 
                  Icons.person_rounded
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  'Avg. Progress', 
                  '${(_dashboardData?.averageProgress ?? 0.0).round()}%', 
                  Icons.trending_up_rounded
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_dashboardData?.studentProgress.isNotEmpty == true)
            ..._buildSubjectProgressList()
          else
            _buildEmptyState('No student progress data yet', 'Students will appear here once they start learning'),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withValues(alpha: 0.1),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF007AFF),
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF86868B),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget> _buildSubjectProgressList() {
    final userSubjects = _userProfile?.subjects ?? [];
    final progressData = _dashboardData?.studentProgress ?? [];
    
    if (userSubjects.isEmpty) {
      return [
        const Center(
          child: Text(
            'No subjects assigned',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ];
    }

    final List<Widget> widgets = [];
    
    for (int i = 0; i < userSubjects.length; i++) {
      final subject = userSubjects[i];
      final subjectProgress = progressData
          .where((p) => p.subject == subject)
          .toList();
      
      double averageProgress = 0.0;
      if (subjectProgress.isNotEmpty) {
        averageProgress = subjectProgress
            .map((p) => p.progressPercentage)
            .reduce((a, b) => a + b) / subjectProgress.length;
      }
      
      widgets.add(_buildSubjectProgress(
        subject, 
        averageProgress / 100, 
        '${averageProgress.round()}%'
      ));
      
      if (i < userSubjects.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }
    
    return widgets;
  }

  List<Widget> _buildRecentActivitiesList() {
    final activities = _dashboardData?.recentActivities ?? [];
    
    if (activities.isEmpty) {
      return [
        const Center(
          child: Text(
            'No recent activities',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ];
    }

    final List<Widget> widgets = [];
    
    for (int i = 0; i < activities.length; i++) {
      final activity = activities[i];
      
      widgets.add(_buildActivityItem(
        activity.title,
        activity.subject,
        activity.displayTime,
        _getIconFromString(activity.iconName),
        Color(activity.colorValue),
      ));
      
      if (i < activities.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }
    
    return widgets;
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'upload_file_rounded':
        return Icons.upload_file_rounded;
      case 'assignment_rounded':
        return Icons.assignment_rounded;
      case 'grade_rounded':
        return Icons.grade_rounded;
      case 'analytics_rounded':
        return Icons.analytics_rounded;
      case 'people_rounded':
        return Icons.people_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Widget _buildSubjectProgress(String subject, double progress, String percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
            Text(
              percentage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF007AFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: const Color(0xFF86868B),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF007AFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_dashboardData?.recentActivities.isNotEmpty == true)
            ..._buildRecentActivitiesList()
          else
            _buildEmptyState('No recent activities', 'Your activities will appear here once you start using the platform'),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String category, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF86868B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              border: Border.all(
                color: const Color(0xFFE5E5E7),
                width: 1,
              ),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF86868B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToLessonUpload() {
    if (_userProfile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LessonUploadScreen(
            teacherProfile: _userProfile!,
          ),
        ),
      );
    }
  }

  void _navigateToLessonLibrary() {
    if (_userProfile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LessonLibraryScreen(
            teacherProfile: _userProfile!,
          ),
        ),
      );
    }
  }

  void _navigateToProgressMonitoring() {
    // TODO: Navigate to progress monitoring screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress monitoring coming soon!')),
    );
  }

  void _navigateToAssessmentCreation() {
    // TODO: Navigate to assessment creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Assessment creation coming soon!')),
    );
  }

  void _navigateToStudentManagement() {
    // TODO: Navigate to student management screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student management coming soon!')),
    );
  }
}
