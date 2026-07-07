import 'package:flutter/widgets.dart';

import 'pdf_preview_stub.dart' if (dart.library.html) 'pdf_preview_web.dart';

Widget buildPdfPreview(String url) => buildPdfPreviewImpl(url);
