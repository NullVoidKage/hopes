class Student {
  final String id;
  final String name;
  final String email;
  final String grade;
  final String section;
  final List<String> subjects;
  final String teacherId;
  final String teacherName;
  final DateTime joinedAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.grade,
    required this.section,
    required this.subjects,
    required this.teacherId,
    required this.teacherName,
    required this.joinedAt,
    this.isActive = true,
    this.metadata = const {},
  });

  factory Student.fromRealtimeDatabase(Map<dynamic, dynamic> data, String id) {
    try {
      
      final name = data['name']?.toString() ?? '';
      
      final email = data['email']?.toString() ?? '';
      
      final grade = data['grade']?.toString() ?? '';
      
      final section = data['section']?.toString() ?? '';
      
      final subjects = data['subjects'] != null 
          ? List<String>.from((data['subjects'] as List).map((e) => e.toString()))
          : <String>[];
      
      final teacherId = data['teacherId']?.toString() ?? '';
      
      final teacherName = data['teacherName']?.toString() ?? '';
      
      final joinedAt = data['joinedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['joinedAt'] as int) 
          : DateTime.now();
      
      final isActive = data['isActive'] as bool? ?? true;
      
      final metadata = data['metadata'] != null 
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : <String, dynamic>{};
      
      final student = Student(
        id: id,
        name: name,
        email: email,
        grade: grade,
        section: section,
        subjects: subjects,
        teacherId: teacherId,
        teacherName: teacherName,
        joinedAt: joinedAt,
        isActive: isActive,
        metadata: metadata,
      );
      
      return student;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'name': name,
      'email': email,
      'grade': grade,
      'section': section,
      'subjects': subjects,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  Student copyWith({
    String? id,
    String? name,
    String? email,
    String? grade,
    String? section,
    List<String>? subjects,
    String? teacherId,
    String? teacherName,
    DateTime? joinedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      subjects: subjects ?? this.subjects,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}
