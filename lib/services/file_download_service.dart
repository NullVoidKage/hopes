import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'file_download_manager.dart';

class FileDownloadService {
  static Future<bool> downloadFile(String url, String fileName, BuildContext context) async {
    try {
      if (kDebugMode) {
        print('FileDownloadService: Starting download for $fileName');
        print('URL: $url');
      }
      
      // Use the new FileDownloadManager for actual file downloading
      return await FileDownloadManager.downloadFile(url, fileName, context);
    } catch (e) {
      if (kDebugMode) {
        print('Error in downloadFile: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: $e'),
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
        print('FileDownloadService: Opening in browser: $url');
      }
      
      // Use the new FileDownloadManager for browser opening
      return await FileDownloadManager.openInBrowser(url, context);
    } catch (e) {
      if (kDebugMode) {
        print('Error in openInBrowser: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening browser: $e'),
            backgroundColor: const Color(0xFFFF3B30),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }
  
  static void showDownloadOptions(BuildContext context, String url, String fileName) {
    // Use the new FileDownloadManager for download options
    FileDownloadManager.showDownloadOptions(context, url, fileName);
  }
}
