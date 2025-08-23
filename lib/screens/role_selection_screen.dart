import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;

  const RoleSelectionScreen({
    super.key,
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? selectedRole;
  String? selectedGrade;
  List<String> selectedSubjects = [];
  bool _isLoading = false;

  final List<String> grades = ['7', '8', '9', '10', '11', '12'];
  final List<String> availableSubjects = [
    'Mathematics',
    'Science',
    'English',
    'History',
    'Geography',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'Art',
    'Music',
    'Physical Education',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Apple's light gray background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Logo/Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 50,
                    color: Color(0xFF007AFF), // Apple's blue
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Welcome Text
                Text(
                  'Welcome, ${widget.displayName}!',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F), // Apple's dark text
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                const Text(
                  'Choose your role to get started',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF86868B), // Apple's secondary text
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Role Selection
                _buildRoleSelection(),
                
                const SizedBox(height: 32),
                
                // Additional Fields based on role
                if (selectedRole != null) _buildAdditionalFields(),
                
                const SizedBox(height: 40),
                
                // Continue Button
                if (selectedRole != null) _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Role',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.3,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                UserRole.student,
                'Student',
                Icons.person_outline,
                'Access learning materials and track progress',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRoleCard(
                UserRole.teacher,
                'Teacher',
                Icons.school_outlined,
                'Manage courses and monitor students',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard(UserRole role, String title, IconData icon, String description) {
    final isSelected = selectedRole == role;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
          // Reset additional fields when role changes
          selectedGrade = null;
          selectedSubjects.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFFFFFFF),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(
            color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5E7),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? const Color(0xFF007AFF).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF86868B),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF86868B),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalFields() {
    if (selectedRole == UserRole.student) {
      return _buildStudentFields();
    } else if (selectedRole == UserRole.teacher) {
      return _buildTeacherFields();
    }
    return const SizedBox.shrink();
  }

  Widget _buildStudentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Student Information',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.3,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grade Level',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(
                    color: selectedGrade != null 
                        ? const Color(0xFF007AFF) 
                        : const Color(0xFFE5E5E7),
                    width: selectedGrade != null ? 2 : 1,
                  ),
                  color: const Color(0xFFF5F5F7),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedGrade,
                    isExpanded: true,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedGrade != null 
                            ? const Color(0xFF007AFF) 
                            : const Color(0xFF86868B),
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    iconSize: 24,
                    dropdownColor: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    elevation: 8,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Color(0xFF1D1D1F),
                      fontWeight: FontWeight.w500,
                    ),
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Select your grade',
                        style: const TextStyle(
                          color: Color(0xFF86868B),
                          fontSize: 17,
                        ),
                      ),
                    ),
                    items: grades.map((grade) {
                      return DropdownMenuItem<String>(
                        value: grade,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 12
                          ),
                          decoration: BoxDecoration(
                            color: selectedGrade == grade 
                                ? const Color(0xFF007AFF).withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 20,
                                color: selectedGrade == grade 
                                    ? const Color(0xFF007AFF)
                                    : const Color(0xFF86868B),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Grade $grade',
                                style: TextStyle(
                                  color: selectedGrade == grade 
                                      ? const Color(0xFF007AFF)
                                      : const Color(0xFF1D1D1F),
                                  fontWeight: selectedGrade == grade 
                                      ? FontWeight.w600 
                                      : FontWeight.w500,
                                ),
                              ),
                              if (selectedGrade == grade) ...[
                                const Spacer(),
                                Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: const Color(0xFF007AFF),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedGrade = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teacher Information',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.3,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subjects You Teach',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: availableSubjects.map((subject) {
                  final isSelected = selectedSubjects.contains(subject);
                  return FilterChip(
                    label: Text(
                      subject,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1D1D1F),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedSubjects.add(subject);
                        } else {
                          selectedSubjects.remove(subject);
                        }
                      });
                    },
                    backgroundColor: const Color(0xFFF5F5F7),
                    selectedColor: const Color(0xFF007AFF),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5E7),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    final canContinue = selectedRole != null &&
        (selectedRole == UserRole.student ? selectedGrade != null : selectedSubjects.isNotEmpty);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canContinue && !_isLoading ? _continueWithRole : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canContinue ? const Color(0xFF007AFF) : const Color(0xFFE5E5E7),
          foregroundColor: canContinue ? Colors.white : const Color(0xFF86868B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: canContinue ? const Color(0xFF007AFF).withValues(alpha: 0.3) : Colors.transparent,
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
                'Continue',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: canContinue ? Colors.white : const Color(0xFF86868B),
                ),
              ),
      ),
    );
  }

  Future<void> _continueWithRole() async {
    if (selectedRole == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      await authService.createUserProfile(
        uid: widget.uid,
        email: widget.email,
        displayName: widget.displayName,
        photoURL: widget.photoURL,
        role: selectedRole!,
        grade: selectedGrade,
        subjects: selectedSubjects.isNotEmpty ? selectedSubjects : null,
      );

      if (mounted) {
        // Go back to auth wrapper which will handle routing
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
}
