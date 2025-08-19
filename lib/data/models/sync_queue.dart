import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_queue.freezed.dart';
part 'sync_queue.g.dart';

enum SyncOperation { create, update, delete }

@freezed
class SyncQueueItem with _$SyncQueueItem {
  const factory SyncQueueItem({
    required String id,
    required String entityTable,
    required SyncOperation operation,
    required String recordId,
    required String dataJson,
    required DateTime createdAt,
    required bool isSynced,
  }) = _SyncQueueItem;

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => _$SyncQueueItemFromJson(json);
} 