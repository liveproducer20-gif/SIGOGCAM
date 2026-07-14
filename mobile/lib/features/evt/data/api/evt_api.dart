import 'dart:convert';

import '../../../../core/api/api_client.dart';

class EvtApi {
  final ApiClient _client;

  EvtApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Map<String, dynamic>>> obtenerTiposEvento() async {
    final response = await _client.get<List<Map<String, dynamic>>>(
      'catalogos/TIPOS_EVENTO',
      parseApiList,
    );

    return response.datos ?? [];
  }

  Future<List<Map<String, dynamic>>> obtenerPersonalOperativo() async {
    final response = await _client.get<List<Map<String, dynamic>>>(
      'personal/operativos',
      parseApiList,
    );

    return response.datos ?? [];
  }

  Future<List<Map<String, dynamic>>> obtenerEventos({
    int? personalId,
    bool marcarVisto = false,
  }) async {
    final params = <String>[];
    if (personalId != null) params.add('personalId=$personalId');
    if (marcarVisto) params.add('marcarVisto=1');
    final path = params.isEmpty ? 'eventos' : 'eventos?${params.join('&')}';
    final response = await _client.get<List<Map<String, dynamic>>>(
      path,
      parseApiList,
    );

    return response.datos ?? [];
  }

  Future<int> crearEvento(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['imagenUrl'] = await _uploadDataUrl(payload['imagenUrl']);
    payload['pdfUrl'] = await _uploadDataUrl(payload['pdfUrl']);
    final response = await _client.post<int>(
      'eventos',
      payload,
      (value) {
        final map = value as Map<String, dynamic>? ?? {};
        return map['eventoId'] as int? ?? 0;
      },
    );

    return response.datos ?? 0;
  }

  Future<String?> _uploadDataUrl(Object? value) async {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    if (!text.startsWith('data:')) return text;

    final comma = text.indexOf(',');
    final separator = text.indexOf(';');
    if (comma < 0 || separator < 5 || separator > comma) {
      throw Exception('El archivo seleccionado no es válido');
    }
    final mimeType = text.substring(5, separator).toLowerCase();
    final bytes = base64Decode(text.substring(comma + 1));
    final response = await _client.postBytes<Map<String, dynamic>>(
      'eventos/archivos',
      bytes,
      mimeType,
      (data) => Map<String, dynamic>.from(data as Map),
    );
    final route = response.datos?['ruta']?.toString();
    if (route == null || route.isEmpty) {
      throw Exception('El servidor no devolvió la ruta del archivo');
    }
    return route;
  }

  Future<void> cambiarEstado(int id, String estado) async {
    await _client.put<bool>(
      'eventos/$id/estado',
      {'estado': estado},
      (_) => true,
    );
  }

  Future<void> actualizarEvento(int id, Map<String, dynamic> data) async {
    await _client.put<bool>(
      'eventos/$id',
      data,
      (_) => true,
    );
  }

  Future<void> eliminarEvento(int id) async {
    await _client.delete<bool>(
      'eventos/$id',
      (_) => true,
    );
  }
}
