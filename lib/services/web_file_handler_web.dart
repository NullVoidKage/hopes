import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Web-specific implementation for file handling
class WebFileHandler {
  /// Enhanced file download for web platform
  static Future<bool> downloadFile(String url, String fileName) async {
    try {
      // Create a temporary anchor element for download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..setAttribute('target', '_blank')
        ..style.display = 'none';
      
      // Add to DOM temporarily
      html.document.body?.append(anchor);
      
      // Trigger download
      anchor.click();
      
      // Clean up after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        anchor.remove();
      });
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Web download failed: $e');
      }
      return false;
    }
  }

  /// Enhanced PDF preview for web platform
  static Future<bool> openPdfPreview(String url) async {
    try {
      // Open PDF in a new tab with proper headers for PDF viewing
      final newWindow = html.window.open('', '_blank');
      newWindow.location.href = url;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('PDF preview failed: $e');
      }
      return false;
    }
  }

  /// Open file in new tab (fallback method)
  static Future<bool> openInNewTab(String url) async {
    try {
      html.window.open(url, '_blank');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Open in new tab failed: $e');
      }
      return false;
    }
  }

  /// Check if the current browser supports file downloads
  static bool get supportsFileDownload {
    try {
      return html.window.navigator.userAgent.contains('Chrome') ||
             html.window.navigator.userAgent.contains('Firefox') ||
             html.window.navigator.userAgent.contains('Safari') ||
             html.window.navigator.userAgent.contains('Edge');
    } catch (e) {
      return true; // Assume support if we can't detect
    }
  }

  /// Get browser name for user feedback
  static String get browserName {
    try {
      final userAgent = html.window.navigator.userAgent;
      if (userAgent.contains('Chrome')) return 'Chrome';
      if (userAgent.contains('Firefox')) return 'Firefox';
      if (userAgent.contains('Safari')) return 'Safari';
      if (userAgent.contains('Edge')) return 'Edge';
      return 'Browser';
    } catch (e) {
      return 'Browser';
    }
  }
}
