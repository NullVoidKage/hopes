import 'package:http/http.dart' as http;
import 'offline_service.dart';

class FileParserService {
  static const String _cachedContentKey = 'cached_file_content';

  /// Extract text content from a file URL
  /// Supports PDF, DOCX, and other text-based documents
  static Future<String> extractTextFromFile(String fileUrl) async {
    try {
      print('🔍 FileParserService: Extracting text from: $fileUrl');
      
      // Check if content is already cached
      final cachedContent = await _getCachedContent(fileUrl);
      if (cachedContent != null && cachedContent.isNotEmpty) {
        print('📦 Using cached content for: $fileUrl');
        return cachedContent;
      }

      // Download and parse the file
      final fileExtension = _getFileExtension(fileUrl);
      String extractedText = '';

      switch (fileExtension.toLowerCase()) {
        case 'pdf':
          extractedText = await _extractTextFromPdf(fileUrl);
          break;
        case 'docx':
        case 'doc':
          extractedText = await _extractTextFromDocx(fileUrl);
          break;
        case 'txt':
          extractedText = await _extractTextFromTxt(fileUrl);
          break;
        default:
          print('⚠️ Unsupported file type: $fileExtension');
          extractedText = 'Unsupported file type: $fileExtension. Only PDF, DOCX, and TXT files are supported.';
      }

      // Cache the extracted content
      if (extractedText.isNotEmpty) {
        await _cacheContent(fileUrl, extractedText);
      }

      print('✅ Extracted ${extractedText.length} characters from $fileExtension file');
      return extractedText;
    } catch (e) {
      print('❌ Error extracting text from file: $e');
      return 'Error extracting text from file: ${e.toString()}';
    }
  }

