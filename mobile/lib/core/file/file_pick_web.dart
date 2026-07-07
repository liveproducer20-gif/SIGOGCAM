import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'file_pick_result.dart';

@JS('FileReader')
extension type _JsFileReader._(JSObject _) implements JSObject {
  external factory _JsFileReader();
  external JSAny? get result;
  external set onloadend(JSFunction value);
  external set onerror(JSFunction value);
  external void readAsDataURL(web.Blob blob);
}

Future<FilePickResult?> pickImageImpl() {
  return _pickFile('image/*', withPreview: true);
}

Future<FilePickResult?> pickPdfImpl() {
  return _pickFile('application/pdf,.pdf', withPreview: true);
}

Future<FilePickResult?> _pickFile(
  String accept, {
  bool withPreview = false,
}) {
  final completer = Completer<FilePickResult?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept
    ..multiple = false
    ..style.display = 'none';

  void complete() {
    final files = input.files;
    final file = files != null && files.length > 0 ? files.item(0) : null;
    input.remove();

    if (completer.isCompleted) return;

    if (file == null) {
      completer.complete(null);
      return;
    }

    final previewUrl = withPreview ? web.URL.createObjectURL(file) : null;

    if (!withPreview) {
      completer.complete(
        FilePickResult(
          name: file.name,
        ),
      );
      return;
    }

    final reader = _JsFileReader();
    reader.onloadend = (() {
      final dataUrl = (reader.result as JSString?)?.toDart;
      if (!completer.isCompleted) {
        completer.complete(
          FilePickResult(
            name: file.name,
            previewUrl: previewUrl,
            dataUrl: dataUrl,
          ),
        );
      }
    }).toJS;
    reader.onerror = (() {
      if (!completer.isCompleted) {
        completer.complete(
          FilePickResult(
            name: file.name,
            previewUrl: previewUrl,
          ),
        );
      }
    }).toJS;
    reader.readAsDataURL(file);
  }

  input.addEventListener('change', ((web.Event _) {
    complete();
  }).toJS);

  web.document.body?.append(input);

  input.click();
  return completer.future;
}
