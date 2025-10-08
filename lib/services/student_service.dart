import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';

class StudentService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get all students for a teacher (now shows all students regardless of teacher ID)
  Future<List<Student>> getStudents(String teacherId) async {
    try {
      
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedStudents(teacherId);
      }

      // If online, fetch from Firebase and cache
      final DatabaseReference ref = _database.ref('students');
      
      // Don't filter by teacherId - show all students to all teachers
      final DatabaseEvent event = await ref.once();
      final DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value == null) {
        return [];
      }
      
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return [];
      }
      
      
      final studentsList = data.entries.map((entry) {
        final entryData = entry.value as Map<dynamic, dynamic>?;
        if (entryData == null) {
          return null;
        }
        
        
        try {
          final student = Student.fromRealtimeDatabase(
            entryData,
            entry.key.toString(),
          );
          return student;
        } catch (e) {
          return null;
        }
      }).whereType<Student>().toList();

      
      // Cache the data for offline use
      await _cacheStudentsLocally(studentsList);
      
      return studentsList;
    } catch (e) {
      // If Firebase fails, try to return cached data
      return await _getCachedStudents(teacherId);
    }
  }

  // Get ALL students in the system (for teachers to manage)
  Future<List<Student>> getAllStudents() async {
    try {
      
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedAllStudents();
      }

      // If online, fetch from Firestore
      final studentsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      
      final studentsList = studentsQuery.docs.map((doc) {
        final data = doc.data();
        
        try {
          // Convert Firestore data to Student model
          final subjects = (data['subjects'] as List<dynamic>?)?.cast<String>() ?? [];
          
          final student = Student(
            id: doc.id,
            name: data['displayName'] ?? 'Unknown',
            email: data['email'] ?? '',
            grade: data['grade'] ?? 'Grade 7',
            section: 'A', // Default section
            subjects: subjects,
            teacherId: data['teacherId'] ?? 'default_teacher',
            teacherName: data['teacherName'] ?? 'Default Teacher',
            joinedAt: data['createdAt'] != null 
                ? (data['createdAt'] as Timestamp).toDate() 
                : DateTime.now(),
            isActive: true,
            metadata: {
              'source': 'firestore',
              'firestoreId': doc.id,
            },
          );
          
          return student;
        } catch (e) {
          return null;
        }
      }).whereType<Student>().toList();

      
      // Cache the data for offline use
      await _cacheAllStudentsLocally(studentsList);
      
      return studentsList;
    } catch (e) {
      // If Firestore fails, try to return cached data
      return await _getCachedAllStudents();
    }
  }

  // Get cached students by teacher
  Future<List<Student>> _getCachedStudents(String teacherId) async {
    try {
      final cachedStudents = await OfflineService.getCachedStudents();
      
      // Filter by teacher ID
      final teacherStudents = cachedStudents.where((data) => 
        data['teacherId'] == teacherId
      ).toList();
      
      return teacherStudents.map((data) => 
        Student.fromRealtimeDatabase(data, data['id'] ?? '')
      ).toList();
    } catch (e) {
      return [];
    }
  }

  // Cache students locally
  Future<void> _cacheStudentsLocally(List<Student> students) async {
    try {
      final studentData = students.map((student) => {
        'id': student.id,
        ...student.toRealtimeDatabase(),
      }).toList();
      await OfflineService.cacheStudents(studentData);
    } catch (e) {
    }
  }

  // Get cached all students
  Future<List<Student>> _getCachedAllStudents() async {
    try {
      final cachedStudents = await OfflineService.getCachedStudents();
      return cachedStudents.map((data) => 
        Student.fromRealtimeDatabase(data, data['id'] ?? '')
      ).toList();
    } catch (e) {
      return [];
    }
  }

  // Cache all students locally
  Future<void> _cacheAllStudentsLocally(List<Student> students) async {
    try {
      final studentData = students.map((student) => {
        'id': student.id,
        ...student.toRealtimeDatabase(),
      }).toList();
      await OfflineService.cacheStudents(studentData);
    } catch (e) {
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
        return null;
      }
    } catch (e) {
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
      return false;
    }
  }

  // Get students by subject
  Future<List<Student>> getStudentsBySubject(String teacherId, String subject) async {
    try {
      final List<Student> allStudents = await getStudents(teacherId);
      return allStudents.where((student) => student.subjects.contains(subject)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get students by grade
  Future<List<Student>> getStudentsByGrade(String teacherId, String grade) async {
    try {
      final List<Student> allStudents = await getStudents(teacherId);
      return allStudents.where((student) => student.grade == grade).toList();
    } catch (e) {
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
      return {};
    }
  }
}
