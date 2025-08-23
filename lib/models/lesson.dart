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
