import 'package:flutter/material.dart';

import 'adm_api.dart';

class CatalogCache {
  CatalogCache._();
  static final CatalogCache instance = CatalogCache._();
  Map<String, List<Map<String, dynamic>>>? _catalogs;

  Future<Map<String, List<Map<String, dynamic>>>> getOrLoad(AdmApi api) async {
    if (_catalogs != null) return _catalogs!;
    _catalogs = await admLoadCatalogs(api);
    return _catalogs!;
  }

  void invalidate() => _catalogs = null;

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

Future<Map<String, List<Map<String, dynamic>>>> admLoadCatalogs(AdmApi api) async {
  final results = await Future.wait(CatalogCache.codes.map((code) async {
    try {
      final items = await api.getCatalogo(code);
      return MapEntry(code, items);
    } catch (_) {
      return MapEntry(code, <Map<String, dynamic>>[]);
    }
  }));
  return Map.fromEntries(results);
}

Future<void> admSafeRun(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Operacion realizada correctamente')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
}

Future<bool?> admConfirm(BuildContext context, String title, String message) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aceptar')),
      ],
    ),
  );
}
