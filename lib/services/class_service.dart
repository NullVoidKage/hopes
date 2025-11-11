import 'package:firebase_database/firebase_database.dart';
import '../models/class_model.dart';
import 'connectivity_service.dart';

class ClassService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Create a new class
  Future<String> createClass(ClassModel classModel) async {
    try {
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot create class while offline. Please connect to the internet.');
      }

      final classRef = _database.ref('classes').push();
      final classId = classRef.key!;
      
      final classData = classModel.copyWith(id: classId).toRealtimeDatabase();
      await classRef.set(classData);
      
      return classId;
    } catch (e) {
      throw Exception('Failed to create class: ${e.toString()}');
    }
  }

  // Get all classes for a teacher
  Future<List<ClassModel>> getClassesByTeacher(String teacherId) async {
    try {
      final query = _database
          .ref('classes')
          .orderByChild('teacherId')
          .equalTo(teacherId);

      final snapshot = await query.get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      final classes = <ClassModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            try {
              final classModel = ClassModel.fromRealtimeDatabase(key.toString(), value);
              classes.add(classModel);
            } catch (e) {
              // Skip invalid classes
            }
          }
        });
      }
      
      // Sort by creation date (newest first)
      classes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return classes;
    } catch (e) {
      return [];
    }
  }

  // Get class by ID
  Future<ClassModel?> getClassById(String classId) async {
    try {
      final snapshot = await _database.ref('classes').child(classId).get();
      
      if (!snapshot.exists) {
        return null;
      }
      
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        return ClassModel.fromRealtimeDatabase(classId, data);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get class by class code
  Future<ClassModel?> getClassByCode(String classCode) async {
    try {
      final query = _database
          .ref('classes')
          .orderByChild('classCode')
          .equalTo(classCode);

      final snapshot = await query.get();
      
      if (!snapshot.exists) {
        return null;
      }
      
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && data.isNotEmpty) {
        final entry = data.entries.first;
        return ClassModel.fromRealtimeDatabase(entry.key.toString(), entry.value);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update class
  Future<void> updateClass(String classId, ClassModel classModel) async {
    try {
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot update class while offline.');
      }

      await _database.ref('classes').child(classId).update(
        classModel.copyWith(id: classId).toRealtimeDatabase()
      );
    } catch (e) {
      throw Exception('Failed to update class: ${e.toString()}');
    }
  }

  // Delete class
  Future<void> deleteClass(String classId) async {
    try {
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot delete class while offline.');
      }

      await _database.ref('classes').child(classId).remove();
    } catch (e) {
      throw Exception('Failed to delete class: ${e.toString()}');
    }
  }

  // Enroll student in class
  Future<void> enrollStudent(String classId, String studentId) async {
    try {
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot enroll student while offline.');
      }

      final classRef = _database.ref('classes').child(classId);
      final snapshot = await classRef.get();
      
      if (!snapshot.exists) {
        throw Exception('Class not found');
      }
      
      final classData = snapshot.value as Map<dynamic, dynamic>;
      final enrolledStudents = List<String>.from(
        (classData['enrolledStudentIds'] as List? ?? []).map((e) => e.toString())
      );
      
      if (enrolledStudents.contains(studentId)) {
        throw Exception('Student is already enrolled in this class');
      }
      
      enrolledStudents.add(studentId);
      
      await classRef.update({
        'enrolledStudentIds': enrolledStudents,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to enroll student: ${e.toString()}');
    }
  }

  // Remove student from class
  Future<void> removeStudent(String classId, String studentId) async {
    try {
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot remove student while offline.');
      }

      final classRef = _database.ref('classes').child(classId);
      final snapshot = await classRef.get();
      
      if (!snapshot.exists) {
        throw Exception('Class not found');
      }
      
      final classData = snapshot.value as Map<dynamic, dynamic>;
      final enrolledStudents = List<String>.from(
        (classData['enrolledStudentIds'] as List? ?? []).map((e) => e.toString())
      );
      
      enrolledStudents.remove(studentId);
      
      await classRef.update({
        'enrolledStudentIds': enrolledStudents,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to remove student: ${e.toString()}');
    }
  }

  // Get classes for a student (by enrollment)
  Future<List<ClassModel>> getClassesByStudent(String studentId) async {
    try {
      final query = _database.ref('classes');
      final snapshot = await query.get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      final classes = <ClassModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            final enrolledStudents = List<String>.from(
              (value['enrolledStudentIds'] as List? ?? []).map((e) => e.toString())
            );
            
            if (enrolledStudents.contains(studentId)) {
              try {
                final classModel = ClassModel.fromRealtimeDatabase(key.toString(), value);
                classes.add(classModel);
              } catch (e) {
                // Skip invalid classes
              }
            }
          }
        });
      }
      
      return classes;
    } catch (e) {
      return [];
    }
  }

  // Get classes by section and subject
  Future<List<ClassModel>> getClassesBySectionAndSubject(String section, String subject) async {
    try {
      final query = _database
          .ref('classes')
          .orderByChild('section')
          .equalTo(section);

      final snapshot = await query.get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      final classes = <ClassModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null) {
        data.forEach((key, value) {
          if (value is Map && value['subject']?.toString() == subject) {
            try {
              final classModel = ClassModel.fromRealtimeDatabase(key.toString(), value);
              classes.add(classModel);
            } catch (e) {
              // Skip invalid classes
            }
          }
        });
      }
      
      return classes;
    } catch (e) {
      return [];
    }
  }
}

