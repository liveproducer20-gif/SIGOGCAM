import '../../core/api/api_client.dart';

class AdmApi {
  final ApiClient _client;

  AdmApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Map<String, dynamic>>> getPersonalList() => _getList('personal');
  Future<AdmPaginatedResult> getPersonal({int page = 1, int limit = 50, String search = ''}) =>
      _getPaginated('personal?page=$page&limit=$limit${search.isNotEmpty ? '&search=$search' : ''}', limit);

  Future<AdmPaginatedResult> getCatalogos() => _getPaginated('admin/catalogos', 50);
  Future<AdmPaginatedResult> getCatalogo(String codigo, {int page = 1, int limit = 100, String search = ''}) =>
      _getPaginated('admin/catalogos/$codigo?incluirInactivos=1&page=$page&limit=$limit${search.isNotEmpty ? '&search=$search' : ''}', limit);
  Future<void> createCatalogoDetalle(String codigo, Map<String, dynamic> data) =>
      _post('admin/catalogos/$codigo', data);
  Future<void> updateCatalogoDetalle(int id, Map<String, dynamic> data) =>
      _put('admin/catalogos/detalles/$id', data);
  Future<void> setCatalogoDetalleActivo(int id, bool activo) =>
      _put('admin/catalogos/detalles/$id/estado', {'activo': activo});

  Future<List<Map<String, dynamic>>> getRolesList() =>
      _getList('admin/roles');
  Future<AdmPaginatedResult> getRoles({int page = 1, int limit = 50, String search = ''}) =>
      _getPaginated('admin/roles?page=$page&limit=$limit${search.isNotEmpty ? '&search=$search' : ''}', limit);
  Future<List<Map<String, dynamic>>> getPermisos() =>
      _getList('admin/permisos');
  Future<void> createRol(Map<String, dynamic> data) =>
      _post('admin/roles', data);
  Future<void> updateRol(int id, Map<String, dynamic> data) =>
      _put('admin/roles/$id', data);
  Future<void> setRolActivo(int id, bool activo) =>
      _put('admin/roles/$id/estado', {'activo': activo});

  Future<List<Map<String, dynamic>>> getLugaresList() =>
      _getList('admin/lugares-servicio');
  Future<AdmPaginatedResult> getLugares({int page = 1, int limit = 50, String search = ''}) =>
      _getPaginated('admin/lugares-servicio?page=$page&limit=$limit${search.isNotEmpty ? '&search=$search' : ''}', limit);
  Future<void> createLugar(Map<String, dynamic> data) =>
      _post('admin/lugares-servicio', data);
  Future<void> updateLugar(int id, Map<String, dynamic> data) =>
      _put('admin/lugares-servicio/$id', data);
  Future<void> setLugarActivo(int id, bool activo) =>
      _put('admin/lugares-servicio/$id/estado', {'activo': activo});

  Future<List<Map<String, dynamic>>> getEasList() =>
      _getList('admin/eas');
  Future<AdmPaginatedResult> getEas({int page = 1, int limit = 50, String search = ''}) =>
      _getPaginated('admin/eas?page=$page&limit=$limit${search.isNotEmpty ? '&search=$search' : ''}', limit);
  Future<void> createEas(Map<String, dynamic> data) =>
      _post('admin/eas', data);
  Future<void> updateEas(int id, Map<String, dynamic> data) =>
      _put('admin/eas/$id', data);
  Future<void> setEasActivo(int id, bool activo) =>
      _put('admin/eas/$id/estado', {'activo': activo});

  Future<List<Map<String, dynamic>>> getRutas() =>
      _getList('admin/rutas');
  Future<List<Map<String, dynamic>>> getGrados() =>
      _getList('admin/grados');
  Future<void> createRuta(Map<String, dynamic> data) =>
      _post('admin/rutas', data);
  Future<void> updateRuta(int id, Map<String, dynamic> data) =>
      _put('admin/rutas/$id', data);
  Future<void> setRutaActivo(int id, bool activo) =>
      _put('admin/rutas/$id/estado', {'activo': activo});

