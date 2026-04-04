// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadZipFile(List<int> zipBytes, String fileName) async {
  final bytes = zipBytes is Uint8List ? zipBytes : Uint8List.fromList(zipBytes);
  final blob = html.Blob([bytes], 'application/zip');
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: objectUrl)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  // Deixa o navegador iniciar o download antes de revogar o blob URL.
  await Future<void>.delayed(Duration.zero);
  html.Url.revokeObjectUrl(objectUrl);
}
