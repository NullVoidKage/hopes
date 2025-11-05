import 'package:cloud_firestore/cloud_firestore.dart';

class StudentRating {
  final String id;
  final String studentId;
  final String studentName;
  final String sectionId;
  final String sectionName;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final double rating; // Overall rating (0.0 to 100.0)
  final Map<String, double> categoryRatings; // Ratings per category (e.g., {'assessments': 85.0, 'lessons': 90.0})
  final int totalAssessments;
  final int completedAssessments;
  final double averageAssessmentScore;
  final int totalLessons;
  final int completedLessons;
  final double averageLessonProgress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String schoolYear;
  final Map<String, dynamic>? metadata;

  StudentRating({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.sectionId,
    required this.sectionName,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.rating,
    this.categoryRatings = const {},
    this.totalAssessments = 0,
    this.completedAssessments = 0,
    this.averageAssessmentScore = 0.0,
    this.totalLessons = 0,
    this.completedLessons = 0,
    this.averageLessonProgress = 0.0,
    required this.createdAt,
    required this.updatedAt,
    required this.schoolYear,
    this.metadata,
  });

  // Create from Firestore
  factory StudentRating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    Map<String, double> parsedCategoryRatings = {};
    if (data['categoryRatings'] != null && data['categoryRatings'] is Map) {
      (data['categoryRatings'] as Map).forEach((key, value) {
        parsedCategoryRatings[key.toString()] = (value ?? 0.0).toDouble();
      });
    }
    
    return StudentRating(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      sectionId: data['sectionId'] ?? '',
      sectionName: data['sectionName'] ?? '',
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      categoryRatings: parsedCategoryRatings,
      totalAssessments: data['totalAssessments'] ?? 0,
      completedAssessments: data['completedAssessments'] ?? 0,
      averageAssessmentScore: (data['averageAssessmentScore'] ?? 0.0).toDouble(),
      totalLessons: data['totalLessons'] ?? 0,
      completedLessons: data['completedLessons'] ?? 0,
      averageLessonProgress: (data['averageLessonProgress'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      schoolYear: data['schoolYear'] ?? '',
      metadata: data['metadata'],
    );
  }

  // Create from Realtime Database
  factory StudentRating.fromRealtimeDatabase(String id, Map<dynamic, dynamic> data) {
    Map<String, double> parsedCategoryRatings = {};
    if (data['categoryRatings'] != null && data['categoryRatings'] is Map) {
      (data['categoryRatings'] as Map).forEach((key, value) {
        parsedCategoryRatings[key.toString()] = (value ?? 0.0).toDouble();
      });
    }
    
    return StudentRating(
      id: id,
      studentId: data['studentId']?.toString() ?? '',
      studentName: data['studentName']?.toString() ?? '',
      sectionId: data['sectionId']?.toString() ?? '',
      sectionName: data['sectionName']?.toString() ?? '',
      subjectId: data['subjectId']?.toString() ?? '',
      subjectName: data['subjectName']?.toString() ?? '',
      teacherId: data['teacherId']?.toString() ?? '',
      teacherName: data['teacherName']?.toString() ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      categoryRatings: parsedCategoryRatings,
      totalAssessments: data['totalAssessments'] ?? 0,
      completedAssessments: data['completedAssessments'] ?? 0,
      averageAssessmentScore: (data['averageAssessmentScore'] ?? 0.0).toDouble(),
      totalLessons: data['totalLessons'] ?? 0,
      completedLessons: data['completedLessons'] ?? 0,
      averageLessonProgress: (data['averageLessonProgress'] ?? 0.0).toDouble(),
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int)
          : DateTime.now(),
      schoolYear: data['schoolYear']?.toString() ?? '',
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata'] as Map) : null,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'rating': rating,
      'categoryRatings': categoryRatings,
      'totalAssessments': totalAssessments,
      'completedAssessments': completedAssessments,
      'averageAssessmentScore': averageAssessmentScore,
      'totalLessons': totalLessons,
      'completedLessons': completedLessons,
      'averageLessonProgress': averageLessonProgress,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'schoolYear': schoolYear,
      'metadata': metadata,
    };
  }

  // Convert to Realtime Database
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'rating': rating,
      'categoryRatings': categoryRatings,
      'totalAssessments': totalAssessments,
      'completedAssessments': completedAssessments,
      'averageAssessmentScore': averageAssessmentScore,
      'totalLessons': totalLessons,
      'completedLessons': completedLessons,
      'averageLessonProgress': averageLessonProgress,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'schoolYear': schoolYear,
      'metadata': metadata,
    };
  }

  // Copy with updated fields
  StudentRating copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? sectionId,
    String? sectionName,
    String? subjectId,
    String? subjectName,
    String? teacherId,
    String? teacherName,
    double? rating,
    Map<String, double>? categoryRatings,
    int? totalAssessments,
    int? completedAssessments,
    double? averageAssessmentScore,
    int? totalLessons,
    int? completedLessons,
    double? averageLessonProgress,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? schoolYear,
    Map<String, dynamic>? metadata,
  }) {
    return StudentRating(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      rating: rating ?? this.rating,
      categoryRatings: categoryRatings ?? this.categoryRatings,
      totalAssessments: totalAssessments ?? this.totalAssessments,
      completedAssessments: completedAssessments ?? this.completedAssessments,
      averageAssessmentScore: averageAssessmentScore ?? this.averageAssessmentScore,
      totalLessons: totalLessons ?? this.totalLessons,
      completedLessons: completedLessons ?? this.completedLessons,
      averageLessonProgress: averageLessonProgress ?? this.averageLessonProgress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schoolYear: schoolYear ?? this.schoolYear,
      metadata: metadata ?? this.metadata,
    );
  }
}

