import '../../core/api/api_client.dart';

class AdmApi {
  final ApiClient _client;

  AdmApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Map<String, dynamic>>> getPersonal() => _getList('personal');
  Future<void> createPersonal(Map<String, dynamic> data) =>
      _post('personal', data);
  Future<void> updatePersonal(int id, Map<String, dynamic> data) =>
      _put('personal/$id', data);
  Future<void> setPersonalActivo(int id, bool activo) =>
      _put('personal/$id/estado', {'activo': activo});
  Future<void> resetPassword(int id) =>
      _post('personal/$id/reset-password', {});

  Future<List<Map<String, dynamic>>> getCatalogos() =>
      _getList('admin/catalogos');
  Future<List<Map<String, dynamic>>> getCatalogo(String codigo) =>
      _getList('admin/catalogos/$codigo?incluirInactivos=1');
  Future<void> createCatalogoDetalle(String codigo, Map<String, dynamic> data) =>
      _post('admin/catalogos/$codigo', data);
  Future<void> updateCatalogoDetalle(int id, Map<String, dynamic> data) =>
      _put('admin/catalogos/detalles/$id', data);
  Future<void> setCatalogoDetalleActivo(int id, bool activo) =>
      _put('admin/catalogos/detalles/$id/estado', {'activo': activo});

  Future<List<Map<String, dynamic>>> getRoles() => _getList('admin/roles');
  Future<List<Map<String, dynamic>>> getPermisos() =>
      _getList('admin/permisos');
  Future<void> createRol(Map<String, dynamic> data) =>
      _post('admin/roles', data);
  Future<void> updateRol(int id, Map<String, dynamic> data) =>
      _put('admin/roles/$id', data);
  Future<void> setRolActivo(int id, bool activo) =>
      _put('admin/roles/$id/estado', {'activo': activo});

  Future<List<Map<String, dynamic>>> getLugares() =>
      _getList('admin/lugares-servicio');
  Future<void> createLugar(Map<String, dynamic> data) =>
      _post('admin/lugares-servicio', data);
  Future<void> updateLugar(int id, Map<String, dynamic> data) =>
      _put('admin/lugares-servicio/$id', data);
  Future<void> setLugarActivo(int id, bool activo) =>
      _put('admin/lugares-servicio/$id/estado', {'activo': activo});

  Future<List<Map<String, dynamic>>> getEas() => _getList('admin/eas');
  Future<void> createEas(Map<String, dynamic> data) =>
      _post('admin/eas', data);
  Future<void> updateEas(int id, Map<String, dynamic> data) =>
      _put('admin/eas/$id', data);
  Future<void> setEasActivo(int id, bool activo) =>
      _put('admin/eas/$id/estado', {'activo': activo});

  Future<List<Map<String, dynamic>>> getMoviles() =>
      _getList('admin/moviles');
  Future<void> createMovil(Map<String, dynamic> data) =>
      _post('admin/moviles', data);
  Future<void> updateMovil(int id, Map<String, dynamic> data) =>
      _put('admin/moviles/$id', data);
  Future<void> setMovilActivo(int id, bool activo) =>
      _put('admin/moviles/$id/estado', {'activo': activo});

  Future<List<Map<String, dynamic>>> getAsignaciones() =>
      _getList('admin/movil-eas-asignaciones');
  Future<void> createAsignacion(Map<String, dynamic> data) =>
      _post('admin/movil-eas-asignaciones', data);
  Future<void> updateAsignacion(int id, Map<String, dynamic> data) =>
      _put('admin/movil-eas-asignaciones/$id', data);

  Future<List<Map<String, dynamic>>> getAlertasMantenimiento() =>
      _getList('admin/dashboard/mantenimiento');

  Future<List<Map<String, dynamic>>> getMantenimientos(int movilId) =>
      _getList('admin/moviles/$movilId/mantenimientos');
  Future<void> createMantenimiento(int movilId, Map<String, dynamic> data) =>
      _post('admin/moviles/$movilId/mantenimientos', data);

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _client.get<List<Map<String, dynamic>>>(
      path,
      _parseList,
    );
    return response.datos ?? [];
  }

  Future<void> _post(String path, Map<String, dynamic> data) async {
    await _client.post<bool>(path, data, (_) => true);
  }

  Future<void> _put(String path, Map<String, dynamic> data) async {
    await _client.put<bool>(path, data, (_) => true);
  }

  List<Map<String, dynamic>> _parseList(Object? value) {
    final list = value as List<dynamic>? ?? [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
