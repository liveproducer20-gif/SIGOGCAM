import '../../core/api/api_client.dart';
import 'ins_mdl.dart';

class InsApi {
  final ApiClient _client;

  InsApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<CartillaRegistroMdl> registrarCartilla({
    required String contenido,
    String? causa,
  }) async {
    final response = await _client.post<CartillaRegistroMdl>(
      'cartillas',
      {'contenido': contenido, 'causa': causa},
      (value) =>
          CartillaRegistroMdl.fromJson(Map<String, dynamic>.from(value as Map)),
    );

    return response.datos!;
  }

  Future<List<InsMdl>> obtenerTodas() async {
    final response = await _client.get<List<InsMdl>>('insignias', (value) {
      final list = value as List<dynamic>? ?? [];
      return list
          .whereType<Map>()
          .map((e) => InsMdl.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });

    return response.datos ?? [];
  }

  Future<List<InsMdl>> obtenerUsuarioInsignias(int usuarioId) async {
    final response = await _client.get<List<InsMdl>>(
      'usuarios/$usuarioId/insignias',
      (value) {
        final list = value as List<dynamic>? ?? [];
        return list
            .whereType<Map>()
            .map((e) => InsMdl.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );

    return response.datos ?? [];
  }

  Future<InsProgresoMdl> obtenerProgreso(int usuarioId) async {
    final response = await _client.get<InsProgresoMdl>(
      'usuarios/$usuarioId/progreso-insignias',
      (value) =>
          InsProgresoMdl.fromJson(Map<String, dynamic>.from(value as Map)),
    );

    return response.datos!;
  }

  Future<List<Map<String, dynamic>>> obtenerRanking() async {
    final response = await _client.get<List<Map<String, dynamic>>>(
      'insignias/ranking',
      (value) {
        final list = value as List<dynamic>? ?? [];
        return list
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      },
    );

    return response.datos ?? [];
  }
}
