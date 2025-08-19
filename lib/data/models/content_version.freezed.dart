// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_version.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ContentVersion _$ContentVersionFromJson(Map<String, dynamic> json) {
  return _ContentVersion.fromJson(json);
}

/// @nodoc
mixin _$ContentVersion {
  String get id => throw _privateConstructorUsedError;
  String get subjectId => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ContentVersion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContentVersion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContentVersionCopyWith<ContentVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentVersionCopyWith<$Res> {
  factory $ContentVersionCopyWith(
          ContentVersion value, $Res Function(ContentVersion) then) =
      _$ContentVersionCopyWithImpl<$Res, ContentVersion>;
  @useResult
  $Res call({String id, String subjectId, String version, DateTime updatedAt});
}

/// @nodoc
class _$ContentVersionCopyWithImpl<$Res, $Val extends ContentVersion>
    implements $ContentVersionCopyWith<$Res> {
  _$ContentVersionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentVersion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? subjectId = null,
    Object? version = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ContentVersionImplCopyWith<$Res>
    implements $ContentVersionCopyWith<$Res> {
  factory _$$ContentVersionImplCopyWith(_$ContentVersionImpl value,
          $Res Function(_$ContentVersionImpl) then) =
      __$$ContentVersionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String subjectId, String version, DateTime updatedAt});
}

/// @nodoc
class __$$ContentVersionImplCopyWithImpl<$Res>
    extends _$ContentVersionCopyWithImpl<$Res, _$ContentVersionImpl>
    implements _$$ContentVersionImplCopyWith<$Res> {
  __$$ContentVersionImplCopyWithImpl(
      _$ContentVersionImpl _value, $Res Function(_$ContentVersionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ContentVersion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? subjectId = null,
    Object? version = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ContentVersionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ContentVersionImpl implements _ContentVersion {
  const _$ContentVersionImpl(
      {required this.id,
      required this.subjectId,
      required this.version,
      required this.updatedAt});

  factory _$ContentVersionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContentVersionImplFromJson(json);

  @override
  final String id;
  @override
  final String subjectId;
  @override
  final String version;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ContentVersion(id: $id, subjectId: $subjectId, version: $version, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContentVersionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, subjectId, version, updatedAt);

  /// Create a copy of ContentVersion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContentVersionImplCopyWith<_$ContentVersionImpl> get copyWith =>
      __$$ContentVersionImplCopyWithImpl<_$ContentVersionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContentVersionImplToJson(
      this,
    );
  }
}

abstract class _ContentVersion implements ContentVersion {
  const factory _ContentVersion(
      {required final String id,
      required final String subjectId,
      required final String version,
      required final DateTime updatedAt}) = _$ContentVersionImpl;

  factory _ContentVersion.fromJson(Map<String, dynamic> json) =
      _$ContentVersionImpl.fromJson;

  @override
  String get id;
  @override
  String get subjectId;
  @override
  String get version;
  @override
  DateTime get updatedAt;

  /// Create a copy of ContentVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContentVersionImplCopyWith<_$ContentVersionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
