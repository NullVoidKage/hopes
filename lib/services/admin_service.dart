import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/assessment.dart';
import '../models/lesson.dart';
import '../models/student_approval.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';

class AdminService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get all users with filtering
  Future<List<UserModel>> getAllUsers({
    String? role,
    String? schoolYear,
  }) async {
    try {
      // Always try to fetch from Firestore first (don't rely on connectivity check for admin)
      firestore.Query query = _firestore.collection('users');

      if (role != null) {
        query = query.where('role', isEqualTo: role);
      }

      final snapshot = await query.get();

      final users = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              return UserModel.fromFirestore(data, doc.id);
            } catch (e) {
              // Skip invalid user documents
              print('Error parsing user ${doc.id}: $e');
              return null;
            }
          })
          .whereType<UserModel>()
          .toList();

      if (schoolYear != null) {
        return users.where((user) => user.schoolYear == schoolYear).toList();
      }

      // Cache for offline use
      await _cacheUsersLocally(users);

      return users;
    } catch (e) {
      print('Error fetching users from Firestore: $e');
      // Try cached users as fallback
      try {
        return await _getCachedUsers(role: role);
      } catch (cacheError) {
        print('Error fetching cached users: $cacheError');
        return [];
      }
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

      // Get users from Firestore
      final usersSnapshot = await _firestore.collection('users').get();
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

      // Get assessments and lessons from Realtime Database
      final assessmentsSnapshot = await _database.ref('assessments').get();
      final lessonsSnapshot = await _database.ref('lessons').get();
      
      int totalAssessments = 0;
      int totalLessons = 0;
      
      if (assessmentsSnapshot.exists) {
        final assessmentsData = assessmentsSnapshot.value;
        if (assessmentsData is Map) {
          totalAssessments = assessmentsData.length;
        }
      }
      
      if (lessonsSnapshot.exists) {
        final lessonsData = lessonsSnapshot.value;
        if (lessonsData is Map) {
          totalLessons = lessonsData.length;
        }
      }

      final statistics = {
        'totalUsers': totalUsers,
        'totalStudents': students,
        'totalTeachers': teachers,
        'totalAdministrators': administrators,
        'totalAssessments': totalAssessments,
        'totalLessons': totalLessons,
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
      // Get from Realtime Database
      final assessmentsSnapshot = await _database.ref('assessments').get();
      final lessonsSnapshot = await _database.ref('lessons').get();

      final assessmentBySubject = <String, int>{};
      final lessonBySubject = <String, int>{};

      if (assessmentsSnapshot.exists) {
        final assessmentsData = assessmentsSnapshot.value;
        if (assessmentsData is Map) {
          assessmentsData.forEach((key, value) {
            if (value is Map) {
              final subject = value['subject']?.toString() ?? 'Unknown';
              assessmentBySubject[subject] = (assessmentBySubject[subject] ?? 0) + 1;
            }
          });
        }
      }

      if (lessonsSnapshot.exists) {
        final lessonsData = lessonsSnapshot.value;
        if (lessonsData is Map) {
          lessonsData.forEach((key, value) {
            if (value is Map) {
              final subject = value['subject']?.toString() ?? 'Unknown';
              lessonBySubject[subject] = (lessonBySubject[subject] ?? 0) + 1;
            }
          });
        }
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

  // Get all assessments from Realtime Database
  Future<List<Assessment>> getAllAssessments() async {
    try {
      final snapshot = await _database.ref('assessments').get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      final assessments = <Assessment>[];
      final data = snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            try {
              final assessment = Assessment.fromRealtimeDatabase(key.toString(), value);
              assessments.add(assessment);
            } catch (e) {
              // Skip invalid assessments
            }
          }
        });
      }
      
      // Sort by creation date (newest first)
      assessments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return assessments;
    } catch (e) {
      return [];
    }
  }

  // Get all lessons from Realtime Database
  Future<List<Lesson>> getAllLessons() async {
    try {
      final snapshot = await _database.ref('lessons').get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      final lessons = <Lesson>[];
      final data = snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            try {
              final lesson = Lesson.fromRealtimeDatabase(key.toString(), value);
              lessons.add(lesson);
            } catch (e) {
              // Skip invalid lessons
            }
          }
        });
      }
      
      // Sort by creation date (newest first)
      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return lessons;
    } catch (e) {
      return [];
    }
  }

  // Delete assessment from Realtime Database
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _database.ref('assessments').child(assessmentId).remove();
    } catch (e) {
      throw Exception('Failed to delete assessment: ${e.toString()}');
    }
  }

  // Delete lesson from Realtime Database
  Future<void> deleteLesson(String lessonId) async {
    try {
      await _database.ref('lessons').child(lessonId).remove();
    } catch (e) {
      throw Exception('Failed to delete lesson: ${e.toString()}');
    }
  }

  // Get all student approvals
  Future<List<StudentApproval>> getAllApprovals() async {
    try {
      final snapshot = await _database.ref('student_approvals').get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      final approvals = <StudentApproval>[];
      final data = snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            try {
              final approvalData = Map<String, dynamic>.from(value);
              final approval = StudentApproval.fromMap(approvalData);
              approvals.add(approval);
            } catch (e) {
              // Skip invalid approvals
            }
          }
        });
      }
      
      // Sort by creation date (newest first)
      approvals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return approvals;
    } catch (e) {
      return [];
    }
  }

  // Get pending approvals
  Future<List<StudentApproval>> getPendingApprovals() async {
    try {
      final allApprovals = await getAllApprovals();
      return allApprovals.where((approval) => approval.status == 'pending').toList();
    } catch (e) {
      return [];
    }
  }

  // Approve student
  Future<void> approveStudent(String approvalId, String adminId, String adminName, {String? notes}) async {
    try {
      await _database.ref('student_approvals').child(approvalId).update({
        'status': 'approved',
        'teacherId': adminId,
        'teacherName': adminName,
        'reviewedAt': ServerValue.timestamp,
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Failed to approve student: ${e.toString()}');
    }
  }

  // Reject student
  Future<void> rejectStudent(String approvalId, String adminId, String adminName, String rejectionReason) async {
    try {
      await _database.ref('student_approvals').child(approvalId).update({
        'status': 'rejected',
        'teacherId': adminId,
        'teacherName': adminName,
        'reviewedAt': ServerValue.timestamp,
        'rejectionReason': rejectionReason,
      });
    } catch (e) {
      throw Exception('Failed to reject student: ${e.toString()}');
    }
  }

  // Get approval statistics
  Future<Map<String, int>> getApprovalStatistics() async {
    try {
      final approvals = await getAllApprovals();
      
      int pending = 0;
      int approved = 0;
      int rejected = 0;
      
      for (final approval in approvals) {
        switch (approval.status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }
      
      return {
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'total': approvals.length,
      };
    } catch (e) {
      return {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'total': 0,
      };
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
      // Try to get cached users from offline service
      // For now, return empty list if no cache available
      return [];
    } catch (e) {
      print('Error getting cached users: $e');
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

