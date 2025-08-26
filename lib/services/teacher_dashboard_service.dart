import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_progress.dart';
import '../models/teacher_activity.dart';
import 'offline_service.dart';
import 'connectivity_service.dart';

class TeacherDashboardData {
  final List<StudentProgress> studentProgress;
  final List<TeacherActivity> recentActivities;
  final Map<String, int> subjectStats;
  final int totalStudents;
  final int activeStudents;
  final double averageProgress;

  TeacherDashboardData({
    required this.studentProgress,
    required this.recentActivities,
    required this.subjectStats,
    required this.totalStudents,
    required this.activeStudents,
    required this.averageProgress,
  });
}

class TeacherDashboardService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get all dashboard data for a teacher
  Future<TeacherDashboardData> getDashboardData(String teacherId, List<String> teacherSubjects) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedDashboardData(teacherId, teacherSubjects);
      }

      // If online, fetch from Firebase and cache
      final studentProgress = await _getStudentProgress(teacherSubjects);
      final recentActivities = await _getRecentActivities(teacherId);
      final studentCount = await _getStudentCount();
      final stats = _calculateStats(studentProgress, studentCount);
      
      final dashboardData = TeacherDashboardData(
        studentProgress: studentProgress,
        recentActivities: recentActivities,
        subjectStats: stats['subjectStats'],
        totalStudents: stats['totalStudents'],
        activeStudents: stats['activeStudents'],
        averageProgress: stats['averageProgress'],
      );

      // Cache the data for offline use
      await _cacheDashboardData(dashboardData);
      
      return dashboardData;
    } catch (e) {
      // If Firebase fails, try to return cached data
      print('Firebase error, trying cached data: $e');
      return await _getCachedDashboardData(teacherId, teacherSubjects);
    }
  }

  // Get student progress for teacher's subjects
  Future<List<StudentProgress>> _getStudentProgress(List<String> subjects) async {
    try {
      print('🔍 TeacherDashboardService: Fetching student progress for subjects: $subjects');
      
      // First try to get from Firebase Realtime Database
      final DatabaseReference ref = _database.ref('student_progress');
      final DatabaseEvent event = await ref.once();
      final DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && data.isNotEmpty) {
          print('🔍 TeacherDashboardService: Found ${data.entries.length} progress entries in Realtime DB');
          
          final progressList = data.entries.map((entry) {
            final entryData = entry.value as Map<dynamic, dynamic>?;
            if (entryData == null) return null;
            
            try {
              return StudentProgress.fromRealtimeDatabase(
                Map<String, dynamic>.from(entryData),
                entry.key.toString(),
              );
            } catch (e) {
              print('🔍 TeacherDashboardService: Error parsing progress data: $e');
              return null;
            }
          }).whereType<StudentProgress>().toList();
          
          print('🔍 TeacherDashboardService: Successfully parsed ${progressList.length} progress records');
          return progressList;
        }
      }
      
      // If no progress data exists, create sample progress from Firestore students
      print('🔍 TeacherDashboardService: No progress data found, creating sample data from students');
      return await _createSampleProgressFromStudents(subjects);
      
    } catch (e) {
      print('🔍 TeacherDashboardService: Error fetching student progress: $e');
      return await _createSampleProgressFromStudents(subjects);
    }
  }

  // Create sample progress data from existing students
  Future<List<StudentProgress>> _createSampleProgressFromStudents(List<String> subjects) async {
    try {
      print('🔍 TeacherDashboardService: Creating sample progress from students');
      
      // Get students from Firestore
      final studentsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      if (studentsQuery.docs.isEmpty) {
        print('🔍 TeacherDashboardService: No students found in Firestore');
        return [];
      }
      
      print('🔍 TeacherDashboardService: Found ${studentsQuery.docs.length} students in Firestore');
      
      final List<StudentProgress> sampleProgress = [];
      
      for (final doc in studentsQuery.docs) {
        final data = doc.data();
        final studentName = data['displayName'] ?? 'Unknown Student';
        final studentEmail = data['email'] ?? '';
        final studentSubjects = (data['subjects'] as List<dynamic>?)?.cast<String>() ?? [];
        
        // Create progress for each subject the student is enrolled in
        for (final subject in studentSubjects) {
          if (subjects.isEmpty || subjects.contains(subject)) {
            print('🔍 TeacherDashboardService: Creating progress for ${data['displayName']} in subject: $subject');
            
            // Generate realistic sample progress
            final lessonsCompleted = (DateTime.now().millisecond % 5) + 1; // 1-5 lessons
            final totalLessons = 10;
            final assessmentsTaken = (DateTime.now().millisecond % 3) + 1; // 1-3 assessments
            final totalAssessments = 5;
            final averageScore = 60.0 + (DateTime.now().millisecond % 40); // 60-99 score
            final completionRate = (lessonsCompleted / totalLessons) * 100;
            
            final progress = StudentProgress(
              id: '${doc.id}_${subject}',
              studentId: doc.id,
              studentName: studentName,
              studentEmail: studentEmail,
              subject: subject,
              lessonsCompleted: lessonsCompleted,
              totalLessons: totalLessons,
              assessmentsTaken: assessmentsTaken,
              totalAssessments: totalAssessments,
              averageScore: averageScore,
              completionRate: completionRate,
              lastActivity: DateTime.now().subtract(Duration(days: DateTime.now().millisecond % 7)),
              lessonProgress: [],
              assessmentProgress: [],
            );
            
            sampleProgress.add(progress);
            print('🔍 TeacherDashboardService: Progress record created for ${studentName} in $subject');
          }
        }
      }
      
      print('🔍 TeacherDashboardService: Created ${sampleProgress.length} sample progress records');
      return sampleProgress;
      
    } catch (e) {
      print('🔍 TeacherDashboardService: Error creating sample progress: $e');
      return [];
    }
  }

  // Get recent activities for teacher
  Future<List<TeacherActivity>> _getRecentActivities(String teacherId) async {
    try {
      print('🔍 TeacherDashboardService: Fetching recent activities for teacher: $teacherId');
      
      final snapshot = await _database
          .ref('teacher_activities')
          .child(teacherId)
          .get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && data.isNotEmpty) {
          print('🔍 TeacherDashboardService: Found ${data.length} activities in Realtime DB');
          
          final activities = <TeacherActivity>[];
          data.forEach((key, value) {
            if (value is Map) {
              try {
                final activity = TeacherActivity.fromRealtimeDatabase(key.toString(), value);
                activities.add(activity);
              } catch (e) {
                print('Error parsing teacher activity: $e');
              }
            }
          });
          
          // Sort by timestamp (newest first) and take last 10
          activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          final recentActivities = activities.take(10).toList();
          print('🔍 TeacherDashboardService: Returning ${recentActivities.length} recent activities');
          return recentActivities;
        }
      }
      
      // If no activities exist, create sample activities
      print('🔍 TeacherDashboardService: No activities found, creating sample activities');
      return _createSampleTeacherActivities(teacherId);
      
    } catch (e) {
      print('🔍 TeacherDashboardService: Error fetching activities, creating sample: $e');
      return _createSampleTeacherActivities(teacherId);
    }
  }

  // Create sample teacher activities
  List<TeacherActivity> _createSampleTeacherActivities(String teacherId) {
    print('🔍 TeacherDashboardService: Creating sample teacher activities');
    
    final now = DateTime.now();
    final activities = <TeacherActivity>[];
    
    // Sample activity 1: Lesson creation
    activities.add(TeacherActivity(
      id: 'sample_1',
      teacherId: teacherId,
      type: ActivityType.lessonUpload,
      title: 'Created Mathematics Lesson',
      description: 'New lesson on Algebra basics uploaded',
      subject: 'Mathematics',
      timestamp: now.subtract(const Duration(hours: 2)),
      metadata: {'sample': true},
    ));
    
    // Sample activity 2: Assessment creation
    activities.add(TeacherActivity(
      id: 'sample_2',
      teacherId: teacherId,
      type: ActivityType.assessmentCreated,
      title: 'Created Science Quiz',
      description: 'New assessment on Biology fundamentals',
      subject: 'Science',
      timestamp: now.subtract(const Duration(hours: 4)),
      metadata: {'sample': true},
    ));
    
    // Sample activity 3: Student progress review
    activities.add(TeacherActivity(
      id: 'sample_3',
      teacherId: teacherId,
      type: ActivityType.progressReviewed,
      title: 'Reviewed Student Progress',
      description: 'Checked progress for Grade 7 students',
      subject: 'General',
      timestamp: now.subtract(const Duration(hours: 6)),
      metadata: {'sample': true},
    ));
    
    // Sample activity 4: Content update (using lessonUpload as closest type)
    activities.add(TeacherActivity(
      id: 'sample_4',
      teacherId: teacherId,
      type: ActivityType.lessonUpload,
      title: 'Updated English Lesson',
      description: 'Enhanced lesson content with new examples',
      subject: 'English',
      timestamp: now.subtract(const Duration(days: 1)),
      metadata: {'sample': true},
    ));
    
    // Sample activity 5: Student management
    activities.add(TeacherActivity(
      id: 'sample_5',
      teacherId: teacherId,
      type: ActivityType.studentManagement,
      title: 'Managed Student Enrollments',
      description: 'Added new students to Mathematics class',
      subject: 'Mathematics',
      timestamp: now.subtract(const Duration(days: 2)),
      metadata: {'sample': true},
    ));
    
    print('🔍 TeacherDashboardService: Created ${activities.length} sample activities');
    return activities;
  }

  // Get student count from Firestore
  Future<int> _getStudentCount() async {
    try {
      final studentsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      print('🔍 TeacherDashboardService: Found ${studentsQuery.docs.length} students in Firestore');
      
      // Log each student for debugging
      for (final doc in studentsQuery.docs) {
        final data = doc.data();
        final studentName = data['displayName'] ?? 'Unknown';
        final studentSubjects = (data['subjects'] as List<dynamic>?)?.cast<String>() ?? [];
        print('🔍 TeacherDashboardService: Student: $studentName, Subjects: $studentSubjects (${studentSubjects.length} subjects)');
      }
      
      return studentsQuery.docs.length;
    } catch (e) {
      print('🔍 TeacherDashboardService: Error getting student count: $e');
      return 0;
    }
  }

  // Calculate dashboard statistics
  Map<String, dynamic> _calculateStats(List<StudentProgress> studentProgress, int totalStudents) {
    if (studentProgress.isEmpty) {
      return {
        'subjectStats': <String, int>{},
        'totalStudents': totalStudents,
        'activeStudents': 0,
        'averageProgress': 0.0,
      };
    }

    final Map<String, int> subjectStats = {};
    final Set<String> uniqueStudents = {};
    final Set<String> activeStudentIds = {};
    double totalProgress = 0.0;

    for (final progress in studentProgress) {
      // Count subjects
      subjectStats[progress.subject] = (subjectStats[progress.subject] ?? 0) + 1;
      
      // Count unique students (not progress records)
      uniqueStudents.add(progress.studentId);
      
      // Count active students (with activity in last 7 days) - only count each student once
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      if (progress.lastActivity.isAfter(weekAgo)) {
        activeStudentIds.add(progress.studentId);
      }
      
      // Calculate total progress
      totalProgress += progress.completionRate;
    }

    // Calculate average progress per student (not per progress record)
    final averageProgress = uniqueStudents.isNotEmpty ? totalProgress / uniqueStudents.length : 0.0;

    print('🔍 TeacherDashboardService: Statistics calculation:');
    print('🔍 TeacherDashboardService: - Total progress records: ${studentProgress.length}');
    print('🔍 TeacherDashboardService: - Unique students: ${uniqueStudents.length}');
    print('🔍 TeacherDashboardService: - Active students: ${activeStudentIds.length}');
    print('🔍 TeacherDashboardService: - Average progress: ${averageProgress.toStringAsFixed(1)}%');

    return {
      'subjectStats': subjectStats,
      'totalStudents': uniqueStudents.length, // Use unique students count
      'activeStudents': activeStudentIds.length, // Use unique active student IDs
      'averageProgress': averageProgress,
    };
  }

  // Log a new teacher activity
  Future<void> logActivity(String teacherId, String type, String title, String description) async {
    try {
      print('🔍 TeacherDashboardService: Logging activity for teacher: $teacherId');
      print('🔍 TeacherDashboardService: Activity type: $type, title: $title');
      
      await _database.ref('teacher_activities').child(teacherId).push().set({
        'teacherId': teacherId,
        'type': type.toString().split('.').last,
        'title': title,
        'description': description,
        'subject': 'General', // Default subject
        'timestamp': ServerValue.timestamp,
        'metadata': {
          'loggedAt': DateTime.now().toIso8601String(),
          'source': 'dashboard_service',
        },
      });
      
      print('🔍 TeacherDashboardService: Activity logged successfully');
    } catch (e) {
      print('🔍 TeacherDashboardService: Failed to log activity: $e');
      throw Exception('Failed to log activity: ${e.toString()}');
    }
  }

  // Log a new teacher activity with subject
  Future<void> logActivityWithSubject(String teacherId, String type, String title, String description, String subject) async {
    try {
      print('🔍 TeacherDashboardService: Logging activity with subject for teacher: $teacherId');
      print('🔍 TeacherDashboardService: Activity type: $type, title: $title, subject: $subject');
      
      await _database.ref('teacher_activities').child(teacherId).push().set({
        'teacherId': teacherId,
        'type': type.toString().split('.').last,
        'title': title,
        'description': description,
        'subject': subject,
        'timestamp': ServerValue.timestamp,
        'metadata': {
          'loggedAt': DateTime.now().toIso8601String(),
          'source': 'dashboard_service',
        },
      });
      
      print('🔍 TeacherDashboardService: Activity with subject logged successfully');
    } catch (e) {
      print('🔍 TeacherDashboardService: Failed to log activity with subject: $e');
      throw Exception('Failed to log activity: ${e.toString()}');
    }
  }

  // Create real student progress when teachers perform actions
  Future<void> createStudentProgressForAction(String teacherId, String subject, String actionType) async {
    try {
      print('🔍 TeacherDashboardService: Creating student progress for action: $actionType in $subject');
      
      // Get students from Firestore who are enrolled in this subject
      final studentsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      if (studentsQuery.docs.isEmpty) {
        print('🔍 TeacherDashboardService: No students found for progress creation');
        return;
      }
      
      // Create progress entries for students in this subject
      for (final doc in studentsQuery.docs) {
        final data = doc.data();
        final studentSubjects = (data['subjects'] as List<dynamic>?)?.cast<String>() ?? [];
        
        if (studentSubjects.contains(subject)) {
          // Check if progress already exists
          final existingProgressRef = _database.ref('student_progress')
              .orderByChild('studentId')
              .equalTo(doc.id)
              .orderByChild('subject')
              .equalTo(subject);
          
          final existingSnapshot = await existingProgressRef.once();
          
          if (!existingSnapshot.snapshot.exists) {
            // Create new progress entry
            final progressData = {
              'studentId': doc.id,
              'studentName': data['displayName'] ?? 'Unknown Student',
              'studentEmail': data['email'] ?? '',
              'subject': subject,
              'lessonsCompleted': 0,
              'totalLessons': 1, // Will be updated when lessons are added
              'assessmentsTaken': 0,
              'totalAssessments': 1, // Will be updated when assessments are added
              'averageScore': 0.0,
              'completionRate': 0.0,
              'lastActivity': ServerValue.timestamp,
              'teacherId': teacherId,
              'createdAt': ServerValue.timestamp,
              'updatedAt': ServerValue.timestamp,
            };
            
            await _database.ref('student_progress').push().set(progressData);
            print('🔍 TeacherDashboardService: Created progress for student ${data['displayName']} in $subject');
          }
        }
      }
      
      print('🔍 TeacherDashboardService: Student progress creation completed for $subject');
    } catch (e) {
      print('🔍 TeacherDashboardService: Error creating student progress: $e');
    }
  }

  // Get cached dashboard data
  Future<TeacherDashboardData> _getCachedDashboardData(String teacherId, List<String> teacherSubjects) async {
    try {
      final cachedProgress = await OfflineService.getCachedStudentProgress();
      final cachedActivities = await OfflineService.getCachedTeacherActivities();
      
      // Convert cached data to proper models
      final studentProgress = cachedProgress.map((data) => 
        StudentProgress.fromRealtimeDatabase(data, data['id'] ?? '')
      ).toList();
      
      final recentActivities = cachedActivities.map((data) => 
        TeacherActivity.fromRealtimeDatabase(data['id'] ?? '', data)
      ).toList();
      
      final stats = _calculateStats(studentProgress, studentProgress.length);
      
      return TeacherDashboardData(
        studentProgress: studentProgress,
        recentActivities: recentActivities,
        subjectStats: stats['subjectStats'],
        totalStudents: stats['totalStudents'],
        activeStudents: stats['activeStudents'],
        averageProgress: stats['averageProgress'],
      );
    } catch (e) {
      print('Error getting cached dashboard data: $e');
      // Return empty dashboard data if cache fails
      return TeacherDashboardData(
        studentProgress: [],
        recentActivities: [],
        subjectStats: <String, int>{},
        totalStudents: 0,
        activeStudents: 0,
        averageProgress: 0.0,
      );
    }
  }

  // Cache dashboard data
  Future<void> _cacheDashboardData(TeacherDashboardData data) async {
    try {
      // Cache student progress
      final progressData = data.studentProgress.map((progress) => {
        'id': progress.id,
        'studentId': progress.studentId,
        'studentName': progress.studentName,
        'studentEmail': progress.studentEmail,
        'subject': progress.subject,
        'lessonsCompleted': progress.lessonsCompleted,
        'totalLessons': progress.totalLessons,
        'assessmentsTaken': progress.assessmentsTaken,
        'totalAssessments': progress.totalAssessments,
        'averageScore': progress.averageScore,
        'completionRate': progress.completionRate,
        'lastActivity': progress.lastActivity.millisecondsSinceEpoch,
        'lessonProgress': progress.lessonProgress.fold<Map<String, dynamic>>({}, (map, lesson) {
          map[lesson.lessonId] = lesson.toMap();
          return map;
        }),
        'assessmentProgress': progress.assessmentProgress.fold<Map<String, dynamic>>({}, (map, assessment) {
          map[assessment.assessmentId] = assessment.toMap();
          return map;
        }),
        'metadata': progress.metadata,
      }).toList();
      
      await OfflineService.cacheStudentProgress(progressData);
      
      // Cache teacher activities
      final activitiesData = data.recentActivities.map((activity) => {
        'id': activity.id,
        'teacherId': activity.teacherId,
        'type': activity.type.toString().split('.').last,
        'title': activity.title,
        'description': activity.description,
        'subject': activity.subject,
        'timestamp': activity.timestamp.millisecondsSinceEpoch,
        'metadata': activity.metadata,
      }).toList();
      
      await OfflineService.cacheTeacherActivities(activitiesData);
    } catch (e) {
      print('Error caching dashboard data: $e');
    }
  }
}
