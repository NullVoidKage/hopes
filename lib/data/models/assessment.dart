import 'package:freezed_annotation/freezed_annotation.dart';

part 'assessment.freezed.dart';
part 'assessment.g.dart';

enum AssessmentType { pre, quiz }

@freezed
class Question with _$Question {
  const factory Question({
    required String id,
    required String text,
    required List<String> choices,
    required int correctIndex,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);
}

@freezed
class Assessment with _$Assessment {
  const factory Assessment({
    required String id,
    String? lessonId,
    required AssessmentType type,
    required List<Question> items,
  }) = _Assessment;

  factory Assessment.fromJson(Map<String, dynamic> json) => _$AssessmentFromJson(json);
} 