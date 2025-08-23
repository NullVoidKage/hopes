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
      print('Parsing student data: $data');
      
      final name = data['name']?.toString() ?? '';
      print('Parsed name: $name');
      
      final email = data['email']?.toString() ?? '';
      print('Parsed email: $email');
      
      final grade = data['grade']?.toString() ?? '';
      print('Parsed grade: $grade');
      
      final section = data['section']?.toString() ?? '';
      print('Parsed section: $section');
      
      final subjects = data['subjects'] != null 
          ? List<String>.from((data['subjects'] as List).map((e) => e.toString()))
          : <String>[];
      print('Parsed subjects: $subjects');
      
      final teacherId = data['teacherId']?.toString() ?? '';
      print('Parsed teacherId: $teacherId');
      
      final teacherName = data['teacherName']?.toString() ?? '';
      print('Parsed teacherName: $teacherName');
      
      final joinedAt = data['joinedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['joinedAt'] as int) 
          : DateTime.now();
      print('Parsed joinedAt: $joinedAt');
      
      final isActive = data['isActive'] as bool? ?? true;
      print('Parsed isActive: $isActive');
      
      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
      print('Parsed metadata: $metadata');
      
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
      
      print('Successfully created student: ${student.name}');
      return student;
    } catch (e) {
      print('Error in Student.fromRealtimeDatabase: $e');
      print('Data: $data');
      print('ID: $id');
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
