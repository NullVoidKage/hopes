import 'package:flutter/material.dart';

/// Mobile fallback for PDF iframe viewer
class PdfIframeViewer extends StatelessWidget {
  final String pdfUrl;
  final String? fileName;

  const PdfIframeViewer({
    Key? key,
    required this.pdfUrl,
    this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('PDF preview only available on web'),
    );
  }
}

