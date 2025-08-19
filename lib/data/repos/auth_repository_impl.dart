import 'dart:convert';
import 'package:drift/drift.dart';
import '../db/database.dart' as db;
import '../models/user.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final db.HopesDatabase _database;

  AuthRepositoryImpl(this._database);

  @override
  Future<User?> getCurrentUser() async {
    final users = await _database.select(_database.users).get();
    if (users.isEmpty) return null;
    
    final user = users.first;
    return User(
      id: user.id,
      name: user.name,
      email: user.email,
      role: _convertUserRole(user.role),
      section: user.section,
    );
  }

  UserRole _convertUserRole(db.UserRole dbRole) {
    switch (dbRole) {
      case db.UserRole.student:
        return UserRole.student;
      case db.UserRole.teacher:
        return UserRole.teacher;
    }
  }

  @override
  Future<User> createUser({
    required String name,
    required String email,
    required UserRole role,
    String? section,
  }) async {
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    
    await _database.into(_database.users).insert(
      db.UsersCompanion.insert(
        id: userId,
        name: name,
        email: email,
        role: _convertToDbUserRole(role),
        section: Value(section),
      ),
    );

    return User(
      id: userId,
      name: name,
      email: email,
      role: role,
      section: section,
    );
  }

  db.UserRole _convertToDbUserRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return db.UserRole.student;
      case UserRole.teacher:
        return db.UserRole.teacher;
    }
  }

  @override
  Future<User> updateUserRole(String userId, UserRole role) async {
    await (_database.update(_database.users)..where((u) => u.id.equals(userId)))
        .write(db.UsersCompanion(role: Value(_convertToDbUserRole(role))));

    final user = await (_database.select(_database.users)..where((u) => u.id.equals(userId))).getSingle();
    
    return User(
      id: user.id,
      name: user.name,
      email: user.email,
      role: _convertUserRole(user.role),
      section: user.section,
    );
  }

  @override
  Future<void> signOut() async {
    await _database.delete(_database.users).go();
  }

  @override
  Future<User> createDemoUser() async {
    return createUser(
      name: 'Demo Student',
      email: 'demo@hopes.edu',
      role: UserRole.student,
      section: '7-A',
    );
  }
} 