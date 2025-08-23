import 'package:cloud_firestore/cloud_firestore.dart';

class LearningPath {
  final String id;
  final String title;
  final String description;
  final String teacherId;
  final String teacherName;
  final List<String> subjects;
  final List<String> tags;
  final List<LearningPathStep> steps;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.teacherId,
    required this.teacherName,
    required this.subjects,
    required this.tags,
    required this.steps,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  // Create from Firestore
  factory LearningPath.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LearningPath(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      subjects: List<String>.from(data['subjects'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      steps: (data['steps'] as List<dynamic>? ?? [])
          .map((step) => LearningPathStep.fromMap(step))
          .toList(),
      isPublished: data['isPublished'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: data['metadata'] ?? {},
    );
  }

  // Create from Realtime Database (for offline support)
  factory LearningPath.fromRealtimeDatabase(Map<String, dynamic> data, String id) {
    return LearningPath(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      subjects: List<String>.from(data['subjects'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      steps: (data['steps'] as List<dynamic>? ?? [])
          .map((step) => LearningPathStep.fromMap(step))
          .toList(),
      isPublished: data['isPublished'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] ?? 0),
      metadata: data['metadata'] ?? {},
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subjects': subjects,
      'tags': tags,
      'steps': steps.map((step) => step.toMap()).toList(),
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  // Convert to Realtime Database (for offline support)
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'title': title,
      'description': description,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subjects': subjects,
      'tags': tags,
      'steps': steps.map((step) => step.toMap()).toList(),
      'isPublished': isPublished,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  // Create a copy with modifications
  LearningPath copyWith({
    String? id,
    String? title,
    String? description,
    String? teacherId,
    String? teacherName,
    List<String>? subjects,
    List<String>? tags,
    List<LearningPathStep>? steps,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return LearningPath(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      subjects: subjects ?? this.subjects,
      tags: tags ?? this.tags,
      steps: steps ?? this.steps,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

class LearningPathStep {
  final String id;
  final String title;
  final String description;
  final String type; // 'lesson', 'assessment', 'activity'
  final String? contentId; // ID of lesson, assessment, or activity
  final int order;
  final int estimatedDuration; // in minutes
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> metadata;

  LearningPathStep({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.contentId,
    required this.order,
    required this.estimatedDuration,
    this.requirements = const {},
    this.metadata = const {},
  });

  factory LearningPathStep.fromMap(Map<String, dynamic> map) {
    return LearningPathStep(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'lesson',
      contentId: map['contentId'],
      order: map['order'] ?? 0,
      estimatedDuration: map['estimatedDuration'] ?? 30,
      requirements: map['requirements'] ?? {},
      metadata: map['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'contentId': contentId,
      'order': order,
      'estimatedDuration': estimatedDuration,
      'requirements': requirements,
      'metadata': metadata,
    };
  }

  LearningPathStep copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? contentId,
    int? order,
    int? estimatedDuration,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? metadata,
  }) {
    return LearningPathStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      contentId: contentId ?? this.contentId,
      order: order ?? this.order,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      requirements: requirements ?? this.requirements,
      metadata: metadata ?? this.metadata,
    );
  }
}

class StudentLearningPath {
  final String id;
  final String studentId;
  final String studentName;
  final String learningPathId;
  final String learningPathTitle;
  final String teacherId;
  final DateTime assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<StudentPathProgress> stepProgress;
  final Map<String, dynamic> customizations;
  final String status; // 'assigned', 'in_progress', 'completed', 'paused'
  final Map<String, dynamic> metadata;

  StudentLearningPath({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.learningPathId,
    required this.learningPathTitle,
    required this.teacherId,
    required this.assignedAt,
    this.startedAt,
    this.completedAt,
    required this.stepProgress,
    this.customizations = const {},
    required this.status,
    this.metadata = const {},
  });

  factory StudentLearningPath.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentLearningPath(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      learningPathId: data['learningPathId'] ?? '',
      learningPathTitle: data['learningPathTitle'] ?? '',
      teacherId: data['teacherId'] ?? '',
      assignedAt: (data['assignedAt'] as Timestamp).toDate(),
      startedAt: data['startedAt'] != null ? (data['startedAt'] as Timestamp).toDate() : null,
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      stepProgress: (data['stepProgress'] as List<dynamic>? ?? [])
          .map((step) => StudentPathProgress.fromMap(step))
          .toList(),
      customizations: data['customizations'] ?? {},
      status: data['status'] ?? 'assigned',
      metadata: data['metadata'] ?? {},
    );
  }

  factory StudentLearningPath.fromRealtimeDatabase(Map<String, dynamic> data, String id) {
    return StudentLearningPath(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      learningPathId: data['learningPathId'] ?? '',
      learningPathTitle: data['learningPathTitle'] ?? '',
      teacherId: data['teacherId'] ?? '',
      assignedAt: DateTime.fromMillisecondsSinceEpoch(data['assignedAt'] ?? 0),
      startedAt: data['startedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(data['startedAt']) : null,
      completedAt: data['completedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(data['completedAt']) : null,
      stepProgress: (data['stepProgress'] as List<dynamic>? ?? [])
          .map((step) => StudentPathProgress.fromMap(step))
          .toList(),
      customizations: data['customizations'] ?? {},
      status: data['status'] ?? 'assigned',
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'learningPathId': learningPathId,
      'learningPathTitle': learningPathTitle,
      'teacherId': teacherId,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'stepProgress': stepProgress.map((step) => step.toMap()).toList(),
      'customizations': customizations,
      'status': status,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'learningPathId': learningPathId,
      'learningPathTitle': learningPathTitle,
      'teacherId': teacherId,
      'assignedAt': assignedAt.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'stepProgress': stepProgress.map((step) => step.toMap()).toList(),
      'customizations': customizations,
      'status': status,
      'metadata': metadata,
    };
  }

  StudentLearningPath copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? learningPathId,
    String? learningPathTitle,
    String? teacherId,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<StudentPathProgress>? stepProgress,
    Map<String, dynamic>? customizations,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return StudentLearningPath(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      learningPathId: learningPathId ?? this.learningPathId,
      learningPathTitle: learningPathTitle ?? this.learningPathTitle,
      teacherId: teacherId ?? this.teacherId,
      assignedAt: assignedAt ?? this.assignedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      stepProgress: stepProgress ?? this.stepProgress,
      customizations: customizations ?? this.customizations,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }
}

class StudentPathProgress {
  final String stepId;
  final String stepTitle;
  final String status; // 'not_started', 'in_progress', 'completed', 'skipped'
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double? score;
  final int timeSpent; // in minutes
  final Map<String, dynamic> metadata;

  StudentPathProgress({
    required this.stepId,
    required this.stepTitle,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.score,
    required this.timeSpent,
    this.metadata = const {},
  });

  factory StudentPathProgress.fromMap(Map<String, dynamic> map) {
    return StudentPathProgress(
      stepId: map['stepId'] ?? '',
      stepTitle: map['stepTitle'] ?? '',
      status: map['status'] ?? 'not_started',
      startedAt: map['startedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['startedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['completedAt']) : null,
      score: map['score']?.toDouble(),
      timeSpent: map['timeSpent'] ?? 0,
      metadata: map['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stepId': stepId,
      'stepTitle': stepTitle,
      'status': status,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'score': score,
      'timeSpent': timeSpent,
      'metadata': metadata,
    };
  }

  StudentPathProgress copyWith({
    String? stepId,
    String? stepTitle,
    String? status,
    DateTime? startedAt,
    DateTime? completedAt,
    double? score,
    int? timeSpent,
    Map<String, dynamic>? metadata,
  }) {
    return StudentPathProgress(
      stepId: stepId ?? this.stepId,
      stepTitle: stepTitle ?? this.stepTitle,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
      timeSpent: timeSpent ?? this.timeSpent,
      metadata: metadata ?? this.metadata,
    );
  }
}
