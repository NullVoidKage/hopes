import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/teacher_dashboard_service.dart';
import '../services/offline_service.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/safe_network_image.dart';
import 'lesson_upload_screen.dart';
import 'lesson_library_screen.dart';
import 'assessment_creation_screen.dart';
import 'assessment_management_screen.dart';
import 'monitor_progress_screen.dart';
import 'student_management_screen.dart';
import 'offline_settings_screen.dart';
import 'learning_path_creation_screen.dart';
import 'learning_path_management_screen.dart';
import 'learning_path_assignment_screen.dart';
import 'learning_path_overview_screen.dart';
import '../services/connectivity_service.dart';

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

  // Safe method to check connectivity status
  bool _isOffline() {
    try {
      return !ConnectivityService().isConnected;
    } catch (e) {
      return false; // Default to online if there's an error
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: Color(0xFF1D1D1F),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        elevation: 0,
        shadowColor: const Color(0xFF000000).withValues(alpha: 0.04),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          // Simplified offline indicator - just one clear button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: ConnectivityService().isConnected 
                ? const Color(0xFFF5F5F7) 
                : const Color(0xFFFF9500).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: !ConnectivityService().isConnected 
                ? Border.all(color: const Color(0xFFFF9500), width: 1)
                : null,
            ),
            child: IconButton(
              icon: Icon(
                ConnectivityService().isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: ConnectivityService().isConnected ? Colors.green : const Color(0xFFFF9500),
                size: 22,
              ),
              onPressed: () => _toggleOfflineMode(),
              tooltip: ConnectivityService().isConnected ? 'Go Offline' : 'Go Online',
            ),
          ),
          // Fix Students button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.build_rounded,
                color: Color(0xFF34C759),
                size: 22,
              ),
              onPressed: () => _fixExistingStudents(),
              tooltip: 'Fix Existing Students',
            ),
          ),
          // Settings button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.settings_rounded,
                color: Color(0xFF007AFF),
                size: 22,
              ),
              onPressed: () => _navigateToOfflineSettings(),
              tooltip: 'Settings',
            ),
          ),
          // Logout button
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
                size: 22,
              ),
              onPressed: () {
                final navigator = Navigator.of(context);
                _authService.signOut().then((_) {
                  if (mounted) {
                    navigator.pushReplacementNamed('/');
                  }
                });
              },
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Offline indicator
            const OfflineIndicator(),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Header
                      _buildWelcomeHeader(),
                      
                      const SizedBox(height: 24),
                      
                      // Quick Actions Grid
                      _buildQuickActions(),
                      
                      const SizedBox(height: 24),
                      
                      // Student Progress Overview
                      _buildStudentProgressOverview(),
                      
                      const SizedBox(height: 24),
                      
                      // Recent Activities
                      _buildRecentActivities(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                ),
                child: _userProfile?.photoURL != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(18)),
                        child: SafeNetworkImage(
                          imageUrl: _userProfile!.photoURL!,
                          fit: BoxFit.cover,
                          fallback: const Icon(
                            Icons.school_rounded,
                            size: 36,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.school_rounded,
                        size: 36,
                        color: Color(0xFF007AFF),
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${_userProfile?.displayName ?? 'Teacher'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ready to inspire your students today?',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF86868B),
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        border: Border.all(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Subjects: ${_userProfile?.subjects?.join(', ') ?? 'Not specified'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF007AFF),
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          

        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.3,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 20),
        // Use a more flexible layout instead of fixed GridView
        Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildActionCard(
                  'Upload Lessons',
                  Icons.upload_file_rounded,
                  'Add new content',
                  () => _navigateToLessonUpload(),
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildActionCard(
                  'My Lessons',
                  Icons.library_books_rounded,
                  'View and manage',
                  () => _navigateToLessonLibrary(),
                )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildActionCard(
                  'Monitor Progress',
                  Icons.analytics_rounded,
                  'Track performance',
                  () => _navigateToProgressMonitoring(),
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildActionCard(
                  'Create Assessments',
                  Icons.quiz_rounded,
                  'Design tests',
                  () => _navigateToAssessmentCreation(),
                )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildActionCard(
                  'Student Management',
                  Icons.people_rounded,
                  'Manage students',
                  () => _navigateToStudentManagement(),
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildActionCard(
                  'Learning Paths',
                  Icons.layers_rounded,
                  'Create & assign',
                  () => _navigateToLearningPathManagement(),
                )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildActionCard(
                  'Assign Paths',
                  Icons.assignment_rounded,
                  'Assign to students',
                  () => _navigateToLearningPathAssignment(),
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildActionCard(
                  'Path Overview',
                  Icons.analytics_rounded,
                  'Track assignments',
                  () => _navigateToLearningPathOverview(),
                )),
              ],
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
        padding: const EdgeInsets.all(16),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Icon(
                icon,
                size: 24,
                color: const Color(0xFF007AFF),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF86868B),
                height: 1.2,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentProgressOverview() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Expanded(
                child: Text(
                  'Student Progress Overview',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
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
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.4,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86868B),
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
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
            .map((p) => p.completionRate)
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
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.2,
              ),
            ),
            Text(
              percentage,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF007AFF),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: const BorderRadius.all(Radius.circular(3)),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: const BorderRadius.all(Radius.circular(3)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            size: 40,
            color: const Color(0xFF86868B),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF86868B),
              letterSpacing: -0.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Expanded(
                child: Text(
                  'Recent Activities',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(16),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF86868B),
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(
                color: const Color(0xFFE5E5E7),
                width: 1,
              ),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF86868B),
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MonitorProgressScreen(),
      ),
    );
  }

  void _navigateToAssessmentCreation() {
    if (_userProfile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AssessmentManagementScreen(
            teacherProfile: _userProfile!,
          ),
        ),
      );
    }
  }

  void _navigateToStudentManagement() {
    if (_userProfile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StudentManagementScreen(
            teacherProfile: _userProfile!,
          ),
        ),
      );
    }
  }

  void _navigateToLearningPathManagement() {
    if (_userProfile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LearningPathManagementScreen(
            teacherProfile: _userProfile!,
          ),
        ),
      );
    }
  }

  void _navigateToLearningPathAssignment() {
    if (_userProfile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LearningPathAssignmentScreen(
            teacherProfile: _userProfile!,
          ),
        ),
      );
    }
  }

  void _navigateToLearningPathOverview() {
    if (_userProfile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LearningPathOverviewScreen(
            teacherProfile: _userProfile!,
          ),
        ),
      );
    }
  }

  void _navigateToOfflineSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OfflineSettingsScreen(),
      ),
    );
  }

  void _toggleOfflineMode() {
    ConnectivityService().toggleOfflineMode();
    setState(() {}); // Refresh the UI to show the new icon
  }

  // Fix existing students who don't have subjects
  Future<void> _fixExistingStudents() async {
    try {
      setState(() => _isLoading = true);
      
      await _authService.fixExistingStudents();
      
      // Refresh the dashboard data
      if (_userProfile != null) {
        final dashboardData = await _dashboardService.getDashboardData(
          _authService.currentUser!.uid,
          _userProfile!.subjects ?? [],
        );
        setState(() {
          _dashboardData = dashboardData;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Existing students fixed successfully!'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error fixing students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
