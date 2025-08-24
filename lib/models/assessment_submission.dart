import 'package:cloud_firestore/cloud_firestore.dart';

class DetailedAnswer {
  final String answer;
  final String correctAnswer;
  final bool isCorrect;
  final int points;
  final String questionType;
  final int timeSpent; // in seconds
  final String? explanation;

  DetailedAnswer({
    required this.answer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.points,
    required this.questionType,
    required this.timeSpent,
    this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'answer': answer,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect,
      'points': points,
      'questionType': questionType,
      'timeSpent': timeSpent,
      'explanation': explanation,
    };
  }

  factory DetailedAnswer.fromMap(Map<Object?, Object?> data) {
    return DetailedAnswer(
      answer: _safeString(data['answer']),
      correctAnswer: _safeString(data['correctAnswer']),
      isCorrect: _safeBool(data['isCorrect']),
      points: _safeInt(data['points']),
      questionType: _safeString(data['questionType']),
      timeSpent: _safeInt(data['timeSpent']),
      explanation: _safeString(data['explanation']),
    );
  }

  // Safe type conversion helpers
  static String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _safeBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return false;
  }
}

class AssessmentSubmission {
  final String id;
  final String assessmentId;
  final String studentId;
  final String teacherId;
  
  // Enhanced Student Information
  final String studentName;
  final String studentEmail;
  final String studentGrade;
  final String studentSection;
  
  // Enhanced Assessment Context
  final String assessmentTitle;
  final String assessmentSubject;
  final String assessmentType;
  final String assessmentGradeLevel;
  final int totalQuestions;
  final int maxPossibleScore;
  
  // Enhanced Answer Analysis
  final Map<int, DetailedAnswer> detailedAnswers;
  final Map<int, String> answers; // Keep for backward compatibility
  
  // Scoring and Performance
  final int score;
  final double accuracy; // Percentage of correct answers
  final int correctAnswers;
  final int incorrectAnswers;
  final int unansweredQuestions;
  
  // Timing and Context
  final DateTime submittedAt;
  final DateTime? startedAt;
  final int timeSpent; // in seconds
  final double averageTimePerQuestion;
  
  // Grading Information
  final String? feedback;
  final bool isGraded;
  final DateTime? gradedAt;
  final String? gradedBy;
  final bool isAutoGraded;

  AssessmentSubmission({
    required this.id,
    required this.assessmentId,
    required this.studentId,
    required this.teacherId,
    
    // Enhanced Student Information
    required this.studentName,
    required this.studentEmail,
    required this.studentGrade,
    required this.studentSection,
    
    // Enhanced Assessment Context
    required this.assessmentTitle,
    required this.assessmentSubject,
    required this.assessmentType,
    required this.assessmentGradeLevel,
    required this.totalQuestions,
    required this.maxPossibleScore,
    
    // Enhanced Answer Analysis
    required this.detailedAnswers,
    required this.answers, // Keep for backward compatibility
    
    // Scoring and Performance
    required this.score,
    required this.accuracy,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.unansweredQuestions,
    
    // Timing and Context
    required this.submittedAt,
    this.startedAt,
    required this.timeSpent,
    required this.averageTimePerQuestion,
    
    // Grading Information
    this.feedback,
    this.isGraded = false,
    this.gradedAt,
    this.gradedBy,
    this.isAutoGraded = false,
  });

