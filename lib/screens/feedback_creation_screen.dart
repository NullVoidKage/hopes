import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feedback.dart';
import '../models/student.dart';
import '../models/assessment.dart';
import '../models/lesson.dart';
import '../models/learning_path.dart';
import '../services/feedback_service.dart';
import '../services/student_service.dart';
import '../services/assessment_service.dart';
import '../services/lesson_service.dart';
import '../services/learning_path_service.dart';

class FeedbackCreationScreen extends StatefulWidget {
  final String? studentId;
  final String? contentId;
  final String? contentType;

  const FeedbackCreationScreen({
    Key? key,
    this.studentId,
    this.contentId,
    this.contentType,
  }) : super(key: key);

  @override
  State<FeedbackCreationScreen> createState() => _FeedbackCreationScreenState();
}

class _FeedbackCreationScreenState extends State<FeedbackCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _recommendationsController = TextEditingController();
  
  String _selectedStudentId = '';
  String _selectedContentId = '';
  String _selectedContentType = 'general';
  double _rating = 3.0;
  bool _isLoading = false;
  bool _isCreatingFeedback = false;
  bool _isCreatingRecommendation = false;

  List<Student> _students = [];
  List<Map<String, dynamic>> _availableContent = [];
  List<String> _contentTypes = ['general', 'assessment', 'lesson', 'learning_path'];

  final FeedbackService _feedbackService = FeedbackService();
  final StudentService _studentService = StudentService();
  final AssessmentService _assessmentService = AssessmentService();
  final LessonService _lessonService = LessonService();
  final LearningPathService _learningPathService = LearningPathService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load students
      final students = await _studentService.getStudents('');
      
      // Load available content
      final content = await _learningPathService.getAvailableContent();
      
      setState(() {
        _students = students;
        _availableContent = [
          ...(content['lessons'] ?? []).map((l) => {'id': l['id'], 'title': l['title'], 'type': 'lesson'}),
          ...(content['assessments'] ?? []).map((a) => {'id': a['id'], 'title': a['title'], 'type': 'assessment'}),
        ];
        
        // Set initial values if provided
        if (widget.studentId != null) {
          _selectedStudentId = widget.studentId!;
        }
        if (widget.contentId != null) {
          _selectedContentId = widget.contentId!;
        }
        if (widget.contentType != null) {
          _selectedContentType = widget.contentType!;
        }
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
        title: const Text('Provide Feedback & Recommendations'),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStudentSelection(),
                    const SizedBox(height: 24),
                    _buildContentSelection(),
                    const SizedBox(height: 24),
                    _buildFeedbackSection(),
                    const SizedBox(height: 24),
                    _buildRecommendationsSection(),
                    const SizedBox(height: 24),
                    _buildRatingSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStudentSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E7)),
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
              const Icon(Icons.person, color: Color(0xFF007AFF)),
              const SizedBox(width: 12),
              const Text(
                'Select Student',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedStudentId.isEmpty ? null : _selectedStudentId,
            decoration: const InputDecoration(
              labelText: 'Student',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF5F5F7),
            ),
            items: _students.map((student) {
              return DropdownMenuItem(
                value: student.id,
                child: Text(student.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStudentId = value ?? '';
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a student';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E7)),
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
              const Icon(Icons.article, color: Color(0xFF007AFF)),
              const SizedBox(width: 12),
              const Text(
                'Content Context',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedContentType,
                  decoration: const InputDecoration(
                    labelText: 'Content Type',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF5F5F7),
                  ),
                  items: _contentTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.replaceAll('_', ' ').toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedContentType = value ?? 'general';
                      _selectedContentId = '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedContentId.isEmpty ? null : _selectedContentId,
                  decoration: const InputDecoration(
                    labelText: 'Specific Content',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF5F5F7),
                  ),
                  items: _availableContent
                      .where((content) => content['type'] == _selectedContentType || _selectedContentType == 'general')
                      .map((content) {
                    return DropdownMenuItem<String>(
                      value: content['id'] as String,
                      child: Text(
                        content['title'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedContentId = value ?? '';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E7)),
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
              const Icon(Icons.feedback, color: Color(0xFF007AFF)),
              const SizedBox(width: 12),
              const Text(
                'Feedback',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Provide detailed feedback',
              hintText: 'Share your observations, suggestions, and constructive criticism...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF5F5F7),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please provide feedback';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E7)),
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
              const Icon(Icons.lightbulb, color: Color(0xFF007AFF)),
              const SizedBox(width: 12),
              const Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _recommendationsController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Action items and next steps',
              hintText: 'Suggest specific actions, resources, or study strategies...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF5F5F7),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please provide recommendations';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E7)),
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
              const Icon(Icons.star, color: Color(0xFF007AFF)),
              const SizedBox(width: 12),
              const Text(
                'Performance Rating',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _rating,
                  min: 1.0,
                  max: 5.0,
                  divisions: 4,
                  activeColor: const Color(0xFF007AFF),
                  onChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    _rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Poor', style: TextStyle(color: Color(0xFF86868B))),
              Text('Excellent', style: TextStyle(color: Color(0xFF86868B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isCreatingFeedback ? null : _createFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isCreatingFeedback
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Feedback',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isCreatingRecommendation ? null : _createRecommendation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isCreatingRecommendation
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create Recommendation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _createFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreatingFeedback = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final selectedStudent = _students.firstWhere((s) => s.id == _selectedStudentId);
      final selectedContent = _availableContent.firstWhere(
        (c) => c['id'] == _selectedContentId,
        orElse: () => {'id': '', 'title': 'General', 'type': 'general'},
      );

      final feedback = StudentFeedback(
        id: '',
        studentId: _selectedStudentId,
        studentName: selectedStudent.name,
        teacherId: currentUser.uid,
        teacherName: currentUser.displayName ?? 'Teacher',
        feedbackType: _selectedContentType,
        contentId: _selectedContentId,
        contentTitle: selectedContent['title'],
        feedback: _feedbackController.text.trim(),
        recommendations: _recommendationsController.text.trim(),
        rating: _rating,
        createdAt: DateTime.now(),
      );

      await _feedbackService.createStudentFeedback(feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback saved successfully!'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingFeedback = false;
      });
    }
  }

  Future<void> _createRecommendation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreatingRecommendation = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final selectedStudent = _students.firstWhere((s) => s.id == _selectedStudentId);
      final selectedContent = _availableContent.firstWhere(
        (c) => c['id'] == _selectedContentId,
        orElse: () => {'id': '', 'title': 'General', 'type': 'general'},
      );

      final recommendation = StudentRecommendation(
        id: '',
        studentId: _selectedStudentId,
        studentName: selectedStudent.name,
        teacherId: currentUser.uid,
        teacherName: currentUser.displayName ?? 'Teacher',
        recommendationType: _selectedContentType,
        title: 'Improvement Recommendation',
        description: _recommendationsController.text.trim(),
        reason: _feedbackController.text.trim(),
        actionItems: _recommendationsController.text.trim(),
        priority: _rating < 3 ? 1 : (_rating < 4 ? 2 : 3),
        createdAt: DateTime.now(),
      );

      await _feedbackService.createStudentRecommendation(recommendation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recommendation created successfully!'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating recommendation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingRecommendation = false;
      });
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }
}
