import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/user_model.dart';
import '../models/assessment.dart';
import '../models/lesson.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';

class AdminService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get all users with filtering
  Future<List<UserModel>> getAllUsers({
    String? role,
    String? schoolYear,
  }) async {
    try {
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedUsers(role: role);
      }

      firestore.Query query = _firestore.collection('users');

      if (role != null) {
        query = query.where('role', isEqualTo: role);
      }

      final snapshot = await query.get();

      final users = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return UserModel.fromFirestore(data, doc.id);
          })
          .toList();

      if (schoolYear != null) {
        return users.where((user) => user.schoolYear == schoolYear).toList();
      }

      // Cache for offline use
      await _cacheUsersLocally(users);

      return users;
    } catch (e) {
      return await _getCachedUsers(role: role);
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      if (_connectivityService.shouldUseCachedData) {
        final cachedUsers = await _getCachedUsers();
        return cachedUsers.firstWhere(
          (user) => user.uid == uid,
          orElse: () => throw Exception('User not found'),
        );
      }

      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!, doc.id);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user role
  Future<void> updateUserRole(String uid, UserRole newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole.toString().split('.').last,
      });

      // Invalidate cache
      await _invalidateUserCache();
    } catch (e) {
      throw Exception('Failed to update user role: ${e.toString()}');
    }
  }

  // Update user information
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(uid).update(updates);

      // Invalidate cache
      await _invalidateUserCache();
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();

      // Invalidate cache
      await _invalidateUserCache();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  // Get system statistics
  Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedStatistics();
      }

      // Get counts
      final usersSnapshot = await _firestore.collection('users').get();
      final assessmentsSnapshot = await _firestore.collection('assessments').get();
      final lessonsSnapshot = await _firestore.collection('lessons').get();

      final totalUsers = usersSnapshot.docs.length;
      final students = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'student')
          .length;
      final teachers = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'teacher')
          .length;
      final administrators = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'administrator')
          .length;

      final statistics = {
        'totalUsers': totalUsers,
        'totalStudents': students,
        'totalTeachers': teachers,
        'totalAdministrators': administrators,
        'totalAssessments': assessmentsSnapshot.docs.length,
        'totalLessons': lessonsSnapshot.docs.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Cache statistics
      await _cacheStatisticsLocally(statistics);

      return statistics;
    } catch (e) {
      return await _getCachedStatistics();
    }
  }

  // Get content statistics (assessments and lessons by subject)
  Future<Map<String, dynamic>> getContentStatistics() async {
    try {
      final assessmentsSnapshot = await _firestore.collection('assessments').get();
      final lessonsSnapshot = await _firestore.collection('lessons').get();

      final assessmentBySubject = <String, int>{};
      final lessonBySubject = <String, int>{};

      for (final doc in assessmentsSnapshot.docs) {
        final data = doc.data();
        final subject = data['subject'] as String? ?? 'Unknown';
        assessmentBySubject[subject] = (assessmentBySubject[subject] ?? 0) + 1;
      }

      for (final doc in lessonsSnapshot.docs) {
        final data = doc.data();
        final subject = data['subject'] as String? ?? 'Unknown';
        lessonBySubject[subject] = (lessonBySubject[subject] ?? 0) + 1;
      }

      return {
        'assessmentsBySubject': assessmentBySubject,
        'lessonsBySubject': lessonBySubject,
      };
    } catch (e) {
      return {
        'assessmentsBySubject': <String, int>{},
        'lessonsBySubject': <String, int>{},
      };
    }
  }

  // Get school years
  Future<List<String>> getSchoolYears() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      final schoolYears = <String>{};
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final schoolYear = data['schoolYear'] as String?;
        if (schoolYear != null && schoolYear.isNotEmpty) {
          schoolYears.add(schoolYear);
        }
      }

      return schoolYears.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  // Get all assessments
  Future<List<Assessment>> getAllAssessments() async {
    try {
      final snapshot = await _firestore.collection('assessments').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore data to Realtime Database format
        final rtData = <String, dynamic>{
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'subject': data['subject'] ?? '',
          'teacherId': data['teacherId'] ?? '',
          'teacherName': data['teacherName'] ?? '',
          'createdAt': data['createdAt'] is firestore.Timestamp
              ? (data['createdAt'] as firestore.Timestamp).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch,
          'updatedAt': data['updatedAt'] is firestore.Timestamp
              ? (data['updatedAt'] as firestore.Timestamp).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch,
          'isPublished': data['isPublished'] ?? false,
          'tags': data['tags'] ?? [],
          'timeLimit': data['timeLimit'] ?? 0,
          'totalPoints': data['totalPoints'] ?? 100,
          'questions': data['questions'] ?? [],
          'dueDate': data['dueDate'] is firestore.Timestamp
              ? (data['dueDate'] as firestore.Timestamp).millisecondsSinceEpoch
              : null,
          'instructions': data['instructions'],
          'assessmentType': data['assessmentType'] ?? 'Quiz',
          'schoolYear': data['schoolYear'],
        };
        return Assessment.fromRealtimeDatabase(doc.id, rtData);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get all lessons
  Future<List<Lesson>> getAllLessons() async {
    try {
      final snapshot = await _firestore.collection('lessons').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Handle Timestamp conversion
        final lessonData = Map<String, dynamic>.from(data);
        if (data['createdAt'] is firestore.Timestamp) {
          lessonData['createdAt'] = data['createdAt'] as firestore.Timestamp;
        }
        if (data['updatedAt'] is firestore.Timestamp) {
          lessonData['updatedAt'] = data['updatedAt'] as firestore.Timestamp;
        }
        return Lesson.fromFirestore(lessonData, doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Delete assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _firestore.collection('assessments').doc(assessmentId).delete();
    } catch (e) {
      throw Exception('Failed to delete assessment: ${e.toString()}');
    }
  }

  // Delete lesson
  Future<void> deleteLesson(String lessonId) async {
    try {
      await _firestore.collection('lessons').doc(lessonId).delete();
    } catch (e) {
      throw Exception('Failed to delete lesson: ${e.toString()}');
    }
  }

  // Cache methods
  Future<void> _cacheUsersLocally(List<UserModel> users) async {
    try {
      for (final user in users) {
        await OfflineService.cacheUserProfile(user.toFirestore()..['uid'] = user.uid);
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<List<UserModel>> _getCachedUsers({String? role}) async {
    try {
      // This would use offline service to get cached users
      // For now, return empty list
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _invalidateUserCache() async {
    // Clear user cache
  }

  Future<void> _cacheStatisticsLocally(Map<String, dynamic> stats) async {
    // Cache statistics
  }

  Future<Map<String, dynamic>> _getCachedStatistics() async {
    return {
      'totalUsers': 0,
      'totalStudents': 0,
      'totalTeachers': 0,
      'totalAdministrators': 0,
      'totalAssessments': 0,
      'totalLessons': 0,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}

