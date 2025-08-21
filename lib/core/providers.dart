import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../data/db/database.dart';
import '../data/models/module.dart';
import '../data/models/lesson.dart';
import '../data/models/progress.dart';
import 'auth_notifier.dart';
import '../data/models/user.dart';

// Database provider
final databaseProvider = Provider<Database>((ref) {
  return Database();
});

// Auth service provider
final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService();
});

// Current user provider
final currentUserProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Database providers for different collections
final subjectsProvider = FutureProvider((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getSubjects();
});

final modulesProvider = FutureProvider.family<List<Module>, String>((ref, subjectId) async {
  final database = ref.read(databaseProvider);
  return await database.getModules(subjectId);
});

final lessonsProvider = FutureProvider.family<List<Lesson>, String>((ref, moduleId) async {
  final database = ref.read(databaseProvider);
  return await database.getLessons(moduleId);
});

final userProgressProvider = FutureProvider.family<List<Progress>, String>((ref, userId) async {
  final database = ref.read(databaseProvider);
  return await database.getUserProgress(userId);
});

final userPointsProvider = FutureProvider.family<int, String>((ref, userId) async {
  final database = ref.read(databaseProvider);
  return await database.getUserPoints(userId);
}); 