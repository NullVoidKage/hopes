import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  final String id;
  final String title;
  final String subject;
  final String content;
  final String teacherId;
  final String teacherName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;
  final List<String> tags;
  final String? description;
  final String? fileUrl;

  Lesson({
    required this.id,
    required this.title,
    required this.subject,
    required this.content,
    required this.teacherId,
    required this.teacherName,
    required this.createdAt,
    required this.updatedAt,
    this.isPublished = false,
    this.tags = const [],
    this.description,
    this.fileUrl,
  });

  // Create from Firestore document
  factory Lesson.fromFirestore(Map<String, dynamic> data, String id) {
    return Lesson(
      id: id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      content: data['content'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isPublished: data['isPublished'] ?? false,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      description: data['description'],
      fileUrl: data['fileUrl'],
    );
  }

  // Create from Realtime Database
  factory Lesson.fromRealtimeDatabase(String id, Map<dynamic, dynamic> data) {
    return Lesson(
      id: id,
      title: data['title']?.toString() ?? '',
      subject: data['subject']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
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
      description: data['description']?.toString(),
      fileUrl: data['fileUrl']?.toString(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subject': subject,
      'content': content,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPublished': isPublished,
      'tags': tags,
      'description': description,
      'fileUrl': fileUrl,
    };
  }

  // Convert to Realtime Database
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'title': title,
      'subject': subject,
      'content': content,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isPublished': isPublished,
      'tags': tags,
      'description': description,
      'fileUrl': fileUrl,
    };
  }

  // Create copy with updated fields
  Lesson copyWith({
    String? id,
    String? title,
    String? subject,
    String? content,
    String? teacherId,
    String? teacherName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
    List<String>? tags,
    String? description,
    String? fileUrl,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }
}
