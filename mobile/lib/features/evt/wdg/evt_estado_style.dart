import 'package:flutter/material.dart';

class EvtEstadoStyle {
  static String label(String estado) {
    switch (estado.toUpperCase()) {
      case 'EN_CURSO':
        return 'En curso';
      case 'FINALIZADO':
        return 'Finalizado';
      case 'CANCELADO':
        return 'Cancelado';
      case 'PLANIFICADO':
      default:
        return 'Planificado';
    }
  }

  static Color color(String estado) {
    switch (estado.toUpperCase()) {
      case 'EN_CURSO':
        return Colors.green;
      case 'FINALIZADO':
        return Colors.blue;
      case 'CANCELADO':
        return Colors.red;
      case 'PLANIFICADO':
      default:
        return Colors.amber.shade700;
    }
  }

  static Color background(String estado) => color(estado).withValues(alpha: 0.14);
}
