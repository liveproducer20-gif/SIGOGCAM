import '../data/repository/evt_repository.dart';
import '../data/mdl/evt_tipo_mdl.dart';
import '../mdl/evt_mdl.dart';
import '../../../shared/slc/prs_slc_mdl.dart';

class EvtSvc {
  static Future<List<EvtMdl>> getLst({
    int? personalId,
    bool marcarVisto = false,
  }) {
    return EvtRepository().obtenerEventos(
      personalId: personalId,
      marcarVisto: marcarVisto,
    );
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
    return EvtRepository().cambiarEstado(id, estado);
  }

  static Future<void> actualizarEvento(int id, Map<String, dynamic> data) {
    return EvtRepository().actualizarEvento(id, data);
  }

  static Future<void> eliminarEvento(int id) {
    return EvtRepository().eliminarEvento(id);
  }
}
