// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttemptImpl _$$AttemptImplFromJson(Map<String, dynamic> json) =>
    _$AttemptImpl(
      id: json['id'] as String,
      assessmentId: json['assessmentId'] as String,
      userId: json['userId'] as String,
      score: (json['score'] as num).toDouble(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: DateTime.parse(json['finishedAt'] as String),
      answersJson: Map<String, int>.from(json['answersJson'] as Map),
    );

Map<String, dynamic> _$$AttemptImplToJson(_$AttemptImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'assessmentId': instance.assessmentId,
      'userId': instance.userId,
      'score': instance.score,
      'startedAt': instance.startedAt.toIso8601String(),
      'finishedAt': instance.finishedAt.toIso8601String(),
      'answersJson': instance.answersJson,
    };
