import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/assessment.dart';
import '../services/auth_service.dart';
import '../services/assessment_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_service.dart';
import '../services/submission_service.dart';
import '../models/assessment_submission.dart';
import '../services/lesson_service_realtime.dart';
import '../models/lesson.dart';
import '../widgets/safe_network_image.dart';
import '../services/achievements_service.dart';
import '../models/achievements.dart';
import 'student_lesson_viewer_screen.dart';
import 'student_assessment_taker_screen.dart';
import 'student_submission_history_screen.dart';
import 'student_progress_detail_screen.dart';
import 'student_learning_path_navigator_screen.dart';
import 'lesson_detail_screen.dart';
import 'student_profile_edit_screen.dart';
import 'student_settings_screen.dart';
import 'badges_screen.dart';
import 'leaderboard_screen.dart';

// Helper class to track assessment submission status
class AssessmentWithSubmissionStatus {
  final Assessment assessment;
  final bool hasSubmitted;
  final AssessmentSubmission? existingSubmission;

  AssessmentWithSubmissionStatus({
    required this.assessment,
    required this.hasSubmitted,
    this.existingSubmission,
  });
}

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final AuthService _authService = AuthService();
  final SubmissionService _submissionService = SubmissionService();
  final LessonServiceRealtime _lessonService = LessonServiceRealtime();
  final AchievementsService _achievementsService = AchievementsService();
  UserModel? _userProfile;
  bool _isLoading = true;
  List<AssessmentSubmission> _recentSubmissions = [];
  List<Lesson> _upcomingLessons = [];
  List<LeaderboardEntry> _leaderboard = [];
  LeaderboardEntry? _currentUserPosition;



  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Load user profile first (critical data)
        final profile = await _authService.getUserProfile(user.uid);
        
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _isLoading = false; // Show UI immediately with profile
          });
        }
        
        // Load non-critical data in background
        _loadBackgroundData(user.uid);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBackgroundData(String userId) async {
    try {
      // Load recent submissions
      List<AssessmentSubmission> recentSubs = [];
      try {
        recentSubs = await _submissionService.getStudentSubmissions(userId);
        recentSubs.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        recentSubs = recentSubs.take(3).toList();
      } catch (e) {
        // Continue without submissions
      }
      
      // Load upcoming lessons
      List<Lesson> upcomingLessons = [];
      try {
        upcomingLessons = await _lessonService.getAllPublishedLessons();
        upcomingLessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        upcomingLessons = upcomingLessons.take(3).toList();
      } catch (e) {
        // Continue without lessons
      }
      
      if (mounted) {
        setState(() {
          _recentSubmissions = recentSubs;
          _upcomingLessons = upcomingLessons;
        });
      }
      
      // Load leaderboard data (least critical)
      _loadLeaderboardData(userId);
      
    } catch (e) {
      // Background data loading failed, continue
    }
  }

  Future<void> _loadLeaderboardData(String userId) async {
    try {
      final leaderboard = await _achievementsService.getLeaderboard(limit: 10);
      final currentUserPosition = await _achievementsService.getStudentLeaderboardPosition(userId);
      
      if (mounted) {
        setState(() {
          _leaderboard = leaderboard;
          _currentUserPosition = currentUserPosition;
        });
      }
    } catch (e) {
      // Leaderboard data is optional, continue without it
    }
  }

  Widget _buildSkeletonLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile skeleton
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats skeleton
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent submissions skeleton
            Container(
              height: 20,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeletonLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              final navigator = Navigator.of(context);
              _authService.signOut().then((_) {
                if (mounted) {
                  navigator.pushReplacementNamed('/');
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                _buildWelcomeHeader(),
                
                const SizedBox(height: 30),
                
                // Quick Actions Grid
                _buildQuickActions(),
                
                const SizedBox(height: 30),
                
                // Profile & Settings Section
                _buildProfileSettingsSection(),
                
                const SizedBox(height: 30),
                
                // Recent Progress
                _buildRecentProgress(),
                
                const SizedBox(height: 30),
                
                // Recent Submissions
                _buildRecentSubmissions(),
                
                const SizedBox(height: 30),
                
                // Upcoming Lessons
                _buildUpcomingLessons(),
                
                const SizedBox(height: 30),
                
                // Leaderboard
                _buildLeaderboard(),
              ],
            ),
          ),
        ),
      
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SafeCircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF7ED321),
            imageUrl: _userProfile?.photoURL,
            fallbackChild: const Icon(
              Icons.person,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${_userProfile?.displayName ?? 'Student'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grade ${_userProfile?.grade ?? '7'} • Ready to learn!',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF86868B),
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
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1, // Reduced from 1.3 to give more height
          children: [
            _buildActionCard(
              'Take Assessment',
              Icons.psychology,
              'Complete quizzes and tests',
              () => _navigateToAssessment(),
            ),
            _buildActionCard(
              'View Pathways',
              Icons.route,
              'Learning journeys',
              () => _navigateToPathways(),
            ),
            _buildActionCard(
              'View Lessons',
              Icons.menu_book,
              'Browse and study lessons',
              () => _navigateToLessons(),
            ),
            _buildActionCard(
              'Progress',
              Icons.rocket_launch,
              'View your learning progress',
              () => _navigateToProgress(),
            ),
            _buildActionCard(
              'Badges',
              Icons.workspace_premium,
              'View your achievements',
              () => _navigateToBadges(),
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: const Color(0xFF00D4FF),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
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

  Widget _buildProfileSettingsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile & Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToSettings(),
                child: const Text(
                  'Manage',
                  style: TextStyle(
                    color: Color(0xFF007AFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                backgroundImage: _userProfile?.photoURL != null
                    ? NetworkImage(_userProfile!.photoURL!)
                    : null,
                child: _userProfile?.photoURL == null
                    ? const Icon(
                        Icons.person,
                        size: 30,
                        color: Color(0xFF00D4FF),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userProfile?.displayName ?? 'Student',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userProfile?.email ?? 'student@example.com',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF86868B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_userProfile?.grade ?? 'Grade 7'} • ${_userProfile?.subjects?.length ?? 0} subjects',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7ED321),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _navigateToProfileEdit(),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF00D4FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentProgress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToProgress(),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF00D4FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Show recent progress or empty state
          if (_recentSubmissions.isEmpty)
            _buildEmptyProgressState()
          else
            _buildProgressItems(),
        ],
      ),
    );
  }

  Widget _buildEmptyProgressState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.analytics_rounded,
            size: 48,
            color: const Color(0xFF86868B),
          ),
          const SizedBox(height: 16),
          Text(
            'No progress data yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your learning progress will appear here once you start taking lessons and assessments.',
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

  Widget _buildProgressItems() {
    return Column(
      children: _recentSubmissions.take(3).map((submission) => _buildProgressItem(submission)).toList(),
    );
  }

  Widget _buildProgressItem(AssessmentSubmission submission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getScoreColor(submission.score.toDouble()).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: _getScoreColor(submission.score.toDouble()),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.assessmentTitle.isNotEmpty 
                      ? submission.assessmentTitle 
                      : 'Assessment ${submission.assessmentId.substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${submission.assessmentSubject} • Score: ${submission.score}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF86868B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed ${_formatDate(submission.submittedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getScoreColor(submission.score.toDouble()).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${submission.score}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(submission.score.toDouble()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingLessons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Lessons',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          // Show upcoming lessons or empty state
          if (_upcomingLessons.isEmpty)
            _buildEmptyLessonsState()
          else
            Column(
              children: _upcomingLessons.map((lesson) => _buildUpcomingLessonItem(lesson)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyLessonsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 48,
            color: const Color(0xFF86868B),
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming lessons',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check the lesson library to start learning or wait for your teacher to assign lessons.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _navigateToLessons,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF667eea),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Browse Lessons',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingLessonItem(Lesson lesson) {
    return GestureDetector(
      onTap: () => _navigateToLessonDetail(lesson),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E5E7),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Color(0xFF00D4FF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lesson.subject} • ${lesson.teacherName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF86868B),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  _formatLessonDate(lesson.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF86868B),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: const Color(0xFF86868B).withValues(alpha: 0.7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLessonDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToLessonDetail(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lesson: lesson),
      ),
    );
  }

  // Get current student ID from Firebase Auth
  String _getCurrentStudentId() {
    try {
      // Get the current Firebase Auth user
      final currentUser = _authService.currentUser;
      if (currentUser != null && currentUser.uid.isNotEmpty) {
        return currentUser.uid; // This is the UNIQUE Firebase UID
      }
      
      // Fallback to user profile if available
      if (_userProfile != null && _userProfile!.uid.isNotEmpty) {
        return _userProfile!.uid;
      }
      
      // Last resort - this should never happen if user is authenticated
      return 'unknown_student_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'unknown_student_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Navigation methods
  void _navigateToAssessment() {
    // Show available assessments from Firebase
    _loadAndShowAssessments();
  }

  Future<void> _loadAndShowAssessments() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final assessmentService = AssessmentService();
      final connectivityService = ConnectivityService();
      final submissionService = SubmissionService();
      
      List<Assessment> assessments = [];
      
      // Check connectivity and load assessments
      if (connectivityService.isConnected) {
        // Load from Firebase
        assessments = await assessmentService.getAllPublishedAssessments();
        
        // Cache assessments offline
        if (assessments.isNotEmpty) {
          final assessmentData = assessments.map((a) => {
            'id': a.id,
            ...a.toRealtimeDatabase(),
          }).toList();
          await OfflineService.cacheAssessments(assessmentData);
        }
      } else {
        // Load from offline cache
        final cachedAssessments = await OfflineService.getCachedAssessments();
        assessments = cachedAssessments
            .where((data) => data['isPublished'] == true)
            .map((data) => Assessment.fromRealtimeDatabase(data['id'] ?? '', data))
            .toList();
      }

      // Get current student ID (this should come from auth service in production)
      final currentStudentId = _getCurrentStudentId();
      
      // Check submission status for each assessment
      List<AssessmentWithSubmissionStatus> assessmentsWithStatus = [];
      for (var assessment in assessments) {
        try {
          // Check if student has already submitted this assessment
          final submissions = await submissionService.getStudentSubmissions(currentStudentId);
          
          final hasSubmitted = submissions.any((submission) => 
            submission.assessmentId == assessment.id
          );
          
          AssessmentSubmission? existingSubmission;
          if (hasSubmitted) {
            existingSubmission = submissions.firstWhere((submission) => 
              submission.assessmentId == assessment.id
            );
          }
          
          assessmentsWithStatus.add(AssessmentWithSubmissionStatus(
            assessment: assessment,
            hasSubmitted: hasSubmitted,
            existingSubmission: existingSubmission,
          ));
        } catch (e) {
          // If we can't check status, assume not submitted
          assessmentsWithStatus.add(AssessmentWithSubmissionStatus(
            assessment: assessment,
            hasSubmitted: false,
            existingSubmission: null,
          ));
        }
      }

      if (mounted) {
        _showAssessmentOptions(assessmentsWithStatus);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading assessments: $e'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAssessmentOptions(List<AssessmentWithSubmissionStatus> assessmentsWithStatus) {
    if (assessmentsWithStatus.isEmpty) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // No assessments message
              const Icon(
                Icons.quiz_outlined,
                size: 48,
                color: Color(0xFF86868B),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'No Assessments Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Your teacher hasn\'t published any assessments yet.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF86868B),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Available Assessments (${assessmentsWithStatus.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Assessment list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: assessmentsWithStatus.length,
                itemBuilder: (context, index) {
                  final assessmentWithStatus = assessmentsWithStatus[index];
                  final assessment = assessmentWithStatus.assessment;
                  return _buildAssessmentOption(
                    assessment.title,
                    assessment.description,
                    assessment.subject,
                    assessmentWithStatus.hasSubmitted,
                    assessmentWithStatus.existingSubmission,
                    () => _startAssessment(assessmentWithStatus),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF86868B),
                  side: const BorderSide(color: Color(0xFFE5E5E7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentOption(String title, String description, String subject, bool hasSubmitted, AssessmentSubmission? existingSubmission, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E5E7)),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.quiz_rounded,
            color: Color(0xFF007AFF),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ),
            if (hasSubmitted && existingSubmission != null)
              Text(
                '${existingSubmission.accuracy.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getScoreColor(existingSubmission.accuracy),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF86868B),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subject,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF34C759),
                ),
              ),
            ),
          ],
        ),
        trailing: hasSubmitted 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF34C759)),
              ),
              child: const Text(
                'Completed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF34C759),
                ),
              ),
            )
          : const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF86868B),
              size: 16,
            ),
      ),
    );
  }

  void _startAssessment(AssessmentWithSubmissionStatus assessmentWithStatus) {
    Navigator.of(context).pop(); // Close the modal
    
    if (assessmentWithStatus.hasSubmitted) {
      // Show submission details instead of allowing retake
      _showSubmissionDetails(assessmentWithStatus.existingSubmission!);
      return;
    }
    
    // Navigate to assessment taker screen if not submitted
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentAssessmentTakerScreen(
          assessment: assessmentWithStatus.assessment,
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF34C759); // Green
    if (percentage >= 60) return const Color(0xFFFF9500); // Orange
    return const Color(0xFFFF3B30); // Red
  }

  void _showSubmissionDetails(AssessmentSubmission submission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assessment Already Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have already completed this assessment.'),
            const SizedBox(height: 16),
            Text('Score: ${submission.accuracy.toStringAsFixed(1)}%'),
            Text('Submitted: ${submission.formattedDate}'),
            Text('Time Spent: ${submission.formattedTimeSpent}'),
            if (submission.feedback != null && submission.feedback!.isNotEmpty)
              Text('Feedback: ${submission.feedback}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to submission history
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentSubmissionHistoryScreen(
                    studentId: _getCurrentStudentId(),
                    studentName: 'Student', // TODO: Get from user profile
                  ),
                ),
              );
            },
            child: const Text('View All Submissions'),
          ),
        ],
      ),
    );
  }



  void _navigateToPathways() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentLearningPathNavigatorScreen(
          studentId: _userProfile?.uid ?? 'student_${DateTime.now().millisecondsSinceEpoch}',
          studentName: _userProfile?.displayName ?? 'Student',
        ),
      ),
    );
  }

  void _navigateToLessons() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudentLessonViewerScreen(),
      ),
    );
  }

  void _navigateToProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentProgressDetailScreen(
          studentId: _userProfile?.uid ?? 'student_${DateTime.now().millisecondsSinceEpoch}',
          studentName: _userProfile?.displayName ?? 'Student',
        ),
      ),
    );
  }

  void _navigateToSubmissions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentSubmissionHistoryScreen(
          studentId: _userProfile?.uid ?? 'student_${DateTime.now().millisecondsSinceEpoch}',
          studentName: _userProfile?.displayName ?? 'Student',
        ),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentSettingsScreen(
          userProfile: _userProfile!,
        ),
      ),
    );
  }

  void _navigateToProfileEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentProfileEditScreen(
          userProfile: _userProfile!,
        ),
      ),
    );
  }

  void _navigateToBadges() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BadgesScreen(),
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

  Widget _buildRecentSubmissions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Submissions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToSubmissions(),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF00D4FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Show recent submissions or empty state
          if (_recentSubmissions.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_turned_in_rounded,
                    size: 48,
                    color: const Color(0xFF86868B),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No submissions yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF86868B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete assessments to see your progress here',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF86868B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: _recentSubmissions.map((submission) => _buildRecentSubmissionItem(submission)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSubmissionItem(AssessmentSubmission submission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getScoreColor(submission.score.toDouble()).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: _getScoreColor(submission.score.toDouble()),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.assessmentTitle.isNotEmpty 
                      ? submission.assessmentTitle 
                      : 'Assessment ${submission.assessmentId.substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${submission.assessmentSubject} • Score: ${submission.score}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(submission.submittedAt),
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }



  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildLeaderboard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToLeaderboard(),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF00D4FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Show leaderboard or empty state
          if (_leaderboard.isEmpty)
            _buildEmptyLeaderboardState()
          else
            _buildLeaderboardItems(),
        ],
      ),
    );
  }

  Widget _buildEmptyLeaderboardState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.leaderboard_rounded,
            size: 48,
            color: const Color(0xFF86868B),
          ),
          const SizedBox(height: 16),
          Text(
            'No leaderboard data yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete lessons and assessments to see rankings here.',
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

  Widget _buildLeaderboardItems() {
    return Column(
      children: _leaderboard.take(5).map((entry) => _buildLeaderboardItem(entry)).toList(),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry) {
    final isCurrentUser = _currentUserPosition?.studentId == entry.studentId;
    final rank = _leaderboard.indexOf(entry) + 1;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFF00D4FF).withOpacity(0.1) : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? const Color(0xFF00D4FF) : const Color(0xFFE5E5E7),
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.studentName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                          color: isCurrentUser ? const Color(0xFF00D4FF) : const Color(0xFF1D1D1F),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.totalPoints}p',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7ED321),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.military_tech, size: 12, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.achievementsCount}a',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF86868B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats chips
          _buildLeaderboardStatsChips(entry),
        ],
      ),
    );
  }

  Widget _buildLeaderboardStatsChips(LeaderboardEntry entry) {
    return Column(
      children: [
        if (entry.stats['lessonsCompleted'] != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF7ED321).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${entry.stats['lessonsCompleted']}L',
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF7ED321),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (entry.stats['assessmentsCompleted'] != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${entry.stats['assessmentsCompleted']}A',
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFFFF6B35),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return const Color(0xFF00D4FF); // Electric Blue
  }
}
