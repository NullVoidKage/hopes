import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'database.dart';

class SeedImporter {
  final HopesDatabase _database;

  SeedImporter(this._database);

  Future<bool> importSeedData() async {
    try {
      // Check if data already exists
      final existingSubjects = await _database.select(_database.subjects).get();
      if (existingSubjects.isNotEmpty) {
        return false; // Data already imported
      }

      // Load seed data from JSON
      final jsonString = await rootBundle.loadString('assets/seed/grade7_science.json');
      final seedData = json.decode(jsonString) as Map<String, dynamic>;

      // Import subject
      await _database.into(_database.subjects).insert(
        SubjectsCompanion.insert(
          id: seedData['subject']['id'],
          name: seedData['subject']['name'],
          gradeLevel: seedData['subject']['gradeLevel'],
        ),
      );

      // Import module
      await _database.into(_database.modules).insert(
        ModulesCompanion.insert(
          id: seedData['module']['id'],
          subjectId: seedData['module']['subjectId'],
          title: seedData['module']['title'],
          version: seedData['module']['version'],
          isPublished: seedData['module']['isPublished'],
        ),
      );

      // Import lessons
      for (final lessonData in seedData['lessons']) {
        await _database.into(_database.lessons).insert(
          LessonsCompanion.insert(
            id: lessonData['id'],
            moduleId: lessonData['moduleId'],
            title: lessonData['title'],
            bodyMarkdown: lessonData['bodyMarkdown'],
            estMins: lessonData['estMins'],
          ),
        );
      }

      // Import assessments
      for (final assessmentData in seedData['assessments']) {
        await _database.into(_database.assessments).insert(
          AssessmentsCompanion.insert(
            id: assessmentData['id'],
            lessonId: Value(assessmentData['lessonId']),
            type: AssessmentType.values.firstWhere(
              (e) => e.name == assessmentData['type'],
            ),
            itemsJson: json.encode(assessmentData['items']),
          ),
        );
      }

      // Create content version
      await _database.into(_database.contentVersions).insert(
        ContentVersionsCompanion.insert(
          id: 'science_7_v1',
          subjectId: seedData['subject']['id'],
          version: '1.0.0',
          updatedAt: DateTime.now(),
        ),
      );

      return true; // Successfully imported
    } catch (e) {
      print('Error importing seed data: $e');
      return false;
    }
  }
} 