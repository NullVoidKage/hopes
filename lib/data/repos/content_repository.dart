import '../models/subject.dart';
import '../models/module.dart';
import '../models/lesson.dart';

abstract class ContentRepository {
  Future<List<Subject>> getSubjects();
  Future<Subject?> getSubject(String id);
  Future<List<Module>> getModulesBySubject(String subjectId);
  Future<Module?> getModule(String id);
  Future<List<Lesson>> getLessonsByModule(String moduleId);
  Future<Lesson?> getLesson(String id);
} 