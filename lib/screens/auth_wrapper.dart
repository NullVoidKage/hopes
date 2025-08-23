import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'signin_screen.dart';
import 'role_selection_screen.dart';
import 'student_dashboard.dart';
import 'teacher_panel.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          
          // Use FutureBuilder to handle profile loading
          return FutureBuilder<UserModel?>(
            future: _authService.getUserProfile(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }
              
              if (profileSnapshot.hasError) {
                // Error loading profile, likely user doesn't have one yet
                return RoleSelectionScreen(
                  uid: user.uid,
                  email: user.email!,
                  displayName: user.displayName ?? 'User',
                  photoURL: user.photoURL,
                );
              }
              
              final userProfile = profileSnapshot.data;
              
              if (userProfile == null) {
                // No profile exists, show role selection
                return RoleSelectionScreen(
                  uid: user.uid,
                  email: user.email!,
                  displayName: user.displayName ?? 'User',
                  photoURL: user.photoURL,
                );
              } else {
                // Profile exists, route based on role
                if (userProfile.isStudent) {
                  return const StudentDashboard();
                } else if (userProfile.isTeacher) {
                  return const TeacherPanel();
                } else {
                  // Fallback to sign in for unknown roles
                  return const SignInScreen();
                }
              }
            },
          );
        }
        
        // User is not signed in
        return const SignInScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(0xFF667eea),
          ),
        ),
      ),
    );
  }
}
