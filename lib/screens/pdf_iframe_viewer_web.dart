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

  @override
  void initState() {
    super.initState();
    _viewType = 'pdf-iframe-${++_viewIdCounter}';
    _createIframe();
  }

  void _createIframe() {
    if (!kIsWeb) return;

    try {
      // Create an iframe element
      final iframe = html.IFrameElement()
        ..src = widget.pdfUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(
        child: Text('PDF preview only available on web'),
      );
    }

    if (!_isLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Use HtmlElementView to embed the iframe
    return HtmlElementView(viewType: _viewType);
  }
}

