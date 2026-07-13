import 'dart:async';

import 'package:flutter/material.dart';

import 'adm_api.dart';

class CatalogCache {
  CatalogCache._();
  static final CatalogCache instance = CatalogCache._();
  Map<String, List<Map<String, dynamic>>>? _catalogs;
  DateTime? _loadedAt;

  static const Duration _ttl = Duration(minutes: 5);

  Future<Map<String, List<Map<String, dynamic>>>> getOrLoad(AdmApi api) async {
    if (_catalogs != null &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < _ttl) {
      return _catalogs!;
    }
    _catalogs = await admLoadCatalogs(api);
    _loadedAt = DateTime.now();
    return _catalogs!;
  }

  void invalidate() {
    _catalogs = null;
    _loadedAt = null;
  }

  Future<List<Map<String, dynamic>>> getOne(AdmApi api, String code) async {
    final all = await getOrLoad(api);
    return all[code] ?? [];
  }

  static const codes = [
    'AREAS',
    'FUNCIONES_OPERATIVAS',
    'GRUPOS',
    'JORNADAS',
    'TIPOS_ROTACION',
    'ESTADOS_PERSONAL',
    'DISTRITOS',
    'SUBUNIDADES_OPERATIVAS',
    'TIPOS_SERVICIO_LUGAR',
    'TIPOS_MOVIL',
    'ESTADOS_MOVIL',
    'TIPOS_MANTENIMIENTO',
  ];
}

Future<Map<String, List<Map<String, dynamic>>>> admLoadCatalogs(
  AdmApi api,
) async {
  final results = await Future.wait(
    CatalogCache.codes.map((code) async {
      try {
        final paginated = await api.getCatalogo(code, page: 1, limit: 200);
        return MapEntry(code, paginated.datos);
      } catch (_) {
        return MapEntry(code, <Map<String, dynamic>>[]);
      }
    }),
  );
  return Map.fromEntries(results);
}

Future<void> admSafeRun(
  BuildContext context,
  Future<void> Function() action,
) async {
  var loaderVisible = false;
  try {
    loaderVisible = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    SizedBox(width: 16),
                    Text('Guardando cambios...'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await action();
    if (context.mounted && loaderVisible) {
      Navigator.of(context, rootNavigator: true).pop();
      loaderVisible = false;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Operación realizada correctamente')),
    );
  } catch (error) {
    if (context.mounted && loaderVisible) {
      Navigator.of(context, rootNavigator: true).pop();
      loaderVisible = false;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

Future<bool?> admConfirm(BuildContext context, String title, String message) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}
