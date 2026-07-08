import '../../../core/api/api_client.dart';

class CrtApi {
  final ApiClient _client;

  CrtApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<String?> getCp() async {
    final resp = await _client.get<Map<String, dynamic>>(
      'cartillas/temp/cp',
      (value) => Map<String, dynamic>.from(value as Map),
    );
    return resp.datos?['nombreCp'] as String?;
  }

  Future<void> saveCp(String nombreCp) async {
    await _client.put('cartillas/temp/cp', {'nombreCp': nombreCp}, (_) => true);
  }

  Future<Map<String, dynamic>?> getPolicia() async {
    final resp = await _client.get<Map<String, dynamic>>(
      'cartillas/temp/policia',
      (value) => Map<String, dynamic>.from(value as Map),
    );
    return resp.datos;
  }

  Future<void> savePolicia(int? servidorPolicialId) async {
    await _client.put(
      'cartillas/temp/policia',
      {'servidorPolicialId': servidorPolicialId},
      (_) => true,
    );
  }

  Future<List<Map<String, dynamic>>> getServidoresPoliciales() async {
    final resp = await _client.get<List>(
      'cartillas/servidores-policiales',
      (value) => value as List,
    );
    return (resp.datos ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getDirecciones(int easId) async {
    final resp = await _client.get<List>(
      'cartillas/eas-direcciones?easId=$easId',
      (value) => value as List,
    );
    return (resp.datos ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> crearDireccion(int easId, String direccion) async {
    await _client.post(
      'cartillas/eas-direcciones',
      {'easId': easId, 'direccion': direccion},
      (_) => true,
    );
  }
}
