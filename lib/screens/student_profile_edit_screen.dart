import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class StudentProfileEditScreen extends StatefulWidget {
  final UserModel userProfile;

  const StudentProfileEditScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<StudentProfileEditScreen> createState() => _StudentProfileEditScreenState();
}

class _StudentProfileEditScreenState extends State<StudentProfileEditScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _gradeController;
  late List<String> _selectedSubjects;
  
  bool _isSaving = false;

  final List<String> _availableSubjects = [
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

  final List<String> _availableGrades = [
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12'
  ];

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.userProfile.displayName);
    _emailController = TextEditingController(text: widget.userProfile.email);
    
    // Handle grade value properly - ensure it matches available grades
    String userGrade = widget.userProfile.grade ?? 'Grade 7';
    // If user grade doesn't match available format, try to find a match
    if (!_availableGrades.contains(userGrade)) {
      // Try to find a grade that contains the user's grade number
      String? matchedGrade = _availableGrades.firstWhere(
        (grade) => grade.contains(userGrade) || userGrade.contains(grade.replaceAll('Grade ', '')),
        orElse: () => 'Grade 7', // Default fallback
      );
      userGrade = matchedGrade;
    }
    
    _gradeController = TextEditingController(text: userGrade);
    // Ensure subjects list is valid and contains only available subjects
    List<String> userSubjects = widget.userProfile.subjects ?? [];
    _selectedSubjects = userSubjects.where((subject) => _availableSubjects.contains(subject)).toList();
    
    // If no valid subjects found, add default subjects
    if (_selectedSubjects.isEmpty) {
      _selectedSubjects = ['Mathematics', 'Science', 'English'];
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updateData = {
        'displayName': _displayNameController.text.trim(),
        'email': _emailController.text.trim(),
        'grade': _getCurrentGrade(),
        'subjects': _selectedSubjects,
      };

      await _authService.updateUserProfile(widget.userProfile.uid, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Return updated profile data
        Navigator.of(context).pop({
          'displayName': _displayNameController.text.trim(),
          'email': _emailController.text.trim(),
          'grade': _getCurrentGrade(),
          'subjects': _selectedSubjects,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating profile: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  // Get the current grade value, ensuring it's valid
  String _getCurrentGrade() {
    String currentGrade = _gradeController.text;
    // If current grade is not in available grades, use default
    if (!_availableGrades.contains(currentGrade)) {
      currentGrade = 'Grade 7';
      _gradeController.text = currentGrade;
    }
    return currentGrade;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1D1D1F),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Card
                _buildProfileHeader(),
                
                const SizedBox(height: 24),
                
                // Personal Information Card
                _buildPersonalInfoCard(),
                
                const SizedBox(height: 24),
                
                // Academic Information Card
                _buildAcademicInfoCard(),
                
                const SizedBox(height: 24),
                
                // Subjects Selection Card
                _buildSubjectsCard(),
                
                const SizedBox(height: 32),
                
                // Save Button
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
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
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF667eea).withValues(alpha: 0.1),
            backgroundImage: widget.userProfile.photoURL != null
                ? NetworkImage(widget.userProfile.photoURL!)
                : null,
            child: widget.userProfile.photoURL == null
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: Color(0xFF667eea),
                  )
                : null,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Edit Your Profile',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Update your personal and academic information',
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

  Widget _buildPersonalInfoCard() {
    return Container(
      width: double.infinity,
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
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Display Name
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoCard() {
    return Container(
      width: double.infinity,
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
          const Text(
            'Academic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Grade Level
          DropdownButtonFormField<String>(
            value: _availableGrades.contains(_gradeController.text) ? _gradeController.text : null,
            decoration: const InputDecoration(
              labelText: 'Grade Level',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: _availableGrades.map((grade) {
              return DropdownMenuItem(
                value: grade,
                child: Text(grade),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _gradeController.text = value;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your grade level';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsCard() {
    return Container(
      width: double.infinity,
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
          const Text(
            'Enrolled Subjects',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Select the subjects you want to study',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableSubjects.map((subject) {
              final isSelected = _selectedSubjects.contains(subject);
              return FilterChip(
                label: Text(subject),
                selected: isSelected,
                onSelected: (_) => _toggleSubject(subject),
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                selectedColor: const Color(0xFF667eea).withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF667eea) : const Color(0xFF1D1D1F),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                checkmarkColor: const Color(0xFF667eea),
              );
            }).toList(),
          ),
          
          if (_selectedSubjects.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Please select at least one subject',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
