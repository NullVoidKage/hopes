import 'dart:convert';
import 'package:drift/drift.dart';
import '../db/database.dart' as db;
import '../models/assessment.dart';
import '../models/attempt.dart';
import 'assessment_repository.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final db.HopesDatabase _database;

  AssessmentRepositoryImpl(this._database);

  @override
  Future<List<Assessment>> getAssessmentsByLesson(String lessonId) async {
    final assessments = await (_database.select(_database.assessments)..where((a) => a.lessonId.equals(lessonId))).get();
    return assessments.map((a) => _convertAssessment(a)).toList();
  }

  @override
  Future<Assessment?> getAssessment(String id) async {
    final assessments = await (_database.select(_database.assessments)..where((a) => a.id.equals(id))).get();
    if (assessments.isEmpty) return null;
    
    return _convertAssessment(assessments.first);
  }

  @override
  Future<Assessment?> getPretest() async {
    final assessments = await (_database.select(_database.assessments)..where((a) => a.type.equals('pre'))).get();
    if (assessments.isEmpty) return null;
    
    return _convertAssessment(assessments.first);
  }

  @override
  Future<Attempt> createAttempt({
    required String assessmentId,
    required String userId,
    required Map<String, int> answers,
  }) async {
    final attemptId = DateTime.now().millisecondsSinceEpoch.toString();
    final assessment = await getAssessment(assessmentId);
    if (assessment == null) {
      throw Exception('Assessment not found');
    }

    final score = await calculateScore(assessment, answers);
    final now = DateTime.now();

    await _database.into(_database.attempts).insert(
      db.AttemptsCompanion.insert(
        id: attemptId,
        assessmentId: assessmentId,
        userId: userId,
        score: score,
        startedAt: now,
        finishedAt: now,
        answersJson: json.encode(answers),
      ),
    );

    return Attempt(
      id: attemptId,
      assessmentId: assessmentId,
      userId: userId,
      score: score,
      startedAt: now,
      finishedAt: now,
      answersJson: answers,
    );
  }

  @override
  Future<List<Attempt>> getAttemptsByUser(String userId) async {
    final attempts = await (_database.select(_database.attempts)..where((a) => a.userId.equals(userId))).get();
    return attempts.map((a) => Attempt(
      id: a.id,
      assessmentId: a.assessmentId,
      userId: a.userId,
      score: a.score,
      startedAt: a.startedAt,
      finishedAt: a.finishedAt,
      answersJson: Map<String, int>.from(json.decode(a.answersJson) as Map<String, dynamic>),
    )).toList();
  }

  @override
  Future<Attempt?> getAttempt(String id) async {
    final attempts = await (_database.select(_database.attempts)..where((a) => a.id.equals(id))).get();
    if (attempts.isEmpty) return null;
    
    final attempt = attempts.first;
    return Attempt(
      id: attempt.id,
      assessmentId: attempt.assessmentId,
      userId: attempt.userId,
      score: attempt.score,
      startedAt: attempt.startedAt,
      finishedAt: attempt.finishedAt,
      answersJson: Map<String, int>.from(json.decode(attempt.answersJson) as Map<String, dynamic>),
    );
  }

  @override
  Future<double> calculateScore(Assessment assessment, Map<String, int> answers) async {
    int correctAnswers = 0;
    int totalQuestions = assessment.items.length;

    for (final question in assessment.items) {
      final userAnswer = answers[question.id];
      if (userAnswer != null && userAnswer == question.correctIndex) {
        correctAnswers++;
      }
    }

    return (correctAnswers / totalQuestions) * 100;
  }

  Assessment _convertAssessment(dynamic assessment) {
    final questions = json.decode(assessment.itemsJson) as List<dynamic>;
    return Assessment(
      id: assessment.id,
      lessonId: assessment.lessonId,
      type: _convertAssessmentType(assessment.type),
      items: questions.map((q) => Question(
        id: q['id'],
        text: q['text'],
        choices: List<String>.from(q['choices']),
        correctIndex: q['correctIndex'],
      )).toList(),
    );
  }

  AssessmentType _convertAssessmentType(db.AssessmentType type) {
    switch (type) {
      case db.AssessmentType.pre:
        return AssessmentType.pre;
      case db.AssessmentType.quiz:
        return AssessmentType.quiz;
    }
  }
} 