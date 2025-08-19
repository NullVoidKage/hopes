import 'dart:convert';
import 'package:drift/drift.dart';
import '../db/database.dart' as db;
import '../models/subject.dart';
import '../models/module.dart';
import '../models/lesson.dart';
import 'content_repository.dart';

class ContentRepositoryImpl implements ContentRepository {
  final db.HopesDatabase _database;

  ContentRepositoryImpl(this._database);

  @override
  Future<List<Subject>> getSubjects() async {
    final subjects = await _database.select(_database.subjects).get();
    return subjects.map((s) => Subject(
      id: s.id,
      name: s.name,
      gradeLevel: s.gradeLevel,
    )).toList();
  }

  @override
  Future<Subject?> getSubject(String id) async {
    final subjects = await (_database.select(_database.subjects)..where((s) => s.id.equals(id))).get();
    if (subjects.isEmpty) return null;
    
    final subject = subjects.first;
    return Subject(
      id: subject.id,
      name: subject.name,
      gradeLevel: subject.gradeLevel,
    );
  }

  @override
  Future<List<Module>> getModulesBySubject(String subjectId) async {
    final modules = await (_database.select(_database.modules)..where((m) => m.subjectId.equals(subjectId))).get();
    return modules.map((m) => Module(
      id: m.id,
      subjectId: m.subjectId,
      title: m.title,
      version: m.version,
      isPublished: m.isPublished,
    )).toList();
  }

  @override
  Future<Module?> getModule(String id) async {
    final modules = await (_database.select(_database.modules)..where((m) => m.id.equals(id))).get();
    if (modules.isEmpty) return null;
    
    final module = modules.first;
    return Module(
      id: module.id,
      subjectId: module.subjectId,
      title: module.title,
      version: module.version,
      isPublished: module.isPublished,
    );
  }

  @override
  Future<List<Lesson>> getLessonsByModule(String moduleId) async {
    final lessons = await (_database.select(_database.lessons)..where((l) => l.moduleId.equals(moduleId))).get();
    return lessons.map((l) => Lesson(
      id: l.id,
      moduleId: l.moduleId,
      title: l.title,
      bodyMarkdown: l.bodyMarkdown,
      estMins: l.estMins,
    )).toList();
  }

  @override
  Future<Lesson?> getLesson(String id) async {
    final lessons = await (_database.select(_database.lessons)..where((l) => l.id.equals(id))).get();
    if (lessons.isEmpty) return null;
    
    final lesson = lessons.first;
    return Lesson(
      id: lesson.id,
      moduleId: lesson.moduleId,
      title: lesson.title,
      bodyMarkdown: lesson.bodyMarkdown,
      estMins: lesson.estMins,
    );
  }
} 