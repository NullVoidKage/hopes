import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_rating.dart';
import '../models/user_model.dart';
import '../models/student.dart';
import '../services/rating_service.dart';
import '../services/student_service.dart';

class StudentRatingsScreen extends StatefulWidget {
  final UserModel teacherProfile;

  const StudentRatingsScreen({
    super.key,
    required this.teacherProfile,
  });

  @override
  State<StudentRatingsScreen> createState() => _StudentRatingsScreenState();
}

class _StudentRatingsScreenState extends State<StudentRatingsScreen> {
  final RatingService _ratingService = RatingService();
  final StudentService _studentService = StudentService();
  
  List<StudentRating> _allRatings = [];
  List<StudentRating> _filteredRatings = [];
  bool _isLoading = true;
  bool _isCalculating = false;
  
  // Filter state
  String? _selectedStudentId;
  String? _selectedSection;
  String? _selectedSubject;
  String _viewMode = 'overall'; // 'overall', 'per_section', 'per_subject', 'per_student'
  
  // Available options
  List<String> _availableSections = ['A', 'B', 'C', 'D'];
  List<String> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final ratings = await _ratingService.getTeacherRatings(
          teacherId: currentUser.uid,
          studentId: _selectedStudentId,
          sectionId: _selectedSection,
          subjectId: _selectedSubject,
        );
        
        // Extract unique values for filters
        final subjects = ratings.map((r) => r.subjectName).toSet().toList();
        
        setState(() {
          _allRatings = ratings;
          _availableSubjects = subjects;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading ratings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = _allRatings;
    
    // Apply view mode filters
    if (_viewMode == 'per_section' && _selectedSection != null) {
      filtered = filtered.where((r) => r.sectionName == _selectedSection).toList();
    } else if (_viewMode == 'per_subject' && _selectedSubject != null) {
      filtered = filtered.where((r) => r.subjectName == _selectedSubject).toList();
    } else if (_viewMode == 'per_student' && _selectedStudentId != null) {
      filtered = filtered.where((r) => r.studentId == _selectedStudentId).toList();
    }
    
    // Apply additional filters
    if (_selectedStudentId != null && _viewMode != 'per_student') {
      filtered = filtered.where((r) => r.studentId == _selectedStudentId).toList();
    }
    if (_selectedSection != null && _viewMode != 'per_section') {
      filtered = filtered.where((r) => r.sectionName == _selectedSection).toList();
    }
    if (_selectedSubject != null && _viewMode != 'per_subject') {
      filtered = filtered.where((r) => r.subjectName == _selectedSubject).toList();
    }
    
    setState(() {
      _filteredRatings = filtered;
    });
  }

  double _calculateOverallRating() {
    if (_filteredRatings.isEmpty) return 0.0;
    final total = _filteredRatings.map((r) => r.rating).reduce((a, b) => a + b);
    return total / _filteredRatings.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Student Ratings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isLoading && _allRatings.isEmpty)
            IconButton(
              icon: _isCalculating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isCalculating ? null : _calculateAllRatings,
              tooltip: 'Calculate Ratings',
            ),
        ],
      ),
      body: Column(
        children: [
          // View Mode Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'View Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildViewModeChip('Overall', 'overall'),
                      const SizedBox(width: 8),
                      _buildViewModeChip('Per Section', 'per_section'),
                      const SizedBox(width: 8),
                      _buildViewModeChip('Per Subject', 'per_subject'),
                      const SizedBox(width: 8),
                      _buildViewModeChip('Per Student', 'per_student'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSection,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Sections')),
                      ..._availableSections.map((section) => DropdownMenuItem(
                        value: section,
                        child: Text('Section $section'),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSection = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Subjects')),
                      ..._availableSubjects.map((subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Overall Rating Card (if overall view)
          if (_viewMode == 'overall' && _filteredRatings.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Overall Average Rating',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _calculateOverallRating().toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(_calculateOverallRating()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on ${_filteredRatings.length} rating(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF86868B),
                    ),
                  ),
                ],
              ),
            ),
          
          // Ratings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRatings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No ratings found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ratings will appear here once students complete assessments and lessons',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRatings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRatings.length,
                          itemBuilder: (context, index) {
                            return _buildRatingCard(_filteredRatings[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeChip(String label, String value) {
    final isSelected = _viewMode == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _viewMode = value;
            // Clear filters when switching modes
            if (value == 'overall') {
              _selectedSection = null;
              _selectedSubject = null;
              _selectedStudentId = null;
            }
          });
          _applyFilters();
        }
      },
      backgroundColor: const Color(0xFFF5F5F7),
      selectedColor: const Color(0xFF007AFF),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1D1D1F),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildRatingCard(StudentRating rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRatingColor(rating.rating).withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: _getRatingColor(rating.rating),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text('Section ${rating.sectionName}'),
                            backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                          Chip(
                            label: Text(rating.subjectName),
                            backgroundColor: const Color(0xFF34C759).withOpacity(0.1),
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF34C759),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getRatingColor(rating.rating).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rating.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(rating.rating),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Category Ratings
            Row(
              children: [
                Expanded(
                  child: _buildCategoryRating(
                    'Assessments',
                    rating.averageAssessmentScore,
                    rating.completedAssessments,
                    rating.totalAssessments,
                    Icons.quiz,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryRating(
                    'Lessons',
                    rating.averageLessonProgress * 100,
                    rating.completedLessons,
                    rating.totalLessons,
                    Icons.menu_book,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Progress indicators
            _buildProgressBar('Assessments', rating.completedAssessments, rating.totalAssessments),
            const SizedBox(height: 8),
            _buildProgressBar('Lessons', rating.completedLessons, rating.totalLessons),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRating(String label, double score, int completed, int total, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF86868B)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF86868B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          Text(
            '$completed/$total completed',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int completed, int total) {
    final percentage = total > 0 ? completed / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF86868B),
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: const Color(0xFFE5E5E7),
          valueColor: AlwaysStoppedAnimation<Color>(
            _getRatingColor(percentage * 100),
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 80) return const Color(0xFF34C759); // Green
    if (rating >= 60) return const Color(0xFFFF9500); // Orange
    return const Color(0xFFFF3B30); // Red
  }

  Future<void> _calculateAllRatings() async {
    setState(() {
      _isCalculating = true;
    });

    try {
      // Get all students
      final students = await _studentService.getAllStudents();
      
      // Filter students by teacher's subjects if not admin
      final teacherSubjects = widget.teacherProfile.subjects ?? [];
      final isAdmin = widget.teacherProfile.isAdministrator;
      
      List<Student> filteredStudents = students;
      if (!isAdmin && teacherSubjects.isNotEmpty) {
        filteredStudents = students.where((student) {
          return student.subjects.any((subject) => teacherSubjects.contains(subject));
        }).toList();
      }

      // Prepare student data for rating calculation
      final studentDataList = filteredStudents.map((student) {
        return {
          'id': student.id,
          'name': student.name,
          'section': student.section,
          'subjects': student.subjects,
          'schoolYear': widget.teacherProfile.schoolYear ?? '2024-2025',
        };
      }).toList();

      // Calculate ratings
      final calculatedCount = await _ratingService.calculateAllTeacherRatings(
        teacherId: widget.teacherProfile.uid,
        teacherName: widget.teacherProfile.displayName,
        students: studentDataList,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calculated $calculatedCount ratings. Refreshing...'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload ratings
        await _loadRatings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating ratings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
      }
    }
  }
}

