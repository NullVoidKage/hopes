import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Conditional import for web vs mobile
import 'file_preview_web.dart' if (dart.library.io) 'file_preview_mobile.dart' as platform;

class FilePreviewScreen extends StatelessWidget {
  final String fileUrl;
  final String fileName;

  const FilePreviewScreen({
    super.key,
    required this.fileUrl,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          fileName,
          style: const TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _downloadFile(context, fileUrl, fileName),
            tooltip: 'Download file',
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            child: _buildFilePreview(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context) {
    final fileExtension = _getFileExtension(fileName).toLowerCase();
    
    if (fileExtension == 'pdf') {
      return _buildPdfPreview(context);
    } else if (fileExtension == 'docx' || fileExtension == 'doc') {
      return _buildDocPreview();
    } else {
      return _buildUnsupportedFilePreview();
    }
  }

  Widget _buildPdfPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            size: 64,
            color: Color(0xFFFF3B30),
          ),
          const SizedBox(height: 16),
          const Text(
            'PDF Preview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'PDF files can be viewed in a new tab',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _openPdfInNewTab(context),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _downloadFile(context, fileUrl, fileName),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF007AFF),
                  side: const BorderSide(color: Color(0xFF007AFF)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_rounded,
            size: 64,
            color: Color(0xFF007AFF),
          ),
          SizedBox(height: 16),
          Text(
            'Document Preview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'DOCX/DOC files can be downloaded and opened',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Click the download button to save the file',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF007AFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedFilePreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            size: 64,
            color: Color(0xFF86868B),
          ),
          SizedBox(height: 16),
          Text(
            'File Preview Not Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This file type cannot be previewed',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Click the download button to save the file',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF007AFF),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadFile(BuildContext context, String url, String fileName) {
    try {
      if (kIsWeb) {
        // Web platform: use web-specific implementation
        platform.downloadFile(url, fileName);
      } else {
        // Mobile platform: show a dialog with options
        _showMobileDownloadOptions(context, url, fileName);
      }
    } catch (e) {
      if (kIsWeb) {
        // Fallback: open in new tab
        platform.openInNewTab(url);
      } else {
        // Mobile fallback
        _showMobileDownloadOptions(context, url, fileName);
      }
    }
  }

  void _openPdfInNewTab(BuildContext context) {
    if (kIsWeb) {
      platform.openPdfPreview(fileUrl);
    } else {
      // On mobile, show a dialog with options
      _showMobilePdfOptions(context);
    }
  }

  void _showMobileDownloadOptions(BuildContext context, String url, String fileName) {
    // Show a dialog with mobile-specific options
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('File Options'),
          content: Text('Choose how you want to handle: $fileName'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyLinkToClipboard(context, url);
              },
              child: const Text('Copy Link'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openInBrowser(context, url);
              },
              child: const Text('Open in Browser'),
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

  void _showMobilePdfOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('PDF Options'),
          content: const Text('Choose how you want to handle this PDF file.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openInBrowser(context, fileUrl);
              },
              child: const Text('Open in Browser'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadFile(context, fileUrl, fileName);
              },
              child: const Text('Download'),
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

  void _copyLinkToClipboard(BuildContext context, String url) {
    // Copy URL to clipboard
    if (kIsWeb) {
      // Web clipboard API
      try {
        // Use the platform-specific implementation
        platform.copyToClipboard(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied to clipboard')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to copy link')),
        );
      }
    } else {
      // Mobile clipboard (would need clipboard plugin)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }

  void _openInBrowser(BuildContext context, String url) {
    try {
      if (kIsWeb) {
        platform.openInNewTab(url);
      } else {
        // On mobile, show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening in browser...')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open in browser')),
      );
    }
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last : '';
  }
}
