import 'dart:html' as html;

void downloadFile(String url, String fileName) {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
}

void openInNewTab(String url) {
  html.window.open(url, '_blank');
}
