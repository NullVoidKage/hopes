import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProgress {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String subject;
  final int lessonsCompleted;
  final int totalLessons;
  final int assessmentsTaken;
  final int totalAssessments;
  final double averageScore;
  final double completionRate;
  final DateTime lastActivity;
  final List<LessonProgress> lessonProgress;
  final List<AssessmentProgress> assessmentProgress;
  final Map<String, dynamic> metadata;

  StudentProgress({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.subject,
    required this.lessonsCompleted,
    required this.totalLessons,
    required this.assessmentsTaken,
    required this.totalAssessments,
    required this.averageScore,
    required this.completionRate,
    required this.lastActivity,
    required this.lessonProgress,
    required this.assessmentProgress,
    this.metadata = const {},
  });

  factory StudentProgress.fromRealtimeDatabase(Map<String, dynamic> data, String id) {
    return StudentProgress(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      subject: data['subject'] ?? '',
      lessonsCompleted: data['lessonsCompleted'] ?? 0,
      totalLessons: data['totalLessons'] ?? 0,
      assessmentsTaken: data['assessmentsTaken'] ?? 0,
      totalAssessments: data['totalAssessments'] ?? 0,
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      completionRate: (data['completionRate'] ?? 0.0).toDouble(),
      lastActivity: data['lastActivity'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['lastActivity']) 
          : DateTime.now(),
      lessonProgress: (data['lessonProgress'] as Map<String, dynamic>? ?? {})
          .entries
          .map((e) => LessonProgress.fromMap(e.value, e.key))
          .toList(),
      assessmentProgress: (data['assessmentProgress'] as Map<String, dynamic>? ?? {})
          .entries
          .map((e) => AssessmentProgress.fromMap(e.value, e.key))
          .toList(),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'subject': subject,
      'lessonsCompleted': lessonsCompleted,
      'totalLessons': totalLessons,
      'assessmentsTaken': assessmentsTaken,
      'totalAssessments': totalAssessments,
      'averageScore': averageScore,
      'completionRate': completionRate,
      'lastActivity': lastActivity.millisecondsSinceEpoch,
      'lessonProgress': lessonProgress.fold<Map<String, dynamic>>({}, (map, progress) {
        map[progress.lessonId] = progress.toMap();
        return map;
      }),
      'assessmentProgress': assessmentProgress.fold<Map<String, dynamic>>({}, (map, progress) {
        map[progress.assessmentId] = progress.toMap();
        return map;
      }),
      'metadata': metadata,
    };
  }

  StudentProgress copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? subject,
    int? lessonsCompleted,
    int? totalLessons,
    int? assessmentsTaken,
    int? totalAssessments,
    double? averageScore,
    double? completionRate,
    DateTime? lastActivity,
    List<LessonProgress>? lessonProgress,
    List<AssessmentProgress>? assessmentProgress,
    Map<String, dynamic>? metadata,
  }) {
    return StudentProgress(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      subject: subject ?? this.subject,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      totalLessons: totalLessons ?? this.totalLessons,
      assessmentsTaken: assessmentsTaken ?? this.assessmentsTaken,
      totalAssessments: totalAssessments ?? this.totalAssessments,
      averageScore: averageScore ?? this.averageScore,
      completionRate: completionRate ?? this.completionRate,
      lastActivity: lastActivity ?? this.lastActivity,
      lessonProgress: lessonProgress ?? this.lessonProgress,
      assessmentProgress: assessmentProgress ?? this.assessmentProgress,
      metadata: metadata ?? this.metadata,
    );
  }
}

class LessonProgress {
  final String lessonId;
  final String lessonTitle;
  final bool isCompleted;
  final DateTime? completedAt;
  final int timeSpent; // in minutes
  final double? score;
  final String status; // 'not_started', 'in_progress', 'completed'

  LessonProgress({
    required this.lessonId,
    required this.lessonTitle,
    required this.isCompleted,
    this.completedAt,
    required this.timeSpent,
    this.score,
    required this.status,
  });

  factory LessonProgress.fromMap(Map<String, dynamic> data, String id) {
    return LessonProgress(
      lessonId: id,
      lessonTitle: data['lessonTitle'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['completedAt']) 
          : null,
      timeSpent: data['timeSpent'] ?? 0,
      score: data['score']?.toDouble(),
      status: data['status'] ?? 'not_started',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonTitle': lessonTitle,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'timeSpent': timeSpent,
      'score': score,
      'status': status,
    };
  }
}

class AssessmentProgress {
  final String assessmentId;
  final String assessmentTitle;
  final bool isCompleted;
  final DateTime? completedAt;
  final int timeSpent; // in minutes
  final double score;
  final int totalQuestions;
  final int correctAnswers;
  final String status; // 'not_started', 'in_progress', 'completed'

  AssessmentProgress({
    required this.assessmentId,
    required this.assessmentTitle,
    required this.isCompleted,
    this.completedAt,
    required this.timeSpent,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.status,
  });

  factory AssessmentProgress.fromMap(Map<String, dynamic> data, String id) {
    return AssessmentProgress(
      assessmentId: id,
      assessmentTitle: data['assessmentTitle'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['completedAt']) 
          : null,
      timeSpent: data['timeSpent'] ?? 0,
      score: (data['score'] ?? 0.0).toDouble(),
      totalQuestions: data['totalQuestions'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      status: data['status'] ?? 'not_started',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assessmentTitle': assessmentTitle,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'timeSpent': timeSpent,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'status': status,
    };
  }
}
