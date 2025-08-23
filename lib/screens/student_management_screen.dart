import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import '../models/user_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class StudentManagementScreen extends StatefulWidget {
  final UserModel teacherProfile;
  
  const StudentManagementScreen({
    super.key,
    required this.teacherProfile,
  });

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen>
    with TickerProviderStateMixin {
  final StudentService _studentService = StudentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Student> _students = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _selectedGrade = 'Grade 7';
  String _searchQuery = '';
  
  late TabController _tabController;
  
  final List<String> _filters = ['All', 'Active', 'Inactive'];
  final List<String> _grades = ['Grade 7'];
  final String _defaultGrade = 'Grade 7';
  final List<String> _subjects = [
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
    _tabController = TabController(length: 2, vsync: this);
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
        print('🔍 StudentManagement: Loading data for teacher: $teacherId');
        print('🔍 StudentManagement: Current user email: ${_auth.currentUser?.email}');
        
        // Load ALL students in the system, not just teacher's students
        final DatabaseReference ref = FirebaseDatabase.instance.ref('students');
        final DatabaseEvent event = await ref.once();
        final DataSnapshot snapshot = event.snapshot;
        
        print('🔍 StudentManagement: Firebase students snapshot exists: ${snapshot.exists}');
        if (snapshot.value != null) {
          final data = snapshot.value as Map<dynamic, dynamic>?;
          print('🔍 StudentManagement: Total students in Firebase: ${data?.length ?? 0}');
          print('🔍 StudentManagement: Firebase data keys: ${data?.keys.toList()}');
          
          // Log each student's data structure
          data?.forEach((key, value) {
            print('🔍 StudentManagement: Student $key: $value');
            if (value is Map) {
              print('🔍 StudentManagement: Student $key teacherId: ${value['teacherId']}');
              print('🔍 StudentManagement: Student $key name: ${value['name']}');
            }
          });
        }
        
        // Get all students from the service
        final students = await _studentService.getAllStudents();
        print('🔍 StudentManagement: Loaded ${students.length} students from service');
        
        final stats = await _studentService.getStudentStatistics(teacherId);
        print('🔍 StudentManagement: Loaded statistics: $stats');
        
        setState(() {
          _students = students;
          _statistics = stats;
          _isLoading = false;
        });
      } else {
        print('🔍 StudentManagement: No teacher ID found');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('🔍 StudentManagement: Error loading student data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Student> get _filteredStudents {
    List<Student> filtered = _students;
    
    // Filter by status
    if (_selectedFilter == 'Active') {
      filtered = filtered.where((s) => s.isActive).toList();
    } else if (_selectedFilter == 'Inactive') {
      filtered = filtered.where((s) => !s.isActive).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) {
        return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               s.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               s.grade.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               s.section.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Student Management',
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
                      Tab(text: 'Students'),
                      Tab(text: 'Analytics'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStudentsTab(),
                      _buildAnalyticsTab(),
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
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5E7)),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search students...',
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF86868B)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter dropdowns
          Container(
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
                hintText: 'Status',
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
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final totalStudents = _statistics['totalStudents'] as int? ?? 0;
    final activeStudents = _statistics['activeStudents'] as int? ?? 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Total Students', '$totalStudents', Icons.people_rounded, const Color(0xFF007AFF))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Active Students', '$activeStudents', Icons.check_circle_rounded, const Color(0xFF34C759))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Subjects', '${_subjects.length}', Icons.book_rounded, const Color(0xFFFF9500))),
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
                'All Students',
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
                backgroundColor: student.isActive ? const Color(0xFF34C759) : const Color(0xFF86868B),
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
                    Text(
                      '${student.grade} - Section ${student.section}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF007AFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) => _handleStudentAction(action, student),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: student.isActive ? 'deactivate' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          student.isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                          size: 18,
                          color: student.isActive ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(student.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert_rounded, color: Color(0xFF86868B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Current subjects
          if (student.subjects.isNotEmpty) ...[
            Text(
              'Current Subjects:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: student.subjects.map((subject) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF007AFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeSubjectFromStudent(student, subject),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],
          
          // Add subject button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddSubjectDialog(student),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Subject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF007AFF),
                side: const BorderSide(color: Color(0xFF007AFF)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grade 7 Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 24),
          _buildGradeDistribution(),
          const SizedBox(height: 24),
          _buildSubjectDistribution(),
        ],
      ),
    );
  }

  Widget _buildGradeDistribution() {
    final gradeStats = _statistics['gradeDistribution'] != null && _statistics['gradeDistribution'] is Map
        ? Map<String, dynamic>.from(_statistics['gradeDistribution'] as Map)
        : <String, dynamic>{};
    
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
            'Grade Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          ..._grades.map((grade) {
            final count = gradeStats[grade] ?? 0;
            final percentage = _students.isEmpty ? 0.0 : (count / _students.length) * 100;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        grade,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      Text(
                        '$count students (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: const Color(0xFFE5E5E7),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubjectDistribution() {
    final subjectStats = _statistics['subjectDistribution'] != null && _statistics['subjectDistribution'] is Map
        ? Map<String, dynamic>.from(_statistics['subjectDistribution'] as Map)
        : <String, dynamic>{};
    
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
            'Subject Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          ..._subjects.map((subject) {
            final count = subjectStats[subject] ?? 0;
            final percentage = _students.isEmpty ? 0.0 : (count / _students.length) * 100;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      Text(
                        '$count students (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: const Color(0xFFE5E5E7),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
                  ),
                ],
              ),
            );
          }),
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
        return Icons.people_rounded;
      case 1:
        return Icons.analytics_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getEmptyStateMessage() {
    switch (_tabController.index) {
      case 0:
        return 'No students found\nAdd your first student to get started';
      case 1:
        return 'No analytics available\nStudent data will appear here';
      default:
        return 'No data available';
    }
  }

  void _handleStudentAction(String action, Student student) {
    switch (action) {
      case 'edit':
        // TODO: Implement edit student
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit student coming soon!')),
        );
        break;
      case 'activate':
      case 'deactivate':
        _toggleStudentStatus(student);
        break;
      case 'delete':
        _showDeleteConfirmation(student);
        break;
    }
  }

  Future<void> _toggleStudentStatus(Student student) async {
    final success = await _studentService.toggleStudentStatus(
      student.id,
      !student.isActive,
    );
    
    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student ${student.isActive ? 'deactivated' : 'activated'} successfully'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update student status')),
      );
    }
  }

  void _showDeleteConfirmation(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _studentService.deleteStudent(student.id);
              if (success) {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${student.name} deleted successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete student')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
            ),
            child: const Text('Delete'),
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
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }





  // Remove subject from student
  Future<void> _removeSubjectFromStudent(Student student, String subject) async {
    try {
      final updatedSubjects = List<String>.from(student.subjects)..remove(subject);
      final updatedStudent = student.copyWith(subjects: updatedSubjects);
      
      final success = await _studentService.updateStudent(updatedStudent);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed $subject from ${student.name}')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove subject')),
        );
      }
    } catch (e) {
      print('Error removing subject: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Show dialog to add subject to student
  void _showAddSubjectDialog(Student student) {
    String? selectedSubject;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Subject to ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select a subject to add:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              items: _subjects
                  .where((subject) => !student.subjects.contains(subject))
                  .map((subject) => DropdownMenuItem(
                    value: subject,
                    child: Text(subject),
                  )).toList(),
              onChanged: (value) => selectedSubject = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: selectedSubject == null ? null : () async {
              Navigator.pop(context);
              await _addSubjectToStudent(student, selectedSubject!);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Add subject to student
  Future<void> _addSubjectToStudent(Student student, String subject) async {
    try {
      final updatedSubjects = List<String>.from(student.subjects)..add(subject);
      final updatedStudent = student.copyWith(subjects: updatedSubjects);
      
      final success = await _studentService.updateStudent(updatedStudent);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $subject to ${student.name}')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add subject')),
        );
      }
    } catch (e) {
      print('Error adding subject: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
