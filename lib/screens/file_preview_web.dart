import 'dart:html' as html;
import 'package:flutter/foundation.dart';

void downloadFile(String url, String fileName) {
  try {
    // Create a temporary anchor element for download
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..setAttribute('target', '_blank')
      ..style.display = 'none';
    
    // Add to DOM temporarily
    html.document.body?.append(anchor);
    
    // Trigger download
    anchor.click();
    
    // Clean up
    anchor.remove();
  } catch (e) {
    if (kDebugMode) {
      print('Download failed: $e');
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
    }
  }
}

// Web-specific PDF preview
void openPdfPreview(String url) {
  try {
    // Open PDF in a new tab with proper headers for PDF viewing
    final newWindow = html.window.open('', '_blank');
    newWindow.location.href = url;
  } catch (e) {
    if (kDebugMode) {
      print('PDF preview failed: $e');
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
    }
    // Fallback: try using navigator.clipboard if available
    try {
      html.window.navigator.clipboard?.writeText(text);
    } catch (e2) {
      if (kDebugMode) {
      }
    }
  }
}