  // Create from Firebase Realtime Database
  factory AssessmentSubmission.fromRealtimeDatabase(Map<Object?, Object?> data, String id) {
    // Parse detailed answers if available
    final detailedAnswers = _parseDetailedAnswers(data['detailedAnswers']);
    
    // Calculate performance metrics
    final totalQuestions = detailedAnswers.length;
    final correctAnswers = detailedAnswers.values.where((a) => a.isCorrect).length;
    final incorrectAnswers = detailedAnswers.values.where((a) => !a.isCorrect).length;
    final accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;
    final averageTimePerQuestion = totalQuestions > 0 ? (_safeInt(data['timeSpent']) / totalQuestions) : 0.0;
    
    return AssessmentSubmission(
      id: id,
      assessmentId: _safeString(data['assessmentId']),
      studentId: _safeString(data['studentId']),
      teacherId: _safeString(data['teacherId']),
      
      // Enhanced Student Information
      studentName: _safeString(data['studentName'] ?? 'Unknown Student'),
      studentEmail: _safeString(data['studentEmail'] ?? ''),
      studentGrade: _safeString(data['studentGrade'] ?? 'Grade 7'),
      studentSection: _safeString(data['studentSection'] ?? 'Section A'),
      
      // Enhanced Assessment Context
      assessmentTitle: _safeString(data['assessmentTitle'] ?? 'Assessment'),
      assessmentSubject: _safeString(data['assessmentSubject'] ?? 'General'),
      assessmentType: _safeString(data['assessmentType'] ?? 'Quiz'),
      assessmentGradeLevel: _safeString(data['assessmentGradeLevel'] ?? 'Grade 7'),
      totalQuestions: totalQuestions,
      maxPossibleScore: _safeInt(data['maxPossibleScore'] ?? 100),
      
      // Enhanced Answer Analysis
      detailedAnswers: detailedAnswers,
      answers: _parseAnswers(data['answers']), // Keep for backward compatibility
      
      // Scoring and Performance
      score: _safeInt(data['score']),
      accuracy: accuracy,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      unansweredQuestions: 0, // Will be calculated if needed
      
      // Timing and Context
      submittedAt: DateTime.fromMillisecondsSinceEpoch(_safeInt(data['submittedAt'])),
      startedAt: data['startedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(_safeInt(data['startedAt']))
          : null,
      timeSpent: _safeInt(data['timeSpent']),
      averageTimePerQuestion: averageTimePerQuestion,
      
      // Grading Information
      feedback: _safeString(data['feedback']),
      isGraded: _safeBool(data['isGraded']),
      gradedAt: data['gradedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(_safeInt(data['gradedAt']))
          : null,
      gradedBy: _safeString(data['gradedBy']),
      isAutoGraded: _safeBool(data['isAutoGraded']),
    );
  }

  // Safe type conversion helpers
  static String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _safeBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return false;
  }

  // Parse answers from Firebase data (handles both Map and List structures)
  static Map<int, String> _parseAnswers(dynamic answersData) {
    if (answersData is Map) {
      Map<int, String> parsedAnswers = {};
      answersData.forEach((key, value) {
        if (key != null) {
          String keyStr = key.toString();
          int? index = int.tryParse(keyStr);
          if (index != null && value != null) {
            parsedAnswers[index] = value.toString();
          }
        }
      });
      return parsedAnswers;
    }
    return {};
  }

  // Parse detailed answers from Firebase data
  static Map<int, DetailedAnswer> _parseDetailedAnswers(dynamic detailedAnswersData) {
    if (detailedAnswersData is Map) {
      Map<int, DetailedAnswer> parsedAnswers = {};
      detailedAnswersData.forEach((key, value) {
        if (key != null) {
          String keyStr = key.toString();
          int? index = int.tryParse(keyStr);
          if (index != null && value is Map) {
            try {
              parsedAnswers[index] = DetailedAnswer.fromMap(value as Map<Object?, Object?>);
            } catch (e) {
              print('⚠️ Error parsing detailed answer $index: $e');
            }
          }
        }
      });
      return parsedAnswers;
    }
    return {};
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'assessmentId': assessmentId,
      'studentId': studentId,
      'teacherId': teacherId,
      
      // Enhanced Student Information
      'studentName': studentName,
      'studentEmail': studentEmail,
      'studentGrade': studentGrade,
      'studentSection': studentSection,
      
      // Enhanced Assessment Context
      'assessmentTitle': assessmentTitle,
      'assessmentSubject': assessmentSubject,
      'assessmentType': assessmentType,
      'assessmentGradeLevel': assessmentGradeLevel,
      'totalQuestions': totalQuestions,
      'maxPossibleScore': maxPossibleScore,
      
      // Enhanced Answer Analysis
      'detailedAnswers': detailedAnswers.map((key, value) => MapEntry(key.toString(), value.toMap())),
      'answers': answers, // Keep for backward compatibility
      
      // Scoring and Performance
      'score': score,
      'accuracy': accuracy,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'unansweredQuestions': unansweredQuestions,
      
      // Timing and Context
      'submittedAt': submittedAt.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'timeSpent': timeSpent,
      'averageTimePerQuestion': averageTimePerQuestion,
      
      // Grading Information
      'feedback': feedback,
      'isGraded': isGraded,
      'gradedAt': gradedAt?.millisecondsSinceEpoch,
      'gradedBy': gradedBy,
      'isAutoGraded': isAutoGraded,
    };
  }

