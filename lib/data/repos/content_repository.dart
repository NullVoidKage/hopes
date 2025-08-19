import '../models/subject.dart';
import '../models/module.dart';
import '../models/lesson.dart';

abstract class ContentRepository {
  Future<List<Subject>> getSubjects();
  Future<Subject?> getSubject(String id);
  Future<Subject> createSubject(Subject subject);
  Future<Subject> updateSubject(Subject subject);
  Future<void> deleteSubject(String id);
  
  Future<List<Module>> getModulesBySubject(String subjectId);
  Future<Module?> getModule(String id);
  Future<Module> createModule(Module module);
  Future<Module> updateModule(Module module);
  Future<void> deleteModule(String id);
  
  Future<List<Lesson>> getLessonsByModule(String moduleId);
  Future<Lesson?> getLesson(String id);
  Future<Lesson> createLesson(Lesson lesson);
  Future<Lesson> updateLesson(Lesson lesson);
  Future<void> deleteLesson(String id);
} 