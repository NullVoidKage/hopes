import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';

class LessonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Create a new lesson
  Future<String> createLesson(Lesson lesson) async {
    try {
      final docRef = await _firestore.collection('lessons').add({
        'title': lesson.title,
        'subject': lesson.subject,
        'content': lesson.content,
        'teacherId': lesson.teacherId,
        'teacherName': lesson.teacherName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isPublished': lesson.isPublished,
        'tags': lesson.tags,
        'description': lesson.description,
        'fileUrl': lesson.fileUrl,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create lesson: ${e.toString()}');
    }
  }

  // Get lessons by teacher
  Future<List<Lesson>> getLessonsByTeacher(String teacherId) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedLessonsByTeacher(teacherId);
      }

      // If online, fetch from Firestore and cache
      final querySnapshot = await _firestore
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .get();

      final lessons = querySnapshot.docs
          .map((doc) => Lesson.fromFirestore(doc.data(), doc.id))
          .toList();

      // Cache the lessons for offline use
      await _cacheLessonsLocally(lessons);

      return lessons;
    } catch (e) {
      // If Firestore fails, try to return cached data
      return await _getCachedLessonsByTeacher(teacherId);
    }
  }

  // Get cached lessons by teacher
  Future<List<Lesson>> _getCachedLessonsByTeacher(String teacherId) async {
    try {
      final cachedLessons = await OfflineService.getCachedLessons();
      return cachedLessons
          .where((data) => (data['teacherId'] as String?) == teacherId)
          .map((data) => Lesson.fromRealtimeDatabase(data['id'] ?? '', data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Cache lessons locally
  Future<void> _cacheLessonsLocally(List<Lesson> lessons) async {
    try {
      final lessonData = lessons.map((lesson) => {
        'id': lesson.id,
        ...lesson.toRealtimeDatabase(),
      }).toList();
      await OfflineService.cacheLessons(lessonData);
    } catch (e) {
    }
  }

  // Get lessons by subject
  Future<List<Lesson>> getLessonsBySubject(String subject) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedLessonsBySubject(subject);
      }

      // If online, fetch from Firestore and cache
      final querySnapshot = await _firestore
          .collection('lessons')
          .where('subject', isEqualTo: subject)
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final lessons = querySnapshot.docs
          .map((doc) => Lesson.fromFirestore(doc.data(), doc.id))
          .toList();

      // Cache the lessons for offline use
      await _cacheLessonsLocally(lessons);

      return lessons;
    } catch (e) {
      // If Firestore fails, try to return cached data
      return await _getCachedLessonsBySubject(subject);
    }
  }

  // Get cached lessons by subject
  Future<List<Lesson>> _getCachedLessonsBySubject(String subject) async {
    try {
      final cachedLessons = await OfflineService.getCachedLessons();
      return cachedLessons
          .where((data) => (data['subject'] as String?) == subject)
          .map((data) => Lesson.fromRealtimeDatabase(data['id'] ?? '', data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get a specific lesson by ID
  Future<Lesson?> getLessonById(String lessonId) async {
    try {
      // Check if we should use cached data
      if (_connectivityService.shouldUseCachedData) {
        return await _getCachedLessonById(lessonId);
      }

      // If online, fetch from Firestore and cache
      final doc = await _firestore
          .collection('lessons')
          .doc(lessonId)
          .get();

      if (doc.exists) {
        final lesson = Lesson.fromFirestore(doc.data()!, doc.id);
        
        // Cache the lesson for offline use
        await _cacheLessonLocally(lesson);
        
        return lesson;
      }
      return null;
    } catch (e) {
      // If Firestore fails, try to return cached data
      return await _getCachedLessonById(lessonId);
    }
  }

  // Update a lesson
  Future<void> updateLesson(String lessonId, Map<String, dynamic> updates) async {
    try {
      // Check if we should queue for sync
      if (_connectivityService.shouldUseCachedData) {
        await _queueLessonUpdateForSync(lessonId, updates);
        return;
      }

      // If online, update in Firestore
      await _firestore
          .collection('lessons')
          .doc(lessonId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update lesson: ${e.toString()}');
    }
  }

  // Delete a lesson
  Future<void> deleteLesson(String lessonId) async {
    try {
      await _firestore
          .collection('lessons')
          .doc(lessonId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete lesson: ${e.toString()}');
    }
  }

  // Toggle lesson publish status
  Future<void> toggleLessonPublish(String lessonId, bool isPublished) async {
    try {
      await _firestore
          .collection('lessons')
          .doc(lessonId)
          .update({
        'isPublished': isPublished,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle lesson publish status: ${e.toString()}');
    }
  }

  // Search lessons by tags
  Future<List<Lesson>> searchLessonsByTags(List<String> tags) async {
    try {
      final List<Lesson> results = [];
      
      for (String tag in tags) {
        final query = await _firestore
            .collection('lessons')
            .where('tags', arrayContains: tag)
            .where('isPublished', isEqualTo: true)
            .get();

        final lessons = query.docs
            .map((doc) => Lesson.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        results.addAll(lessons);
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
      final query = await _firestore
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      final lessons = query.docs
          .map((doc) => Lesson.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

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

  // Get cached lesson by ID
  Future<Lesson?> _getCachedLessonById(String lessonId) async {
    try {
      final cachedLessons = await OfflineService.getCachedLessons();
      final lessonData = cachedLessons.firstWhere(
        (data) => (data['id'] as String?) == lessonId,
        orElse: () => {},
      );
      
      if (lessonData.isNotEmpty) {
        return Lesson.fromRealtimeDatabase(lessonId, lessonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Cache a single lesson locally
  Future<void> _cacheLessonLocally(Lesson lesson) async {
    try {
      final existingLessons = await OfflineService.getCachedLessons();
      
      // Update existing lesson or add new one
      bool found = false;
      for (int i = 0; i < existingLessons.length; i++) {
        if (existingLessons[i]['id'] == lesson.id) {
          existingLessons[i] = {
            'id': lesson.id,
            ...lesson.toRealtimeDatabase(),
          };
          found = true;
          break;
        }
      }
      
      if (!found) {
        existingLessons.add({
          'id': lesson.id,
          ...lesson.toRealtimeDatabase(),
        });
      }
      
      await OfflineService.cacheLessons(existingLessons);
    } catch (e) {
    }
  }

  // Queue lesson update for sync when online
  Future<void> _queueLessonUpdateForSync(String lessonId, Map<String, dynamic> updates) async {
    try {
      // This would typically save to a sync queue
      // For now, we'll just update the cached version
      final cachedLessons = await OfflineService.getCachedLessons();
      for (int i = 0; i < cachedLessons.length; i++) {
        if (cachedLessons[i]['id'] == lessonId) {
          cachedLessons[i].addAll(updates);
          break;
        }
      }
      await OfflineService.cacheLessons(cachedLessons);
    } catch (e) {
    }
  }
}
