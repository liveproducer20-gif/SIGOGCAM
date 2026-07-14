import 'dart:convert';

import '../../../../core/api/api_client.dart';
import '../../../../shared/slc/prs_slc_mdl.dart';
import '../../mdl/evt_mdl.dart';
import '../api/evt_api.dart';
import '../mdl/evt_tipo_mdl.dart';

class EvtRepository {
  final EvtApi _api;

  EvtRepository({EvtApi? api}) : _api = api ?? EvtApi();

  Future<List<EvtTipoMdl>> obtenerTiposEvento() async {
    final data = await _api.obtenerTiposEvento();
    return data.map(EvtTipoMdl.fromJson).toList();
  }

  Future<List<PrsSlcMdl>> obtenerPersonalOperativo() async {
    final data = await _api.obtenerPersonalOperativo();
    return data.map(_mapPersonal).toList();
  }

  Future<List<EvtMdl>> obtenerEventos({
    int? personalId,
    bool marcarVisto = false,
  }) async {
    final data = await _api.obtenerEventos(
      personalId: personalId,
      marcarVisto: marcarVisto,
    );
    return data.map(_mapEvento).toList();
  }

  Future<int> crearEvento(Map<String, dynamic> data) {
    return _api.crearEvento(data);
  }

  Future<void> cambiarEstado(int id, String estado) {
    return _api.cambiarEstado(id, estado);
  }

  Future<void> actualizarEvento(int id, Map<String, dynamic> data) {
    return _api.actualizarEvento(id, data);
  }

  Future<void> eliminarEvento(int id) {
    return _api.eliminarEvento(id);
  }

  PrsSlcMdl _mapPersonal(Map<String, dynamic> json) {
    final nombres = json['nombres']?.toString() ?? '';
    final apellidos = json['apellidos']?.toString() ?? '';
    final nombreCompleto = json['nombre_completo']?.toString().trim();

    return PrsSlcMdl(
      id: json['id'] as int,
      nom: (nombreCompleto != null && nombreCompleto.isNotEmpty)
          ? nombreCompleto
          : '$nombres $apellidos'.trim(),
      ced: json['cedula']?.toString() ?? '',
      grado: _firstText(json, ['cargo', 'grado'], 'N/D'),
      area: _firstText(json, ['area'], 'N/D'),
      grupo: _firstText(json, ['grupo'], 'N/D'),
      jornada: _firstText(json, ['jornada'], 'N/D'),
      disp: true,
    );
  }

  EvtMdl _mapEvento(Map<String, dynamic> json) {
    final inicio = DateTime.tryParse(
      json['fecha_inicio']?.toString() ?? '',
    );
    final fin = DateTime.tryParse(
      json['fecha_fin']?.toString() ?? '',
    );

    return EvtMdl(
      id: _toInt(json['id']),
      nom: _cleanText(json['titulo']?.toString() ?? ''),
      tipoId: _toInt(json['tipo_evento_id']),
      tipo: _cleanText(json['tipo_evento']?.toString() ?? ''),
      fecha: _formatDate(inicio),
      fechaFin: _formatDate(fin),
      fechaInicioRaw: json['fecha_inicio']?.toString() ?? '',
      fechaFinRaw: json['fecha_fin']?.toString() ?? '',
      hora: _formatTime(inicio),
      lugar: _cleanText(json['lugar']?.toString() ?? ''),
      descripcion: _cleanText(json['descripcion']?.toString() ?? ''),
      prioridad: _cleanText(_firstText(json, ['prioridad', 'nivel_prioridad'], 'Normal')),
      imgUrl: _absoluteNullableText(json, ['imagen_url', 'img_url', 'imagen']),
      pdfNombre: _nullableText(json, ['pdf_nombre', 'archivo_pdf_nombre']),
      pdfUrl: _absoluteNullableText(json, ['pdf_url', 'archivo_pdf_url']),
      notificar: _toBool(json['notificar'], fallback: true),
      convocados: _toInt(json['convocados']),
      confirmados: _toInt(json['confirmados']),
      estado: _cleanText(
        json['estado']?.toString() ??
            json['estado_evento']?.toString() ??
            '',
      ),
    );
  }

  String _firstText(
    Map<String, dynamic> json,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return fallback;
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _toBool(Object? value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (['1', 'true', 'si', 'sí', 'yes'].contains(text)) return true;
    if (['0', 'false', 'no'].contains(text)) return false;
    return fallback;
  }

  String _cleanText(String value) {
    final patched = value
        .replaceAll('Reuni\u{FFFD}n', 'Reunión')
        .replaceAll('Capacitaci\u{FFFD}n', 'Capacitación')
        .replaceAll('Administraci\u{FFFD}n', 'Administración');

    if (!patched.contains('\u00C3') && !patched.contains('\u00C2')) {
      return patched;
    }

    try {
      return utf8.decode(latin1.encode(patched));
    } catch (_) {
      return patched;
    }
  }

  String? _nullableText(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }

    return null;
  }

  String? _absoluteNullableText(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = _nullableText(json, keys);
    return value == null ? null : ApiClient.absoluteUrl(value);
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
