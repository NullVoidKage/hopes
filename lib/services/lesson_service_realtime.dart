import 'package:firebase_database/firebase_database.dart';
import '../models/lesson.dart';

class LessonServiceRealtime {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Create a new lesson
  Future<String> createLesson(Lesson lesson) async {
    try {
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
      return lessonId;
    } catch (e) {
      throw Exception('Failed to create lesson: ${e.toString()}');
    }
  }

  // Get lessons by teacher
  Future<List<Lesson>> getLessonsByTeacher(String teacherId) async {
    try {
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
        return lessons;
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get lessons: ${e.toString()}');
    }
  }

  // Get lessons by subject
  Future<List<Lesson>> getLessonsBySubject(String subject) async {
    try {
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
        return lessons;
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get lessons by subject: ${e.toString()}');
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
}
