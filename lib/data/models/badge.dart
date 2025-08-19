import 'package:freezed_annotation/freezed_annotation.dart';

part 'badge.freezed.dart';
part 'badge.g.dart';

@freezed
class Badge with _$Badge {
  const factory Badge({
    required String id,
    required String name,
    required Map<String, dynamic> ruleJson,
  }) = _Badge;

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
}

@freezed
class UserBadge with _$UserBadge {
  const factory UserBadge({
    required String userId,
    required String badgeId,
    required DateTime awardedAt,
  }) = _UserBadge;

  factory UserBadge.fromJson(Map<String, dynamic> json) => _$UserBadgeFromJson(json);
} 