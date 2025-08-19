import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_version.freezed.dart';
part 'content_version.g.dart';

@freezed
class ContentVersion with _$ContentVersion {
  const factory ContentVersion({
    required String id,
    required String subjectId,
    required String version,
    required DateTime updatedAt,
  }) = _ContentVersion;

  factory ContentVersion.fromJson(Map<String, dynamic> json) => _$ContentVersionFromJson(json);
} 