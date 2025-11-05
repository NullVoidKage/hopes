import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String teacherId;
  final String teacherName;
  final String subject;
  final String section;
  final String classCode; // 6-character unique code
  final String schoolYear;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isModerated; // If true, students cannot take assessments
  final List<String> enrolledStudentIds;
  final int maxStudents;
  final String? description;

  ClassModel({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.subject,
    required this.section,
    required this.classCode,
    required this.schoolYear,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isModerated = false,
    this.enrolledStudentIds = const [],
    this.maxStudents = 50,
    this.description,
  });

  // Create from Firestore
  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      id: doc.id,
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      subject: data['subject'] ?? '',
      section: data['section'] ?? '',
      classCode: data['classCode'] ?? '',
      schoolYear: data['schoolYear'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      isModerated: data['isModerated'] ?? false,
      enrolledStudentIds: data['enrolledStudentIds'] != null
          ? List<String>.from(data['enrolledStudentIds'])
          : [],
      maxStudents: data['maxStudents'] ?? 50,
      description: data['description'],
    );
  }

  // Create from Realtime Database
  factory ClassModel.fromRealtimeDatabase(String id, Map<dynamic, dynamic> data) {
    return ClassModel(
      id: id,
      teacherId: data['teacherId']?.toString() ?? '',
      teacherName: data['teacherName']?.toString() ?? '',
      subject: data['subject']?.toString() ?? '',
      section: data['section']?.toString() ?? '',
      classCode: data['classCode']?.toString() ?? '',
      schoolYear: data['schoolYear']?.toString() ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int)
          : DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      isModerated: data['isModerated'] as bool? ?? false,
      enrolledStudentIds: data['enrolledStudentIds'] != null
          ? List<String>.from((data['enrolledStudentIds'] as List).map((e) => e.toString()))
          : [],
      maxStudents: data['maxStudents'] ?? 50,
      description: data['description']?.toString(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subject': subject,
      'section': section,
      'classCode': classCode,
      'schoolYear': schoolYear,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'isModerated': isModerated,
      'enrolledStudentIds': enrolledStudentIds,
      'maxStudents': maxStudents,
      'description': description,
    };
  }

  // Convert to Realtime Database
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subject': subject,
      'section': section,
      'classCode': classCode,
      'schoolYear': schoolYear,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'isModerated': isModerated,
      'enrolledStudentIds': enrolledStudentIds,
      'maxStudents': maxStudents,
      'description': description,
    };
  }

  // Copy with updated fields
  ClassModel copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    String? subject,
    String? section,
    String? classCode,
    String? schoolYear,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isModerated,
    List<String>? enrolledStudentIds,
    int? maxStudents,
    String? description,
  }) {
    return ClassModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      subject: subject ?? this.subject,
      section: section ?? this.section,
      classCode: classCode ?? this.classCode,
      schoolYear: schoolYear ?? this.schoolYear,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isModerated: isModerated ?? this.isModerated,
      enrolledStudentIds: enrolledStudentIds ?? this.enrolledStudentIds,
      maxStudents: maxStudents ?? this.maxStudents,
      description: description ?? this.description,
    );
  }

  // Generate unique class code (6 characters)
  static String generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();
    for (int i = 0; i < 6; i++) {
      code.write(chars[(random + i) % chars.length]);
    }
    return code.toString();
  }
}

