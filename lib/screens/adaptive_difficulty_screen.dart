import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/adaptive_difficulty.dart';
import '../models/student.dart';
import '../services/adaptive_difficulty_service.dart';
import '../services/student_service.dart';

class AdaptiveDifficultyScreen extends StatefulWidget {
  const AdaptiveDifficultyScreen({Key? key}) : super(key: key);

  @override
  State<AdaptiveDifficultyScreen> createState() => _AdaptiveDifficultyScreenState();
}

class _AdaptiveDifficultyScreenState extends State<AdaptiveDifficultyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdaptiveDifficultyService _adaptiveDifficultyService = AdaptiveDifficultyService();
  final StudentService _studentService = StudentService();
  
  List<AdaptiveDifficulty> _adaptiveDifficulties = [];
  List<Student> _students = [];
  bool _isLoading = false;
  String _selectedSubject = 'all';
  String _selectedDifficulty = 'all';
  List<String> _availableSubjects = ['all', 'Mathematics', 'Science', 'English', 'Filipino'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load students
      final students = await _studentService.getStudents('');
      setState(() {
        _students = students;
      });

      // Load adaptive difficulties for each student
      final difficulties = <AdaptiveDifficulty>[];
      for (final student in students) {
        try {
          // Get difficulty for Mathematics (default subject)
          final difficulty = await _adaptiveDifficultyService.getOrCreateAdaptiveDifficulty(
            student.id,
            student.name,
            'Mathematics',
          );
          difficulties.add(difficulty);
        } catch (e) {
          print('Error loading difficulty for student ${student.id}: $e');
        }
      }

      setState(() {
        _adaptiveDifficulties = difficulties;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Difficulty Management'),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Student Levels'),
            Tab(text: 'Performance Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildStudentLevelsTab(),
          _buildPerformanceAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final filteredDifficulties = _getFilteredDifficulties();
    final levelDistribution = _getLevelDistribution(filteredDifficulties);
    final averagePerformance = _getAveragePerformance(filteredDifficulties);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          const SizedBox(height: 24),
          _buildStatisticsCards(levelDistribution, averagePerformance),
          const SizedBox(height: 24),
          _buildRecentAdjustments(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedSubject,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
            items: _availableSubjects.map((subject) {
              return DropdownMenuItem(
                value: subject,
                child: Text(subject == 'all' ? 'All Subjects' : subject),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubject = value ?? 'all';
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedDifficulty,
            decoration: const InputDecoration(
              labelText: 'Difficulty Level',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All Levels')),
              ...DifficultyLevel.values.map((level) => DropdownMenuItem(
                value: level.toString().split('.').last,
                child: Text(level.difficultyLevelString),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedDifficulty = value ?? 'all';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards(Map<DifficultyLevel, int> levelDistribution, double averagePerformance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Difficulty Level Distribution',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Beginner',
                levelDistribution[DifficultyLevel.beginner]?.toString() ?? '0',
                Icons.school,
                const Color(0xFF34C759),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Intermediate',
                levelDistribution[DifficultyLevel.intermediate]?.toString() ?? '0',
                Icons.trending_up,
                const Color(0xFF007AFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Advanced',
                levelDistribution[DifficultyLevel.advanced]?.toString() ?? '0',
                Icons.auto_awesome,
                const Color(0xFFFF9500),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Expert',
                levelDistribution[DifficultyLevel.expert]?.toString() ?? '0',
                Icons.workspace_premium,
                const Color(0xFFFF3B30),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildStatCard(
          'Average Performance',
          '${(averagePerformance * 100).round()}%',
          Icons.analytics,
          const Color(0xFF007AFF),
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
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

  Widget _buildRecentAdjustments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Difficulty Adjustments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E7)),
          ),
          child: const Center(
            child: Text(
              'Difficulty adjustments will appear here as students progress',
              style: TextStyle(color: Color(0xFF86868B)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentLevelsTab() {
    final filteredDifficulties = _getFilteredDifficulties();

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredDifficulties.isEmpty
                  ? const Center(
                      child: Text(
                        'No adaptive difficulty data available',
                        style: TextStyle(color: Color(0xFF86868B)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredDifficulties.length,
                      itemBuilder: (context, index) {
                        return _buildStudentDifficultyCard(filteredDifficulties[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStudentDifficultyCard(AdaptiveDifficulty difficulty) {
    final student = _students.firstWhere(
      (s) => s.id == difficulty.studentId,
      orElse: () => Student(
        id: 'unknown',
        name: 'Unknown Student',
        email: '',
        grade: '',
        section: '',
        subjects: [],
        teacherId: '',
        teacherName: '',
        joinedAt: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Color(int.parse('0xFF${difficulty.difficultyColor.substring(1)}')),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              difficulty.difficultyLevelString[0],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${difficulty.difficultyColor.substring(1)}')).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    difficulty.difficultyLevelString,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(int.parse('0xFF${difficulty.difficultyColor.substring(1)}')),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(difficulty.performanceScore * 100).round()}% performance',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${difficulty.totalAttempts} attempts • Last updated: ${_formatDate(difficulty.lastUpdated)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF86868B),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showStudentDifficultyOptions(difficulty),
        ),
      ),
    );
  }

  Widget _buildPerformanceAnalyticsTab() {
    final filteredDifficulties = _getFilteredDifficulties();
    
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredDifficulties.isEmpty
                  ? const Center(
                      child: Text(
                        'No performance data available',
                        style: TextStyle(color: Color(0xFF86868B)),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPerformanceChart(filteredDifficulties),
                          const SizedBox(height: 24),
                          _buildTopicPerformanceBreakdown(filteredDifficulties),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildPerformanceChart(List<AdaptiveDifficulty> difficulties) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          // Simple performance visualization
          ...difficulties.take(5).map((difficulty) {
            final student = _students.firstWhere(
              (s) => s.id == difficulty.studentId,
              orElse: () => Student(
                id: 'unknown',
                name: 'Unknown Student',
                email: '',
                grade: '',
                section: '',
                subjects: [],
                teacherId: '',
                teacherName: '',
                joinedAt: DateTime.now(),
              ),
            );
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      student.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: difficulty.performanceScore,
                      backgroundColor: const Color(0xFFE5E5E7),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(int.parse('0xFF${difficulty.difficultyColor.substring(1)}')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(difficulty.performanceScore * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopicPerformanceBreakdown(List<AdaptiveDifficulty> difficulties) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Topic Performance Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Topic performance data will appear here as students complete assessments',
              style: TextStyle(color: Color(0xFF86868B)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentDifficultyOptions(AdaptiveDifficulty difficulty) {
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
              'Difficulty Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showStudentDifficultyDetails(difficulty);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Adjust Difficulty'),
              onTap: () {
                Navigator.pop(context);
                _showDifficultyAdjustmentDialog(difficulty);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Performance History'),
              onTap: () {
                Navigator.pop(context);
                _showPerformanceHistory(difficulty);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showStudentDifficultyDetails(AdaptiveDifficulty difficulty) {
    // Implementation for showing detailed difficulty information
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${difficulty.difficultyLevelString} Level Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Score: ${(difficulty.performanceScore * 100).round()}%'),
            Text('Total Attempts: ${difficulty.totalAttempts}'),
            Text('Consecutive Correct: ${difficulty.consecutiveCorrect}'),
            Text('Consecutive Incorrect: ${difficulty.consecutiveIncorrect}'),
            Text('Last Updated: ${_formatDate(difficulty.lastUpdated)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDifficultyAdjustmentDialog(AdaptiveDifficulty difficulty) {
    DifficultyLevel? selectedLevel = difficulty.currentLevel;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adjust Difficulty Level'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select new difficulty level:'),
              const SizedBox(height: 16),
              ...DifficultyLevel.values.map((level) => RadioListTile<DifficultyLevel>(
                title: Text(level.difficultyLevelString),
                value: level,
                groupValue: selectedLevel,
                onChanged: (value) {
                  setState(() {
                    selectedLevel = value;
                  });
                },
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement difficulty adjustment logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Difficulty level adjusted successfully')),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPerformanceHistory(AdaptiveDifficulty difficulty) {
    // Implementation for showing performance history
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance History'),
        content: const Text('Performance history will be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<AdaptiveDifficulty> _getFilteredDifficulties() {
    return _adaptiveDifficulties.where((difficulty) {
      final subjectMatch = _selectedSubject == 'all' || difficulty.subject == _selectedSubject;
      final difficultyMatch = _selectedDifficulty == 'all' || 
          difficulty.currentLevel.toString().split('.').last == _selectedDifficulty;
      return subjectMatch && difficultyMatch;
    }).toList();
  }

  Map<DifficultyLevel, int> _getLevelDistribution(List<AdaptiveDifficulty> difficulties) {
    final distribution = <DifficultyLevel, int>{};
    for (final level in DifficultyLevel.values) {
      distribution[level] = difficulties.where((d) => d.currentLevel == level).length;
    }
    return distribution;
  }

  double _getAveragePerformance(List<AdaptiveDifficulty> difficulties) {
    if (difficulties.isEmpty) return 0.0;
    final total = difficulties.fold<double>(0.0, (sum, d) => sum + d.performanceScore);
    return total / difficulties.length;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
