import 'package:firebase_database/firebase_database.dart';
import '../models/lesson.dart';
import 'offline_service.dart';
import 'connectivity_service.dart';
import 'package:flutter/foundation.dart';

class LessonServiceRealtime {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Create a new lesson
  Future<String> createLesson(Lesson lesson) async {
    try {
      // Check if online before creating
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot create lesson while offline. Please check your internet connection.');
      }

      final lessonRef = _database.child('lessons').push();
      final lessonId = lessonRef.key!;
      
      final lessonData = {
        'title': lesson.title,
        'subject': lesson.subject,
        'content': lesson.content,
        'teacherId': lesson.teacherId,
        'teacherName': lesson.teacherName,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'isPublished': lesson.isPublished,
        'tags': lesson.tags,
        'description': lesson.description,
        'fileUrl': lesson.fileUrl,
      };

      await lessonRef.set(lessonData);
      
      // Cache the new lesson locally
      await _cacheLessonLocally(lessonId, lessonData);
      
      return lessonId;
    } catch (e) {
      throw Exception('Failed to create lesson: ${e.toString()}');
    }
  }

  // Get lessons by teacher with offline support
  Future<List<Lesson>> getLessonsByTeacher(String teacherId) async {
    try {
      // If offline, return cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedLessonsByTeacher(teacherId);
      }

      // If online, fetch from Firebase and cache
      final query = _database
          .child('lessons')
          .orderByChild('teacherId')
          .equalTo(teacherId);

      final snapshot = await query.get();
      
      if (snapshot.exists) {
        final lessons = <Lesson>[];
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map) {
            final lesson = Lesson.fromRealtimeDatabase(key, value);
            lessons.add(lesson);
          }
        });

        // Sort by creation date (newest first)
        lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Cache lessons locally
        await _cacheLessonsLocally(lessons);
        
        return lessons;
      }
      
      return [];
    } catch (e) {
      // If Firebase fails, try to return cached data
      if (kDebugMode) {
        print('Firebase error, trying cached data: $e');
      }
      return await _getCachedLessonsByTeacher(teacherId);
    }
  }

  // Get lessons by subject with offline support
  Future<List<Lesson>> getLessonsBySubject(String subject) async {
    try {
      // If offline, return cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedLessonsBySubject(subject);
      }

      // If online, fetch from Firebase and cache
      final query = _database
          .child('lessons')
          .orderByChild('subject')
          .equalTo(subject);

      final snapshot = await query.get();
      
      if (snapshot.exists) {
        final lessons = <Lesson>[];
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map) {
            final lesson = Lesson.fromRealtimeDatabase(key, value);
            // Only return published lessons
            if (lesson.isPublished) {
              lessons.add(lesson);
            }
          }
        });

        // Sort by creation date (newest first)
        lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Cache lessons locally
        await _cacheLessonsLocally(lessons);
        
        return lessons;
      }
      
      return [];
    } catch (e) {
      // If Firebase fails, try to return cached data
      if (kDebugMode) {
        print('Firebase error, trying cached data: $e');
      }
      return await _getCachedLessonsBySubject(subject);
    }
  }

  // Get a specific lesson by ID
  Future<Lesson?> getLessonById(String lessonId) async {
    try {
      final snapshot = await _database
          .child('lessons')
          .child(lessonId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return Lesson.fromRealtimeDatabase(lessonId, data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get lesson: ${e.toString()}');
    }
  }

  // Update a lesson
  Future<void> updateLesson(String lessonId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = ServerValue.timestamp;
      
      await _database
          .child('lessons')
          .child(lessonId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update lesson: ${e.toString()}');
    }
  }

  // Delete a lesson
  Future<void> deleteLesson(String lessonId) async {
    try {
      await _database
          .child('lessons')
          .child(lessonId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete lesson: ${e.toString()}');
    }
  }

  // Toggle lesson publish status
  Future<void> toggleLessonPublish(String lessonId, bool isPublished) async {
    try {
      await _database
          .child('lessons')
          .child(lessonId)
          .update({
        'isPublished': isPublished,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to toggle lesson publish status: ${e.toString()}');
    }
  }

  // Search lessons by tags
  Future<List<Lesson>> searchLessonsByTags(List<String> tags) async {
    try {
      final List<Lesson> results = [];
      
      // Get all lessons and filter by tags
      final snapshot = await _database.child('lessons').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map) {
            final lesson = Lesson.fromRealtimeDatabase(key, value);
            
            // Check if lesson has any of the search tags
            final hasMatchingTag = lesson.tags.any((tag) => tags.contains(tag));
            if (hasMatchingTag && lesson.isPublished) {
              results.add(lesson);
            }
          }
        });
      }

      // Remove duplicates and sort by creation date
      final uniqueLessons = results.toSet().toList();
      uniqueLessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return uniqueLessons;
    } catch (e) {
      throw Exception('Failed to search lessons by tags: ${e.toString()}');
    }
  }

  // Get lesson statistics for teacher
  Future<Map<String, dynamic>> getLessonStats(String teacherId) async {
    try {
      final lessons = await getLessonsByTeacher(teacherId);
      
      final totalLessons = lessons.length;
      final publishedLessons = lessons.where((l) => l.isPublished).length;
      final draftLessons = totalLessons - publishedLessons;

      // Group by subject
      final Map<String, int> subjectCounts = {};
      for (final lesson in lessons) {
        subjectCounts[lesson.subject] = (subjectCounts[lesson.subject] ?? 0) + 1;
      }

      return {
        'totalLessons': totalLessons,
        'publishedLessons': publishedLessons,
        'draftLessons': draftLessons,
        'subjectCounts': subjectCounts,
      };
    } catch (e) {
      throw Exception('Failed to get lesson stats: ${e.toString()}');
    }
  }

  // Get cached lessons by teacher
  Future<List<Lesson>> _getCachedLessonsByTeacher(String teacherId) async {
    try {
      final cachedData = await OfflineService.getCachedLessons();
      final lessons = <Lesson>[];
      
      for (final lessonData in cachedData) {
        if (lessonData['teacherId'] == teacherId) {
          final lesson = Lesson.fromRealtimeDatabase(
            lessonData['id'] ?? '', 
            lessonData
          );
          lessons.add(lesson);
        }
      }
      
      // Sort by creation date (newest first)
      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return lessons;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached lessons by teacher: $e');
      }
      return [];
    }
  }

  // Get cached lessons by subject
  Future<List<Lesson>> _getCachedLessonsBySubject(String subject) async {
    try {
      final cachedData = await OfflineService.getCachedLessons();
      final lessons = <Lesson>[];
      
      for (final lessonData in cachedData) {
        if (lessonData['subject'] == subject && lessonData['isPublished'] == true) {
          final lesson = Lesson.fromRealtimeDatabase(
            lessonData['id'] ?? '', 
            lessonData
          );
          lessons.add(lesson);
        }
      }
      
      // Sort by creation date (newest first)
      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return lessons;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached lessons by subject: $e');
      }
      return [];
    }
  }

  // Cache lessons locally
  Future<void> _cacheLessonsLocally(List<Lesson> lessons) async {
    try {
      final lessonsData = lessons.map((lesson) => {
        'id': lesson.id,
        'title': lesson.title,
        'subject': lesson.subject,
        'content': lesson.content,
        'teacherId': lesson.teacherId,
        'teacherName': lesson.teacherName,
        'createdAt': lesson.createdAt.millisecondsSinceEpoch,
        'updatedAt': lesson.updatedAt.millisecondsSinceEpoch,
        'isPublished': lesson.isPublished,
        'tags': lesson.tags,
        'description': lesson.description,
        'fileUrl': lesson.fileUrl,
      }).toList();
      
      await OfflineService.cacheLessons(lessonsData);
    } catch (e) {
      if (kDebugMode) {
        print('Error caching lessons locally: $e');
      }
    }
  }

  // Cache a single lesson locally
  Future<void> _cacheLessonLocally(String lessonId, Map<String, dynamic> lessonData) async {
    try {
      final existingLessons = await OfflineService.getCachedLessons();
      
      // Update existing lesson or add new one
      bool found = false;
      for (int i = 0; i < existingLessons.length; i++) {
        if (existingLessons[i]['id'] == lessonId) {
          existingLessons[i] = lessonData;
          found = true;
          break;
        }
      }
      
      if (!found) {
        lessonData['id'] = lessonId;
        existingLessons.add(lessonData);
      }
      
      await OfflineService.cacheLessons(existingLessons);
    } catch (e) {
      if (kDebugMode) {
        print('Error caching single lesson locally: $e');
      }
    }
  }

  // Check if data is available offline
  Future<bool> hasOfflineData() async {
    try {
      final cachedLessons = await OfflineService.getCachedLessons();
      return cachedLessons.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get offline data info
  Future<Map<String, dynamic>> getOfflineDataInfo() async {
    try {
      final cacheInfo = await OfflineService.getCacheInfo();
      final lastSync = await OfflineService.getLastSync();
      final isStale = await OfflineService.isDataStale();
      
      return {
        'hasData': cacheInfo['total']! > 0,
        'lessonsCount': cacheInfo['lessons']!,
        'lastSync': lastSync?.toIso8601String(),
        'isStale': isStale,
        'isOnline': _connectivityService.isConnected,
      };
    } catch (e) {
      return {
        'hasData': false,
        'lessonsCount': 0,
        'lastSync': null,
        'isStale': true,
        'isOnline': false,
      };
    }
  }
}
