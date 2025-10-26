/// Stub implementation for non-web platforms
class WebFileHandler {
  /// Enhanced file download for web platform
  static Future<bool> downloadFile(String url, String fileName) async {
    // Not supported on non-web platforms
    return false;
  }

  /// Enhanced PDF preview for web platform
  static Future<bool> openPdfPreview(String url) async {
    // Not supported on non-web platforms
    return false;
  }

  /// Open file in new tab (fallback method)
  static Future<bool> openInNewTab(String url) async {
    // Not supported on non-web platforms
    return false;
  }

  /// Check if the current browser supports file downloads
  static bool get supportsFileDownload {
    return false;
  }

  /// Get browser name for user feedback
  static String get browserName {
    return 'Mobile App';
  }
}
