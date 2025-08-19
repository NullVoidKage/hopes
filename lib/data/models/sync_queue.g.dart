// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SyncQueueItemImpl _$$SyncQueueItemImplFromJson(Map<String, dynamic> json) =>
    _$SyncQueueItemImpl(
      id: json['id'] as String,
      entityTable: json['entityTable'] as String,
      operation: $enumDecode(_$SyncOperationEnumMap, json['operation']),
      recordId: json['recordId'] as String,
      dataJson: json['dataJson'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isSynced: json['isSynced'] as bool,
    );

Map<String, dynamic> _$$SyncQueueItemImplToJson(_$SyncQueueItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'entityTable': instance.entityTable,
      'operation': _$SyncOperationEnumMap[instance.operation]!,
      'recordId': instance.recordId,
      'dataJson': instance.dataJson,
      'createdAt': instance.createdAt.toIso8601String(),
      'isSynced': instance.isSynced,
    };

const _$SyncOperationEnumMap = {
  SyncOperation.create: 'create',
  SyncOperation.update: 'update',
  SyncOperation.delete: 'delete',
};
