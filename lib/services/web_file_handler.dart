import 'package:flutter/foundation.dart';

// Conditional imports for web platform
import 'web_file_handler_stub.dart'
    if (dart.library.html) 'web_file_handler_web.dart'
    as web_handler;

class WebFileHandler {
  /// Enhanced file download for web platform
  static Future<bool> downloadFile(String url, String fileName) async {
    return web_handler.WebFileHandler.downloadFile(url, fileName);
  }

  /// Enhanced PDF preview for web platform
  static Future<bool> openPdfPreview(String url) async {
    return web_handler.WebFileHandler.openPdfPreview(url);
  }

  /// Open file in new tab (fallback method)
  static Future<bool> openInNewTab(String url) async {
    return web_handler.WebFileHandler.openInNewTab(url);
  }

  /// Check if the current browser supports file downloads
  static bool get supportsFileDownload {
    return web_handler.WebFileHandler.supportsFileDownload;
  }

  /// Get browser name for user feedback
  static String get browserName {
    return web_handler.WebFileHandler.browserName;
  }
}
