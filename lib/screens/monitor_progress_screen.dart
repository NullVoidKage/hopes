import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/progress_service.dart';
import '../models/student_progress.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import 'package:firebase_database/firebase_database.dart';

class MonitorProgressScreen extends StatefulWidget {
  const MonitorProgressScreen({super.key});

  @override
  State<MonitorProgressScreen> createState() => _MonitorProgressScreenState();
}

class _MonitorProgressScreenState extends State<MonitorProgressScreen>
    with TickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  final StudentService _studentService = StudentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Student> _students = [];
  List<StudentProgress> _studentProgress = [];
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;
  String _selectedSubject = 'All';
  String _selectedFilter = 'All';
  
  late TabController _tabController;
  
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
  final List<String> _filters = ['All', 'High Performers', 'Needs Help', 'Recently Active'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final String? teacherId = _auth.currentUser?.uid;
      if (teacherId != null) {
        
        // Get students from Firestore (like Student Management does)
        final students = await _studentService.getAllStudents();
        
        // Get progress data for those students
        final progress = await _progressService.getStudentProgress(teacherId);
        
        // Calculate statistics from actual database collections
        final stats = await _calculateStatisticsFromDatabase(teacherId);
        final activity = await _generateActivityFromDatabase();
        
        // If no data exists, create sample data
        if (stats['totalStudents'] == 0 && students.isNotEmpty) {
          await _createSampleProgressData(students, teacherId);
          // Reload data after creating sample data
          final updatedStats = await _calculateStatisticsFromDatabase(teacherId);
          final updatedActivity = await _generateActivityFromDatabase();
          
          setState(() {
            _students = students;
            _studentProgress = progress;
            _statistics = updatedStats;
            _recentActivity = updatedActivity;
            _isLoading = false;
          });
        } else {
          setState(() {
            _students = students;
            _studentProgress = progress;
            _statistics = stats;
            _recentActivity = activity;
            _isLoading = false;
          });
        }
        
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Create sample progress data for students using existing collections
  Future<void> _createSampleProgressData(List<Student> students, String teacherId) async {
    try {
      // Create sample data in the existing collections
      final studentsRef = FirebaseDatabase.instance.ref('students');
      final assessmentsRef = FirebaseDatabase.instance.ref('assessments');
      final lessonsRef = FirebaseDatabase.instance.ref('lessons');
      final submissionsRef = FirebaseDatabase.instance.ref('assessment_submissions');
      final achievementsRef = FirebaseDatabase.instance.ref('student_achievements');
      
      for (final student in students) {
        // Create student entry
        final studentData = {
          'id': student.id,
          'name': student.name,
          'email': student.email,
          'grade': student.grade,
          'section': student.section,
          'subjects': student.subjects,
          'joinedAt': student.joinedAt.millisecondsSinceEpoch,
          'teacherId': teacherId,
        };
        await studentsRef.child(student.id).set(studentData);
        
        // Create sample lessons for each subject
        for (final subject in student.subjects) {
          final lessonData = {
            'id': 'lesson_${student.id}_${subject}_${DateTime.now().millisecondsSinceEpoch}',
            'title': 'Sample Lesson - $subject',
            'subject': subject,
            'teacherId': teacherId,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'isCompleted': _generateRandomInt(0, 1) == 1,
            'studentId': student.id,
          };
          await lessonsRef.push().set(lessonData);
        }
        
        // Create sample assessments for each subject
        for (final subject in student.subjects) {
          final assessmentData = {
            'id': 'assessment_${student.id}_${subject}_${DateTime.now().millisecondsSinceEpoch}',
            'title': 'Sample Assessment - $subject',
            'subject': subject,
            'teacherId': teacherId,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'totalQuestions': 10,
            'timeLimit': 30,
          };
          final assessmentKey = assessmentsRef.push();
          await assessmentKey.set(assessmentData);
          
          // Create sample submission
          final submissionData = {
            'id': 'submission_${student.id}_${subject}_${DateTime.now().millisecondsSinceEpoch}',
            'studentId': student.id,
            'studentName': student.name,
            'assessmentId': assessmentKey.key,
            'assessmentTitle': 'Sample Assessment - $subject',
            'assessmentSubject': subject,
            'score': _generateRandomInt(60, 95),
            'totalQuestions': 10,
            'correctAnswers': _generateRandomInt(6, 9),
            'incorrectAnswers': _generateRandomInt(1, 4),
            'unansweredQuestions': 0,
            'timeSpent': _generateRandomInt(300, 1800),
            'submittedAt': DateTime.now().subtract(Duration(days: _generateRandomInt(0, 7))).millisecondsSinceEpoch,
            'isGraded': true,
            'gradedAt': DateTime.now().subtract(Duration(days: _generateRandomInt(0, 7))).millisecondsSinceEpoch,
            'accuracy': _generateRandomDouble(60.0, 95.0),
          };
          await submissionsRef.push().set(submissionData);
        }
        
        // Create sample achievements
        final achievementData = {
          'id': 'achievement_${student.id}_${DateTime.now().millisecondsSinceEpoch}',
          'studentId': student.id,
          'studentName': student.name,
          'achievementType': 'lesson_completed',
          'title': 'First Lesson Completed',
          'description': 'Completed first lesson in ${student.subjects.first}',
          'points': 10,
          'earnedAt': DateTime.now().subtract(Duration(days: _generateRandomInt(0, 7))).millisecondsSinceEpoch,
          'subject': student.subjects.first,
        };
        await achievementsRef.push().set(achievementData);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Calculate statistics from actual database collections
  Future<Map<String, dynamic>> _calculateStatisticsFromDatabase(String teacherId) async {
    try {
      // Get data from actual collections
      final studentsRef = FirebaseDatabase.instance.ref('students');
      final submissionsRef = FirebaseDatabase.instance.ref('assessment_submissions');
      final lessonsRef = FirebaseDatabase.instance.ref('lessons');
      
      final studentsSnapshot = await studentsRef.once();
      final submissionsSnapshot = await submissionsRef.once();
      final lessonsSnapshot = await lessonsRef.once();
      
      final studentsData = studentsSnapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final submissionsData = submissionsSnapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final lessonsData = lessonsSnapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      final int totalStudents = studentsData.length;
      
      // Calculate average score from submissions
      double totalScore = 0.0;
      int submissionCount = 0;
      submissionsData.forEach((key, value) {
        if (value is Map && value['score'] != null) {
          totalScore += (value['score'] as num).toDouble();
          submissionCount++;
        }
      });
      final double averageScore = submissionCount > 0 ? totalScore / submissionCount : 0.0;
      
      // Calculate lessons completed
      int lessonsCompleted = 0;
      lessonsData.forEach((key, value) {
        if (value is Map && value['isCompleted'] == true) {
          lessonsCompleted++;
        }
      });
      
      // Calculate assessments taken
      final int assessmentsTaken = submissionsData.length;
      
      // Calculate completion rate (lessons completed / total lessons)
      final double averageCompletionRate = lessonsData.isNotEmpty 
          ? (lessonsCompleted / lessonsData.length) * 100 
          : 0.0;
      
      // Count active students (with submissions in last 7 days)
      final DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
      int activeStudents = 0;
      final Set<String> activeStudentIds = {};
      
      submissionsData.forEach((key, value) {
        if (value is Map && value['submittedAt'] != null) {
          final submittedAt = DateTime.fromMillisecondsSinceEpoch(value['submittedAt'] as int);
          if (submittedAt.isAfter(weekAgo)) {
            activeStudentIds.add(value['studentId'] as String? ?? '');
          }
        }
      });
      activeStudents = activeStudentIds.length;

      return {
        'totalStudents': totalStudents,
        'averageScore': averageScore,
        'averageCompletionRate': averageCompletionRate,
        'totalLessonsCompleted': lessonsCompleted,
        'totalAssessmentsTaken': assessmentsTaken,
        'activeStudents': activeStudents,
      };
    } catch (e) {
      return {
        'totalStudents': 0,
        'averageScore': 0.0,
        'averageCompletionRate': 0.0,
        'totalLessonsCompleted': 0,
        'totalAssessmentsTaken': 0,
        'activeStudents': 0,
      };
    }
  }

  // Generate activity from actual database collections
  Future<List<Map<String, dynamic>>> _generateActivityFromDatabase() async {
    try {
      final List<Map<String, dynamic>> activities = [];
      
      // Get submissions data
      final submissionsRef = FirebaseDatabase.instance.ref('assessment_submissions');
      final submissionsSnapshot = await submissionsRef.once();
      final submissionsData = submissionsSnapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      // Get lessons data
      final lessonsRef = FirebaseDatabase.instance.ref('lessons');
      final lessonsSnapshot = await lessonsRef.once();
      final lessonsData = lessonsSnapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      // Add assessment completions
      submissionsData.forEach((key, value) {
        if (value is Map) {
          activities.add({
            'type': 'assessment_completed',
            'studentName': value['studentName'] ?? 'Unknown Student',
            'assessmentTitle': value['assessmentTitle'] ?? 'Assessment',
            'timestamp': value['submittedAt'] ?? DateTime.now().millisecondsSinceEpoch,
            'score': value['score'] ?? 0,
          });
        }
      });
      
      // Add lesson completions
      lessonsData.forEach((key, value) {
        if (value is Map && value['isCompleted'] == true) {
          activities.add({
            'type': 'lesson_completed',
            'studentName': value['studentName'] ?? 'Unknown Student',
            'lessonTitle': value['title'] ?? 'Lesson',
            'timestamp': value['completedAt'] ?? DateTime.now().millisecondsSinceEpoch,
            'score': 100, // Lessons don't have scores, use 100 as completion
          });
        }
      });
      
      // Sort by timestamp (most recent first)
      activities.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      
      return activities.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  // Helper methods for generating random data
  int _generateRandomInt(int min, int max) {
    return min + (DateTime.now().millisecondsSinceEpoch % (max - min + 1));
  }

  double _generateRandomDouble(double min, double max) {
    final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000.0;
    return min + (random * (max - min));
  }

  // Create sample data manually
  Future<void> _createSampleData() async {
    final String? teacherId = _auth.currentUser?.uid;
    if (teacherId != null) {
      setState(() => _isLoading = true);
      
      try {
        final students = await _studentService.getAllStudents();
        if (students.isNotEmpty) {
          await _createSampleProgressData(students, teacherId);
          await _loadData(); // Reload data
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sample progress data created successfully!'),
              backgroundColor: Color(0xFF34C759),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No students found to create sample data'),
              backgroundColor: Color(0xFFFF9500),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating sample data: $e'),
            backgroundColor: Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  List<Student> get _filteredStudents {
    
    List<Student> filtered = _students;
    
    // Filter by subject (check if student has the selected subject)
    if (_selectedSubject != 'All') {
      filtered = filtered.where((s) => s.subjects.contains(_selectedSubject)).toList();
    }
    
    // Filter by performance (this will need to be implemented based on progress data)
    switch (_selectedFilter) {
      case 'High Performers':
        // TODO: Implement based on progress data
        break;
      case 'Needs Help':
        // TODO: Implement based on progress data
        break;
      case 'Recently Active':
        // TODO: Implement based on progress data
        break;
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Monitor Progress',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1D1D1F)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart_rounded, color: Color(0xFF34C759)),
            onPressed: () => _createSampleData(),
            tooltip: 'Create Sample Data',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF007AFF)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                                 _buildStatistics(),
                 Container(
                   margin: const EdgeInsets.symmetric(horizontal: 16),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: const Color(0xFFE5E5E7)),
                   ),
                   child: TabBar(
                     controller: _tabController,
                     labelColor: const Color(0xFF007AFF),
                     unselectedLabelColor: const Color(0xFF86868B),
                     indicatorColor: const Color(0xFF007AFF),
                     indicatorSize: TabBarIndicatorSize.tab,
                     tabs: const [
                       Tab(text: 'Overview'),
                       Tab(text: 'Students'),
                       Tab(text: 'Activity'),
                     ],
                   ),
                 ),
                 const SizedBox(height: 16),
                 Expanded(
                   child: TabBarView(
                     controller: _tabController,
                     children: [
                       _buildOverviewTab(),
                       _buildStudentsTab(),
                       _buildActivityTab(),
                     ],
                   ),
                 ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
          SizedBox(
            width: (MediaQuery.of(context).size.width * 0.4).clamp(120.0, 200.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E7)),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                  hintText: 'Subject',
                ),
                items: _subjects.map((subject) => DropdownMenuItem(
                  value: subject,
                  child: Text(
                    subject,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedSubject = value!);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: (MediaQuery.of(context).size.width * 0.4).clamp(120.0, 200.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E7)),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                  hintText: 'Filter',
                ),
                items: _filters.map((filter) => DropdownMenuItem(
                  value: filter,
                  child: Text(
                    filter,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedFilter = value!);
                },
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Total Students', '${_statistics['totalStudents'] ?? 0}', Icons.people_rounded, const Color(0xFF007AFF))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Avg. Score', '${(_statistics['averageScore'] ?? 0.0).toStringAsFixed(1)}%', Icons.trending_up_rounded, const Color(0xFF34C759))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Completion', '${(_statistics['averageCompletionRate'] ?? 0.0).toStringAsFixed(1)}%', Icons.check_circle_rounded, const Color(0xFFFF9500))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF86868B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressChart(),
          const SizedBox(height: 24),
          _buildSubjectBreakdown(),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    if (_students.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded, size: 48, color: Color(0xFF86868B)),
              SizedBox(height: 16),
              Text(
                'No progress data available',
                style: TextStyle(color: Color(0xFF86868B)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
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
          const Text(
            'Average Performance by Subject',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildChartBars(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChartBars() {
    final subjects = [
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
    final colors = [
      const Color(0xFF007AFF),    // Blue
      const Color(0xFF34C759),    // Green
      const Color(0xFFFF9500),    // Orange
      const Color(0xFFFF3B30),    // Red
      const Color(0xFFAF52DE),    // Purple
      const Color(0xFFFF6B35),    // Deep Orange
      const Color(0xFF4ECDC4),    // Teal
      const Color(0xFFFFD93D),    // Yellow
      const Color(0xFF6C5CE7),    // Indigo
      const Color(0xFF00B894),    // Emerald
      const Color(0xFFE84393),    // Pink
    ];

    return subjects.asMap().entries.map((entry) {
      final index = entry.key;
      final subject = entry.value;
      final color = colors[index];
      
      // Calculate average score for this subject from progress data
      final subjectProgress = _studentProgress.where((p) => p.subject == subject).toList();
      final averageScore = subjectProgress.isEmpty 
          ? 0.0 
          : subjectProgress.map((p) => p.averageScore).reduce((a, b) => a + b) / subjectProgress.length;
      
      final barHeight = (averageScore / 100) * 100; // Scale to 100px max height
      
      return Expanded(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: 20,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                height: barHeight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subject.substring(0, 3),
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF86868B),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${averageScore.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSubjectBreakdown() {
    return Container(
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
          const Text(
            'Subject Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          ..._subjects.where((s) => s != 'All').map((subject) {
            final subjectProgress = _studentProgress.where((p) => p.subject == subject).toList();
            final count = subjectProgress.length;
            final avgScore = subjectProgress.isEmpty 
                ? 0.0 
                : subjectProgress.map((p) => p.averageScore).reduce((a, b) => a + b) / subjectProgress.length;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '$count students',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF86868B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${avgScore.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Student Progress',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              Text(
                '${_filteredStudents.length} students',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF86868B),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredStudents.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredStudents.length,
                  itemBuilder: (context, index) {
                    return _buildStudentCard(_filteredStudents[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Student student) {
    // Find progress data for this student
    final studentProgress = _studentProgress.where((p) => p.studentId == student.id).toList();
    final hasProgress = studentProgress.isNotEmpty;
    final progress = hasProgress ? studentProgress.first : null;
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF007AFF),
                child: Text(
                  student.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    Text(
                      student.email,
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
                  color: hasProgress 
                      ? _getScoreColor(progress!.averageScore).withOpacity(0.1)
                      : const Color(0xFF86868B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasProgress 
                      ? '${progress!.averageScore.toStringAsFixed(0)}%'
                      : 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasProgress 
                        ? _getScoreColor(progress!.averageScore)
                        : const Color(0xFF86868B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                  'Progress',
                  hasProgress 
                      ? '${progress!.completionRate.toStringAsFixed(0)}%'
                      : 'No data',
                  hasProgress ? progress!.completionRate : 0.0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressItem(
                  'Lessons',
                  hasProgress 
                      ? '${progress!.lessonsCompleted}/${progress!.totalLessons}'
                      : '0/0',
                  hasProgress 
                      ? (progress!.lessonsCompleted / progress!.totalLessons * 100)
                      : 0.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasProgress 
                ? 'Last activity: ${_formatDate(progress!.lastActivity)}'
                : 'Joined: ${_formatDate(student.joinedAt)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, double percentage) {
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
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: const Color(0xFFE5E5E7),
          valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(percentage)),
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ),
        Expanded(
          child: _recentActivity.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recentActivity.length,
                  itemBuilder: (context, index) {
                    return _buildActivityCard(_recentActivity[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final isLesson = activity['type'] == 'lesson_completed';
    final icon = isLesson ? Icons.book_rounded : Icons.quiz_rounded;
    final color = isLesson ? const Color(0xFF34C759) : const Color(0xFFFF9500);
    final title = activity['lessonTitle'] ?? activity['assessmentTitle'] ?? 'Unknown';
    final studentName = activity['studentName'] ?? 'Unknown Student';
    final score = activity['score']?.toString() ?? 'N/A';
    final timestamp = activity['timestamp'] as int?;
    
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$studentName ${isLesson ? 'completed lesson' : 'completed assessment'}: $title',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Score: $score',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF86868B),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (timestamp != null)
                      Text(
                        _formatDate(DateTime.fromMillisecondsSinceEpoch(timestamp)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF86868B),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEmptyStateIcon(),
            size: 64,
            color: const Color(0xFF86868B),
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateMessage(),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_tabController.index) {
      case 0:
        return Icons.bar_chart_rounded;
      case 1:
        return Icons.people_rounded;
      case 2:
        return Icons.timeline_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getEmptyStateMessage() {
    switch (_tabController.index) {
      case 0:
        return 'No progress data available\nStart by creating lessons and assessments';
      case 1:
        return 'No students found\nStudents will appear here once they start using the app';
      case 2:
        return 'No recent activity\nActivity will appear here as students complete lessons';
      default:
        return 'No data available';
    }
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
