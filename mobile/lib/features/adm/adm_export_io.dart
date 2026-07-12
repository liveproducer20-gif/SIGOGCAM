import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> exportAdminCsv(String content, String fileName) async {
  final directory =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(content, flush: true);
  return file.path;
}

Future<bool> printAdminPage() async => false;
