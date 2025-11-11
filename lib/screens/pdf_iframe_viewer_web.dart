import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Conditional import - only for web
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Web-specific PDF iframe viewer widget
class PdfIframeViewer extends StatefulWidget {
  final String pdfUrl;
  final String? fileName;

  const PdfIframeViewer({
    Key? key,
    required this.pdfUrl,
    this.fileName,
  }) : super(key: key);

  @override
  State<PdfIframeViewer> createState() => _PdfIframeViewerState();
}

class _PdfIframeViewerState extends State<PdfIframeViewer> {
  static int _viewIdCounter = 0;
  late final String _viewType;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'pdf-iframe-${++_viewIdCounter}';
    _createIframe();
  }

  void _createIframe() {
    if (!kIsWeb) return;

    try {
      // Try using Google Docs Viewer as fallback for CORS issues
      // If direct URL fails, we'll use Google's viewer
      String pdfUrl = widget.pdfUrl;
      
      // Check if URL is from Firebase Storage (might have CORS issues)
      if (pdfUrl.contains('firebasestorage.googleapis.com')) {
        // Use Google Docs Viewer as proxy to avoid CORS
        pdfUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.pdfUrl)}&embedded=true';
      }

      // Create an iframe element
      final iframe = html.IFrameElement()
        ..src = pdfUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..onError.listen((event) {
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        })
        ..onLoad.listen((event) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        });

      // Set timeout to detect if iframe fails to load
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && !_isLoaded) {
          setState(() {
            _hasError = true;
          });
        }
      });

      // Register the platform view
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) {
          return iframe;
        },
      );

      setState(() {
        _isLoaded = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error creating PDF iframe: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(
        child: Text('PDF preview only available on web'),
      );
    }

    if (_hasError) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Color(0xFFFF3B30)),
            SizedBox(height: 16),
            Text(
              'Unable to load PDF preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please use the "Open in new tab" button',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF86868B),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isLoaded) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF86868B),
              ),
            ),
          ],
        ),
      );
    }

    // Use HtmlElementView to embed the iframe
    return HtmlElementView(viewType: _viewType);
  }
}

