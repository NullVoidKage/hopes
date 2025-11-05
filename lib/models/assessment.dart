class Assessment {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String teacherId;
  final String teacherName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;
  final List<String> tags;
  final int timeLimit; // in minutes, 0 = no time limit
  final int totalPoints;
  final List<AssessmentQuestion> questions;
  final DateTime? dueDate;
  final String? instructions;
  final String assessmentType; // Quiz, Activity, Test, Assignment
  final String? schoolYear; // School year (e.g., "2024-2025")

  Assessment({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.teacherId,
    required this.teacherName,
    required this.createdAt,
    required this.updatedAt,
    this.isPublished = false,
    this.tags = const [],
    this.timeLimit = 0,
    this.totalPoints = 100,
    this.questions = const [],
    this.dueDate,
    this.instructions,
    this.assessmentType = 'Quiz',
    this.schoolYear,
  });

  // Create from Realtime Database
  factory Assessment.fromRealtimeDatabase(String id, Map<dynamic, dynamic> data) {
    
    final assessment = Assessment(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      subject: data['subject']?.toString() ?? '',
      teacherId: data['teacherId']?.toString() ?? '',
      teacherName: data['teacherName']?.toString() ?? '',
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int)
          : DateTime.now(),
      isPublished: data['isPublished'] as bool? ?? false,
      tags: data['tags'] != null 
          ? List<String>.from((data['tags'] as List).map((e) => e.toString()))
          : [],
      timeLimit: data['timeLimit'] as int? ?? 0,
      totalPoints: data['totalPoints'] as int? ?? 100,
      questions: data['questions'] != null 
          ? _parseQuestionsFromData(data['questions'])
          : [],
      dueDate: data['dueDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['dueDate'] as int)
          : null,
      instructions: data['instructions']?.toString(),
      assessmentType: data['assessmentType']?.toString() ?? 'Quiz',
      schoolYear: data['schoolYear']?.toString(),
    );
    
    return assessment;
  }

  // Helper method to parse questions from different data structures
  static List<AssessmentQuestion> _parseQuestionsFromData(dynamic questionsData) {
    final questions = <AssessmentQuestion>[];
    
    if (questionsData is List) {
      // Questions are stored as an array
      for (var questionData in questionsData) {
        if (questionData is Map) {
          try {
            final question = AssessmentQuestion.fromMap(questionData);
            questions.add(question);
          } catch (e) {
          }
        }
      }
    } else if (questionsData is Map) {
      // Questions are stored as a map with numeric keys (0, 1, 2...)
      questionsData.forEach((key, questionData) {
        if (questionData is Map) {
          try {
            final question = AssessmentQuestion.fromMap(questionData);
            questions.add(question);
          } catch (e) {
          }
        }
      });
    }
    
    // Sort questions by key/index to maintain order
    questions.sort((a, b) => a.id.compareTo(b.id));
    
    return questions;
  }

  // Convert to Realtime Database
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isPublished': isPublished,
      'tags': tags,
      'timeLimit': timeLimit,
      'totalPoints': totalPoints,
      'questions': questions.map((q) => q.toMap()).toList(),
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'instructions': instructions,
      'assessmentType': assessmentType,
      'schoolYear': schoolYear,
    };
  }

  // Create copy with updated fields
  Assessment copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    String? teacherId,
    String? teacherName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
    List<String>? tags,
    int? timeLimit,
    int? totalPoints,
    List<AssessmentQuestion>? questions,
    DateTime? dueDate,
    String? instructions,
    String? assessmentType,
    String? schoolYear,
  }) {
    return Assessment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      tags: tags ?? this.tags,
      timeLimit: timeLimit ?? this.timeLimit,
      totalPoints: totalPoints ?? this.totalPoints,
      questions: questions ?? this.questions,
      dueDate: dueDate ?? this.dueDate,
      instructions: instructions ?? this.instructions,
      assessmentType: assessmentType ?? this.assessmentType,
      schoolYear: schoolYear ?? this.schoolYear,
    );
  }
}

class AssessmentQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options; // For multiple choice
  final List<String> correctAnswers; // For multiple choice/true-false
  final String? correctAnswer; // For single answer questions
  final int points;
  final Map<String, int> optionPoints; // Points for each option (e.g., {"A": 10, "B": 5, "C": 0})
  final String? explanation;
  final bool showCorrectAnswer; // Whether to show correct answer to students

  AssessmentQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options = const [],
    this.correctAnswers = const [],
    this.correctAnswer,
    this.points = 10,
    this.optionPoints = const {}, // Points for each option
    this.explanation,
    this.showCorrectAnswer = false, // Default to hidden
  });

  // Create from Map
  factory AssessmentQuestion.fromMap(Map<dynamic, dynamic> data) {
    
    final questionType = data['type']?.toString() ?? '';
    
    QuestionType parsedType;
    try {
      parsedType = QuestionType.values.firstWhere(
        (e) => e.toString().split('.').last == questionType,
        orElse: () => QuestionType.multipleChoice,
      );
    } catch (e) {
      parsedType = QuestionType.multipleChoice;
    }
    
    // Parse option points if available
    Map<String, int> parsedOptionPoints = {};
    if (data['optionPoints'] != null && data['optionPoints'] is Map) {
      (data['optionPoints'] as Map).forEach((key, value) {
        if (key != null && value != null) {
          final intValue = value is int ? value : (int.tryParse(value.toString()) ?? 0);
          parsedOptionPoints[key.toString()] = intValue;
        }
      });
    }
    
    final question = AssessmentQuestion(
      id: data['id']?.toString() ?? '',
      question: data['question']?.toString() ?? '',
      type: parsedType,
      options: data['options'] != null 
          ? List<String>.from((data['options'] as List).map((e) => e.toString()))
          : [],
      correctAnswers: data['correctAnswers'] != null 
          ? List<String>.from((data['correctAnswers'] as List).map((e) => e.toString()))
          : [],
      correctAnswer: data['correctAnswer']?.toString(),
      points: data['points'] as int? ?? 10,
      optionPoints: parsedOptionPoints,
      explanation: data['explanation']?.toString(),
      showCorrectAnswer: data['showCorrectAnswer'] as bool? ?? false,
    );
    
    return question;
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type.toString().split('.').last,
      'options': options,
      'correctAnswers': correctAnswers,
      'correctAnswer': correctAnswer,
      'points': points,
      'optionPoints': optionPoints,
      'explanation': explanation,
      'showCorrectAnswer': showCorrectAnswer,
    };
  }

  // Create copy with updated fields
  AssessmentQuestion copyWith({
    String? id,
    String? question,
    QuestionType? type,
    List<String>? options,
    List<String>? correctAnswers,
    String? correctAnswer,
    int? points,
    Map<String, int>? optionPoints,
    String? explanation,
    bool? showCorrectAnswer,
  }) {
    return AssessmentQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      points: points ?? this.points,
      optionPoints: optionPoints ?? this.optionPoints,
      explanation: explanation ?? this.explanation,
      showCorrectAnswer: showCorrectAnswer ?? this.showCorrectAnswer,
    );
  }
}

enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
  essay,
  fillInTheBlank,
}
