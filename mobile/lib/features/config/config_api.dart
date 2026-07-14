import '../../core/api/api_client.dart';
import 'config_mdl.dart';

class ConfigApi {
  final ApiClient _client;

  ConfigApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<EstructuraData> getEstructura() async {
    final res = await _client.getFull('configuracion/estructura');
    return EstructuraData.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<List<ModuloModel>> getModulos() async {
    final res = await _client.getFull('configuracion/modulos');
    return ((res['data'] as List<dynamic>?) ?? [])
        .map((e) => ModuloModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ModuloModel> crearModulo(Map<String, dynamic> body) async {
    final res = await _client.postFull('configuracion/modulos', body);
    return ModuloModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<ModuloModel> actualizarModulo(int id, Map<String, dynamic> body) async {
    final res = await _client.putFull('configuracion/modulos/$id', body);
    return ModuloModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> eliminarModulo(int id) async {
    await _client.deleteFull('configuracion/modulos/$id');
  }

  Future<List<dynamic>> getPermisosModulo(int id) async {
    final res = await _client.getFull('configuracion/modulos/$id/permisos');
    return (res['data'] as List<dynamic>?) ?? [];
  }

  Future<List<RolMenuConfigModel>> getMenuRol(int rolId) async {
    final res = await _client.getFull('configuracion/roles/$rolId/menu');
    return ((res['data'] as List<dynamic>?) ?? [])
        .map((e) => RolMenuConfigModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> guardarMenuRol(int rolId, List<Map<String, dynamic>> items) async {
    await _client.putFull('configuracion/roles/$rolId/menu', {'items': items});
  }

  Future<List<ScopeModel>> getAlcanceRol(int rolId) async {
    final res = await _client.getFull('configuracion/roles/$rolId/alcance');
    return ((res['data'] as List<dynamic>?) ?? [])
        .map((e) => ScopeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> guardarAlcanceRol(int rolId, List<Map<String, dynamic>> items) async {
    await _client.putFull('configuracion/roles/$rolId/alcance', {'items': items});
  }

  Future<List<CampoPermisoModel>> getCamposRol(int rolId) async {
    final res = await _client.getFull('configuracion/roles/$rolId/campos');
    return ((res['data'] as List<dynamic>?) ?? [])
        .map((e) => CampoPermisoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> guardarCamposRol(int rolId, List<Map<String, dynamic>> items) async {
    await _client.putFull('configuracion/roles/$rolId/campos', {'items': items});
  }

  Future<List<VersionModel>> getVersiones(int rolId) async {
    final res = await _client.getFull('configuracion/roles/$rolId/versiones');
    return ((res['data'] as List<dynamic>?) ?? [])
        .map((e) => VersionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> crearVersion(int rolId, String datosJson, {String? descripcion}) async {
    await _client.postFull('configuracion/roles/$rolId/versiones', {
      'datos_json': datosJson,
      'descripcion': descripcion ?? '',
    });
  }

  Future<void> restaurarVersion(int rolId, int versionId) async {
    await _client.postFull(
      'configuracion/roles/$rolId/versiones/$versionId/restaurar',
      {},
    );
  }

  Future<List<AuditoriaModel>> getAuditoria({
    int? rolId,
    String? modulo,
    String? accion,
    int? limite,
  }) async {
    final params = <String, String>{};
    if (rolId != null) params['rolId'] = rolId.toString();
    if (modulo != null) params['modulo'] = modulo;
    if (accion != null) params['accion'] = accion;
    if (limite != null) params['limite'] = limite.toString();
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final res = await _client
        .getFull('configuracion/auditoria${query.isNotEmpty ? '?$query' : ''}');
    return ((res['data'] as List<dynamic>?) ?? [])
        .map((e) => AuditoriaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<dynamic>> getCamposSistema({String? entidad}) async {
    final q = entidad != null ? '?entidad=$entidad' : '';
    final res = await _client.getFull('configuracion/campos-sistema$q');
    return (res['data'] as List<dynamic>?) ?? [];
  }
}
