import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class FileDownloadManager {
  static final Dio _dio = Dio();
  
  static Future<bool> downloadFile(String url, String fileName, BuildContext context) async {
    try {
      if (kDebugMode) {
        print('FileDownloadManager: Starting download for $fileName');
        print('URL: $url');
      }
      
      // Show download options dialog first
      return await _showDownloadOptionsDialog(url, fileName, context);
    } catch (e) {
      if (kDebugMode) {
        print('FileDownloadManager error: $e');
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
  
  static Future<bool> _showDownloadOptionsDialog(String url, String fileName, BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.file_present_rounded, color: Color(0xFF007AFF)),
              const SizedBox(width: 8),
              const Text('File Options'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose how you want to handle this file:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007AFF),
                ),
              ),
              const SizedBox(height: 20),
              _buildDownloadOption(
                context,
                'Open in Browser',
                'Download via browser',
                Icons.language,
                () => _openInBrowser(url, context),
              ),
              const SizedBox(height: 12),
              _buildDownloadOption(
                context,
                'Copy Link',
                'Copy download link',
                Icons.link,
                () => _copyLink(url, context),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  static Widget _buildDownloadOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF007AFF), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
  
  static Future<bool> _showDownloadLocationPicker(String url, String fileName, BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.folder_rounded, color: Color(0xFF007AFF)),
              const SizedBox(width: 8),
              const Text('Choose Download Location'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where would you like to save:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007AFF),
                ),
              ),
              const SizedBox(height: 20),
              _buildLocationOption(
                context,
                'Documents',
                'Save to Documents folder',
                Icons.description,
                'Documents',
                () => _downloadToLocation(url, fileName, context, 'Documents'),
              ),
              const SizedBox(height: 12),
              _buildLocationOption(
                context,
                'Downloads',
                'Save to Downloads folder',
                Icons.download,
                'Downloads',
                () => _downloadToLocation(url, fileName, context, 'Downloads'),
              ),
              const SizedBox(height: 12),
              _buildLocationOption(
                context,
                'App Storage',
                'Save to app private storage',
                Icons.phone_android,
                'AppStorage',
                () => _downloadToLocation(url, fileName, context, 'AppStorage'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  static Widget _buildLocationOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    String locationType,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF007AFF), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
  
  static Future<bool> _downloadToLocation(String url, String fileName, BuildContext context, String locationType) async {
    Navigator.of(context).pop(); // Close location picker dialog
    
    try {
      if (kDebugMode) {
        print('FileDownloadManager: Starting download to $locationType for $fileName');
        print('URL: $url');
      }
      
      // Show initial loading message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting download to $locationType...'),
            backgroundColor: const Color(0xFF007AFF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Get the appropriate download directory based on location type
      final Directory? downloadDir = await _getDownloadDirectoryByType(locationType);
      if (downloadDir == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot access download directory'),
              backgroundColor: Color(0xFFFF3B30),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
      
      // Wrap entire download process in timeout
      return await Future.any([
        _performDownloadToLocation(url, fileName, context, downloadDir),
        Future.delayed(const Duration(minutes: 3), () {
          throw TimeoutException('Download timed out after 3 minutes', const Duration(minutes: 3));
        }),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('FileDownloadManager error: $e');
      }
      
      // Hide progress dialog if still showing
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: const Color(0xFFFF3B30),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }
  
  static Future<Directory?> _getDownloadDirectoryByType(String locationType) async {
    try {
      if (Platform.isAndroid) {
        final Directory documentsDir = await getApplicationDocumentsDirectory();
        
        switch (locationType) {
          case 'Documents':
            final Directory docsDir = Directory('${documentsDir.path}/Documents');
            if (!await docsDir.exists()) {
              await docsDir.create(recursive: true);
            }
            if (kDebugMode) {
              print('FileDownloadManager: Android Documents directory: ${docsDir.path}');
            }
            return docsDir;
            
          case 'Downloads':
            final Directory downloadsDir = Directory('${documentsDir.path}/Downloads');
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
            if (kDebugMode) {
              print('FileDownloadManager: Android Downloads directory: ${downloadsDir.path}');
            }
            return downloadsDir;
            
          case 'AppStorage':
            final Directory appDir = Directory('${documentsDir.path}/AppFiles');
            if (!await appDir.exists()) {
              await appDir.create(recursive: true);
            }
            if (kDebugMode) {
              print('FileDownloadManager: Android App storage directory: ${appDir.path}');
            }
            return appDir;
            
          default:
            return null;
        }
      } else if (Platform.isIOS) {
        final Directory documentsDir = await getApplicationDocumentsDirectory();
        
        switch (locationType) {
          case 'Documents':
            final Directory docsDir = Directory('${documentsDir.path}/Documents');
            if (!await docsDir.exists()) {
              await docsDir.create(recursive: true);
            }
            if (kDebugMode) {
              print('FileDownloadManager: iOS Documents directory: ${docsDir.path}');
            }
            return docsDir;
            
          case 'Downloads':
            final Directory downloadsDir = Directory('${documentsDir.path}/Downloads');
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
            if (kDebugMode) {
              print('FileDownloadManager: iOS Downloads directory: ${downloadsDir.path}');
            }
            return downloadsDir;
            
          case 'AppStorage':
            final Directory appDir = Directory('${documentsDir.path}/AppFiles');
            if (!await appDir.exists()) {
              await appDir.create(recursive: true);
            }
            if (kDebugMode) {
              print('FileDownloadManager: iOS App storage directory: ${appDir.path}');
            }
            return appDir;
            
          default:
            return null;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('FileDownloadManager: Error getting download directory: $e');
      }
    }
    return null;
  }
  
  static Future<bool> _performDownloadToLocation(String url, String fileName, BuildContext context, Directory downloadDir) async {
    // Create file path
    final String filePath = '${downloadDir.path}/$fileName';
    final File file = File(filePath);
    
    // Show progress dialog with timeout
    if (context.mounted) {
      _showDownloadProgress(context, fileName);
    }
    
    // Download file with timeout and error handling
    try {
      await _dio.download(
        url,
        filePath,
        options: Options(
          receiveTimeout: const Duration(minutes: 2), // Reduced timeout
          sendTimeout: const Duration(seconds: 30),
        ),
        onReceiveProgress: (received, total) {
          if (kDebugMode) {
            print('Download progress: ${(received / total * 100).toStringAsFixed(1)}%');
          }
        },
      );
    } catch (e) {
      // Hide progress dialog on error
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
      }
      throw e; // Re-throw to be handled by outer catch
    }
    
    // Hide progress dialog
    if (context.mounted) {
      Navigator.of(context).pop(); // Close progress dialog
    }
    
    // Check if file was downloaded successfully
    if (await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$fileName downloaded successfully!'),
                const SizedBox(height: 4),
                Text(
                  'Location: ${file.path}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF34C759),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy Path',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.path));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File path copied to clipboard'),
                    backgroundColor: Color(0xFF34C759),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
      return true;
    } else {
      throw Exception('File download failed - file not found');
    }
  }
  
  static Future<bool> _downloadToDevice(String url, String fileName, BuildContext context) async {
    Navigator.of(context).pop(); // Close dialog first
    
    try {
      if (kDebugMode) {
        print('FileDownloadManager: Starting device download for $fileName');
        print('URL: $url');
      }
      
      // Show initial loading message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting download of $fileName...'),
            backgroundColor: const Color(0xFF007AFF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Wrap entire download process in timeout
      return await Future.any([
        _performDownload(url, fileName, context),
        Future.delayed(const Duration(minutes: 3), () {
          throw TimeoutException('Download timed out after 3 minutes', const Duration(minutes: 3));
        }),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('FileDownloadManager error: $e');
      }
      
      // Hide progress dialog if still showing
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: const Color(0xFFFF3B30),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }
  
  static Future<bool> _performDownload(String url, String fileName, BuildContext context) async {
    // Check platform-specific permissions
    if (!await _checkPermissions(context)) {
      return false;
    }
    
    // Get download directory
    final Directory? downloadDir = await _getDownloadDirectory();
    if (downloadDir == null) {
      if (kIsWeb) {
        // For web, use browser download
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $fileName in browser for download...'),
              backgroundColor: const Color(0xFF007AFF),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return await openInBrowser(url, context);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot access download directory'),
              backgroundColor: Color(0xFFFF3B30),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    }
    
    // Create file path
    final String filePath = '${downloadDir.path}/$fileName';
    final File file = File(filePath);
    
    // Show progress dialog with timeout
    if (context.mounted) {
      _showDownloadProgress(context, fileName);
    }
    
    // Download file with timeout and error handling
    try {
      await _dio.download(
        url,
        filePath,
        options: Options(
          receiveTimeout: const Duration(minutes: 2), // Reduced timeout
          sendTimeout: const Duration(seconds: 30),
        ),
        onReceiveProgress: (received, total) {
          if (kDebugMode) {
            print('Download progress: ${(received / total * 100).toStringAsFixed(1)}%');
          }
        },
      );
    } catch (e) {
      // Hide progress dialog on error
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
      }
      throw e; // Re-throw to be handled by outer catch
    }
    
    // Hide progress dialog
    if (context.mounted) {
      Navigator.of(context).pop(); // Close progress dialog
    }
    
    // Check if file was downloaded successfully
    if (await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$fileName downloaded successfully!'),
                const SizedBox(height: 4),
                Text(
                  'Location: ${file.path}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF34C759),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy Path',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.path));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File path copied to clipboard'),
                    backgroundColor: Color(0xFF34C759),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
      return true;
    } else {
      throw Exception('File download failed - file not found');
    }
  }
  
  static Future<bool> _checkPermissions(BuildContext context) async {
    // For now, we'll proceed without explicit permission requests
    // The Android manifest already has the necessary permissions
    // iOS will handle permissions automatically when accessing directories
    if (kDebugMode) {
      print('FileDownloadManager: Checking permissions...');
    }
    return true;
  }
  
  static Future<Directory?> _getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Use app documents directory for Android (more reliable)
        final Directory documentsDir = await getApplicationDocumentsDirectory();
        final Directory downloadDir = Directory('${documentsDir.path}/Downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        if (kDebugMode) {
          print('FileDownloadManager: Android download directory: ${downloadDir.path}');
        }
        return downloadDir;
      } else if (Platform.isIOS) {
        // Use documents directory for iOS
        final Directory documentsDir = await getApplicationDocumentsDirectory();
        final Directory downloadDir = Directory('${documentsDir.path}/Downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        if (kDebugMode) {
          print('FileDownloadManager: iOS download directory: ${downloadDir.path}');
        }
        return downloadDir;
      } else if (kIsWeb) {
        // For web, we'll use a different approach
        if (kDebugMode) {
          print('FileDownloadManager: Web platform detected');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('FileDownloadManager: Error getting download directory: $e');
      }
    }
    return null;
  }
  
  static void _showDownloadProgress(BuildContext context, String fileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Downloading...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Downloading $fileName'),
              const SizedBox(height: 8),
              const Text(
                'This may take a few moments...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Show cancellation message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Download cancelled'),
                    backgroundColor: Color(0xFFFF9500),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  static Future<bool> openInBrowser(String url, BuildContext context) async {
    try {
      final Uri uri = Uri.parse(url);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Opening in browser...'),
            backgroundColor: const Color(0xFF007AFF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open in browser. URL may be invalid.'),
              backgroundColor: Color(0xFFFF3B30),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    } catch (e) {
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
  
  static Future<bool> _openInBrowser(String url, BuildContext context) async {
    Navigator.of(context).pop(); // Close dialog first
    return await openInBrowser(url, context);
  }
  
  static Future<bool> _copyLink(String url, BuildContext context) async {
    Navigator.of(context).pop(); // Close dialog first
    _copyToClipboard(context, url);
    return true;
  }
  
  static void _copyToClipboard(BuildContext context, String url) {
    try {
      Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          backgroundColor: Color(0xFF34C759),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy link: $e'),
          backgroundColor: const Color(0xFFFF3B30),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  static void showDownloadOptions(BuildContext context, String url, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('File Options'),
          content: Text('Choose how you want to handle: $fileName'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await downloadFile(url, fileName, context);
              },
              child: const Text('Download File'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openInBrowser(url, context);
              },
              child: const Text('Open in Browser'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyToClipboard(context, url);
              },
              child: const Text('Copy Link'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}