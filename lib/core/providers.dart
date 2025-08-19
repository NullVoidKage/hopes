import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db/database.dart' as db;
import '../data/db/seed_importer.dart';
import '../data/repos/auth_repository.dart';
import '../data/repos/auth_repository_impl.dart';
import '../data/repos/content_repository.dart';
import '../data/repos/content_repository_impl.dart';
import '../data/repos/assessment_repository.dart';
import '../data/repos/assessment_repository_impl.dart';
import '../data/repos/progress_repository.dart';
import '../data/repos/progress_repository_impl.dart';
import '../services/sync/content_sync_service.dart';
import '../services/sync/progress_sync_service.dart';
import 'auth_notifier.dart';
import '../data/models/user.dart';

// Database provider
final databaseProvider = Provider<db.HopesDatabase>((ref) {
  return db.HopesDatabase();
});

// Seed importer provider
final seedImporterProvider = Provider<SeedImporter>((ref) {
  final database = ref.watch(databaseProvider);
  return SeedImporter(database);
});

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return AuthRepositoryImpl(database);
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ContentRepositoryImpl(database);
});

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return AssessmentRepositoryImpl(database);
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ProgressRepositoryImpl(database);
});

// Current user provider
final currentUserProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

// Seed data provider
final seedDataProvider = FutureProvider<bool>((ref) async {
  final seedImporter = ref.watch(seedImporterProvider);
  return await seedImporter.importSeedData();
});

// Sync service providers
final contentSyncServiceProvider = Provider<ContentSyncService>((ref) {
  final database = ref.watch(databaseProvider);
  return ContentSyncServiceImpl(database);
});

final progressSyncServiceProvider = Provider<ProgressSyncService>((ref) {
  final database = ref.watch(databaseProvider);
  return ProgressSyncServiceImpl(database);
}); 