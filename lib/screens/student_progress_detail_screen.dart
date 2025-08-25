import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_progress.dart';
import '../models/assessment_submission.dart';
import '../services/progress_service.dart';
import '../services/submission_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/offline_indicator.dart';

class StudentProgressDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentProgressDetailScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<StudentProgressDetailScreen> createState() => _StudentProgressDetailScreenState();
}

class _StudentProgressDetailScreenState extends State<StudentProgressDetailScreen>
    with TickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  final SubmissionService _submissionService = SubmissionService();
  final ConnectivityService _connectivityService = ConnectivityService();

  late TabController _tabController;
  
  StudentProgress? _studentProgress;
  List<AssessmentSubmission> _submissions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedSubject = 'All';
  
  final List<String> _subjects = [
    'All',
    'Mathematics',
    'GMRC',
    'Values Education',
    'Araling Panlipunan',
    'English',
    'Filipino',
    'Music & Arts',
    'Science',
    'Physical Education & Health',
    'EPP',
    'TLE'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProgressData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProgressData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load student progress by ID
      final progress = await _progressService.getStudentProgressById(widget.studentId);
      
      // Load assessment submissions
      final submissions = await _submissionService.getStudentSubmissions(widget.studentId);

      if (!mounted) return;

      setState(() {
        _studentProgress = progress;
        _submissions = submissions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading progress data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    await _loadProgressData();

    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
    });
  }

  double get _overallCompletionRate {
    if (_studentProgress == null) return 0.0;
    return _studentProgress!.completionRate;
  }

  double get _overallAverageScore {
    if (_submissions.isEmpty) return 0.0;
    final totalScore = _submissions.map((s) => s.score).reduce((a, b) => a + b);
    return totalScore / _submissions.length;
  }

  int get _totalLessonsCompleted {
    if (_studentProgress == null) return 0;
    return _studentProgress!.lessonsCompleted;
  }

  int get _totalAssessmentsTaken {
    if (_studentProgress == null) return 0;
    return _studentProgress!.assessmentsTaken;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildOverviewCards(),
                const SizedBox(height: 24),
                _buildSubjectFilter(),
                const SizedBox(height: 24),
                _buildTabBar(),
                const SizedBox(height: 24),
                _buildTabBarView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1D1D1F)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isRefreshing ? Icons.refresh : Icons.refresh_outlined,
            color: const Color(0xFF007AFF),
          ),
          onPressed: _isRefreshing ? null : _refreshData,
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Progress Details',
          style: TextStyle(
            color: const Color(0xFF1D1D1F),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 32,
                  color: const Color(0xFF007AFF),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.studentName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF86868B),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Overall Progress',
                  '${_overallCompletionRate.round()}%',
                  Icons.trending_up,
                  const Color(0xFF34C759),
                  _overallCompletionRate >= 80 ? 'Excellent!' : _overallCompletionRate >= 60 ? 'Good Progress' : 'Keep Going!',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewCard(
                  'Average Score',
                  '${_overallAverageScore.round()}%',
                  Icons.analytics,
                  const Color(0xFF007AFF),
                  _overallAverageScore >= 80 ? 'Outstanding!' : _overallAverageScore >= 60 ? 'Well Done!' : 'Practice More!',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Lessons Completed',
                  '$_totalLessonsCompleted',
                  Icons.book,
                  const Color(0xFFFF9500),
                  'Learning Journey',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewCard(
                  'Assessments Taken',
                  '$_totalAssessmentsTaken',
                  Icons.quiz,
                  const Color(0xFFFF3B30),
                  'Knowledge Check',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.1),
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
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              OfflineIndicator(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Subject',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _subjects.map((subject) {
                final isSelected = _selectedSubject == subject;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSubject = subject;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF007AFF).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF86868B),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5E7),
                      width: isSelected ? 2 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFF007AFF),
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF86868B),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Subjects'),
            Tab(text: 'Assessments'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return Container(
      height: 600,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildSubjectsTab(),
          _buildAssessmentsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your progress...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF86868B),
              ),
            ),
          ],
        ),
      );
    }

    if (_studentProgress == null && _submissions.isEmpty) {
      return _buildEmptyState(
        'No Progress Data Available',
        'Start learning to see your progress here. Complete lessons and take assessments to track your growth!',
        Icons.rocket_launch,
        const Color(0xFF007AFF),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (_studentProgress != null) ...[
            _buildProgressChart(),
            const SizedBox(height: 24),
          ],
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    if (_studentProgress == null) return const SizedBox.shrink();

    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.insights,
                  color: Color(0xFF007AFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Learning Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressRow('Subject Progress', _studentProgress!.subject, _studentProgress!.completionRate),
          const SizedBox(height: 16),
          _buildProgressRow('Lessons', '${_studentProgress!.lessonsCompleted}/${_studentProgress!.totalLessons}', 
              (_studentProgress!.lessonsCompleted / _studentProgress!.totalLessons * 100).clamp(0, 100)),
          const SizedBox(height: 16),
          _buildProgressRow('Assessments', '${_studentProgress!.assessmentsTaken}/${_studentProgress!.totalAssessments}', 
              (_studentProgress!.assessmentsTaken / _studentProgress!.totalAssessments * 100).clamp(0, 100)),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, double percentage) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (percentage / 100).toDouble(),
                backgroundColor: const Color(0xFFE5E5E7),
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage >= 80
                      ? const Color(0xFF34C759)
                      : percentage >= 60
                          ? const Color(0xFFFF9500)
                          : const Color(0xFFFF3B30),
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF86868B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 50,
          child: Text(
            '${percentage.round()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: percentage >= 80
                  ? const Color(0xFF34C759)
                  : percentage >= 60
                      ? const Color(0xFFFF9500)
                      : const Color(0xFFFF3B30),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final recentSubmissions = _submissions.take(5).toList();

    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: Color(0xFF34C759),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recentSubmissions.isEmpty)
            _buildEmptyState(
              'No Recent Activity',
              'Complete your first assessment to see activity here!',
              Icons.assignment,
              const Color(0xFF86868B),
            )
          else
            ...recentSubmissions.map((submission) => _buildActivityItem(submission)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AssessmentSubmission submission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
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
              color: _getScoreColor(submission.score.toDouble()).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.quiz,
              color: _getScoreColor(submission.score.toDouble()),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completed ${submission.assessmentTitle ?? 'Assessment'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                Text(
                  'Score: ${submission.score}% • ${submission.assessmentSubject ?? 'Subject'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getScoreColor(submission.score.toDouble()).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
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

  Widget _buildSubjectsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_studentProgress == null) {
      return _buildEmptyState(
        'No Subject Data',
        'Subject progress will appear here once you start learning',
        Icons.subject,
        const Color(0xFF86868B),
      );
    }

    return SingleChildScrollView(
      child: _buildSubjectProgressCard(_studentProgress!),
    );
  }

  Widget _buildSubjectProgressCard(StudentProgress progress) {
    return Container(
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Color(0xFF007AFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.subject,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    Text(
                      'Learning Progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF86868B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getProgressColor(progress.completionRate).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${progress.completionRate.round()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(progress.completionRate),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressMetric('Lessons Completed', '${progress.lessonsCompleted}/${progress.totalLessons}'),
          const SizedBox(height: 16),
          _buildProgressMetric('Assessments Taken', '${progress.assessmentsTaken}/${progress.totalAssessments}'),
          const SizedBox(height: 16),
          _buildProgressMetric('Average Score', '${progress.averageScore.round()}%'),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF86868B),
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (progress.completionRate / 100).toDouble(),
                backgroundColor: const Color(0xFFE5E5E7),
                valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress.completionRate)),
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF86868B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredSubmissions = _submissions
        .where((submission) => _selectedSubject == 'All' || 
                               submission.assessmentSubject == _selectedSubject)
        .toList();

    if (filteredSubmissions.isEmpty) {
      return _buildEmptyState(
        'No Assessments Available',
        'Complete assessments to see your results here',
        Icons.quiz,
        const Color(0xFF86868B),
      );
    }

    return ListView.builder(
      itemCount: filteredSubmissions.length,
      itemBuilder: (context, index) {
        final submission = filteredSubmissions[index];
        return _buildAssessmentCard(submission);
      },
    );
  }

  Widget _buildAssessmentCard(AssessmentSubmission submission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.assessmentTitle ?? 'Assessment',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      submission.assessmentSubject ?? 'Subject',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF86868B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getScoreColor(submission.score.toDouble()).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${submission.score}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(submission.score.toDouble()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildAssessmentMetric('Questions', '${submission.totalQuestions ?? 0}'),
              const SizedBox(width: 32),
              _buildAssessmentMetric('Time Spent', '${submission.timeSpent}s'),
              const SizedBox(width: 32),
              _buildAssessmentMetric('Accuracy', '${submission.accuracy?.round() ?? 0}%'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: const Color(0xFF86868B),
                ),
                const SizedBox(width: 8),
                Text(
                  'Submitted: ${_formatDate(submission.submittedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
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

  Widget _buildAssessmentMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86868B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: color,
            ),
          ),
          const SizedBox(height: 24),
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

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF34C759);
    if (percentage >= 60) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF34C759);
    if (score >= 60) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