  Future<List<Map<String, dynamic>>> getMovilesList() =>
      _getList('admin/moviles');
  Future<AdmPaginatedResult> getMoviles({int page = 1, int limit = 50, String search = ''}) =>
      _getPaginated('admin/moviles?page=$page&limit=$limit${search.isNotEmpty ? '&search=$search' : ''}', limit);
  Future<void> createMovil(Map<String, dynamic> data) =>
      _post('admin/moviles', data);
  Future<void> updateMovil(int id, Map<String, dynamic> data) =>
      _put('admin/moviles/$id', data);
  Future<void> setMovilActivo(int id, bool activo) =>
      _put('admin/moviles/$id/estado', {'activo': activo});

  Future<List<Map<String, dynamic>>> getAsignacionesList() =>
      _getList('admin/movil-eas-asignaciones');
  Future<AdmPaginatedResult> getAsignaciones({int page = 1, int limit = 50, String search = ''}) =>
      _getPaginated('admin/movil-eas-asignaciones?page=$page&limit=$limit${search.isNotEmpty ? '&search=$search' : ''}', limit);
  Future<void> createAsignacion(Map<String, dynamic> data) =>
      _post('admin/movil-eas-asignaciones', data);
  Future<void> updateAsignacion(int id, Map<String, dynamic> data) =>
      _put('admin/movil-eas-asignaciones/$id', data);

  Future<void> createPersonal(Map<String, dynamic> data) => _post('personal', data);
  Future<void> updatePersonal(int id, Map<String, dynamic> data) => _put('personal/$id', data);
  Future<void> setPersonalActivo(int id, bool activo) => _put('personal/$id/estado', {'activo': activo});
  Future<void> resetPassword(int id) => _post('personal/$id/reset-password', {});
  Future<void> deletePersonal(int id) => _delete('personal/$id');
  Future<void> deleteCatalogoDetalle(int id) => _delete('admin/catalogos/detalles/$id');
  Future<void> deleteRol(int id) => _delete('admin/roles/$id');
  Future<void> deleteLugar(int id) => _delete('admin/lugares-servicio/$id');
  Future<void> deleteEas(int id) => _delete('admin/eas/$id');
  Future<void> deleteRuta(int id) => _delete('admin/rutas/$id');
  Future<void> deleteMovil(int id) => _delete('admin/moviles/$id');
  Future<void> deleteAsignacion(int id) => _delete('admin/movil-eas-asignaciones/$id');

  Future<List<Map<String, dynamic>>> getAlertasMantenimiento() =>
      _getList('admin/dashboard/mantenimiento');

  Future<List<Map<String, dynamic>>> getMantenimientos(int movilId) =>
      _getList('admin/moviles/$movilId/mantenimientos');
  Future<void> createMantenimiento(int movilId, Map<String, dynamic> data) =>
      _post('admin/moviles/$movilId/mantenimientos', data);

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _client.get<List<Map<String, dynamic>>>(
      path,
      parseApiList,
    );
    return response.datos ?? [];
  }

  Future<AdmPaginatedResult> _getPaginated(String path, int limit) async {
    final full = await _client.getFull(path);
    final datos = parseApiList(full['datos']);
    final total = full['total'] as int? ?? datos.length;
    final page = full['page'] as int? ?? 1;
    return AdmPaginatedResult(datos: datos, total: total, page: page, limit: limit);
  }

  Future<void> _post(String path, Map<String, dynamic> data) async {
    await _client.post<bool>(path, data, (_) => true);
  }

  Future<void> _put(String path, Map<String, dynamic> data) async {
    await _client.put<bool>(path, data, (_) => true);
  }

  Future<void> _delete(String path) async {
    await _client.delete<bool>(path, (_) => true);
  }
}

class AdmPaginatedResult {
  final List<Map<String, dynamic>> datos;
  final int total;
  final int page;
  final int limit;

  const AdmPaginatedResult({
    required this.datos,
    required this.total,
    this.page = 1,
    this.limit = 50,
  });

  int get totalPages {
    if (total == 0) return 1;
    return (total / limit).ceil();
  }
}
