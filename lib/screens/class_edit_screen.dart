import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';

class ClassEditScreen extends StatefulWidget {
  final ClassModel classModel;
  final UserModel teacherProfile;

  const ClassEditScreen({
    super.key,
    required this.classModel,
    required this.teacherProfile,
  });

  @override
  State<ClassEditScreen> createState() => _ClassEditScreenState();
}

class _ClassEditScreenState extends State<ClassEditScreen> {
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
    // Initialize with existing class data
    _selectedSubject = widget.classModel.subject;
    _selectedSection = widget.classModel.section;
    _schoolYear = widget.classModel.schoolYear;
    _maxStudents = widget.classModel.maxStudents;
    _isModerated = widget.classModel.isModerated;
    _descriptionController.text = widget.classModel.description ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateClass() async {
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

      // Validate teacher can only edit classes for assigned subjects
      final teacherSubjects = widget.teacherProfile.subjects ?? [];
      if (teacherSubjects.isNotEmpty && !teacherSubjects.contains(_selectedSubject)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You can only edit classes for your assigned subjects: ${teacherSubjects.join(", ")}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final now = DateTime.now();

      final updatedClassModel = widget.classModel.copyWith(
        subject: _selectedSubject!,
        section: _selectedSection!,
        schoolYear: _schoolYear ?? widget.classModel.schoolYear,
        updatedAt: now,
        isModerated: _isModerated,
        maxStudents: _maxStudents,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      await _classService.updateClass(widget.classModel.id, updatedClassModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating class: ${e.toString()}'),
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
          'Edit Class',
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
              // Class Code Display (Read-only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vpn_key, color: Color(0xFF007AFF)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Class Code',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF86868B),
                          ),
                        ),
                        Text(
                          widget.classModel.classCode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
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
              
              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateClass,
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
                          'Update Class',
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

