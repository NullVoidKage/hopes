import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

@freezed
class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(String message) = Failure<T>;
}

@freezed
class AsyncResult<T> with _$AsyncResult<T> {
  const factory AsyncResult.initial() = Initial<T>;
  const factory AsyncResult.loading() = Loading<T>;
  const factory AsyncResult.success(T data) = AsyncSuccess<T>;
  const factory AsyncResult.failure(String message) = AsyncFailure<T>;
} 