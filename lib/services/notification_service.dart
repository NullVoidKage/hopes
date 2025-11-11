import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: kIsWeb, // Web requires provisional permission
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        String? token;
        try {
          token = await _messaging.getToken(
            vapidKey: kIsWeb 
                ? 'BPlvl_JDPkHVgw027DjOGjKJ0rgxLuVbTNMizi4yJsCPjHV9mXe50fVdeGCEPqoXqds17cBWTE8_Jv2Mr5qSNG0' // VAPID public key for web push notifications
                : null,
          );
        } catch (e) {
          // On web, if VAPID key is not set, token will be null
          // This is okay - notifications will still be stored in database
          if (kIsWeb) {
            // Web push notifications require VAPID key setup
            // For now, we'll just store notifications in database
          }
        }
        
        if (token != null) {
          await _saveToken(token);
        }

        // Listen for token refresh (works on mobile, web needs service worker)
        if (!kIsWeb) {
          _messaging.onTokenRefresh.listen((newToken) {
            _saveToken(newToken);
          });
        }
      }
    } catch (e) {
      // Handle errors gracefully - notifications will still work via database
    }
  }

  // Save FCM token to Realtime Database
  Future<void> _saveToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _database.ref('user_tokens/$userId').set({
          'token': token,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Send notification to all students when teacher uploads content
  Future<void> notifyStudentsAboutNewContent({
    required String title,
    required String body,
    required String type, // 'assessment' or 'lesson'
    required String contentId,
    required String subject,
  }) async {
    try {
      // Get all student tokens from Realtime Database
      final tokensSnapshot = await _database.ref('user_tokens').get();
      
      if (!tokensSnapshot.exists) return;

      final tokens = <String>[];
      tokensSnapshot.children.forEach((child) {
        final tokenData = child.value as Map<dynamic, dynamic>?;
        if (tokenData != null && tokenData['token'] != null) {
          tokens.add(tokenData['token'].toString());
        }
      });

      if (tokens.isEmpty) return;

      // Store notification in database for students to see
      final notificationRef = _database.ref('notifications').push();
      await notificationRef.set({
        'title': title,
        'body': body,
        'type': type,
        'contentId': contentId,
        'subject': subject,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'read': false,
      });

      // Note: For actual push notifications, you would need to use Firebase Cloud Functions
      // or a backend service to send notifications to multiple tokens
      // This is a simplified version that stores notifications in the database
      // Students can check the notifications node to see new content
    } catch (e) {
      // Handle error silently
    }
  }

  // Get notifications for current user
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _database.ref('notifications').get();
      if (!snapshot.exists) return [];

      final notifications = <Map<String, dynamic>>[];
      snapshot.children.forEach((child) {
        final data = child.value as Map<dynamic, dynamic>?;
        if (data != null) {
          notifications.add({
            'id': child.key,
            ...data.map((key, value) => MapEntry(key.toString(), value)),
          });
        }
      });

      // Sort by createdAt descending
      notifications.sort((a, b) {
        final aTime = a['createdAt'] as int? ?? 0;
        final bTime = b['createdAt'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      return notifications;
    } catch (e) {
      return [];
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _database.ref('notifications/$notificationId/read').set(true);
    } catch (e) {
      // Handle error silently
    }
  }
}

