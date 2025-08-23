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
        print('🔍 MonitorProgress: Loading data for teacher: $teacherId');
        print('🔍 MonitorProgress: Current user email: ${_auth.currentUser?.email}');
        
        // First, let's check what's actually in the student_progress collection
        final DatabaseReference ref = FirebaseDatabase.instance.ref('student_progress');
        final DatabaseEvent event = await ref.once();
        final DataSnapshot snapshot = event.snapshot;
        
        print('🔍 MonitorProgress: Firebase student_progress snapshot exists: ${snapshot.exists}');
        if (snapshot.value != null) {
          final data = snapshot.value as Map<dynamic, dynamic>?;
          print('🔍 MonitorProgress: Total progress items in Firebase: ${data?.length ?? 0}');
          print('🔍 MonitorProgress: Firebase data keys: ${data?.keys.toList()}');
          
          // Log each progress item's data structure
          data?.forEach((key, value) {
            print('🔍 MonitorProgress: Progress $key: $value');
            if (value is Map) {
              print('🔍 MonitorProgress: Progress $key teacherId: ${value['teacherId']}');
              print('🔍 MonitorProgress: Progress $key studentName: ${value['studentName']}');
            }
          });
        }
        
        // Get students from Firestore (like Student Management does)
        final students = await _studentService.getAllStudents();
        print('🔍 MonitorProgress: Loaded ${students.length} students from Firestore');
        
        // Get progress data for those students
        final progress = await _progressService.getStudentProgress(teacherId);
        print('🔍 MonitorProgress: Loaded ${progress.length} progress items');
        
        // Calculate statistics from student data (like Student Management does)
        final stats = _calculateStatistics(students);
        print('🔍 MonitorProgress: Calculated statistics: $stats');
        
        final activity = await _progressService.getRecentActivity(teacherId);
        print('🔍 MonitorProgress: Loaded activity: ${activity.length} items');
        
        print('🔍 MonitorProgress: Setting state with ${students.length} students');
        print('🔍 MonitorProgress: First student: ${students.isNotEmpty ? students.first.name : 'No students'}');
        print('🔍 MonitorProgress: First student subjects: ${students.isNotEmpty ? students.first.subjects : 'No subjects'}');
        
        setState(() {
          _students = students;
          _studentProgress = progress;
          _statistics = stats;
          _recentActivity = activity;
          _isLoading = false;
        });
        
        print('🔍 MonitorProgress: State updated. _students length: ${_students.length}');
        print('🔍 MonitorProgress: _filteredStudents length: ${_filteredStudents.length}');
      }
    } catch (e) {
      print('🔍 MonitorProgress: Error loading progress data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Calculate statistics from student data (like Student Management does)
  Map<String, dynamic> _calculateStatistics(List<Student> students) {
    final totalStudents = students.length;
    
    // Calculate grade distribution
    final gradeDistribution = <String, int>{};
    for (final student in students) {
      final grade = student.grade;
      gradeDistribution[grade] = (gradeDistribution[grade] ?? 0) + 1;
    }
    
    // Calculate subject distribution
    final subjectDistribution = <String, int>{};
    for (final student in students) {
      for (final subject in student.subjects) {
        subjectDistribution[subject] = (subjectDistribution[subject] ?? 0) + 1;
      }
    }
    
    return {
      'totalStudents': totalStudents,
      'gradeDistribution': gradeDistribution,
      'subjectDistribution': subjectDistribution,
      'averageScore': 0.0, // TODO: Calculate from progress data
      'averageCompletionRate': 0.0, // TODO: Calculate from progress data
    };
  }

  List<Student> get _filteredStudents {
    print('🔍 MonitorProgress: _filteredStudents called. _students length: ${_students.length}');
    print('🔍 MonitorProgress: _selectedSubject: $_selectedSubject');
    print('🔍 MonitorProgress: _selectedFilter: $_selectedFilter');
    
    List<Student> filtered = _students;
    
    // Filter by subject (check if student has the selected subject)
    if (_selectedSubject != 'All') {
      filtered = filtered.where((s) => s.subjects.contains(_selectedSubject)).toList();
      print('🔍 MonitorProgress: After subject filter: ${filtered.length} students');
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
    
    print('🔍 MonitorProgress: Final filtered students: ${filtered.length}');
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
      child: Row(
        children: [
          Expanded(
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
                  child: Text(subject),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedSubject = value!);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                  child: Text(filter),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedFilter = value!);
                },
              ),
            ),
          ),
        ],
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
      
      // Calculate average score for this subject
      final subjectStudents = _students.where((s) => s.subjects.contains(subject)).toList();
      final averageScore = subjectStudents.isEmpty 
          ? 0.0 
          : 0.0; // TODO: Calculate from progress data
      
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
            final subjectStudents = _students.where((s) => s.subjects.contains(subject)).toList();
            final count = subjectStudents.length;
            final avgScore = subjectStudents.isEmpty 
                ? 0.0 
                : 0.0; // TODO: Calculate from progress data
            
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
    print('🔍 MonitorProgress: Building Students tab');
    print('🔍 MonitorProgress: _students length: ${_students.length}');
    print('🔍 MonitorProgress: _filteredStudents length: ${_filteredStudents.length}');
    
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
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF007AFF),
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
                  'Subjects',
                  '${student.subjects.length} enrolled',
                  100.0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressItem(
                  'Grade',
                  '${student.grade} - ${student.section}',
                  100.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Joined: ${_formatDate(student.joinedAt)}',
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
    final title = activity['title'] ?? 'Unknown';
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
                  '$studentName completed $title',
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
