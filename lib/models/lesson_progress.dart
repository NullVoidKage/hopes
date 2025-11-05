import 'package:cloud_firestore/cloud_firestore.dart';

class LessonProgress {
  final String id;
  final String studentId;
  final String studentName;
  final String lessonId;
  final String lessonTitle;
  final String subject;
  final String teacherId;
  final String teacherName;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime lastActivity;
  final bool isCompleted;
  final double progressPercentage; // 0.0 to 1.0
  final int timeSpent; // in seconds
  final Map<String, dynamic>? metadata; // Additional tracking data
  final String? section; // Section if enrolled in class
  final String? classId; // Class ID if enrolled

  LessonProgress({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.lessonId,
    required this.lessonTitle,
    required this.subject,
    required this.teacherId,
    required this.teacherName,
    required this.startedAt,
    this.completedAt,
    required this.lastActivity,
    this.isCompleted = false,
    this.progressPercentage = 0.0,
    this.timeSpent = 0,
    this.metadata,
    this.section,
    this.classId,
  });

  // Create from Firestore
  factory LessonProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonProgress(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      lessonId: data['lessonId'] ?? '',
      lessonTitle: data['lessonTitle'] ?? '',
      subject: data['subject'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      lastActivity: (data['lastActivity'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      progressPercentage: (data['progressPercentage'] ?? 0.0).toDouble(),
      timeSpent: data['timeSpent'] ?? 0,
      metadata: data['metadata'],
      section: data['section'],
      classId: data['classId'],
    );
  }

  // Create from Realtime Database
  factory LessonProgress.fromRealtimeDatabase(String id, Map<dynamic, dynamic> data) {
    return LessonProgress(
      id: id,
      studentId: data['studentId']?.toString() ?? '',
      studentName: data['studentName']?.toString() ?? '',
      lessonId: data['lessonId']?.toString() ?? '',
      lessonTitle: data['lessonTitle']?.toString() ?? '',
      subject: data['subject']?.toString() ?? '',
      teacherId: data['teacherId']?.toString() ?? '',
      teacherName: data['teacherName']?.toString() ?? '',
      startedAt: data['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['startedAt'] as int)
          : DateTime.now(),
      completedAt: data['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['completedAt'] as int)
          : null,
      lastActivity: data['lastActivity'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastActivity'] as int)
          : DateTime.now(),
      isCompleted: data['isCompleted'] as bool? ?? false,
      progressPercentage: (data['progressPercentage'] ?? 0.0).toDouble(),
      timeSpent: data['timeSpent'] ?? 0,
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata'] as Map) : null,
      section: data['section']?.toString(),
      classId: data['classId']?.toString(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'subject': subject,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'lastActivity': Timestamp.fromDate(lastActivity),
      'isCompleted': isCompleted,
      'progressPercentage': progressPercentage,
      'timeSpent': timeSpent,
      'metadata': metadata,
      'section': section,
      'classId': classId,
    };
  }

  // Convert to Realtime Database
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'subject': subject,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'lastActivity': lastActivity.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'progressPercentage': progressPercentage,
      'timeSpent': timeSpent,
      'metadata': metadata,
      'section': section,
      'classId': classId,
    };
  }

  // Copy with updated fields
  LessonProgress copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? lessonId,
    String? lessonTitle,
    String? subject,
    String? teacherId,
    String? teacherName,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastActivity,
    bool? isCompleted,
    double? progressPercentage,
    int? timeSpent,
    Map<String, dynamic>? metadata,
    String? section,
    String? classId,
  }) {
    return LessonProgress(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      lessonId: lessonId ?? this.lessonId,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      subject: subject ?? this.subject,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastActivity: lastActivity ?? this.lastActivity,
      isCompleted: isCompleted ?? this.isCompleted,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      timeSpent: timeSpent ?? this.timeSpent,
      metadata: metadata ?? this.metadata,
      section: section ?? this.section,
      classId: classId ?? this.classId,
    );
  }
}

