import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativeFileOpener {
  static const MethodChannel _channel = MethodChannel('native_file_opener');
  
  static Future<bool> openFile(String url, String fileName, BuildContext context) async {
    try {
      if (kDebugMode) {
        print('NativeFileOpener: Attempting to open $fileName');
        print('URL: $url');
      }
      
      // Show loading message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening $fileName...'),
            backgroundColor: const Color(0xFF007AFF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Try to open using native method channel
      final bool result = await _channel.invokeMethod('openFile', {
        'url': url,
        'fileName': fileName,
      });
      
      if (result) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $fileName in external app...'),
              backgroundColor: const Color(0xFF34C759),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return true;
      } else {
        throw Exception('Failed to open file');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NativeFileOpener error: $e');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open $fileName: $e'),
            backgroundColor: const Color(0xFFFF3B30),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }
  
  static Future<bool> openInBrowser(String url, BuildContext context) async {
    try {
      if (kDebugMode) {
        print('NativeFileOpener: Attempting to open in browser: $url');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Opening in browser...'),
            backgroundColor: const Color(0xFF007AFF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Try to open using native method channel
      final bool result = await _channel.invokeMethod('openInBrowser', {
        'url': url,
      });
      
      if (result) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opened in browser successfully'),
              backgroundColor: Color(0xFF34C759),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return true;
      } else {
        throw Exception('Failed to open in browser');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NativeFileOpener browser error: $e');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open in browser: $e'),
            backgroundColor: const Color(0xFFFF3B30),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }
}
