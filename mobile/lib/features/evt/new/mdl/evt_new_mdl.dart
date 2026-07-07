import '../../../../shared/slc/prs_slc_mdl.dart';

class EvtNewMdl {
  String nom = '';
  int? tipoId;
  String tipo = 'Capacitacion';
  String lugar = '';
  String fechaTxt = '';
  DateTime? fecha;
  String horaIni = '';
  String horaFin = '';
  String desc = '';

  bool pubAhora = true;
  bool enviarNot = true;

  String prioridad = 'Normal';
  String? imagenNombre;
  String? imagenUrl;
  String? pdfNombre;
  String? pdfUrl;

  DateTime? fecExp;
  String fecExpTxt = '';

  final List<int> prsIds = [];
  final List<PrsSlcMdl> prsItems = [];

  void limpiar() {
    nom = '';
    tipoId = null;
    tipo = 'Capacitacion';
    lugar = '';
    fechaTxt = '';
    fecha = null;
    horaIni = '';
    horaFin = '';
    desc = '';

    pubAhora = true;
    enviarNot = true;

    prioridad = 'Normal';
    imagenNombre = null;
    imagenUrl = null;
    pdfNombre = null;
    pdfUrl = null;

    fecExp = null;
    fecExpTxt = '';

    prsIds.clear();
    prsItems.clear();
  }
}
