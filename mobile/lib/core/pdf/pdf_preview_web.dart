import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget buildPdfPreviewImpl(String url) {
  final viewType = 'pdf-preview-${url.hashCode}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    return web.HTMLIFrameElement()
      ..src = url
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
  });

  return HtmlElementView(viewType: viewType);
}
