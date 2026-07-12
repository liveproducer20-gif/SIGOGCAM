import 'dart:convert';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String> downloadAchievementImage(
  Uint8List bytes,
  String fileName,
) async {
  final anchor = web.HTMLAnchorElement()
    ..href = 'data:image/png;base64,${base64Encode(bytes)}'
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return 'Descargas/$fileName';
}
