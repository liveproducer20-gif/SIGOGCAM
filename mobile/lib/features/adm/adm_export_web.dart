import 'dart:convert';

import 'package:web/web.dart' as web;

Future<String> exportAdminCsv(String content, String fileName) async {
  final bytes = utf8.encode('\ufeff$content');
  final anchor = web.HTMLAnchorElement()
    ..href = 'data:text/csv;base64,${base64Encode(bytes)}'
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return 'Descargas/$fileName';
}

Future<bool> printAdminPage() async {
  web.window.print();
  return true;
}
