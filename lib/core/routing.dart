import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/role_select_screen.dart';
import '../features/student/dashboard/student_dashboard_screen.dart';
import '../features/student/lesson_reader/lesson_reader_screen.dart';
import '../features/student/quiz/quiz_screen.dart';
import '../features/student/progress/progress_screen.dart';
import '../features/teacher/panel_stub/teacher_panel_screen_stub.dart';
import 'providers.dart';
import '../data/models/user.dart';

// Create a provider for the router
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Get the current user from the provider
      final userAsync = ref.read(currentUserProvider);
      
      // If still loading, don't redirect yet
      if (userAsync.isLoading) return null;
      
      // If there's an error, stay on login
      if (userAsync.hasError) return null;
      
      final user = userAsync.value;
      
      // If no user, stay on login
      if (user == null) return null;
      
      // If we're on the login page and user is logged in, redirect based on role
      if (state.matchedLocation == '/') {
        if (user.role == UserRole.student) {
          return '/student/dashboard';
        } else if (user.role == UserRole.teacher) {
          return '/teacher/panel';
        }
      }
      
      // If we're on role-select page and user is logged in, redirect based on role
      if (state.matchedLocation == '/role-select') {
        if (user.role == UserRole.student) {
          return '/student/dashboard';
        } else if (user.role == UserRole.teacher) {
          return '/teacher/panel';
        }
      }
      
      // If user is on student dashboard but has teacher role, redirect to teacher panel
      if (state.matchedLocation == '/student/dashboard' && user.role == UserRole.teacher) {
        print('Redirecting from student dashboard to teacher panel'); // Debug log
        return '/teacher/panel';
      }
      
      // If user is on teacher panel but has student role, redirect to student dashboard
      if (state.matchedLocation == '/teacher/panel' && user.role == UserRole.student) {
        print('Redirecting from teacher panel to student dashboard'); // Debug log
        return '/student/dashboard';
      }
      
      return null;
    },
    routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/role-select',
      builder: (context, state) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: '/student/dashboard',
      builder: (context, state) => const StudentDashboardScreen(),
    ),
    GoRoute(
      path: '/student/lesson/:lessonId',
      builder: (context, state) {
        final lessonId = state.pathParameters['lessonId']!;
        return LessonReaderScreen(
          lessonId: lessonId,
          lessonTitle: 'Lesson', // Default title, could be enhanced later
        );
      },
    ),
    GoRoute(
      path: '/student/quiz/:assessmentId',
      builder: (context, state) {
        final assessmentId = state.pathParameters['assessmentId']!;
        return QuizScreen(assessmentId: assessmentId);
      },
    ),
          GoRoute(
        path: '/student/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
    GoRoute(
      path: '/teacher/panel',
      builder: (context, state) => const TeacherPanelScreen(),
    ),
  ],
  );
});

// Keep the old router for backward compatibility
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/role-select',
      builder: (context, state) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: '/student/dashboard',
      builder: (context, state) => const StudentDashboardScreen(),
    ),
    GoRoute(
      path: '/student/lesson/:lessonId',
      builder: (context, state) {
        final lessonId = state.pathParameters['lessonId']!;
        return LessonReaderScreen(
          lessonId: lessonId,
          lessonTitle: 'Lesson', // Default title, could be enhanced later
        );
      },
    ),
    GoRoute(
      path: '/student/quiz/:assessmentId',
      builder: (context, state) {
        final assessmentId = state.pathParameters['assessmentId']!;
        return QuizScreen(assessmentId: assessmentId);
      },
    ),
    GoRoute(
      path: '/student/progress',
      builder: (context, state) => const ProgressScreen(),
    ),
    GoRoute(
      path: '/teacher/panel',
      builder: (context, state) => const TeacherPanelScreen(),
    ),
  ],
); 