import '../models/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> createUser({
    required String name,
    required String email,
    required UserRole role,
    String? section,
  });
  Future<User> updateUserRole(String userId, UserRole role);
  Future<void> signOut();
  Future<User> createDemoUser();
} 