// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attempt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Attempt _$AttemptFromJson(Map<String, dynamic> json) {
  return _Attempt.fromJson(json);
}

/// @nodoc
mixin _$Attempt {
  String get id => throw _privateConstructorUsedError;
  String get assessmentId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime get finishedAt => throw _privateConstructorUsedError;
  Map<String, int> get answersJson => throw _privateConstructorUsedError;

  /// Serializes this Attempt to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Attempt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AttemptCopyWith<Attempt> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttemptCopyWith<$Res> {
  factory $AttemptCopyWith(Attempt value, $Res Function(Attempt) then) =
      _$AttemptCopyWithImpl<$Res, Attempt>;
  @useResult
  $Res call(
      {String id,
      String assessmentId,
      String userId,
      double score,
      DateTime startedAt,
      DateTime finishedAt,
      Map<String, int> answersJson});
}

/// @nodoc
class _$AttemptCopyWithImpl<$Res, $Val extends Attempt>
    implements $AttemptCopyWith<$Res> {
  _$AttemptCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Attempt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? assessmentId = null,
    Object? userId = null,
    Object? score = null,
    Object? startedAt = null,
    Object? finishedAt = null,
    Object? answersJson = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      assessmentId: null == assessmentId
          ? _value.assessmentId
          : assessmentId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      finishedAt: null == finishedAt
          ? _value.finishedAt
          : finishedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      answersJson: null == answersJson
          ? _value.answersJson
          : answersJson // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttemptImplCopyWith<$Res> implements $AttemptCopyWith<$Res> {
  factory _$$AttemptImplCopyWith(
          _$AttemptImpl value, $Res Function(_$AttemptImpl) then) =
      __$$AttemptImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String assessmentId,
      String userId,
      double score,
      DateTime startedAt,
      DateTime finishedAt,
      Map<String, int> answersJson});
}

/// @nodoc
class __$$AttemptImplCopyWithImpl<$Res>
    extends _$AttemptCopyWithImpl<$Res, _$AttemptImpl>
    implements _$$AttemptImplCopyWith<$Res> {
  __$$AttemptImplCopyWithImpl(
      _$AttemptImpl _value, $Res Function(_$AttemptImpl) _then)
      : super(_value, _then);

  /// Create a copy of Attempt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? assessmentId = null,
    Object? userId = null,
    Object? score = null,
    Object? startedAt = null,
    Object? finishedAt = null,
    Object? answersJson = null,
  }) {
    return _then(_$AttemptImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      assessmentId: null == assessmentId
          ? _value.assessmentId
          : assessmentId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      finishedAt: null == finishedAt
          ? _value.finishedAt
          : finishedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      answersJson: null == answersJson
          ? _value._answersJson
          : answersJson // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttemptImpl implements _Attempt {
  const _$AttemptImpl(
      {required this.id,
      required this.assessmentId,
      required this.userId,
      required this.score,
      required this.startedAt,
      required this.finishedAt,
      required final Map<String, int> answersJson})
      : _answersJson = answersJson;

  factory _$AttemptImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttemptImplFromJson(json);

  @override
  final String id;
  @override
  final String assessmentId;
  @override
  final String userId;
  @override
  final double score;
  @override
  final DateTime startedAt;
  @override
  final DateTime finishedAt;
  final Map<String, int> _answersJson;
  @override
  Map<String, int> get answersJson {
    if (_answersJson is EqualUnmodifiableMapView) return _answersJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_answersJson);
  }

  @override
  String toString() {
    return 'Attempt(id: $id, assessmentId: $assessmentId, userId: $userId, score: $score, startedAt: $startedAt, finishedAt: $finishedAt, answersJson: $answersJson)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttemptImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.assessmentId, assessmentId) ||
                other.assessmentId == assessmentId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.finishedAt, finishedAt) ||
                other.finishedAt == finishedAt) &&
            const DeepCollectionEquality()
                .equals(other._answersJson, _answersJson));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, assessmentId, userId, score,
      startedAt, finishedAt, const DeepCollectionEquality().hash(_answersJson));

  /// Create a copy of Attempt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttemptImplCopyWith<_$AttemptImpl> get copyWith =>
      __$$AttemptImplCopyWithImpl<_$AttemptImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttemptImplToJson(
      this,
    );
  }
}

abstract class _Attempt implements Attempt {
  const factory _Attempt(
      {required final String id,
      required final String assessmentId,
      required final String userId,
      required final double score,
      required final DateTime startedAt,
      required final DateTime finishedAt,
      required final Map<String, int> answersJson}) = _$AttemptImpl;

  factory _Attempt.fromJson(Map<String, dynamic> json) = _$AttemptImpl.fromJson;

  @override
  String get id;
  @override
  String get assessmentId;
  @override
  String get userId;
  @override
  double get score;
  @override
  DateTime get startedAt;
  @override
  DateTime get finishedAt;
  @override
  Map<String, int> get answersJson;

  /// Create a copy of Attempt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttemptImplCopyWith<_$AttemptImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
