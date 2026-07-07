import 'file_pick_stub.dart'
    if (dart.library.html) 'file_pick_web.dart';
import 'file_pick_result.dart';

Future<FilePickResult?> pickImage() => pickImageImpl();

Future<FilePickResult?> pickPdf() => pickPdfImpl();
