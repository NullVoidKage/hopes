import 'package:cloud_firestore/cloud_firestore.dart';

class StudentFeedback {
  final String id;
  final String studentId;
  final String studentName;
  final String teacherId;
  final String teacherName;
  final String feedbackType; // 'assessment', 'lesson', 'learning_path', 'general'
  final String contentId; // ID of the related content (assessment, lesson, etc.)
  final String contentTitle;
  final String feedback;
  final String recommendations;
  final double rating; // 1-5 scale
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isRead;
  final Map<String, dynamic> metadata; // Additional context

  StudentFeedback({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.teacherName,
    required this.feedbackType,
    required this.contentId,
    required this.contentTitle,
    required this.feedback,
    required this.recommendations,
    required this.rating,
    required this.createdAt,
    this.updatedAt,
    this.isRead = false,
    this.metadata = const {},
  });

  // Create from Firestore
  factory StudentFeedback.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentFeedback(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      feedbackType: data['feedbackType'] ?? '',
      contentId: data['contentId'] ?? '',
      contentTitle: data['contentTitle'] ?? '',
      feedback: data['feedback'] ?? '',
      recommendations: data['recommendations'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'] ?? {},
    );
  }

  // Create from Realtime Database
  factory StudentFeedback.fromRealtimeDatabase(Map<String, dynamic> data, String id) {
    return StudentFeedback(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      feedbackType: data['feedbackType'] ?? '',
      contentId: data['contentId'] ?? '',
      contentTitle: data['contentTitle'] ?? '',
      feedback: data['feedback'] ?? '',
      recommendations: data['recommendations'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      updatedAt: data['updatedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt']) : null,
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'] ?? {},
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'feedbackType': feedbackType,
      'contentId': contentId,
      'contentTitle': contentTitle,
      'feedback': feedback,
      'recommendations': recommendations,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  // Convert to Realtime Database format
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'feedbackType': feedbackType,
      'contentId': contentId,
      'contentTitle': contentTitle,
      'feedback': feedback,
      'recommendations': recommendations,
      'rating': rating,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  // Create copy with modifications
  StudentFeedback copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? teacherId,
    String? teacherName,
    String? feedbackType,
    String? contentId,
    String? contentTitle,
    String? feedback,
    String? recommendations,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return StudentFeedback(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      feedbackType: feedbackType ?? this.feedbackType,
      contentId: contentId ?? this.contentId,
      contentTitle: contentTitle ?? this.contentTitle,
      feedback: feedback ?? this.feedback,
      recommendations: recommendations ?? this.recommendations,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}

class StudentRecommendation {
  final String id;
  final String studentId;
  final String studentName;
  final String teacherId;
  final String teacherName;
  final String recommendationType; // 'content', 'learning_path', 'study_habit', 'resource'
  final String title;
  final String description;
  final String reason;
  final String actionItems;
  final int priority; // 1-5 scale
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isRead;
  final Map<String, dynamic> metadata;

  StudentRecommendation({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.teacherName,
    required this.recommendationType,
    required this.title,
    required this.description,
    required this.reason,
    required this.actionItems,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.isCompleted = false,
    this.isRead = false,
    this.metadata = const {},
  });

  // Create from Firestore
  factory StudentRecommendation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentRecommendation(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      recommendationType: data['recommendationType'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      reason: data['reason'] ?? '',
      actionItems: data['actionItems'] ?? '',
      priority: data['priority'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      isCompleted: data['isCompleted'] ?? false,
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'] ?? {},
    );
  }

  // Create from Realtime Database
  factory StudentRecommendation.fromRealtimeDatabase(Map<String, dynamic> data, String id) {
    return StudentRecommendation(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      recommendationType: data['recommendationType'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      reason: data['reason'] ?? '',
      actionItems: data['actionItems'] ?? '',
      priority: data['priority'] ?? 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      dueDate: data['dueDate'] != null ? DateTime.fromMillisecondsSinceEpoch(data['dueDate']) : null,
      isCompleted: data['isCompleted'] ?? false,
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'] ?? {},
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'recommendationType': recommendationType,
      'title': title,
      'description': description,
      'reason': reason,
      'actionItems': actionItems,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isCompleted': isCompleted,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  // Convert to Realtime Database format
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'recommendationType': recommendationType,
      'title': title,
      'description': description,
      'reason': reason,
      'actionItems': actionItems,
      'priority': priority,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  // Create copy with modifications
  StudentRecommendation copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? teacherId,
    String? teacherName,
    String? recommendationType,
    String? title,
    String? description,
    String? reason,
    String? actionItems,
    int? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return StudentRecommendation(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      recommendationType: recommendationType ?? this.recommendationType,
      title: title ?? this.title,
      description: description ?? this.description,
      reason: reason ?? this.reason,
      actionItems: actionItems ?? this.actionItems,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}
