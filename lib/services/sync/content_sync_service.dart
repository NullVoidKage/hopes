import 'dart:convert';
import 'package:drift/drift.dart';
import '../../data/db/database.dart' as db;
import '../../data/models/sync_queue.dart';

abstract class ContentSyncService {
  Future<bool> syncContent();
  Future<bool> checkForUpdates();
  Future<String> getLatestVersion(String subjectId);
  Future<void> queueContentChange(String entityTable, SyncOperation operation, String recordId, Map<String, dynamic> data);
  Future<void> processSyncQueue();
}

class ContentSyncServiceImpl implements ContentSyncService {
  final db.HopesDatabase _database;
  bool _isOnline = true; // Simulate online status

  ContentSyncServiceImpl(this._database);

  @override
  Future<bool> syncContent() async {
    try {
      if (!_isOnline) {
        return false; // Queue changes for later sync
      }

      await processSyncQueue();
      return true;
    } catch (e) {
      print('Content sync error: $e');
      return false;
    }
  }

  @override
  Future<bool> checkForUpdates() async {
    // Simulate checking for updates
    await Future.delayed(const Duration(milliseconds: 500));
    return _isOnline && DateTime.now().millisecondsSinceEpoch % 3 == 0; // 33% chance of updates
  }

  @override
  Future<String> getLatestVersion(String subjectId) async {
    // Simulate getting latest version from server
    await Future.delayed(const Duration(milliseconds: 200));
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  Future<void> queueContentChange(
    String entityTable,
    SyncOperation operation,
    String recordId,
    Map<String, dynamic> data,
  ) async {
    final syncItem = db.SyncQueueCompanion.insert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      entityTable: entityTable,
      operation: operation.name,
      recordId: recordId,
      dataJson: jsonEncode(data),
      createdAt: DateTime.now(),
      isSynced: false,
    );

    await _database.into(_database.syncQueue).insert(syncItem);
  }

  @override
  Future<void> processSyncQueue() async {
    if (!_isOnline) return;

    final pendingItems = await (_database.select(_database.syncQueue)
          ..where((tbl) => tbl.isSynced.equals(false)))
        .get();

    for (final item in pendingItems) {
      try {
        // Simulate sending to server
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Mark as synced
        await (_database.update(_database.syncQueue)
              ..where((tbl) => tbl.id.equals(item.id)))
            .write(const db.SyncQueueCompanion(isSynced: Value(true)));
      } catch (e) {
        print('Failed to sync item ${item.id}: $e');
      }
    }
  }

  // Method to simulate online/offline status
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
  }

  bool get isOnline => _isOnline;
} 