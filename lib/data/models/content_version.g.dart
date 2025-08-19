// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContentVersionImpl _$$ContentVersionImplFromJson(Map<String, dynamic> json) =>
    _$ContentVersionImpl(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      version: json['version'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ContentVersionImplToJson(
        _$ContentVersionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subjectId': instance.subjectId,
      'version': instance.version,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
