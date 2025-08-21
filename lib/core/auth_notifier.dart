import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import '../services/auth_service.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      state = const AsyncValue.loading();
      
      final firebaseUser = _authService.user;
      
      if (firebaseUser != null) {
        final user = User(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Unknown User',
          email: firebaseUser.email ?? '',
          role: UserRole.student, // Default role
          section: '7-A', // Default section
        );
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (error, stackTrace) {
      print('Error loading current user: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();
      final error = await _authService.signInWithGoogle();
      
      if (error != null) {
        state = AsyncValue.error(error, StackTrace.current);
        return;
      }

      // Reload user after successful sign-in
      await _loadCurrentUser();
    } catch (error, stackTrace) {
      print('Error signing in with Google: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateRole(UserRole role) async {
    try {
      final currentUser = state.value;
      if (currentUser == null) return;

      print('Updating role from ${currentUser.role} to $role'); // Debug log
      state = const AsyncValue.loading();
      
      // Update local state
      final updatedUser = currentUser.copyWith(role: role);
      state = AsyncValue.data(updatedUser);
      
      print('Role updated successfully to ${updatedUser.role}'); // Debug log
    } catch (error, stackTrace) {
      print('Error updating role: $error'); // Debug log
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSection(String section) async {
    try {
      final currentUser = state.value;
      if (currentUser == null) return;

      state = const AsyncValue.loading();
      
      // Update local state
      final updatedUser = currentUser.copyWith(section: section);
      state = AsyncValue.data(updatedUser);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
} 