import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson.dart';

class LessonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final query = await _firestore
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      // Sort in memory instead of using orderBy to avoid index requirement
      final lessons = query.docs
          .map((doc) => Lesson.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Sort by createdAt descending
      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return lessons;
    } catch (e) {
      throw Exception('Failed to get lessons: ${e.toString()}');
    }
  }

  // Get lessons by subject
  Future<List<Lesson>> getLessonsBySubject(String subject) async {
    try {
      final query = await _firestore
          .collection('lessons')
          .where('subject', isEqualTo: subject)
          .where('isPublished', isEqualTo: true)
          .get();

      // Sort in memory instead of using orderBy to avoid index requirement
      final lessons = query.docs
          .map((doc) => Lesson.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Sort by createdAt descending
      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return lessons;
    } catch (e) {
      throw Exception('Failed to get lessons by subject: ${e.toString()}');
    }
  }

  // Get a specific lesson by ID
  Future<Lesson?> getLessonById(String lessonId) async {
    try {
      final doc = await _firestore
          .collection('lessons')
          .doc(lessonId)
          .get();

      if (doc.exists) {
        return Lesson.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get lesson: ${e.toString()}');
    }
  }

  // Update a lesson
  Future<void> updateLesson(String lessonId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
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
}
