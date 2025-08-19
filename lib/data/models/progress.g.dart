// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProgressImpl _$$ProgressImplFromJson(Map<String, dynamic> json) =>
    _$ProgressImpl(
      userId: json['userId'] as String,
      lessonId: json['lessonId'] as String,
      status: $enumDecode(_$ProgressStatusEnumMap, json['status']),
      lastScore: (json['lastScore'] as num?)?.toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ProgressImplToJson(_$ProgressImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'lessonId': instance.lessonId,
      'status': _$ProgressStatusEnumMap[instance.status]!,
      'lastScore': instance.lastScore,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ProgressStatusEnumMap = {
  ProgressStatus.locked: 'locked',
  ProgressStatus.inProgress: 'inProgress',
  ProgressStatus.mastered: 'mastered',
};
