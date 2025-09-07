import 'package:cloud_firestore/cloud_firestore.dart';

class FlashCard {
  final String id;
  final String lessonId;
  final String lessonTitle;
  final String subject;
  final String question;
  final String answer;
  final String studentId;
  final String studentName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final bool isPublic; // Allow students to share their flash cards

  FlashCard({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.subject,
    required this.question,
    required this.answer,
    required this.studentId,
    required this.studentName,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.isPublic = false,
  });

  // Create from Firestore document
  factory FlashCard.fromFirestore(Map<String, dynamic> data, String id) {
    return FlashCard(
      id: id,
      lessonId: data['lessonId'] ?? '',
      lessonTitle: data['lessonTitle'] ?? '',
      subject: data['subject'] ?? '',
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      isPublic: data['isPublic'] ?? false,
    );
  }

  // Create from Realtime Database
  factory FlashCard.fromRealtimeDatabase(String id, Map<dynamic, dynamic> data) {
    return FlashCard(
      id: id,
      lessonId: data['lessonId']?.toString() ?? '',
      lessonTitle: data['lessonTitle']?.toString() ?? '',
      subject: data['subject']?.toString() ?? '',
      question: data['question']?.toString() ?? '',
      answer: data['answer']?.toString() ?? '',
      studentId: data['studentId']?.toString() ?? '',
      studentName: data['studentName']?.toString() ?? '',
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int)
          : DateTime.now(),
      tags: data['tags'] != null 
          ? List<String>.from((data['tags'] as List).map((e) => e.toString()))
          : [],
      isPublic: data['isPublic'] as bool? ?? false,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'subject': subject,
      'question': question,
      'answer': answer,
      'studentId': studentId,
      'studentName': studentName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'tags': tags,
      'isPublic': isPublic,
    };
  }

  // Convert to Realtime Database
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'subject': subject,
      'question': question,
      'answer': answer,
      'studentId': studentId,
      'studentName': studentName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'tags': tags,
      'isPublic': isPublic,
    };
  }

  // Create copy with updated fields
  FlashCard copyWith({
    String? id,
    String? lessonId,
    String? lessonTitle,
    String? subject,
    String? question,
    String? answer,
    String? studentId,
    String? studentName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? isPublic,
  }) {
    return FlashCard(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      subject: subject ?? this.subject,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