  // Create a copy with updated fields
  AssessmentSubmission copyWith({
    String? id,
    String? assessmentId,
    String? studentId,
    String? teacherId,
    
    // Enhanced Student Information
    String? studentName,
    String? studentEmail,
    String? studentGrade,
    String? studentSection,
    
    // Enhanced Assessment Context
    String? assessmentTitle,
    String? assessmentSubject,
    String? assessmentType,
    String? assessmentGradeLevel,
    int? totalQuestions,
    int? maxPossibleScore,
    
    // Enhanced Answer Analysis
    Map<int, DetailedAnswer>? detailedAnswers,
    Map<int, String>? answers,
    
    // Scoring and Performance
    int? score,
    double? accuracy,
    int? correctAnswers,
    int? incorrectAnswers,
    int? unansweredQuestions,
    
    // Timing and Context
    DateTime? submittedAt,
    DateTime? startedAt,
    int? timeSpent,
    double? averageTimePerQuestion,
    
    // Grading Information
    String? feedback,
    bool? isGraded,
    DateTime? gradedAt,
    String? gradedBy,
    bool? isAutoGraded,
  }) {
    return AssessmentSubmission(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      
      // Enhanced Student Information
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      studentGrade: studentGrade ?? this.studentGrade,
      studentSection: studentSection ?? this.studentSection,
      
      // Enhanced Assessment Context
      assessmentTitle: assessmentTitle ?? this.assessmentTitle,
      assessmentSubject: assessmentSubject ?? this.assessmentSubject,
      assessmentType: assessmentType ?? this.assessmentType,
      assessmentGradeLevel: assessmentGradeLevel ?? this.assessmentGradeLevel,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      maxPossibleScore: maxPossibleScore ?? this.maxPossibleScore,
      
      // Enhanced Answer Analysis
      detailedAnswers: detailedAnswers ?? this.detailedAnswers,
      answers: answers ?? this.answers,
      
      // Scoring and Performance
      score: score ?? this.score,
      accuracy: accuracy ?? this.accuracy,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      unansweredQuestions: unansweredQuestions ?? this.unansweredQuestions,
      
      // Timing and Context
      submittedAt: submittedAt ?? this.submittedAt,
      startedAt: startedAt ?? this.startedAt,
      timeSpent: timeSpent ?? this.timeSpent,
      averageTimePerQuestion: averageTimePerQuestion ?? this.averageTimePerQuestion,
      
      // Grading Information
      feedback: feedback ?? this.feedback,
      isGraded: isGraded ?? this.isGraded,
      gradedAt: gradedAt ?? this.gradedAt,
      gradedBy: gradedBy ?? this.gradedBy,
      isAutoGraded: isAutoGraded ?? this.isAutoGraded,
    );
  }

  // Get formatted submission date
  String get formattedDate {
    return '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}';
  }

  // Get formatted submission time
  String get formattedTime {
    return '${submittedAt.hour.toString().padLeft(2, '0')}:${submittedAt.minute.toString().padLeft(2, '0')}';
  }

  // Get formatted time spent
  String get formattedTimeSpent {
    if (timeSpent < 60) {
      return '${timeSpent}s';
    } else {
      int minutes = timeSpent ~/ 60;
      int seconds = timeSpent % 60;
      return '${minutes}m ${seconds}s';
    }
  }

  // Get score percentage (assuming 100 is max)
  double get scorePercentage {
    return (score / 100.0) * 100;
  }

  // Get score color based on performance
  String get scoreColor {
    if (scorePercentage >= 80) return '#34C759'; // Green
    if (scorePercentage >= 60) return '#FF9500'; // Orange
    return '#FF3B30'; // Red
  }

  @override
  String toString() {
    return 'AssessmentSubmission(id: $id, assessmentId: $assessmentId, studentId: $studentId, score: $score)';
  }
}
