import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import '../data/repos/auth_repository.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      state = const AsyncValue.loading();
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signIn({
    required String name,
    required String email,
    required UserRole role,
    String? section,
  }) async {
    try {
      state = const AsyncValue.loading();
      final user = await _authRepository.createUser(
        name: name,
        email: email,
        role: role,
        section: section,
      );
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createDemoUser() async {
    try {
      state = const AsyncValue.loading();
      final user = await _authRepository.createDemoUser();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateRole(UserRole role) async {
    try {
      final currentUser = state.value;
      if (currentUser == null) return;

      state = const AsyncValue.loading();
      final updatedUser = await _authRepository.updateUserRole(currentUser.id, role);
      state = AsyncValue.data(updatedUser);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
} 