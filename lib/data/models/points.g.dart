// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PointsImpl _$$PointsImplFromJson(Map<String, dynamic> json) => _$PointsImpl(
      userId: json['userId'] as String,
      totalPoints: (json['totalPoints'] as num).toInt(),
    );

Map<String, dynamic> _$$PointsImplToJson(_$PointsImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'totalPoints': instance.totalPoints,
    };
