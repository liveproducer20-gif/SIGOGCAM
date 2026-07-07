import 'package:flutter/material.dart';

import '../../data/mdl/evt_tipo_mdl.dart';
import '../../data/repository/evt_repository.dart';
import '../../../../shared/slc/prs_slc_mdl.dart';
import '../mdl/evt_new_mdl.dart';

class EvtNewCtl extends ChangeNotifier {
  final EvtNewMdl mdl = EvtNewMdl();
  final EvtRepository _repository;
  final int creadoPor;
  Future<List<EvtTipoMdl>>? _tiposFuture;

  EvtNewCtl({
    required this.creadoPor,
    EvtRepository? repository,
  }) : _repository = repository ?? EvtRepository();

  Future<List<EvtTipoMdl>> cargarTiposEvento() {
    return _tiposFuture ??= _repository.obtenerTiposEvento().then(
          (items) => items
              .where((tipo) => tipo.codigo.toUpperCase() != 'COMISION')
              .where((tipo) => tipo.nombre.toLowerCase() != 'comision')
              .toList(),
        );
  }

  void setNom(String v) {
    mdl.nom = v;
    notifyListeners();
  }

  void setTipo(EvtTipoMdl v) {
    mdl.tipoId = v.id;
    mdl.tipo = v.nombre;
    notifyListeners();
  }

  void setLugar(String v) {
    mdl.lugar = v;
    notifyListeners();
  }

  void setFechaTxt(String v) {
    mdl.fechaTxt = v;
    notifyListeners();
  }

  void setHoraIni(String v) {
    mdl.horaIni = v;
    notifyListeners();
  }

  void setHoraFin(String v) {
    mdl.horaFin = v;
    notifyListeners();
  }

  void setDesc(String v) {
    mdl.desc = v;
    notifyListeners();
  }

  void setPubAhora(bool v) {
    mdl.pubAhora = v;
    notifyListeners();
  }

  void setEnviarNot(bool v) {
    mdl.enviarNot = v;
    notifyListeners();
  }

  void setPrioridad(String v) {
    mdl.prioridad = v;
    notifyListeners();
  }

  void setImagen(String? nombre, String? url) {
    mdl.imagenNombre = nombre;
    mdl.imagenUrl = url;
    notifyListeners();
  }

  void setPdf(String? nombre, String? url) {
    mdl.pdfNombre = nombre;
    mdl.pdfUrl = url;
    notifyListeners();
  }

  void setPrsIds(List<int> ids) {
    mdl.prsIds
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  void setPrsItems(List<PrsSlcMdl> items) {
    mdl.prsItems
      ..clear()
      ..addAll(items);
    setPrsIds(items.map((e) => e.id).toSet().toList());
  }

  void setFecExp(DateTime value) {
    mdl.fecExp = value;
    mdl.fecExpTxt = _formatDate(value);
    notifyListeners();
  }

  bool get puedeCrear {
    return mdl.nom.trim().isNotEmpty &&
        mdl.tipoId != null &&
        mdl.lugar.trim().isNotEmpty &&
        mdl.fechaTxt.trim().isNotEmpty &&
        mdl.horaIni.trim().isNotEmpty &&
        mdl.horaFin.trim().isNotEmpty &&
        mdl.desc.trim().isNotEmpty &&
        mdl.prsIds.isNotEmpty;
  }

  Future<int> crearEvento() {
    if (!puedeCrear) {
      throw Exception('Complete la informacion requerida del evento');
    }

    return _repository.crearEvento({
      'titulo': mdl.nom.trim(),
      'tipoEventoId': mdl.tipoId,
      'fechaInicio': _buildDateTime(mdl.fechaTxt, mdl.horaIni),
      'fechaFin': _buildDateTime(mdl.fechaTxt, mdl.horaFin),
      'lugar': mdl.lugar.trim(),
      'descripcion': mdl.desc.trim(),
      'creadoPor': creadoPor,
      'prioridad': mdl.prioridad,
      'notificar': mdl.enviarNot,
      'imagenUrl': mdl.imagenUrl,
      'pdfNombre': mdl.pdfNombre,
      'pdfUrl': mdl.pdfUrl,
      'personalIds': mdl.prsIds.toSet().toList(),
    });
  }

  String formatDate(DateTime value) => _formatDate(value);

  String _buildDateTime(String fecha, String hora) {
    final cleanFecha = fecha.trim();
    final cleanHora = hora.trim();
    final normalizedDate = _normalizeDate(cleanFecha);
    final normalizedTime = cleanHora.length == 5 ? '$cleanHora:00' : cleanHora;

    return '$normalizedDate $normalizedTime';
  }

  String _normalizeDate(String value) {
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return value;
    }

    final parts = value.split('/');
    if (parts.length == 3) {
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year = parts[2];
      return '$year-$month-$day';
    }

    throw Exception('Use la fecha en formato dd/mm/aaaa');
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  void limpiar() {
    mdl.limpiar();
    notifyListeners();
  }
}
