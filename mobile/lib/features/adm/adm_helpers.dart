import 'package:flutter/material.dart';

import 'adm_api.dart';

Future<Map<String, List<Map<String, dynamic>>>> admLoadCatalogs(AdmApi api) async {
  const codes = [
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
  final results = await Future.wait(codes.map((code) async {
    try {
      final items = await api.getCatalogo(code);
      return MapEntry(code, items);
    } catch (_) {
      return MapEntry(code, <Map<String, dynamic>>[]);
    }
  }));
  return Map.fromEntries(results);
}

/// Ejecuta una accion y muestra un mensaje claro segun el resultado.
/// [operation] describe la accion para personalizar el mensaje
/// (por ejemplo 'eliminar', 'guardar', 'actualizar').
Future<void> admSafeRun(
  BuildContext context,
  Future<void> Function() action, {
  String operation = 'realizar la operacion',
}) async {
  try {
    await action();
    if (!context.mounted) return;
    final exito = operation.toLowerCase().contains('elimin')
        ? 'Se elimino correctamente.'
        : 'Operacion realizada correctamente.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(exito)),
    );
  } catch (error) {
    if (!context.mounted) return;
    final fallo = operation.toLowerCase().contains('elimin')
        ? 'No se pudo eliminar: ${_admMensaje(error)}'
        : 'No se pudo $operation: ${_admMensaje(error)}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(fallo)),
    );
  }
}

/// Confirma y elimina un elemento mostrando siempre un mensaje claro:
/// exito, cancelacion o error.
Future<void> admSafeDelete(
  BuildContext context,
  String label,
  Future<void> Function() deleteFn,
) async {
  final ok = await admConfirm(context, 'Confirmar', '¿Eliminar $label?');
  if (ok != true) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se elimino. Accion cancelada.')),
    );
    return;
  }
  await admSafeRun(context, deleteFn, operation: 'eliminar');
}

String _admMensaje(Object error) {
  final msg = error.toString().replaceFirst(RegExp(r'^.*Exception:\s*'), '');
  return msg.isEmpty ? 'Error desconocido' : msg;
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
