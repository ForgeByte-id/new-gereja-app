// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:typed_data';

import 'dart:html' as html;

Future<String> saveDownloadedBytes({
  required Uint8List bytes,
  required String fileName,
}) async {
  final mimeType = fileName.toLowerCase().endsWith('.pdf')
      ? 'application/pdf'
      : 'application/zip';

  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  return fileName;
}
