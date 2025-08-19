import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress.freezed.dart';
part 'progress.g.dart';

enum ProgressStatus { locked, inProgress, mastered }

@freezed
class Progress with _$Progress {
  const factory Progress({
    required String userId,
    required String lessonId,
    required ProgressStatus status,
    double? lastScore,
    @Default(0) int attemptCount,
    required DateTime updatedAt,
  }) = _Progress;

  factory Progress.fromJson(Map<String, dynamic> json) => _$ProgressFromJson(json);
} 