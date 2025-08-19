import 'package:freezed_annotation/freezed_annotation.dart';

part 'attempt.freezed.dart';
part 'attempt.g.dart';

@freezed
class Attempt with _$Attempt {
  const factory Attempt({
    required String id,
    required String assessmentId,
    required String userId,
    required double score,
    required DateTime startedAt,
    required DateTime finishedAt,
    required Map<String, int> answersJson, // questionId -> selectedChoiceIndex
  }) = _Attempt;

  factory Attempt.fromJson(Map<String, dynamic> json) => _$AttemptFromJson(json);
} 