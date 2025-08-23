import 'package:flutter/material.dart';
import '../models/learning_path.dart';
import '../models/student.dart';
import '../models/user_model.dart';
import '../services/learning_path_service.dart';
import '../services/student_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/offline_indicator.dart';

class LearningPathAssignmentScreen extends StatefulWidget {
  final UserModel teacherProfile;
  
  const LearningPathAssignmentScreen({
    super.key,
    required this.teacherProfile,
  });

  @override
  State<LearningPathAssignmentScreen> createState() => _LearningPathAssignmentScreenState();
}

class _LearningPathAssignmentScreenState extends State<LearningPathAssignmentScreen> {
  final LearningPathService _learningPathService = LearningPathService();
  final StudentService _studentService = StudentService();
  
  List<LearningPath> _availableLearningPaths = [];
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  String? _error;
  
  String? _selectedSubject;
  String _searchQuery = '';
  
  // Assignment state
  LearningPath? _selectedLearningPath;
  List<Student> _selectedStudents = [];
  Map<String, dynamic> _customizations = {};
  
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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load learning paths and students in parallel
      final futures = await Future.wait([
        _learningPathService.getAllLearningPaths(),
        _studentService.getAllStudents(),
      ]);

      setState(() {
        _availableLearningPaths = futures[0] as List<LearningPath>;
        _students = futures[1] as List<Student>;
        _filteredStudents = futures[1] as List<Student>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterStudents() {
    List<Student> filtered = _students;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((student) =>
        student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        student.email.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Filter by subject
    if (_selectedSubject != null && _selectedSubject != 'All') {
      filtered = filtered.where((student) =>
        student.subjects.contains(_selectedSubject!)
      ).toList();
    }
    
    setState(() {
      _filteredStudents = filtered;
    });
  }

  void _toggleStudentSelection(Student student) {
    setState(() {
      if (_selectedStudents.contains(student)) {
        _selectedStudents.remove(student);
      } else {
        _selectedStudents.add(student);
      }
    });
  }

  void _selectAllStudents() {
    setState(() {
      _selectedStudents = List.from(_filteredStudents);
    });
  }

  void _deselectAllStudents() {
    setState(() {
      _selectedStudents.clear();
    });
  }

  void _updateCustomization(String key, dynamic value) {
    setState(() {
      _customizations[key] = value;
    });
  }

  Future<void> _assignLearningPaths() async {
    if (_selectedLearningPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a learning path')),
      );
      return;
    }

    if (_selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one student')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      // Assign learning path to each selected student
      for (final student in _selectedStudents) {
        await _learningPathService.assignLearningPathToStudent(
          student.id,
          student.name,
          _selectedLearningPath!.id,
          _selectedLearningPath!.title,
          _customizations,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Learning path assigned to ${_selectedStudents.length} student${_selectedStudents.length == 1 ? '' : 's'} successfully'
          ),
        ),
      );

      // Reset selection
      setState(() {
        _selectedStudents.clear();
        _selectedLearningPath = null;
        _customizations.clear();
      });

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning learning paths: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Assign Learning Paths',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        elevation: 0,
        shadowColor: const Color(0xFF000000).withValues(alpha: 0.04),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!ConnectivityService().isConnected)
            const OfflineIndicator(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Learning Path Selection
                    _buildLearningPathSection(),
                    
                    // Student Selection
                    _buildStudentSelectionSection(),
                    
                    // Customization Options
                    _buildCustomizationSection(),
                    
                    // Assignment Button
                    _buildAssignmentButton(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFFFF3B30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: const TextStyle(color: Color(0xFF86868B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPathSection() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          const Text(
            'Select Learning Path',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          
          if (_availableLearningPaths.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No published learning paths available',
                  style: TextStyle(color: Color(0xFF86868B)),
                ),
              ),
            )
          else
            ..._availableLearningPaths.map((path) => _buildLearningPathOption(path)),
        ],
      ),
    );
  }

  Widget _buildLearningPathOption(LearningPath path) {
    final isSelected = _selectedLearningPath?.id == path.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF007AFF).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5E7),
        ),
      ),
      child: RadioListTile<LearningPath>(
        value: path,
        groupValue: _selectedLearningPath,
        onChanged: (value) {
          setState(() {
            _selectedLearningPath = value;
          });
        },
        title: Text(
          path.title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(path.description),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(Icons.format_list_numbered, '${path.steps.length} steps'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.schedule, '${path.steps.fold<int>(0, (sum, step) => sum + step.estimatedDuration)} min'),
                if (path.subjects.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.subject, path.subjects.first),
                ],
              ],
            ),
          ],
        ),
        activeColor: const Color(0xFF007AFF),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF86868B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelectionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_rounded, color: Color(0xFF007AFF)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Students',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      Text(
                        '${_selectedStudents.length} of ${_filteredStudents.length} selected',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _selectAllStudents,
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: _deselectAllStudents,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF5F5F7),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _filterStudents();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E5E7)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: InputBorder.none,
                        hintText: 'Subject',
                      ),
                      items: _subjects.map((subject) => DropdownMenuItem(
                        value: subject == 'All' ? null : subject,
                        child: Text(subject),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value;
                        });
                        _filterStudents();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Student List
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: _filteredStudents.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No students found',
                        style: TextStyle(color: Color(0xFF86868B)),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final isSelected = _selectedStudents.contains(student);
                      
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) => _toggleStudentSelection(student),
                        title: Text(
                          student.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(student.email),
                        secondary: CircleAvatar(
                          backgroundColor: const Color(0xFF007AFF),
                          child: Text(
                            student.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        activeColor: const Color(0xFF007AFF),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationSection() {
    if (_selectedLearningPath == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
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
          const Text(
            'Customization Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          
          // Difficulty Level
          _buildCustomizationItem(
            'Difficulty Level',
            'Set the difficulty level for this student',
            [
              'Beginner',
              'Intermediate',
              'Advanced',
            ],
            'difficulty',
            'Intermediate',
          ),
          
          const SizedBox(height: 16),
          
          // Learning Pace
          _buildCustomizationItem(
            'Learning Pace',
            'Adjust the pace of learning',
            [
              'Slow',
              'Normal',
              'Fast',
            ],
            'pace',
            'Normal',
          ),
          
          const SizedBox(height: 16),
          
          // Additional Support
          SwitchListTile(
            title: const Text('Additional Support'),
            subtitle: const Text('Provide extra help and resources'),
            value: _customizations['additionalSupport'] ?? false,
            onChanged: (value) => _updateCustomization('additionalSupport', value),
            activeColor: const Color(0xFF007AFF),
          ),
          
          const SizedBox(height: 16),
          
          // Notes
          TextField(
            decoration: const InputDecoration(
              labelText: 'Teacher Notes',
              hintText: 'Add any specific notes for this student...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF5F5F7),
            ),
            maxLines: 3,
            onChanged: (value) => _updateCustomization('notes', value),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationItem(
    String title,
    String subtitle,
    List<String> options,
    String key,
    String defaultValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF86868B),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) => ChoiceChip(
            label: Text(option),
            selected: _customizations[key] == option,
            onSelected: (selected) {
              if (selected) {
                _updateCustomization(key, option);
              }
            },
            selectedColor: const Color(0xFF007AFF).withOpacity(0.2),
            labelStyle: TextStyle(
              color: _customizations[key] == option 
                  ? const Color(0xFF007AFF)
                  : const Color(0xFF1D1D1F),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildAssignmentButton() {
    final canAssign = _selectedLearningPath != null && _selectedStudents.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5E7)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canAssign && !_isLoading ? _assignLearningPaths : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Assign to ${_selectedStudents.length} Student${_selectedStudents.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
