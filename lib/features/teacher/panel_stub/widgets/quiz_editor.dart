import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../../core/providers.dart';
import '../../../../data/models/assessment.dart';
import '../../../../data/models/sync_queue.dart';
import '../../../../services/sync/content_sync_service.dart';

class QuizEditor extends ConsumerStatefulWidget {
  final Assessment? assessment; // null for new quiz
  final String lessonId;

  const QuizEditor({
    super.key,
    this.assessment,
    required this.lessonId,
  });

  @override
  ConsumerState<QuizEditor> createState() => _QuizEditorState();
}

class _QuizEditorState extends ConsumerState<QuizEditor> {
  final _formKey = GlobalKey<FormState>();
  final List<QuizQuestion> _questions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.assessment != null) {
      _loadExistingQuiz();
    } else {
      _addQuestion(); // Start with one question
    }
  }

  void _loadExistingQuiz() {
    try {
      final items = widget.assessment!.items;
      for (final item in items) {
        _questions.add(QuizQuestion.fromQuestion(item));
      }
    } catch (e) {
      // If parsing fails, start with a new question
      _addQuestion();
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuizQuestion(
        question: '',
        choices: ['', ''],
        correctAnswer: 0,
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _addChoice(int questionIndex) {
    setState(() {
      _questions[questionIndex].choices.add('');
    });
  }

  void _removeChoice(int questionIndex, int choiceIndex) {
    setState(() {
      final question = _questions[questionIndex];
      question.choices.removeAt(choiceIndex);
      
      // Adjust correct answer if needed
      if (question.correctAnswer >= choiceIndex) {
        question.correctAnswer = (question.correctAnswer - 1).clamp(0, question.choices.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment == null ? 'Create Quiz' : 'Edit Quiz'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _questions.length,
                itemBuilder: (context, questionIndex) {
                  return _buildQuestionCard(questionIndex);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Question'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveQuiz,
                      child: Text(_isSaving ? 'Saving...' : 'Save Quiz'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int questionIndex) {
    final question = _questions[questionIndex];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Question ${questionIndex + 1}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_questions.length > 1)
                  IconButton(
                    onPressed: () => _removeQuestion(questionIndex),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Remove Question',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: question.question,
              decoration: const InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => question.question = value,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a question';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Choices:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(question.choices.length, (choiceIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: choiceIndex,
                      groupValue: question.correctAnswer,
                      onChanged: (value) {
                        setState(() {
                          question.correctAnswer = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: question.choices[choiceIndex],
                        decoration: InputDecoration(
                          labelText: 'Choice ${choiceIndex + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => question.choices[choiceIndex] = value,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter choice text';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (question.choices.length > 2)
                      IconButton(
                        onPressed: () => _removeChoice(questionIndex, choiceIndex),
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        tooltip: 'Remove Choice',
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _addChoice(questionIndex),
              icon: const Icon(Icons.add),
              label: const Text('Add Choice'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that each question has at least 2 choices
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if (question.choices.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${i + 1} must have at least 2 choices'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final assessmentRepo = ref.read(assessmentRepositoryProvider);
      final syncService = ref.read(contentSyncServiceProvider);
      
      final assessmentId = widget.assessment?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final questions = _questions.map((q) => Question(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: q.question,
        choices: q.choices,
        correctIndex: q.correctAnswer,
      )).toList();
      
      final assessment = Assessment(
        id: assessmentId,
        lessonId: widget.lessonId,
        type: AssessmentType.quiz,
        items: questions,
      );

      if (widget.assessment == null) {
        // Create new assessment
        await assessmentRepo.createAssessment(assessment);
        await syncService.queueContentChange(
          'assessments',
          SyncOperation.create,
          assessmentId,
          assessment.toJson(),
        );
      } else {
        // Update existing assessment
        await assessmentRepo.updateAssessment(assessment);
        await syncService.queueContentChange(
          'assessments',
          SyncOperation.update,
          assessmentId,
          assessment.toJson(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.assessment == null ? 'Quiz created!' : 'Quiz updated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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
}

class QuizQuestion {
  String question;
  List<String> choices;
  int correctAnswer;

  QuizQuestion({
    required this.question,
    required this.choices,
    required this.correctAnswer,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'choices': choices,
      'correctAnswer': correctAnswer,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      choices: List<String>.from(json['choices'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
    );
  }

  factory QuizQuestion.fromQuestion(Question question) {
    return QuizQuestion(
      question: question.text,
      choices: question.choices,
      correctAnswer: question.correctIndex,
    );
  }
} 