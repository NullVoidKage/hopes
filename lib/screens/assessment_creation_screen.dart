import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:io';
import '../models/assessment.dart';
import '../models/user_model.dart';
import '../services/assessment_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_database/firebase_database.dart';

class AssessmentCreationScreen extends StatefulWidget {
  final UserModel teacherProfile;

  const AssessmentCreationScreen({
    super.key,
    required this.teacherProfile,
  });

  @override
  State<AssessmentCreationScreen> createState() => _AssessmentCreationScreenState();
}

class _AssessmentCreationScreenState extends State<AssessmentCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  String? _selectedSubject;
  bool _isPublished = false;
  String? _selectedTag; // Single tag selection only
  // Removed Beginner, Intermediate, Advanced tags as requested
  List<String> _availableTags = [
    'Quiz', 'Test', 'Assignment', 'Homework', 'Exam',
    'Theory', 'Practice', 'Review'
  ];
  
  int _totalPoints = 100;
  DateTime? _dueDate;
  String? _selectedSchoolYear;
  
  List<AssessmentQuestion> _questions = [];
  
  final List<String> _schoolYears = [
    '2024-2025',
    '2025-2026',
    '2026-2027',
    '2027-2028',
  ];
  Map<int, String?> _questionImageUrls = {}; // Store image URLs for each question
  Map<int, XFile?> _selectedQuestionImages = {}; // Store selected image files
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default subject to teacher's first assigned subject
    final teacherSubjects = widget.teacherProfile.subjects ?? [];
    if (teacherSubjects.isNotEmpty) {
      _selectedSubject = teacherSubjects.first;
    }
    // Set default school year to current school year
    final currentYear = DateTime.now().year;
    final nextYear = currentYear + 1;
    _selectedSchoolYear = '$currentYear-$nextYear';
    // Add a default question
    _addQuestion();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Assessment',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createAssessment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.white,
                elevation: 0,
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
                  : const Text(
                      'Create',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 32),
                  
                  // Basic Information
                  _buildBasicInformation(),
                  const SizedBox(height: 32),
                  
                  // Assessment Settings
                  _buildAssessmentSettings(),
                  const SizedBox(height: 32),
                  
                  // Tags Selection
                  _buildTagsSelection(),
                  const SizedBox(height: 32),
                  
                  // Questions Section
                  _buildQuestionsSection(),
                  const SizedBox(height: 32),
                  
                  // Publish Toggle
                  _buildPublishToggle(),
                  const SizedBox(height: 32),
                  
                  // Create Button
                  _buildCreateButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            child: const Icon(
              Icons.psychology,
              size: 32,
              color: Color(0xFFFF9500),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Assessment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create quizzes, tests, and assignments for your students',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF86868B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 24),
          
          // Subject Selection
          _buildSubjectDropdown(),
          const SizedBox(height: 20),
          
          // Title Field
          _buildTextField(
            controller: _titleController,
            label: 'Assessment Title',
            hint: 'Enter a clear, descriptive title',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an assessment title';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Description Field
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Brief overview of what this assessment covers',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          
          // Instructions Field
          _buildTextField(
            controller: _instructionsController,
            label: 'Instructions (Optional)',
            hint: 'Special instructions for students taking this assessment',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    // Only show subjects assigned to this teacher
    final teacherSubjects = widget.teacherProfile.subjects ?? [];
    final List<String> subjects = teacherSubjects.isEmpty 
        ? [
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
          ]
        : teacherSubjects;
    
    // Show warning if no subjects assigned
    if (teacherSubjects.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFF9500)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Color(0xFFFF9500), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No subjects assigned. Please contact administrator to assign subjects.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSubjectDropdownWidget(subjects),
        ],
      );
    }
    
    return _buildSubjectDropdownWidget(subjects);
  }
  
  Widget _buildSubjectDropdownWidget(List<String> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: const Color(0xFFE5E5E7),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedSubject,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Select a subject'),
              ),
              ...subjects.map((subject) => DropdownMenuItem(
                value: subject,
                child: Text(subject),
              )),
            ],
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
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
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
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF86868B),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E7),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E7),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF007AFF),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFF3B30),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildAssessmentSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assessment Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 24),
          
          // Time Limit
          // Total Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Points',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(
                    color: const Color(0xFFE5E5E7),
                    width: 1,
                  ),
                ),
                child: TextFormField(
                  initialValue: _totalPoints.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    hintText: '100',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _totalPoints = int.tryParse(value) ?? 100;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // School Year
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'School Year',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(
                    color: const Color(0xFFE5E5E7),
                    width: 1,
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedSchoolYear,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                  items: _schoolYears.map((year) => DropdownMenuItem(
                    value: year,
                    child: Text(year),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSchoolYear = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Due Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Due Date (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDueDate(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    border: Border.all(
                      color: const Color(0xFFE5E5E7),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: _dueDate != null 
                            ? const Color(0xFF007AFF)
                            : const Color(0xFF86868B),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _dueDate != null 
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'Select due date',
                        style: TextStyle(
                          color: _dueDate != null 
                              ? const Color(0xFF1D1D1F)
                              : const Color(0xFF86868B),
                        ),
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _dueDate = null;
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFFFF3B30),
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSelection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a tag to help students find your assessment',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTag == tag;
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      // Only allow one tag to be selected at a time
                      _selectedTag = tag;
                    } else {
                      // Deselect if clicking the already selected tag
                      if (_selectedTag == tag) {
                        _selectedTag = null;
                      }
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
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1D1D1F),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          
          if (_questions.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(
                  color: const Color(0xFFE5E5E7),
                  width: 1,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.psychology,
                    size: 48,
                    color: Color(0xFF86868B),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No questions yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first question to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF86868B),
                    ),
                  ),
                ],
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _questions.removeAt(oldIndex);
                  _questions.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final question = _questions[index];
                return _buildQuestionCard(index, question, key: ValueKey('question_${question.id}_$index'));
              },
            ),
          
          // Add Question button moved to bottom as requested
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add_circle_rounded),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, AssessmentQuestion question, {Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Drag handle for reordering
              const Icon(
                Icons.drag_handle,
                color: Color(0xFF86868B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _removeQuestion(index),
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFFF3B30),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Question Type
          _buildQuestionTypeSelector(index),
          const SizedBox(height: 16),
          
          // Question Text
          _buildQuestionTextField(index),
          const SizedBox(height: 16),
          
          // Question Image Upload
          _buildQuestionImageUpload(index),
          const SizedBox(height: 16),
          
          // Question Options (for multiple choice and true/false)
          if (question.type == QuestionType.multipleChoice || question.type == QuestionType.trueFalse)
            _buildQuestionOptions(index),
          
          const SizedBox(height: 16),
          
          // Correct Answer Section (Teacher Only)
          _buildCorrectAnswerSection(index),
          
          // For essay questions, show manual grading note
          if (question.type == QuestionType.essay) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF9500)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF9500),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Essay questions require manual grading by teacher. Points will be assigned during grading.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF9500),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionTypeSelector(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Question Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: const Color(0xFFE5E5E7),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<QuestionType>(
            value: _questions[index].type,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
            items: QuestionType.values.map((type) => DropdownMenuItem(
              value: type,
              child: Text(_getQuestionTypeDisplayName(type)),
            )).toList(),
            onChanged: (value) {
              if (value != null) {
                _updateQuestionType(index, value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTextField(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Question',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _questions[index].question,
          decoration: const InputDecoration(
            hintText: 'Enter your question here...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 3,
          onChanged: (value) {
            _updateQuestionText(index, value);
          },
        ),
      ],
    );
  }

  Widget _buildQuestionOptions(int index) {
    final question = _questions[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        ...question.options.asMap().entries.map((entry) {
          final optionIndex = entry.key;
          final option = entry.value;
          final optionPoints = question.optionPoints[option] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Drag handle icon
                Icon(
                  Icons.drag_handle,
                  color: const Color(0xFF86868B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                // Option text field
                Expanded(
                  child: TextFormField(
                    initialValue: option,
                    decoration: InputDecoration(
                      hintText: 'Option ${optionIndex + 1}',
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      _updateQuestionOption(index, optionIndex, value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Points input field
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: optionPoints.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Points',
                      labelText: 'Points',
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF86868B),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) {
                      final points = int.tryParse(value) ?? 0;
                      _updateOptionPoints(index, option, points);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Remove button
                IconButton(
                  onPressed: () => _removeQuestionOption(index, optionIndex),
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: Color(0xFFFF3B30),
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _addQuestionOption(index),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Option'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF007AFF),
          ),
        ),
      ],
    );
  }

  Widget _buildCorrectAnswerSection(int index) {
    final question = _questions[index];
    
    // Only show for question types that need correct answers
    if (question.type != QuestionType.multipleChoice && 
        question.type != QuestionType.trueFalse) {
      return const SizedBox.shrink();
    }
    
    // Filter out empty options and ensure we have valid options
    final validOptions = question.options.where((option) => option.trim().isNotEmpty).toList();
    
    if (validOptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(
            color: const Color(0xFFFF3B30),
            width: 1,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Color(0xFFFF3B30),
              size: 16,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Please add options first before setting the correct answer',
                style: TextStyle(
                  color: Color(0xFFFF3B30),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Ensure the current correct answer is valid
    String? currentValue = question.correctAnswer;
    if (currentValue == null || !validOptions.contains(currentValue)) {
      currentValue = validOptions.isNotEmpty ? validOptions.first : null;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Correct Answer (Teacher Only)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: const Color(0xFFE5E5E7),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: currentValue,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              hintText: 'Select correct answer',
            ),
            items: validOptions.map((option) => DropdownMenuItem(
              value: option,
              child: Text(option),
            )).toList(),
            onChanged: (value) {
              if (value != null) {
                _updateCorrectAnswer(index, value);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a correct answer';
              }
              return null;
            },
          ),
        ),
        if (validOptions.length < 2)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: const Text(
              'Add at least 2 options for multiple choice questions',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPublishToggle() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Publish Assessment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                Text(
                  _isPublished 
                      ? 'Students can see and access this assessment'
                      : 'Assessment is private and only visible to you',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublished,
            onChanged: (value) {
              setState(() {
                _isPublished = value;
              });
            },
            activeColor: const Color(0xFF007AFF),
            activeTrackColor: const Color(0xFF007AFF).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createAssessment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Creating Assessment...'),
                ],
              )
            : const Text(
                'Create Assessment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // Image upload methods
  Widget _buildQuestionImageUpload(int index) {
    final question = _questions[index];
    final imageUrl = _questionImageUrls[index] ?? question.imageUrl;
    final selectedImage = _selectedQuestionImages[index];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Question Image (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        if (imageUrl != null || selectedImage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.contain,
                          cacheWidth: 800,
                          cacheHeight: 600,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Container(
                              width: double.infinity,
                              height: 200,
                              color: const Color(0xFFF5F5F7),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFF007AFF),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 200,
                              color: const Color(0xFFF5F5F7),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 48, color: Color(0xFF86868B)),
                                    SizedBox(height: 8),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(color: Color(0xFF86868B), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : selectedImage != null
                          ? kIsWeb
                              ? FutureBuilder<Uint8List>(
                                  future: selectedImage.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return Container(
                                      width: double.infinity,
                                      height: 200,
                                      color: const Color(0xFFF5F5F7),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(selectedImage.path),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: 200,
                                      color: const Color(0xFFF5F5F7),
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 48, color: Color(0xFF86868B)),
                                      ),
                                    );
                                  },
                                )
                          : const SizedBox.shrink(),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _questionImageUrls.remove(index);
                        _selectedQuestionImages.remove(index);
                        _updateQuestionImage(index, null);
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickQuestionImage(index),
                icon: const Icon(Icons.image, size: 20),
                label: const Text('Upload Image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF007AFF),
                  side: const BorderSide(color: Color(0xFF007AFF)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickQuestionImage(int index) async {
    try {
      XFile? image;
      
      if (kIsWeb) {
        // Use file_picker for web
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          if (file.bytes != null) {
            // Convert PlatformFile to XFile for web
            image = XFile.fromData(
              file.bytes!,
              name: file.name,
              mimeType: file.extension != null ? 'image/${file.extension}' : 'image/jpeg',
            );
          }
        }
      } else {
        // Use image_picker for mobile
        final ImagePicker picker = ImagePicker();
        image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
      }

      if (image != null) {
        setState(() {
          _selectedQuestionImages[index] = image;
        });

        // Upload image to Firebase Storage
        await _uploadQuestionImage(index, image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadQuestionImage(int index, XFile imageFile) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final storage = FirebaseStorage.instance;
      final fileName = 'assessment_questions/${widget.teacherProfile.uid}/${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final ref = storage.ref().child(fileName);

      Uint8List? imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = await imageFile.readAsBytes();
      }

      final uploadTask = ref.putData(imageBytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _questionImageUrls[index] = downloadUrl;
          _updateQuestionImage(index, downloadUrl);
          _isLoading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully'),
            backgroundColor: Color(0xFF34C759),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateQuestionImage(int index, String? imageUrl) {
    setState(() {
      final question = _questions[index];
      _questions[index] = question.copyWith(imageUrl: imageUrl);
    });
  }

  // Helper methods
  void _addQuestion() {
    setState(() {
      // Initialize option points for default options
      final defaultOptionPoints = <String, int>{
        'Option 1': 0,
        'Option 2': 0,
      };
      
      // Calculate initial points from max option points (or default to 0)
      final initialPoints = defaultOptionPoints.values.isNotEmpty 
          ? defaultOptionPoints.values.reduce((a, b) => a > b ? a : b)
          : 0;
      
      _questions.add(AssessmentQuestion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: '',
        type: QuestionType.multipleChoice,
        options: ['Option 1', 'Option 2'], // Initialize with default options
        correctAnswer: 'Option 1', // Set a default correct answer
        points: initialPoints, // Points will be calculated from option points
        optionPoints: defaultOptionPoints,
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      _questionImageUrls.remove(index);
      _selectedQuestionImages.remove(index);
    });
  }

  void _updateQuestionType(int index, QuestionType type) {
    setState(() {
      final question = _questions[index];
      List<String> newOptions = [];
      String? newCorrectAnswer = '';
      Map<String, int> newOptionPoints = {};
      
      switch (type) {
        case QuestionType.multipleChoice:
          newOptions = ['Option 1', 'Option 2'];
          newCorrectAnswer = 'Option 1';
          newOptionPoints = {
            'Option 1': 0,
            'Option 2': 0,
          };
          break;
        case QuestionType.trueFalse:
          newOptions = ['True', 'False'];
          newCorrectAnswer = 'True';
          newOptionPoints = {
            'True': 0,
            'False': 0,
          };
          break;
        case QuestionType.shortAnswer:
        case QuestionType.essay:
        case QuestionType.fillInTheBlank:
          newOptions = [];
          newCorrectAnswer = null;
          newOptionPoints = {};
          break;
      }
      
      _questions[index] = question.copyWith(
        type: type,
        options: newOptions,
        correctAnswer: newCorrectAnswer,
        optionPoints: newOptionPoints,
      );
    });
  }

  void _updateQuestionText(int index, String text) {
    setState(() {
      final question = _questions[index];
      _questions[index] = question.copyWith(question: text);
    });
  }


  void _addQuestionOption(int questionIndex) {
    setState(() {
      final question = _questions[questionIndex];
      final currentOptions = question.options;
      final newOptionNumber = currentOptions.length + 1;
      final newOption = 'Option $newOptionNumber';
      
      question.options.add(newOption);
      
      // Initialize option points for the new option (default 0)
      final newOptionPoints = Map<String, int>.from(question.optionPoints);
      newOptionPoints[newOption] = 0;
      
      // If this is the first option added and no correct answer is set, set it as default
      if (question.correctAnswer == null || question.correctAnswer!.isEmpty) {
        _questions[questionIndex] = question.copyWith(
          correctAnswer: newOption,
          optionPoints: newOptionPoints,
        );
      } else {
        _questions[questionIndex] = question.copyWith(
          optionPoints: newOptionPoints,
        );
      }
    });
  }

  void _removeQuestionOption(int questionIndex, int optionIndex) {
    setState(() {
      final question = _questions[questionIndex];
      if (question.options.length > 2) {
        final removedOption = question.options[optionIndex];
        question.options.removeAt(optionIndex);
        
        // Remove option points for the removed option
        final newOptionPoints = Map<String, int>.from(question.optionPoints);
        newOptionPoints.remove(removedOption);
        
        // If the removed option was the correct answer, set a new default
        if (question.correctAnswer == removedOption && question.options.isNotEmpty) {
          _questions[questionIndex] = question.copyWith(
            correctAnswer: question.options.first,
            optionPoints: newOptionPoints,
          );
        } else {
          _questions[questionIndex] = question.copyWith(
            optionPoints: newOptionPoints,
          );
        }
      }
    });
  }

  void _updateQuestionOption(int questionIndex, int optionIndex, String value) {
    setState(() {
      final question = _questions[questionIndex];
      final oldOption = question.options[optionIndex];
      
      // Update option text
      question.options[optionIndex] = value;
      
      // Update optionPoints map if the option text changed
      if (oldOption != value && question.optionPoints.containsKey(oldOption)) {
        final points = question.optionPoints[oldOption] ?? 0;
        final newOptionPoints = Map<String, int>.from(question.optionPoints);
        newOptionPoints.remove(oldOption);
        newOptionPoints[value] = points;
        _questions[questionIndex] = question.copyWith(optionPoints: newOptionPoints);
      }
    });
  }

  void _updateOptionPoints(int questionIndex, String option, int points) {
    setState(() {
      final question = _questions[questionIndex];
      final newOptionPoints = Map<String, int>.from(question.optionPoints);
      newOptionPoints[option] = points;
      
      // Calculate question points from max option points (for multiple choice/true false)
      int calculatedPoints = 0;
      if (question.type == QuestionType.multipleChoice || question.type == QuestionType.trueFalse) {
        if (newOptionPoints.values.isNotEmpty) {
          calculatedPoints = newOptionPoints.values.reduce((a, b) => a > b ? a : b);
        }
      } else if (question.type == QuestionType.essay) {
        calculatedPoints = 0; // Essay questions are manually graded
      } else {
        calculatedPoints = question.points; // Keep existing points for other types
      }
      
      _questions[questionIndex] = question.copyWith(
        optionPoints: newOptionPoints,
        points: calculatedPoints,
      );
    });
  }

  void _updateCorrectAnswer(int index, String correctAnswer) {
    setState(() {
      _questions[index] = _questions[index].copyWith(correctAnswer: correctAnswer);
    });
  }

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  String _getQuestionTypeDisplayName(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.essay:
        return 'Essay';
      case QuestionType.fillInTheBlank:
        return 'Fill in the Blank';
    }
  }

  Future<void> _createAssessment() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subject'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate that teacher can only upload for assigned subjects
    final teacherSubjects = widget.teacherProfile.subjects ?? [];
    if (teacherSubjects.isNotEmpty && !teacherSubjects.contains(_selectedSubject)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only create assessments for your assigned subjects: ${teacherSubjects.join(", ")}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final assessment = Assessment(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        subject: _selectedSubject ?? 'Unknown Subject',
        teacherId: widget.teacherProfile.uid,
        teacherName: widget.teacherProfile.displayName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublished: _isPublished,
        tags: _selectedTag != null ? [_selectedTag!] : [],
        timeLimit: 0, // No time limit
        totalPoints: _totalPoints,
        questions: _questions,
        dueDate: _dueDate,
        instructions: _instructionsController.text.trim().isEmpty 
            ? null 
            : _instructionsController.text.trim(),
        schoolYear: _selectedSchoolYear,
      );

      final assessmentService = AssessmentService();
      final assessmentId = await assessmentService.createAssessment(assessment);

      // Log the activity for teacher dashboard
      await _logTeacherActivity('Assessment Created', 'Created assessment: ${assessment.title}');

      // Send notification to students about new assessment
      if (_isPublished) {
        try {
          final notificationService = NotificationService();
          await notificationService.notifyStudentsAboutNewContent(
            title: 'New Assessment Available',
            body: '${widget.teacherProfile.displayName} has uploaded a new assessment: ${assessment.title}',
            type: 'assessment',
            contentId: assessmentId,
            subject: assessment.subject,
          );
        } catch (e) {
          // Don't fail assessment creation if notification fails
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment created successfully!'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating assessment: ${e.toString()}'),
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

  Future<void> _logTeacherActivity(String action, String description) async {
    try {
      final database = FirebaseDatabase.instance.ref();
      final activityRef = database.child('teacher_activities').push();
      
      await activityRef.set({
        'teacherId': widget.teacherProfile.uid,
        'teacherName': widget.teacherProfile.displayName,
        'action': action,
        'description': description,
        'timestamp': ServerValue.timestamp,
        'assessmentId': '', // Will be set after assessment creation
        'subject': _selectedSubject,
      });
      
    } catch (e) {
      // Don't fail the assessment creation if activity logging fails
    }
  }
}
