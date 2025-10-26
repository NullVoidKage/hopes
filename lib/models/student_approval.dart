class StudentApproval {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String gradeLevel;
  final String status; // 'pending', 'approved', 'rejected'
  final String? teacherId;
  final String? teacherName;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? notes;
  final String? rejectionReason;

  StudentApproval({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.gradeLevel,
    required this.status,
    this.teacherId,
    this.teacherName,
    required this.createdAt,
    this.reviewedAt,
    this.notes,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'gradeLevel': gradeLevel,
      'status': status,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'reviewedAt': reviewedAt?.millisecondsSinceEpoch,
      'notes': notes,
      'rejectionReason': rejectionReason,
    };
  }

  factory StudentApproval.fromMap(Map<String, dynamic> map) {
    return StudentApproval(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentEmail: map['studentEmail'] ?? '',
      gradeLevel: map['gradeLevel'] ?? '',
      status: map['status'] ?? 'pending',
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      reviewedAt: map['reviewedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['reviewedAt'])
          : null,
      notes: map['notes'],
      rejectionReason: map['rejectionReason'],
    );
  }

  StudentApproval copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? gradeLevel,
    String? status,
    String? teacherId,
    String? teacherName,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? notes,
    String? rejectionReason,
  }) {
    return StudentApproval(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      status: status ?? this.status,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      notes: notes ?? this.notes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isGrade7 => gradeLevel == 'Grade 7';

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
