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
      print('🔍 StudentService: Getting students for teacher: $teacherId');
      print('🔍 StudentService: shouldUseCachedData: ${_connectivityService.shouldUseCachedData}');
      print('🔍 StudentService: isConnected: ${_connectivityService.isConnected}');
      
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        print('🔍 StudentService: Using cached data');
        return await _getCachedStudents(teacherId);
      }

      // If online, fetch from Firebase and cache
      print('🔍 StudentService: Fetching from Firebase');
      final DatabaseReference ref = _database.ref('students');
      
      // Don't filter by teacherId - show all students to all teachers
      final DatabaseEvent event = await ref.once();
      final DataSnapshot snapshot = event.snapshot;
      
      print('🔍 StudentService: Snapshot exists: ${snapshot.exists}');
      if (snapshot.value == null) {
        print('🔍 StudentService: Snapshot value is null');
        return [];
      }
      
      print('🔍 StudentService: Snapshot value type: ${snapshot.value.runtimeType}');
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        print('🔍 StudentService: Snapshot value is null after casting');
        return [];
      }
      
      print('🔍 StudentService: Data entries count: ${data.entries.length}');
      print('🔍 StudentService: Data keys: ${data.keys.toList()}');
      
      final studentsList = data.entries.map((entry) {
        print('🔍 StudentService: Processing entry: ${entry.key}');
        final entryData = entry.value as Map<dynamic, dynamic>?;
        if (entryData == null) {
          print('🔍 StudentService: Entry data is null for key: ${entry.key}');
          return null;
        }
        
        print('🔍 StudentService: Entry data: $entryData');
        print('🔍 StudentService: Entry teacherId: ${entryData['teacherId']}');
        
        try {
          final student = Student.fromRealtimeDatabase(
            entryData,
            entry.key.toString(),
          );
          print('🔍 StudentService: Successfully parsed student: ${student.name}');
          return student;
        } catch (e) {
          print('🔍 StudentService: Error parsing student data for key ${entry.key}: $e');
          return null;
        }
      }).whereType<Student>().toList();

      print('🔍 StudentService: Final students list length: ${studentsList.length}');
      
      // Cache the data for offline use
      await _cacheStudentsLocally(studentsList);
      
      return studentsList;
    } catch (e) {
      print('🔍 StudentService: Error getting students: $e');
      // If Firebase fails, try to return cached data
      return await _getCachedStudents(teacherId);
    }
  }

  // Get ALL students in the system (for teachers to manage)
  Future<List<Student>> getAllStudents() async {
    try {
      print('🔍 StudentService: Getting ALL students from Firestore');
      print('🔍 StudentService: shouldUseCachedData: ${_connectivityService.shouldUseCachedData}');
      print('🔍 StudentService: isConnected: ${_connectivityService.isConnected}');
      
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        print('🔍 StudentService: Using cached data for all students');
        return await _getCachedAllStudents();
      }

      // If online, fetch from Firestore
      print('🔍 StudentService: Fetching all students from Firestore');
      final studentsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      print('🔍 StudentService: Found ${studentsQuery.docs.length} students in Firestore');
      
      final studentsList = studentsQuery.docs.map((doc) {
        final data = doc.data();
        print('🔍 StudentService: Processing student: ${data['displayName']}');
        print('🔍 StudentService: Student subjects: ${data['subjects']}');
        print('🔍 StudentService: Student email: ${data['email']}');
        print('🔍 StudentService: Student grade: ${data['grade']}');
        
        try {
          // Convert Firestore data to Student model
          final subjects = (data['subjects'] as List<dynamic>?)?.cast<String>() ?? [];
          print('🔍 StudentService: Converted subjects: $subjects (length: ${subjects.length})');
          
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
          
          print('🔍 StudentService: Successfully created student: ${student.name} with ${student.subjects.length} subjects');
          return student;
        } catch (e) {
          print('🔍 StudentService: Error creating student from Firestore data: $e');
          return null;
        }
      }).whereType<Student>().toList();

      print('🔍 StudentService: Final students list length: ${studentsList.length}');
      
      // Cache the data for offline use
      await _cacheAllStudentsLocally(studentsList);
      
      return studentsList;
    } catch (e) {
      print('🔍 StudentService: Error getting all students from Firestore: $e');
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
      print('Error getting cached students: $e');
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
      print('Error caching students: $e');
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
      print('Error getting cached all students: $e');
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
      print('Error caching all students: $e');
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
