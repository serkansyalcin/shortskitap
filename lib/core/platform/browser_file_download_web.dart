// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

Future<void> downloadBytes({
  required List<int> bytes,
  required String mimeType,
  required String filename,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  html.Url.revokeObjectUrl(url);
}
