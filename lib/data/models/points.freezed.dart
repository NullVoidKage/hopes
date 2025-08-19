// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'points.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Points _$PointsFromJson(Map<String, dynamic> json) {
  return _Points.fromJson(json);
}

/// @nodoc
mixin _$Points {
  String get userId => throw _privateConstructorUsedError;
  int get totalPoints => throw _privateConstructorUsedError;

  /// Serializes this Points to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Points
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PointsCopyWith<Points> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointsCopyWith<$Res> {
  factory $PointsCopyWith(Points value, $Res Function(Points) then) =
      _$PointsCopyWithImpl<$Res, Points>;
  @useResult
  $Res call({String userId, int totalPoints});
}

/// @nodoc
class _$PointsCopyWithImpl<$Res, $Val extends Points>
    implements $PointsCopyWith<$Res> {
  _$PointsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Points
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? totalPoints = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PointsImplCopyWith<$Res> implements $PointsCopyWith<$Res> {
  factory _$$PointsImplCopyWith(
          _$PointsImpl value, $Res Function(_$PointsImpl) then) =
      __$$PointsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String userId, int totalPoints});
}

/// @nodoc
class __$$PointsImplCopyWithImpl<$Res>
    extends _$PointsCopyWithImpl<$Res, _$PointsImpl>
    implements _$$PointsImplCopyWith<$Res> {
  __$$PointsImplCopyWithImpl(
      _$PointsImpl _value, $Res Function(_$PointsImpl) _then)
      : super(_value, _then);

  /// Create a copy of Points
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? totalPoints = null,
  }) {
    return _then(_$PointsImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PointsImpl implements _Points {
  const _$PointsImpl({required this.userId, required this.totalPoints});

  factory _$PointsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointsImplFromJson(json);

  @override
  final String userId;
  @override
  final int totalPoints;

  @override
  String toString() {
    return 'Points(userId: $userId, totalPoints: $totalPoints)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointsImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, totalPoints);

  /// Create a copy of Points
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointsImplCopyWith<_$PointsImpl> get copyWith =>
      __$$PointsImplCopyWithImpl<_$PointsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PointsImplToJson(
      this,
    );
  }
}

abstract class _Points implements Points {
  const factory _Points(
      {required final String userId,
      required final int totalPoints}) = _$PointsImpl;

  factory _Points.fromJson(Map<String, dynamic> json) = _$PointsImpl.fromJson;

  @override
  String get userId;
  @override
  int get totalPoints;

  /// Create a copy of Points
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointsImplCopyWith<_$PointsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
