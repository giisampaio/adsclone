import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Salva o ZIP no diretório de downloads quando disponível; caso contrário, em documentos do app.
Future<void> downloadZipFile(List<int> zipBytes, String fileName) async {
  final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(zipBytes, flush: true);
}
