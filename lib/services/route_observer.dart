import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'route_restoration_service.dart';

// Web-only imports
import 'dart:html' as html show window;

/// Route observer that syncs browser URL with Flutter navigation
class WebRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (kIsWeb) {
      _updateUrl(route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (kIsWeb && previousRoute != null) {
      _updateUrl(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (kIsWeb && newRoute != null) {
      _updateUrl(newRoute);
    }
  }

  void _updateUrl(Route<dynamic> route) {
    if (!kIsWeb) return;
    
    try {
      final routeName = route.settings.name ?? _getRouteName(route);
      if (routeName != null && routeName.isNotEmpty) {
        // Update browser URL without reloading
        html.window.history.pushState(null, '', routeName);
        // Save route for restoration on reload
        RouteRestorationService.saveRoute(routeName);
      }
    } catch (e) {
      // Silently fail if URL update doesn't work (e.g., on mobile)
      if (kIsWeb) {
        debugPrint('Error updating URL: $e');
      }
    }
  }

  String? _getRouteName(Route<dynamic> route) {
    // Try to extract route name from route settings
    if (route.settings.name != null) {
      return route.settings.name;
    }
    
    // Try to get route name from route's runtime type
    final routeType = route.runtimeType.toString();
    
    // Map common route types to URL paths
    if (routeType.contains('StudentDashboard')) return '/student';
    if (routeType.contains('TeacherPanel')) return '/teacher';
    if (routeType.contains('AdminDashboard')) return '/admin';
    if (routeType.contains('SignInScreen')) return '/signin';
    if (routeType.contains('WelcomeScreen')) return '/';
    
    return null;
  }
}

