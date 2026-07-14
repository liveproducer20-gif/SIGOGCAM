import '../data/repository/evt_repository.dart';
import '../data/mdl/evt_tipo_mdl.dart';
import '../mdl/evt_mdl.dart';
import '../../../shared/slc/prs_slc_mdl.dart';

class EvtSvc {
  static final Map<int?, List<EvtMdl>> _cache = {};
  static final Map<int?, DateTime> _cacheTime = {};
  static final Map<int?, Future<List<EvtMdl>>> _inFlight = {};
  static const _cacheDuration = Duration(seconds: 30);

  static Future<List<EvtMdl>> getLst({
    int? personalId,
    bool marcarVisto = false,
  }) {
    if (marcarVisto) {
      return EvtRepository().obtenerEventos(
        personalId: personalId,
        marcarVisto: true,
      );
    }

    final cachedAt = _cacheTime[personalId];
    if (cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheDuration) {
      return Future.value(_cache[personalId] ?? const []);
    }
    final pending = _inFlight[personalId];
    if (pending != null) return pending;

    final request = EvtRepository()
        .obtenerEventos(personalId: personalId, marcarVisto: false)
        .then((items) {
          _cache[personalId] = items;
          _cacheTime[personalId] = DateTime.now();
          return items;
        })
        .whenComplete(() {
          _inFlight.remove(personalId);
        });
    _inFlight[personalId] = request;
    return request;
  }

  static void invalidateCache() {
    _cache.clear();
    _cacheTime.clear();
    _inFlight.clear();
  }

  static Future<List<EvtTipoMdl>> getTipos() {
    return EvtRepository().obtenerTiposEvento().then(
      (items) => items
          .where((tipo) => tipo.codigo.toUpperCase() != 'COMISION')
          .where((tipo) => tipo.nombre.toLowerCase() != 'comision')
          .toList(),
    );
  }

  static Future<List<PrsSlcMdl>> getPersonalOperativo() {
    return EvtRepository().obtenerPersonalOperativo();
  }

  static Future<void> cambiarEstado(int id, String estado) {
    invalidateCache();
    return EvtRepository().cambiarEstado(id, estado);
  }

  static Future<void> actualizarEvento(int id, Map<String, dynamic> data) {
    invalidateCache();
    return EvtRepository().actualizarEvento(id, data);
  }

  static Future<void> eliminarEvento(int id) {
    invalidateCache();
    return EvtRepository().eliminarEvento(id);
  }
}
