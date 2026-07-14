import '../../../core/api/api_client.dart';

class SideMenuApi {
  final ApiClient _client;

  SideMenuApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Map<String, dynamic>>> getCurrentStructure() async {
    final response = await _client.getFull('configuracion/mi-estructura');
    return parseApiList(response['datos'] ?? response['data']);
  }
}
