import 'package:cloud_firestore/cloud_firestore.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String category; // 'academic', 'participation', 'streak', 'milestone', 'special'
  final int points;
  final String iconName;
  final String colorHex;
  final Map<String, dynamic> criteria; // Achievement unlock conditions
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.points,
    required this.iconName,
    required this.colorHex,
    required this.criteria,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Create from Firestore
  factory Achievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Achievement(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      points: data['points'] ?? 0,
      iconName: data['iconName'] ?? '',
      colorHex: data['colorHex'] ?? '#007AFF',
      criteria: data['criteria'] ?? {},
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  // Create from Realtime Database
  factory Achievement.fromRealtimeDatabase(Map<String, dynamic> data, String id) {
    return Achievement(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      points: data['points'] ?? 0,
      iconName: data['iconName'] ?? '',
      colorHex: data['colorHex'] ?? '#007AFF',
      criteria: data['criteria'] ?? {},
      isActive: data['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      updatedAt: data['updatedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt']) : null,
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'points': points,
      'iconName': iconName,
      'colorHex': colorHex,
      'criteria': criteria,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Convert to Realtime Database format
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'points': points,
      'iconName': iconName,
      'colorHex': colorHex,
      'criteria': criteria,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Create copy with modifications
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? points,
    String? iconName,
    String? colorHex,
    Map<String, dynamic>? criteria,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      points: points ?? this.points,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      criteria: criteria ?? this.criteria,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class StudentAchievement {
  final String id;
  final String studentId;
  final String studentName;
  final String achievementId;
  final String achievementTitle;
  final String achievementDescription;
  final int points;
  final DateTime unlockedAt;
  final Map<String, dynamic> metadata; // Additional context about how it was earned

  StudentAchievement({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.achievementId,
    required this.achievementTitle,
    required this.achievementDescription,
    required this.points,
    required this.unlockedAt,
    this.metadata = const {},
  });

  // Create from Firestore
  factory StudentAchievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentAchievement(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      achievementId: data['achievementId'] ?? '',
      achievementTitle: data['achievementTitle'] ?? '',
      achievementDescription: data['achievementDescription'] ?? '',
      points: data['points'] ?? 0,
      unlockedAt: (data['unlockedAt'] as Timestamp).toDate(),
      metadata: data['metadata'] ?? {},
    );
  }

  // Create from Realtime Database
  factory StudentAchievement.fromRealtimeDatabase(Map<String, dynamic> data, String id) {
    return StudentAchievement(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      achievementId: data['achievementId'] ?? '',
      achievementTitle: data['achievementTitle'] ?? '',
      achievementDescription: data['achievementDescription'] ?? '',
      points: data['points'] ?? 0,
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(data['unlockedAt'] ?? 0),
      metadata: data['metadata'] ?? {},
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'achievementId': achievementId,
      'achievementTitle': achievementTitle,
      'achievementDescription': achievementDescription,
      'points': points,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
      'metadata': metadata,
    };
  }

  // Convert to Realtime Database format
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'achievementId': achievementId,
      'achievementTitle': achievementTitle,
      'achievementDescription': achievementDescription,
      'points': points,
      'unlockedAt': unlockedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  // Create copy with modifications
  StudentAchievement copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? achievementId,
    String? achievementTitle,
    String? achievementDescription,
    int? points,
    DateTime? unlockedAt,
    Map<String, dynamic>? metadata,
  }) {
    return StudentAchievement(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      achievementId: achievementId ?? this.achievementId,
      achievementTitle: achievementTitle ?? this.achievementTitle,
      achievementDescription: achievementDescription ?? this.achievementDescription,
      points: points ?? this.points,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

class LeaderboardEntry {
  final String studentId;
  final String studentName;
  final String studentEmail;
  final int totalPoints;
  final int achievementsCount;
  final int rank;
  final DateTime lastActivity;
  final Map<String, dynamic> stats; // Additional statistics

  LeaderboardEntry({
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.totalPoints,
    required this.achievementsCount,
    required this.rank,
    required this.lastActivity,
    this.stats = const {},
  });

  // Create from Firestore
  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      studentId: doc.id,
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      totalPoints: data['totalPoints'] ?? 0,
      achievementsCount: data['achievementsCount'] ?? 0,
      rank: data['rank'] ?? 0,
      lastActivity: (data['lastActivity'] as Timestamp).toDate(),
      stats: data['stats'] ?? {},
    );
  }

  // Create from Realtime Database
  factory LeaderboardEntry.fromRealtimeDatabase(Map<String, dynamic> data, String id) {
    return LeaderboardEntry(
      studentId: id,
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      totalPoints: data['totalPoints'] ?? 0,
      achievementsCount: data['achievementsCount'] ?? 0,
      rank: data['rank'] ?? 0,
      lastActivity: DateTime.fromMillisecondsSinceEpoch(data['lastActivity'] ?? 0),
      stats: data['stats'] ?? {},
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'studentName': studentName,
      'studentEmail': studentEmail,
      'totalPoints': totalPoints,
      'achievementsCount': achievementsCount,
      'rank': rank,
      'lastActivity': Timestamp.fromDate(lastActivity),
      'stats': stats,
    };
  }

  // Convert to Realtime Database format
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'studentName': studentName,
      'studentEmail': studentEmail,
      'totalPoints': totalPoints,
      'achievementsCount': achievementsCount,
      'rank': rank,
      'lastActivity': lastActivity.millisecondsSinceEpoch,
      'stats': stats,
    };
  }

  // Create copy with modifications
  LeaderboardEntry copyWith({
    String? studentId,
    String? studentName,
    String? studentEmail,
    int? totalPoints,
    int? achievementsCount,
    int? rank,
    DateTime? lastActivity,
    Map<String, dynamic>? stats,
  }) {
    return LeaderboardEntry(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      totalPoints: totalPoints ?? this.totalPoints,
      achievementsCount: achievementsCount ?? this.achievementsCount,
      rank: rank ?? this.rank,
      lastActivity: lastActivity ?? this.lastActivity,
      stats: stats ?? this.stats,
    );
  }
}
