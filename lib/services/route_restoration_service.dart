import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Service to save and restore routes for web reload
class RouteRestorationService {
  static const String _routeKey = 'last_route';
  
  /// Save the current route
  static Future<void> saveRoute(String route) async {
    if (!kIsWeb) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_routeKey, route);
    } catch (e) {
      // Silently fail
    }
  }
  
  /// Get the last saved route
  static Future<String?> getLastRoute() async {
    if (!kIsWeb) return null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_routeKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Clear the saved route
  static Future<void> clearRoute() async {
    if (!kIsWeb) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_routeKey);
    } catch (e) {
      // Silently fail
    }
  }
}

