import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  lessonUpload,
  assessmentCreated,
  graded,
  progressReviewed,
  studentManagement,
}

class TeacherActivity {
  final String id;
  final String teacherId;
  final ActivityType type;
  final String title;
  final String description;
  final String subject;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  TeacherActivity({
    required this.id,
    required this.teacherId,
    required this.type,
    required this.title,
    required this.description,
    required this.subject,
    required this.timestamp,
    this.metadata = const {},
  });

  // Create from Firestore document
  factory TeacherActivity.fromFirestore(Map<String, dynamic> data, String id) {
    return TeacherActivity(
      id: id,
      teacherId: data['teacherId'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ActivityType.lessonUpload,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      subject: data['subject'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'] ?? {},
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'teacherId': teacherId,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'subject': subject,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }

  // Get display time (e.g., "2 hours ago")
  String get displayTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }

  // Get icon based on activity type
  String get iconName {
    switch (type) {
      case ActivityType.lessonUpload:
        return 'upload_file_rounded';
      case ActivityType.assessmentCreated:
        return 'assignment_rounded';
      case ActivityType.graded:
        return 'grade_rounded';
      case ActivityType.progressReviewed:
        return 'analytics_rounded';
      case ActivityType.studentManagement:
        return 'people_rounded';
    }
  }

  // Get color based on activity type
  int get colorValue {
    switch (type) {
      case ActivityType.lessonUpload:
        return 0xFF34C759; // Apple's green
      case ActivityType.assessmentCreated:
        return 0xFFFF9500; // Apple's orange
      case ActivityType.graded:
        return 0xFF007AFF; // Apple's blue
      case ActivityType.progressReviewed:
        return 0xFFAF52DE; // Apple's purple
      case ActivityType.studentManagement:
        return 0xFFFF3B30; // Apple's red
    }
  }
}
