// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BadgeImpl _$$BadgeImplFromJson(Map<String, dynamic> json) => _$BadgeImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      ruleJson: json['ruleJson'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$BadgeImplToJson(_$BadgeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'ruleJson': instance.ruleJson,
    };

_$UserBadgeImpl _$$UserBadgeImplFromJson(Map<String, dynamic> json) =>
    _$UserBadgeImpl(
      userId: json['userId'] as String,
      badgeId: json['badgeId'] as String,
      awardedAt: DateTime.parse(json['awardedAt'] as String),
    );

Map<String, dynamic> _$$UserBadgeImplToJson(_$UserBadgeImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'badgeId': instance.badgeId,
      'awardedAt': instance.awardedAt.toIso8601String(),
    };
