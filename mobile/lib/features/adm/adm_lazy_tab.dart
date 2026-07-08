import 'package:flutter/material.dart';

/// Mezcla que retrasa la carga de datos de un tab hasta que el usuario
/// selecciona esa pestaña por primera vez. Evita que todas las pestañas
/// hagan fetch simultáneo al abrir la pantalla de Administración, lo que
/// causaba congelamientos por la avalancha de conexiones al backend.
mixin AdmLazyTabMixin<T extends StatefulWidget> on State<T> {
  bool _didLoad = false;

  void initLazy(int myIndex, Future<void> Function() load) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = DefaultTabController.maybeOf(context);
      if (controller == null) {
        _loadOnce(load);
        return;
      }
      if (controller.index == myIndex) {
        _loadOnce(load);
      } else {
        controller.addListener(() {
          if (!mounted) return;
          if (controller.index == myIndex) {
            _loadOnce(load);
          }
        });
      }
    });
  }

  void _loadOnce(Future<void> Function() load) {
    if (_didLoad || !mounted) return;
    _didLoad = true;
    load();
    if (mounted) setState(() {});
  }
}
