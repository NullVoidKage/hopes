import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';

class ClassCreationScreen extends StatefulWidget {
  final UserModel teacherProfile;

  const ClassCreationScreen({
    super.key,
    required this.teacherProfile,
  });

  @override
  State<ClassCreationScreen> createState() => _ClassCreationScreenState();
}

class _ClassCreationScreenState extends State<ClassCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ClassService _classService = ClassService();
  final AuthService _authService = AuthService();
  
  String? _selectedSubject;
  String? _selectedSection;
  String? _schoolYear;
  int _maxStudents = 50;
  bool _isModerated = false;
  bool _isLoading = false;
  
  final List<String> _sections = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    // Set default subject to teacher's first assigned subject
    final teacherSubjects = widget.teacherProfile.subjects ?? [];
    if (teacherSubjects.isNotEmpty) {
      _selectedSubject = teacherSubjects.first;
    }
    // Set default section to 'A'
    _selectedSection = 'A';
    // Set default school year (current year)
    final now = DateTime.now();
    _schoolYear = '${now.year}-${now.year + 1}';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedSubject == null || _selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select subject and section'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userProfile = await _authService.getUserProfile(currentUser.uid);
      if (userProfile == null) return;

      // Validate teacher can only create classes for assigned subjects
      final teacherSubjects = widget.teacherProfile.subjects ?? [];
      if (teacherSubjects.isNotEmpty && !teacherSubjects.contains(_selectedSubject)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You can only create classes for your assigned subjects: ${teacherSubjects.join(", ")}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final classCode = ClassModel.generateClassCode();
      final now = DateTime.now();

      final classModel = ClassModel(
        id: '', // Will be set by service
        teacherId: currentUser.uid,
        teacherName: userProfile.displayName,
        subject: _selectedSubject!,
        section: _selectedSection!,
        classCode: classCode,
        schoolYear: _schoolYear ?? '${now.year}-${now.year + 1}',
        createdAt: now,
        updatedAt: now,
        isActive: true,
        isModerated: _isModerated,
        enrolledStudentIds: [],
        maxStudents: _maxStudents,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      await _classService.createClass(classModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class created! Class Code: $classCode'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating class: ${e.toString()}'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final teacherSubjects = widget.teacherProfile.subjects ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Create Class',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Selection
              _buildDropdown(
                label: 'Subject',
                value: _selectedSubject,
                items: teacherSubjects.isEmpty 
                    ? ['Mathematics', 'English', 'Science'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList()
                    : teacherSubjects.map((subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubject = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Section Selection
              _buildDropdown(
                label: 'Section',
                value: _selectedSection,
                items: _sections.map((section) => DropdownMenuItem(
                  value: section,
                  child: Text('Section $section'),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSection = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a section';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // School Year
              TextFormField(
                initialValue: _schoolYear,
                decoration: const InputDecoration(
                  labelText: 'School Year',
                  hintText: '2024-2025',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _schoolYear = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter school year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Max Students
              TextFormField(
                initialValue: _maxStudents.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Students',
                  hintText: '50',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _maxStudents = int.tryParse(value) ?? 50;
                  });
                },
              ),
              const SizedBox(height: 20),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter class description...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              
              // Moderated Switch
              SwitchListTile(
                title: const Text('Moderated Class'),
                subtitle: const Text('Students cannot take assessments if moderated'),
                value: _isModerated,
                onChanged: (value) {
                  setState(() {
                    _isModerated = value;
                  });
                },
              ),
              const SizedBox(height: 32),
              
              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Class',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}

