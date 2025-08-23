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
import 'feedback_management_screen.dart';
import 'feedback_creation_screen.dart';
import 'leaderboard_screen.dart';
import 'adaptive_difficulty_screen.dart';
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
        backgroundColor: Color(0xFFF5F5F7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                strokeWidth: 3,
              ),
              SizedBox(height: 24),
              Text(
                'Loading your classroom...',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF86868B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Apple-style design
          SliverAppBar(
            expandedHeight: 120, // Reduced height since we don't need bottom row
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.1),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Row(
                      children: [
                        // Profile Avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF007AFF).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: _userProfile?.photoURL != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SafeNetworkImage(
                                    imageUrl: _userProfile!.photoURL!,
                                    fit: BoxFit.cover,
                                    fallback: const Icon(
                                      Icons.school_rounded,
                                      size: 28,
                                      color: Color(0xFF007AFF),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.school_rounded,
                                  size: 28,
                                  color: Color(0xFF007AFF),
                                ),
                        ),
                        const SizedBox(width: 16),
                        // Welcome Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF86868B),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _userProfile?.displayName ?? 'Teacher',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D1D1F),
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Hamburger Menu Icon
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.menu_rounded,
                              color: Color(0xFF007AFF),
                              size: 24,
                            ),
                            onPressed: _showHamburgerMenu,
                            tooltip: 'Menu',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  // Subjects Badge
                  if (_userProfile?.subjects?.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF007AFF).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Teaching: ${_userProfile!.subjects!.join(' • ')}',
                        style: const TextStyle(
                          fontSize: 13, // Reduced from 14
                          color: Color(0xFF007AFF),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 2, // Allow up to 2 lines
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Quick Actions Section
                  _buildSectionHeader('Quick Actions', Icons.flash_on_rounded),
                  const SizedBox(height: 20),
                  _buildQuickActionsGrid(),
                  
                  const SizedBox(height: 40),
                  
                  // Student Progress Section
                  _buildSectionHeader('Student Progress', Icons.analytics_rounded),
                  const SizedBox(height: 20),
                  _buildStudentProgressCards(),
                  
                  const SizedBox(height: 40),
                  
                  // Recent Activities Section
                  _buildSectionHeader('Recent Activities', Icons.history_rounded),
                  const SizedBox(height: 20),
                  _buildRecentActivitiesList(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHamburgerMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Menu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 20),
            _buildModalOption(
              'Settings',
              Icons.settings_rounded,
              'App preferences and configuration',
              _navigateToOfflineSettings,
            ),
            _buildModalOption(
              'Connectivity',
              Icons.wifi_rounded,
              '${ConnectivityService().isConnected ? 'Online' : 'Offline'} - Tap to toggle',
              _toggleOfflineMode,
            ),
            _buildModalOption(
              'Logout',
              Icons.logout_rounded,
              'Sign out of your account',
              () {
                Navigator.pop(context);
                final navigator = Navigator.of(context);
                _authService.signOut().then((_) {
                  if (mounted) {
                    navigator.pushReplacementNamed('/');
                  }
                });
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF007AFF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded( // Added Expanded to prevent text overflow
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 21, // Reduced from 22 to prevent overflow
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing for web vs mobile
        final isWeb = constraints.maxWidth > 600;
        final crossAxisCount = isWeb ? 3 : 2; // 3 columns on web, 2 on mobile
        final childAspectRatio = isWeb ? 1.4 : 1.3; // Wider cards on web
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildActionCard(
              'Lessons & Assessments',
              Icons.library_books_rounded,
              'Create and manage content',
              const Color(0xFF007AFF),
              () => _navigateToLessonUpload(),
            ),
            _buildActionCard(
              'Students & Progress',
              Icons.people_rounded,
              'Manage students & track performance',
              const Color(0xFF34C759),
              () => _navigateToStudentManagement(),
            ),
            _buildActionCard(
              'Learning Paths',
              Icons.layers_rounded,
              'Design learning sequences',
              const Color(0xFFFF9500),
              () => _navigateToLearningPathManagement(),
            ),
            _buildActionCard(
              'Feedback & Rankings',
              Icons.feedback_rounded,
              'Engage & motivate students',
              const Color(0xFFAF52DE),
              () => _navigateToFeedbackManagement(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(String title, IconData icon, String description, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16), // Further reduced padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Ensure minimum size
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(8), // Further reduced padding
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20, // Further reduced icon size
                color: color,
              ),
            ),
            const SizedBox(height: 10), // Reduced spacing
            // Title with strict overflow control
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14, // Further reduced font size
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Description with strict overflow control
            Flexible(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 10, // Further reduced font size
                  color: const Color(0xFF86868B),
                  height: 1.1, // Reduced line height
                  letterSpacing: 0.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentProgressCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 600;
        final cardCount = isWeb ? 4 : 3; // Show 4 stats on web, 3 on mobile
        
        return Column(
          children: [
            // Progress Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildProgressCard(
                    'Total Students',
                    '${_dashboardData?.totalStudents ?? 0}',
                    Icons.people_rounded,
                    const Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProgressCard(
                    'Active Students',
                    '${_dashboardData?.activeStudents ?? 0}',
                    Icons.person_rounded,
                    const Color(0xFF34C759),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProgressCard(
                    'Avg. Progress',
                    '${(_dashboardData?.averageProgress ?? 0.0).round()}%',
                    Icons.trending_up_rounded,
                    const Color(0xFFFF9500),
                  ),
                ),
                if (isWeb) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildProgressCard(
                      'Lessons Created',
                      '${_dashboardData?.recentActivities.length ?? 0}',
                      Icons.library_books_rounded,
                      const Color(0xFFAF52DE),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Subject Progress
            if (_dashboardData?.studentProgress.isNotEmpty == true)
              ..._buildSubjectProgressCards()
            else
              _buildEmptyState(
                'No student progress yet',
                'Student progress will appear here once they start learning',
                Icons.analytics_outlined,
              ),
          ],
        );
      },
    );
  }

  Widget _buildProgressCard(String label, String value, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 600;
        
        return Container(
          padding: EdgeInsets.all(isWeb ? 16 : 18), // Smaller padding on web
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isWeb ? 8 : 10), // Smaller padding on web
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isWeb ? 20 : 22, // Smaller icon on web
                ),
              ),
              SizedBox(height: isWeb ? 12 : 14), // Smaller spacing on web
              Text(
                value,
                style: TextStyle(
                  fontSize: isWeb ? 24 : 26, // Smaller font on web
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D1D1F),
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: isWeb ? 11 : 12, // Smaller font on web
                  color: const Color(0xFF86868B),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSubjectProgressCards() {
    final userSubjects = _userProfile?.subjects ?? [];
    final progressData = _dashboardData?.studentProgress ?? [];
    
    if (userSubjects.isEmpty) {
      return [
        _buildEmptyState(
          'No subjects assigned',
          'Add subjects to your profile to track progress',
          Icons.subject_outlined,
        ),
      ];
    }

    return userSubjects.map((subject) {
      final subjectProgress = progressData
          .where((p) => p.subject == subject)
          .toList();
      
      double averageProgress = 0.0;
      if (subjectProgress.isNotEmpty) {
        averageProgress = subjectProgress
            .map((p) => p.completionRate)
            .reduce((a, b) => a + b) / subjectProgress.length;
      }
      
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${averageProgress.round()}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF007AFF),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: averageProgress / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRecentActivitiesList() {
    final activities = _dashboardData?.recentActivities ?? [];
    
    if (activities.isEmpty) {
      return _buildEmptyState(
        'No recent activities',
        'Your activities will appear here once you start using the platform',
        Icons.history_outlined,
      );
    }

    return Column(
      children: activities.map((activity) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(activity.colorValue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getIconFromString(activity.iconName),
                color: Color(activity.colorValue),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D1D1F),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.subject,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF86868B),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                activity.displayTime,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF86868B),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: const Color(0xFF86868B),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
              letterSpacing: 0.1,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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

  Widget _buildModalOption(String title, IconData icon, String description, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF007AFF), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D1D1F),
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF86868B),
        ),
      ),
      onTap: onTap,
    );
  }

  // Navigation methods
  void _navigateToLessonUpload() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Content Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 20),
            _buildModalOption(
              'Upload Lessons',
              Icons.upload_file_rounded,
              'Add new learning content',
              () {
                Navigator.pop(context);
                if (_userProfile != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LessonUploadScreen(
                        teacherProfile: _userProfile!,
                      ),
                    ),
                  );
                }
              },
            ),
            _buildModalOption(
              'My Lessons',
              Icons.library_books_rounded,
              'View and manage existing lessons',
              () {
                Navigator.pop(context);
                if (_userProfile != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LessonLibraryScreen(
                        teacherProfile: _userProfile!,
                      ),
                    ),
                  );
                }
              },
            ),
            _buildModalOption(
              'Create Assessments',
              Icons.quiz_rounded,
              'Design tests and quizzes',
              () {
                Navigator.pop(context);
                if (_userProfile != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AssessmentManagementScreen(
                        teacherProfile: _userProfile!,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Student & Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 20),
            _buildModalOption(
              'Student Management',
              Icons.people_rounded,
              'Manage student accounts and classes',
              () {
                Navigator.pop(context);
                if (_userProfile != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StudentManagementScreen(
                        teacherProfile: _userProfile!,
                      ),
                    ),
                  );
                }
              },
            ),
            _buildModalOption(
              'Monitor Progress',
              Icons.analytics_rounded,
              'Track student performance and analytics',
              () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MonitorProgressScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToLearningPathManagement() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Learning Paths',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 20),
            _buildModalOption(
              'Create Paths',
              Icons.layers_rounded,
              'Design and create learning sequences',
              () {
                Navigator.pop(context);
                if (_userProfile != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LearningPathManagementScreen(
                        teacherProfile: _userProfile!,
                      ),
                    ),
                  );
                }
              },
            ),
            _buildModalOption(
              'Assign Paths',
              Icons.assignment_rounded,
              'Assign learning paths to students',
              () {
                Navigator.pop(context);
                if (_userProfile != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LearningPathAssignmentScreen(
                        teacherProfile: _userProfile!,
                      ),
                    ),
                  );
                }
              },
            ),
            _buildModalOption(
              'Path Overview',
              Icons.analytics_rounded,
              'Track assignments and progress',
              () {
                Navigator.pop(context);
                if (_userProfile != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LearningPathOverviewScreen(
                        teacherProfile: _userProfile!,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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

  void _navigateToFeedbackManagement() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Engagement & Feedback',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 20),
            _buildModalOption(
              'Feedback Management',
              Icons.feedback_rounded,
              'View and manage student feedback',
              () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const FeedbackManagementScreen(),
                ));
              },
            ),
            _buildModalOption(
              'Create Feedback',
              Icons.add_comment_rounded,
              'Create new feedback for students',
              () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const FeedbackCreationScreen(),
                ));
              },
            ),
            _buildModalOption(
              'Leaderboard',
              Icons.leaderboard_rounded,
              'View student rankings and achievements',
              () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const LeaderboardScreen(),
                ));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToFeedbackCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FeedbackCreationScreen(),
      ),
    );
  }

  void _navigateToLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LeaderboardScreen(),
      ),
    );
  }

  void _navigateToAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LeaderboardScreen(), // Using leaderboard screen for now
      ),
    );
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

  void _navigateToAdaptiveDifficulty() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdaptiveDifficultyScreen(),
      ),
    );
  }
}
