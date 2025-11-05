import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/file_download_service.dart';
import '../services/web_file_handler.dart';

// Conditional import for web vs mobile
import 'file_preview_web.dart' if (dart.library.io) 'file_preview_mobile.dart' as platform;
import 'pdf_iframe_viewer_web.dart' if (dart.library.io) 'pdf_iframe_viewer_mobile.dart' as pdf_viewer;

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
    if (kIsWeb) {
      // Use embedded iframe for web
      return _buildWebPdfPreview();
    } else {
      // Mobile: show button to open PDF
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
  }

  Widget _buildWebPdfPreview() {
    return Builder(
      builder: (context) {
        // Use embedded iframe for web
        return Stack(
          children: [
            // Embedded PDF iframe
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: kIsWeb
                  ? pdf_viewer.PdfIframeViewer(
                      pdfUrl: fileUrl,
                      fileName: fileName,
                    )
                  : const Center(
                      child: Text('PDF preview only available on web'),
                    ),
            ),
            // Floating action button for download
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  // Download file
                  _downloadFile(context, fileUrl, fileName);
                },
                backgroundColor: const Color(0xFF007AFF),
                child: const Icon(Icons.download_rounded, color: Colors.white),
                tooltip: 'Download PDF',
              ),
            ),
          ],
        );
      },
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

  void _downloadFile(BuildContext context, String url, String fileName) async {
    if (kIsWeb) {
      // Web platform: use enhanced web file handler
      try {
        final success = await WebFileHandler.downloadFile(url, fileName);
        if (success) {
          // Show success message for web
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Downloading $fileName...'),
                backgroundColor: const Color(0xFF34C759),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Fallback to platform method
          platform.downloadFile(url, fileName);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: ${e.toString()}'),
              backgroundColor: const Color(0xFFFF3B30),
            ),
          );
        }
      }
    } else {
      // Mobile platform: use the new file download service
      final bool success = await FileDownloadService.downloadFile(url, fileName, context);
      if (!success) {
        // If download fails, show options dialog
        FileDownloadService.showDownloadOptions(context, url, fileName);
      }
    }
  }

  void _openPdfInNewTab(BuildContext context) {
    if (kIsWeb) {
      // Use enhanced web file handler for PDF preview
      WebFileHandler.openPdfPreview(fileUrl).then((success) {
        if (!success) {
          // Fallback to platform method
          platform.openPdfPreview(fileUrl);
        }
      });
    } else {
      // On mobile, show a dialog with options
      _showMobilePdfOptions(context);
    }
  }

  void _showMobilePdfOptions(BuildContext context) {
    // Use the new file download service for PDF options
    FileDownloadService.showDownloadOptions(context, fileUrl, fileName);
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last : '';
  }
}
