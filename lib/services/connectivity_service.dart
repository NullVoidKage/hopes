import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'offline_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  Timer? _connectivityTimer;
  bool _isConnected = true;
  bool _isInitialized = false;

  // Initialize the service
  void initialize() {
    if (_isInitialized) return;
    
    _checkConnectivity();
    _startPeriodicCheck();
    _isInitialized = true;
  }

  // Check connectivity status
  Future<void> _checkConnectivity() async {
    try {
      if (kIsWeb) {
        // For web, we'll assume connected (web doesn't have offline detection)
        _updateConnectionStatus(true);
      } else {
        // For mobile platforms, check actual connectivity
        final result = await InternetAddress.lookup('google.com');
        _updateConnectionStatus(result.isNotEmpty && result[0].rawAddress.isNotEmpty);
      }
    } catch (e) {
      _updateConnectionStatus(false);
    }
  }

  // Update connection status
  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      OfflineService.setOnlineStatus(isConnected);
      
      if (kDebugMode) {
        print('Connection status changed: ${isConnected ? 'Online' : 'Offline'}');
      }
    }
  }

  // Start periodic connectivity check
  void _startPeriodicCheck() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkConnectivity();
    });
  }

  // Toggle offline mode for testing
  void toggleOfflineMode() {
    _isConnected = !_isConnected;
    OfflineService.setOnlineStatus(_isConnected);
    
    if (kDebugMode) {
      print('🔌 Offline mode toggled: ${_isConnected ? 'Online' : 'Offline'}');
      print('🔌 shouldUseCachedData will now return: ${!_isConnected}');
    }
  }

  // Force offline mode for testing
  void forceOfflineMode() {
    _isConnected = false;
    OfflineService.setOnlineStatus(false);
    
    if (kDebugMode) {
      print('🔌 Forced offline mode');
      print('🔌 shouldUseCachedData will now return: true');
    }
  }

  // Force online mode for testing
  void forceOnlineMode() {
    _isConnected = true;
    OfflineService.setOnlineStatus(true);
    
    if (kDebugMode) {
      print('🔌 Forced online mode');
      print('🔌 shouldUseCachedData will now return: false');
    }
  }

  // Get current connection status
  bool get isConnected {
    if (!_isInitialized) {
      initialize();
      return true; // Default to online until we check
    }
    return _isConnected;
  }

  // Check if we should use cached data
  bool get shouldUseCachedData {
    if (!_isInitialized) {
      initialize();
      // Give it a moment to check connectivity, then return the result
      return false; // Default to online until we check
    }
    
    // For testing purposes, if we're in debug mode and manually toggled offline
    if (kDebugMode && !_isConnected) {
      return true;
    }
    
    // For web, we'll assume online unless manually toggled
    if (kIsWeb) {
      return !_isConnected;
    }
    
    return !_isConnected;
  }

  // Manual connectivity check
  Future<bool> checkConnectivity() async {
    if (!_isInitialized) {
      initialize();
    }
    await _checkConnectivity();
    return _isConnected;
  }

  // Dispose resources
  void dispose() {
    _connectivityTimer?.cancel();
    _isInitialized = false;
  }
}