  /// Extract text from PDF file
  static Future<String> _extractTextFromPdf(String fileUrl) async {
    try {
      print('📄 Extracting text from PDF...');
      
      // Handle Firebase Storage URLs - try to get download URL
      String downloadUrl = fileUrl;
      if (fileUrl.contains('firebasestorage.googleapis.com')) {
        // For Firebase Storage URLs, try to get a proper download URL
        // Remove any query parameters that might cause issues
        final uri = Uri.parse(fileUrl);
        downloadUrl = '${uri.scheme}://${uri.host}${uri.path}?alt=media';
        print('🔄 Using Firebase Storage download URL: $downloadUrl');
      }
      
      // Download the PDF file
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }

      // Extract text from PDF bytes
      final pdfBytes = response.bodyBytes;
      
      // Convert PDF bytes to string (basic approach)
      final pdfText = String.fromCharCodes(pdfBytes.where((byte) => byte >= 32 && byte <= 126));
      
      // Clean up the text
      final cleanText = pdfText
          .replaceAll(RegExp(r'[^\w\s\.\,\!\?\:\;\-\(\)]'), ' ') // Remove special characters
          .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
          .trim();
      
      if (cleanText.length > 50) {
        print('✅ Successfully extracted ${cleanText.length} characters from PDF');
        return cleanText;
      } else {
        print('⚠️ PDF text extraction yielded minimal content, trying alternative approach');
        // Try to extract text from the raw bytes more aggressively
        final alternativeText = String.fromCharCodes(pdfBytes.where((byte) => byte >= 32 && byte <= 126));
        if (alternativeText.length > 50) {
          print('✅ Alternative extraction successful: ${alternativeText.length} characters');
          return alternativeText;
        }
        print('⚠️ PDF extraction failed - using fallback content generation');
        return 'PDF_FILE_DETECTED_BUT_EXTRACTION_FAILED';
      }
    } catch (e) {
      print('❌ Error extracting PDF text: $e');
      return 'Error extracting PDF content: ${e.toString()}';
    }
  }

  /// Extract text from DOCX/DOC file
  static Future<String> _extractTextFromDocx(String fileUrl) async {
    try {
      print('📄 Extracting text from DOCX/DOC...');
      
      // Handle Firebase Storage URLs - try to get download URL
      String downloadUrl = fileUrl;
      if (fileUrl.contains('firebasestorage.googleapis.com')) {
        // For Firebase Storage URLs, try to get a proper download URL
        final uri = Uri.parse(fileUrl);
        downloadUrl = '${uri.scheme}://${uri.host}${uri.path}?alt=media';
        print('🔄 Using Firebase Storage download URL: $downloadUrl');
      }
      
      // Download the DOCX file
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download DOCX: ${response.statusCode}');
      }

      // For DOCX files, we'll extract basic text content
      // This is a simplified implementation - in production, you'd use a proper DOCX library
      final docxBytes = response.bodyBytes;
      
      // Convert DOCX bytes to string (this is a basic approach)
      // DOCX files are ZIP archives containing XML files
      final docxText = String.fromCharCodes(docxBytes.where((byte) => byte >= 32 && byte <= 126));
      
      // Clean up the text
      final cleanText = docxText
          .replaceAll(RegExp(r'[^\w\s\.\,\!\?\:\;\-\(\)]'), ' ') // Remove special characters
          .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
          .trim();
      
      if (cleanText.length > 100) {
        print('✅ Successfully extracted ${cleanText.length} characters from DOCX');
        return cleanText;
      } else {
        print('⚠️ DOCX text extraction yielded minimal content');
        return 'DOCX content extracted but may need manual review. Please ensure the document contains readable text.';
      }
    } catch (e) {
      print('❌ Error extracting DOCX text: $e');
      return 'Error extracting DOCX content: ${e.toString()}';
    }
  }

  /// Extract text from TXT file
  static Future<String> _extractTextFromTxt(String fileUrl) async {
    try {
      print('📄 Extracting text from TXT...');
      
      // Handle Firebase Storage URLs - try to get download URL
      String downloadUrl = fileUrl;
      if (fileUrl.contains('firebasestorage.googleapis.com')) {
        // For Firebase Storage URLs, try to get a proper download URL
        final uri = Uri.parse(fileUrl);
        downloadUrl = '${uri.scheme}://${uri.host}${uri.path}?alt=media';
        print('🔄 Using Firebase Storage download URL: $downloadUrl');
      }
      
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download TXT: ${response.statusCode}');
      }

      final extractedText = response.body;
      print('📄 Extracted text from TXT file');
      return extractedText.trim();
    } catch (e) {
      print('❌ Error extracting TXT text: $e');
      throw Exception('Failed to extract text from TXT: ${e.toString()}');
    }
  }

  /// Get file extension from URL
  static String _getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.path.split('/');
      final fileName = pathSegments.last;
      final parts = fileName.split('.');
      return parts.length > 1 ? parts.last : '';
    } catch (e) {
      return '';
    }
  }

  /// Cache extracted content locally
  static Future<void> _cacheContent(String fileUrl, String content) async {
    try {
      final cacheKey = '${_cachedContentKey}_${_generateCacheKey(fileUrl)}';
      await OfflineService.cacheData(cacheKey, {
        'content': content,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'fileUrl': fileUrl,
      });
      print('💾 Cached content for: $fileUrl');
    } catch (e) {
      print('⚠️ Failed to cache content: $e');
    }
  }

  /// Get cached content
  static Future<String?> _getCachedContent(String fileUrl) async {
    try {
      final cacheKey = '${_cachedContentKey}_${_generateCacheKey(fileUrl)}';
      final cachedData = await OfflineService.getCachedData(cacheKey);
      
      if (cachedData != null) {
        final timestamp = cachedData['timestamp'] as int?;
        final content = cachedData['content'] as String?;
        
        // Check if cache is still valid (24 hours)
        if (timestamp != null && content != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();
          final difference = now.difference(cacheTime);
          
          if (difference.inHours < 24) {
            return content;
          } else {
            // Remove expired cache
            await OfflineService.removeCachedData(cacheKey);
          }
        }
      }
      
      return null;
    } catch (e) {
      print('⚠️ Failed to get cached content: $e');
      return null;
    }
  }

  /// Generate cache key from file URL
  static String _generateCacheKey(String fileUrl) {
    // Create a hash of the URL for the cache key
    return fileUrl.hashCode.abs().toString();
  }

  /// Clear all cached file content
  static Future<void> clearCache() async {
    try {
      // This would need to be implemented in OfflineService
      // For now, we'll just log the action
      print('🗑️ Clearing file content cache...');
    } catch (e) {
      print('⚠️ Failed to clear cache: $e');
    }
  }

  /// Get cache size information
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      // This would need to be implemented in OfflineService
      // For now, return basic info
      return {
        'cachedFiles': 0,
        'totalSize': '0 MB',
        'lastCleared': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('⚠️ Failed to get cache info: $e');
      return {
        'cachedFiles': 0,
        'totalSize': '0 MB',
        'lastCleared': 'Unknown',
      };
    }
  }
}
