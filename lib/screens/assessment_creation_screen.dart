import 'package:flutter/material.dart';
import '../models/assessment.dart';
import '../models/user_model.dart';
import '../services/assessment_service.dart';
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
  List<String> _selectedTags = [];
  List<String> _availableTags = [
    'Quiz', 'Test', 'Assignment', 'Homework', 'Exam',
    'Beginner', 'Intermediate', 'Advanced',
    'Theory', 'Practice', 'Review'
  ];
  
  int _timeLimit = 0; // 0 = no time limit
  int _totalPoints = 100;
  DateTime? _dueDate;
  
  List<AssessmentQuestion> _questions = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
                backgroundColor: const Color(0xFF007AFF),
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
              Icons.quiz_rounded,
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
    final subjects = widget.teacherProfile.subjects ?? [];
    
    if (subjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(
            color: const Color(0xFFE5E5E7),
            width: 1,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Color(0xFFFF9500),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'No subjects assigned. Please contact admin.',
              style: TextStyle(
                color: Color(0xFF86868B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time Limit (minutes)',
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
                        initialValue: _timeLimit.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                          hintText: '0 = no limit',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _timeLimit = int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
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
            'Add relevant tags to help students find your assessment',
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
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF007AFF)
                        : const Color(0xFFF5F5F7),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFE5E5E7),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1D1D1F),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
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
          Row(
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
              const Spacer(),
              TextButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Question'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF007AFF),
                ),
              ),
            ],
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
                    Icons.quiz_rounded,
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
            ..._questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return _buildQuestionCard(index, question);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, AssessmentQuestion question) {
    return Container(
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
                  Icons.delete_rounded,
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
          
          // Question Options (for multiple choice)
          if (question.type == QuestionType.multipleChoice)
            _buildQuestionOptions(index),
          
          const SizedBox(height: 16),
          
          // Correct Answer Section (Teacher Only)
          _buildCorrectAnswerSection(index),
          
          const SizedBox(height: 16),
          
          // Points
          Row(
            children: [
              const Text(
                'Points: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: question.points.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    hintText: '10',
                  ),
                  onChanged: (value) {
                    _updateQuestionPoints(index, int.tryParse(value) ?? 10);
                  },
                ),
              ),
            ],
          ),
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
          return Row(
            children: [
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
              IconButton(
                onPressed: () => _removeQuestionOption(index, optionIndex),
                icon: const Icon(
                  Icons.remove_circle_rounded,
                  color: Color(0xFFFF3B30),
                  size: 20,
                ),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            ],
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

  // Helper methods
  void _addQuestion() {
    setState(() {
      _questions.add(AssessmentQuestion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: '',
        type: QuestionType.multipleChoice,
        options: ['Option 1', 'Option 2'], // Initialize with default options
        correctAnswer: 'Option 1', // Set a default correct answer
        points: 10,
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _updateQuestionType(int index, QuestionType type) {
    setState(() {
      final question = _questions[index];
      List<String> newOptions = [];
      String? newCorrectAnswer = '';
      
      switch (type) {
        case QuestionType.multipleChoice:
          newOptions = ['Option 1', 'Option 2'];
          newCorrectAnswer = 'Option 1';
          break;
        case QuestionType.trueFalse:
          newOptions = ['True', 'False'];
          newCorrectAnswer = 'True';
          break;
        case QuestionType.shortAnswer:
        case QuestionType.essay:
        case QuestionType.matching:
        case QuestionType.fillInTheBlank:
          newOptions = [];
          newCorrectAnswer = null;
          break;
      }
      
      _questions[index] = question.copyWith(
        type: type,
        options: newOptions,
        correctAnswer: newCorrectAnswer,
      );
    });
  }

  void _updateQuestionText(int index, String text) {
    setState(() {
      final question = _questions[index];
      _questions[index] = question.copyWith(question: text);
    });
  }

  void _updateQuestionPoints(int index, int points) {
    setState(() {
      final question = _questions[index];
      _questions[index] = question.copyWith(points: points);
    });
  }

  void _addQuestionOption(int questionIndex) {
    setState(() {
      final currentOptions = _questions[questionIndex].options;
      final newOptionNumber = currentOptions.length + 1;
      _questions[questionIndex].options.add('Option $newOptionNumber');
      
      // If this is the first option added and no correct answer is set, set it as default
      if (_questions[questionIndex].correctAnswer == null || 
          _questions[questionIndex].correctAnswer!.isEmpty) {
        _questions[questionIndex] = _questions[questionIndex].copyWith(
          correctAnswer: 'Option $newOptionNumber',
        );
      }
    });
  }

  void _removeQuestionOption(int questionIndex, int optionIndex) {
    setState(() {
      final question = _questions[questionIndex];
      if (question.options.length > 2) {
        question.options.removeAt(optionIndex);
      }
    });
  }

  void _updateQuestionOption(int questionIndex, int optionIndex, String value) {
    setState(() {
      _questions[questionIndex].options[optionIndex] = value;
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
      case QuestionType.matching:
        return 'Matching';
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
        tags: _selectedTags,
        timeLimit: _timeLimit,
        totalPoints: _totalPoints,
        questions: _questions,
        dueDate: _dueDate,
        instructions: _instructionsController.text.trim().isEmpty 
            ? null 
            : _instructionsController.text.trim(),
      );

      final assessmentService = AssessmentService();
      await assessmentService.createAssessment(assessment);

      // Log the activity for teacher dashboard
      await _logTeacherActivity('Assessment Created', 'Created assessment: ${assessment.title}');

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
      
      print('✅ Activity logged: $action - $description');
    } catch (e) {
      print('❌ Failed to log activity: $e');
      // Don't fail the assessment creation if activity logging fails
    }
  }
}
