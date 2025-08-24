import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/assessment.dart';
import '../services/auth_service.dart';
import '../services/assessment_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_service.dart';
import '../widgets/safe_network_image.dart';
import 'student_lesson_viewer_screen.dart';
import 'student_assessment_taker_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final AuthService _authService = AuthService();
  UserModel? _userProfile;
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
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: const Color(0xFF667eea),
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
                
                // Recent Progress
                _buildRecentProgress(),
                
                const SizedBox(height: 30),
                
                // Upcoming Lessons
                _buildUpcomingLessons(),
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
            backgroundColor: const Color(0xFF007AFF),
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              'Take Assessment',
              Icons.quiz,
              'Coming soon',
              () => _navigateToAssessment(),
            ),
            _buildActionCard(
              'View Pathways',
              Icons.timeline,
              'Coming soon',
              () => _navigateToPathways(),
            ),
            _buildActionCard(
              'View Lessons',
              Icons.school,
              'Browse and study lessons',
              () => _navigateToLessons(),
            ),
            _buildActionCard(
              'Progress',
              Icons.trending_up,
              'Coming soon',
              () => _navigateToProgress(),
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
        padding: const EdgeInsets.all(20),
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
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color(0xFF667eea),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          const Text(
            'Recent Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          _buildEmptyProgressState(),
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
            Icons.analytics_outlined,
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
          _buildEmptyLessonsState(),
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
            Icons.schedule_outlined,
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

  // Navigation methods
  void _navigateToAssessment() {
    // Show available assessments from Firebase
    _loadAndShowAssessments();
  }

  Future<void> _loadAndShowAssessments() async {
    try {
      print('🚀 Starting to load assessments...');
      setState(() {
        _isLoading = true;
      });

      final assessmentService = AssessmentService();
      final connectivityService = ConnectivityService();
      
      List<Assessment> assessments = [];
      
      // Check connectivity and load assessments
      if (connectivityService.isConnected) {
        print('🌐 Online - loading from Firebase');
        // Load from Firebase
        assessments = await assessmentService.getAllPublishedAssessments();
        print('📊 Found ${assessments.length} assessments from Firebase');
        
        // Debug each assessment
        for (var assessment in assessments) {
          print('🔍 Assessment: ${assessment.title} - ${assessment.questions.length} questions');
          if (assessment.questions.isNotEmpty) {
            print('🔍 First question: ${assessment.questions.first.question} (Type: ${assessment.questions.first.type})');
          }
        }
        
        // Cache assessments offline
        if (assessments.isNotEmpty) {
          final assessmentData = assessments.map((a) => {
            'id': a.id,
            ...a.toRealtimeDatabase(),
          }).toList();
          await OfflineService.cacheAssessments(assessmentData);
          print('💾 Cached ${assessmentData.length} assessments offline');
        }
      } else {
        print('🔌 Offline - loading from cache');
        // Load from offline cache
        final cachedAssessments = await OfflineService.getCachedAssessments();
        assessments = cachedAssessments
            .where((data) => data['isPublished'] == true)
            .map((data) => Assessment.fromRealtimeDatabase(data['id'] ?? '', data))
            .toList();
        print('📊 Found ${assessments.length} assessments from cache');
        
        // Debug each assessment from cache
        for (var assessment in assessments) {
          print('🔍 Cached Assessment: ${assessment.title} - ${assessment.questions.length} questions');
          if (assessment.questions.isNotEmpty) {
            print('🔍 First question: ${assessment.questions.first.question} (Type: ${assessment.questions.first.type})');
          }
        }
      }

      print('🎯 Total assessments to show: ${assessments.length}');
      if (mounted) {
        _showAssessmentOptions(assessments);
      }
    } catch (e) {
      print('❌ Error loading assessments: $e');
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

  void _showAssessmentOptions(List<Assessment> assessments) {
    if (assessments.isEmpty) {
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
              'Available Assessments (${assessments.length})',
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
                itemCount: assessments.length,
                itemBuilder: (context, index) {
                  final assessment = assessments[index];
                  return _buildAssessmentOption(
                    assessment.title,
                    assessment.description,
                    assessment.subject,
                    () => _startAssessment(assessment),
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

  Widget _buildAssessmentOption(String title, String description, String subject, VoidCallback onTap) {
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
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
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
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color(0xFF86868B),
          size: 16,
        ),
      ),
    );
  }

  void _startAssessment(Assessment assessment) {
    Navigator.of(context).pop(); // Close the modal
    
    // Navigate directly to the assessment taker screen with the real assessment
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentAssessmentTakerScreen(
          assessment: assessment,
        ),
      ),
    );
  }



  void _navigateToPathways() {
    // TODO: Navigate to learning pathways screen when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Learning pathways will be available soon!'),
        backgroundColor: Color(0xFF667eea),
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
    // TODO: Navigate to detailed progress screen when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detailed progress tracking will be available soon!'),
        backgroundColor: Color(0xFF667eea),
      ),
    );
  }
}
