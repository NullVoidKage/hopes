import 'dart:html' as html;
import 'package:flutter/foundation.dart';

void downloadFile(String url, String fileName) {
  try {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..setAttribute('target', '_blank')
      ..click();
  } catch (e) {
    if (kDebugMode) {
      print('Web download error: $e');
    }
    // Fallback: open in new tab
    openInNewTab(url);
  }
}

void openInNewTab(String url) {
  try {
    html.window.open(url, '_blank');
  } catch (e) {
    if (kDebugMode) {
      print('Web open error: $e');
    }
  }
}

// Web-specific PDF preview
void openPdfPreview(String url) {
  try {
    // Open PDF in a new tab - browser will handle PDF display
    html.window.open(url, '_blank');
  } catch (e) {
    if (kDebugMode) {
      print('Web PDF preview error: $e');
    }
    // Fallback: open in new tab
    openInNewTab(url);
  }
}

// Web clipboard functionality
void copyToClipboard(String text) {
  try {
    final textArea = html.TextAreaElement()
      ..value = text
      ..style.position = 'fixed'
      ..style.left = '-999999px'
      ..style.top = '-999999px';
    
    html.document.body?.append(textArea);
    textArea.select();
    html.document.execCommand('copy');
    textArea.remove();
  } catch (e) {
    if (kDebugMode) {
      print('Web clipboard error: $e');
    }
    // Fallback: try using navigator.clipboard if available
    try {
      html.window.navigator.clipboard?.writeText(text);
    } catch (e2) {
      if (kDebugMode) {
        print('Web navigator clipboard error: $e2');
      }
    }
  }
}
