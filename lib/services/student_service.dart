import 'package:firebase_database/firebase_database.dart';
import '../models/student.dart';

class StudentService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Get all students for a teacher
  Future<List<Student>> getStudents(String teacherId) async {
    try {
      print('Getting students for teacher: $teacherId');
      final DatabaseReference ref = _database.ref('students');
      final Query query = ref.orderByChild('teacherId').equalTo(teacherId);
      
      final DatabaseEvent event = await query.once();
      final DataSnapshot snapshot = event.snapshot;
      
      print('Snapshot exists: ${snapshot.exists}');
      if (snapshot.value == null) {
        print('Snapshot value is null');
        return [];
      }
      
      print('Snapshot value type: ${snapshot.value.runtimeType}');
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        print('Data is null after casting');
        return [];
      }
      
      print('Data entries count: ${data.entries.length}');
      return data.entries.map((entry) {
        print('Processing entry: ${entry.key}');
        final entryData = entry.value as Map<dynamic, dynamic>?;
        if (entryData == null) {
          print('Entry data is null for key: ${entry.key}');
          return null;
        }
        
        try {
          final student = Student.fromRealtimeDatabase(
            entryData,
            entry.key.toString(),
          );
          print('Successfully parsed student: ${student.name}');
          return student;
        } catch (e) {
          print('Error parsing student data for key ${entry.key}: $e');
          return null;
        }
      }).whereType<Student>().toList();
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }

  // Get student by ID
  Future<Student?> getStudentById(String studentId) async {
    try {
      final DatabaseReference ref = _database.ref('students/$studentId');
      final DatabaseEvent event = await ref.once();
      final DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value == null) return null;
      
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      
      try {
        return Student.fromRealtimeDatabase(
          Map<String, dynamic>.from(data),
          studentId,
        );
      } catch (e) {
        print('Error parsing student data: $e');
        return null;
      }
    } catch (e) {
      print('Error getting student by ID: $e');
      return null;
    }
  }

  // Add new student
  Future<bool> addStudent(Student student) async {
    try {
      final DatabaseReference ref = _database.ref('students');
      final DatabaseReference newStudentRef = ref.push();
      
      await newStudentRef.set(student.toRealtimeDatabase());
      return true;
    } catch (e) {
      print('Error adding student: $e');
      return false;
    }
  }

  // Update existing student
  Future<bool> updateStudent(Student student) async {
    try {
      final DatabaseReference ref = _database.ref('students/${student.id}');
      await ref.update(student.toRealtimeDatabase());
      return true;
    } catch (e) {
      print('Error updating student: $e');
      return false;
    }
  }

  // Delete student
  Future<bool> deleteStudent(String studentId) async {
    try {
      final DatabaseReference ref = _database.ref('students/$studentId');
      await ref.remove();
      return true;
    } catch (e) {
      print('Error deleting student: $e');
      return false;
    }
  }

  // Get students by subject
  Future<List<Student>> getStudentsBySubject(String teacherId, String subject) async {
    try {
      final List<Student> allStudents = await getStudents(teacherId);
      return allStudents.where((student) => student.subjects.contains(subject)).toList();
    } catch (e) {
      print('Error getting students by subject: $e');
      return [];
    }
  }

  // Get students by grade
  Future<List<Student>> getStudentsByGrade(String teacherId, String grade) async {
    try {
      final List<Student> allStudents = await getStudents(teacherId);
      return allStudents.where((student) => student.grade == grade).toList();
    } catch (e) {
      print('Error getting students by grade: $e');
      return [];
    }
  }

  // Search students
  Future<List<Student>> searchStudents(String teacherId, String query) async {
    try {
      final List<Student> allStudents = await getStudents(teacherId);
      final String lowercaseQuery = query.toLowerCase();
      
      return allStudents.where((student) {
        return student.name.toLowerCase().contains(lowercaseQuery) ||
               student.email.toLowerCase().contains(lowercaseQuery) ||
               student.grade.toLowerCase().contains(lowercaseQuery) ||
               student.section.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('Error searching students: $e');
      return [];
    }
  }

  // Toggle student active status
  Future<bool> toggleStudentStatus(String studentId, bool isActive) async {
    try {
      final DatabaseReference ref = _database.ref('students/$studentId/isActive');
      await ref.set(isActive);
      return true;
    } catch (e) {
      print('Error toggling student status: $e');
      return false;
    }
  }

  // Get student statistics
  Future<Map<String, dynamic>> getStudentStatistics(String teacherId) async {
    try {
      final List<Student> students = await getStudents(teacherId);
      
      if (students.isEmpty) {
        return {
          'totalStudents': 0,
          'activeStudents': 0,
          'gradeDistribution': {},
          'subjectDistribution': {},
        };
      }

      final int totalStudents = students.length;
      final int activeStudents = students.where((s) => s.isActive).length;
      
      // Grade distribution
      final Map<String, int> gradeDistribution = <String, int>{};
      for (final student in students) {
        gradeDistribution[student.grade] = (gradeDistribution[student.grade] ?? 0) + 1;
      }
      
      // Subject distribution
      final Map<String, int> subjectDistribution = <String, int>{};
      for (final student in students) {
        for (final studentSubject in student.subjects) {
          subjectDistribution[studentSubject] = (subjectDistribution[studentSubject] ?? 0) + 1;
        }
      }

      return {
        'totalStudents': totalStudents,
        'activeStudents': activeStudents,
        'gradeDistribution': gradeDistribution,
        'subjectDistribution': subjectDistribution,
      };
    } catch (e) {
      print('Error getting student statistics: $e');
      return {};
    }
  }
}
