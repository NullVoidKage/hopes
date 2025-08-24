import 'package:cloud_firestore/cloud_firestore.dart';

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert;

  String get difficultyLevelString {
    switch (this) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.advanced:
        return 'Advanced';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }
}

class AdaptiveDifficulty {
  final String id;
  final String studentId;
  final String studentName;
  final String subject;
  final DifficultyLevel currentLevel;
  final double performanceScore; // 0.0 to 1.0
  final int consecutiveCorrect;
  final int consecutiveIncorrect;
  final int totalAttempts;
  final DateTime lastUpdated;
  final Map<String, dynamic> subjectPerformance; // Performance by topic
  final Map<String, dynamic> difficultyHistory; // History of level changes
  final Map<String, dynamic> metadata;

  AdaptiveDifficulty({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subject,
    required this.currentLevel,
    required this.performanceScore,
    required this.consecutiveCorrect,
    required this.consecutiveIncorrect,
    required this.totalAttempts,
    required this.lastUpdated,
    this.subjectPerformance = const {},
    this.difficultyHistory = const {},
    this.metadata = const {},
  });

  // Create from Firestore
  factory AdaptiveDifficulty.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdaptiveDifficulty(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      subject: data['subject'] ?? '',
      currentLevel: DifficultyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == (data['currentLevel'] ?? 'beginner'),
        orElse: () => DifficultyLevel.beginner,
      ),
      performanceScore: (data['performanceScore'] ?? 0.0).toDouble(),
      consecutiveCorrect: data['consecutiveCorrect'] ?? 0,
      consecutiveIncorrect: data['consecutiveIncorrect'] ?? 0,
      totalAttempts: data['totalAttempts'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      subjectPerformance: data['subjectPerformance'] ?? {},
      difficultyHistory: data['difficultyHistory'] ?? {},
      metadata: data['metadata'] ?? {},
    );
  }

  // Create from Realtime Database
  factory AdaptiveDifficulty.fromRealtimeDatabase(Map<String, dynamic> data, String id) {
    return AdaptiveDifficulty(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      subject: data['subject'] ?? '',
      currentLevel: DifficultyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == (data['currentLevel'] ?? 'beginner'),
        orElse: () => DifficultyLevel.beginner,
      ),
      performanceScore: (data['performanceScore'] ?? 0.0).toDouble(),
      consecutiveCorrect: data['consecutiveCorrect'] ?? 0,
      consecutiveIncorrect: data['consecutiveIncorrect'] ?? 0,
      totalAttempts: data['totalAttempts'] ?? 0,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(data['lastUpdated'] ?? 0),
      subjectPerformance: data['subjectPerformance'] ?? {},
      difficultyHistory: data['difficultyHistory'] ?? {},
      metadata: data['metadata'] ?? {},
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'subject': subject,
      'currentLevel': currentLevel.toString().split('.').last,
      'performanceScore': performanceScore,
      'consecutiveCorrect': consecutiveCorrect,
      'consecutiveIncorrect': consecutiveIncorrect,
      'totalAttempts': totalAttempts,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'subjectPerformance': subjectPerformance,
      'difficultyHistory': difficultyHistory,
      'metadata': metadata,
    };
  }

  // Convert to Realtime Database format
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'subject': subject,
      'currentLevel': currentLevel.toString().split('.').last,
      'performanceScore': performanceScore,
      'consecutiveCorrect': consecutiveCorrect,
      'consecutiveIncorrect': consecutiveIncorrect,
      'totalAttempts': totalAttempts,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'subjectPerformance': subjectPerformance,
      'difficultyHistory': difficultyHistory,
      'metadata': metadata,
    };
  }

  // Create copy with modifications
  AdaptiveDifficulty copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? subject,
    DifficultyLevel? currentLevel,
    double? performanceScore,
    int? consecutiveCorrect,
    int? consecutiveIncorrect,
    int? totalAttempts,
    DateTime? lastUpdated,
    Map<String, dynamic>? subjectPerformance,
    Map<String, dynamic>? difficultyHistory,
    Map<String, dynamic>? metadata,
  }) {
    return AdaptiveDifficulty(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      subject: subject ?? this.subject,
      currentLevel: currentLevel ?? this.currentLevel,
      performanceScore: performanceScore ?? this.performanceScore,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      consecutiveIncorrect: consecutiveIncorrect ?? this.consecutiveIncorrect,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      subjectPerformance: subjectPerformance ?? this.subjectPerformance,
      difficultyHistory: difficultyHistory ?? this.difficultyHistory,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get difficulty level as string
  String get difficultyLevelString {
    switch (currentLevel) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.advanced:
        return 'Advanced';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }

  // Get difficulty color
  String get difficultyColor {
    switch (currentLevel) {
      case DifficultyLevel.beginner:
        return '#34C759'; // Green
      case DifficultyLevel.intermediate:
        return '#007AFF'; // Blue
      case DifficultyLevel.advanced:
        return '#FF9500'; // Orange
      case DifficultyLevel.expert:
        return '#FF3B30'; // Red
    }
  }
}

class DifficultyAdjustment {
  final String id;
  final String studentId;
  final String subject;
  final DifficultyLevel previousLevel;
  final DifficultyLevel newLevel;
  final String reason;
  final double performanceThreshold;
  final DateTime adjustedAt;
  final Map<String, dynamic> performanceData;

  DifficultyAdjustment({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.previousLevel,
    required this.newLevel,
    required this.reason,
    required this.performanceThreshold,
    required this.adjustedAt,
    this.performanceData = const {},
  });

  // Create from Firestore
  factory DifficultyAdjustment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DifficultyAdjustment(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      subject: data['subject'] ?? '',
      previousLevel: DifficultyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == (data['previousLevel'] ?? 'beginner'),
        orElse: () => DifficultyLevel.beginner,
      ),
      newLevel: DifficultyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == (data['newLevel'] ?? 'beginner'),
        orElse: () => DifficultyLevel.beginner,
      ),
      reason: data['reason'] ?? '',
      performanceThreshold: (data['performanceThreshold'] ?? 0.0).toDouble(),
      adjustedAt: (data['adjustedAt'] as Timestamp).toDate(),
      performanceData: data['performanceData'] ?? {},
    );
  }

  // Create from Realtime Database
  factory DifficultyAdjustment.fromRealtimeDatabase(Map<String, dynamic> data, String id) {
    return DifficultyAdjustment(
      id: id,
      studentId: data['studentId'] ?? '',
      subject: data['subject'] ?? '',
      previousLevel: DifficultyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == (data['previousLevel'] ?? 'beginner'),
        orElse: () => DifficultyLevel.beginner,
      ),
      newLevel: DifficultyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == (data['newLevel'] ?? 'beginner'),
        orElse: () => DifficultyLevel.beginner,
      ),
      reason: data['reason'] ?? '',
      performanceThreshold: (data['performanceThreshold'] ?? 0.0).toDouble(),
      adjustedAt: DateTime.fromMillisecondsSinceEpoch(data['adjustedAt'] ?? 0),
      performanceData: data['performanceData'] ?? {},
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'subject': subject,
      'previousLevel': previousLevel.toString().split('.').last,
      'newLevel': newLevel.toString().split('.').last,
      'reason': reason,
      'performanceThreshold': performanceThreshold,
      'adjustedAt': Timestamp.fromDate(adjustedAt),
      'performanceData': performanceData,
    };
  }

  // Convert to Realtime Database format
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'studentId': studentId,
      'subject': subject,
      'previousLevel': previousLevel.toString().split('.').last,
      'newLevel': newLevel.toString().split('.').last,
      'reason': reason,
      'performanceThreshold': performanceThreshold,
      'adjustedAt': adjustedAt.millisecondsSinceEpoch,
      'performanceData': performanceData,
    };
  }
}
