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
    final response = await _client.post<int>(
      'eventos',
      data,
      (value) {
        final map = value as Map<String, dynamic>? ?? {};
        return map['eventoId'] as int? ?? 0;
      },
    );

    return response.datos ?? 0;
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
