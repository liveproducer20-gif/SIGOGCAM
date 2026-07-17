import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/crt/mdl/crt_enums.dart';
import 'package:mobile/features/crt/mdl/crt_models.dart';
import 'package:mobile/features/crt/svc/crt_catalog.dart';
import 'package:mobile/features/crt/svc/crt_text_generator.dart';

void main() {
  CrtFormData makeOtras({
    TipoModuloCartilla modulo = TipoModuloCartilla.filaPedestre,
    String distrito = '',
    String causa = 'NOVEDAD',
    String novedad = 'Procedimiento de prueba.',
    String personal = 'ACM Pérez Juan',
    String reporta = 'ACM Pérez Juan',
    String movil = '',
    String bicicleta = '',
    String cuadrante = '',
    String motorizado = '',
    String conductor = '',
    String auxiliar1 = '',
    String auxiliar2 = '',
    String ruta = '',
  }) =>
      CrtFormData(
        modulo: modulo,
        tipo: TipoCartilla.novedades,
        jornada: Jornada.vespertina,
        horario: '14:00 A 22:30',
        fecha: '14/07/2026',
        hora: '19:25',
        values: {
          'direccion': 'Av. 9 de Octubre y 10 de Agosto',
          'causa': causa,
          'novedad': novedad,
          'personal': personal,
          'reporta': reporta,
          'distrito': distrito,
          'movil': movil,
          'bicicleta': bicicleta,
          'cuadrante': cuadrante,
          'motorizado': motorizado,
          'conductor': conductor,
          'auxiliar1': auxiliar1,
          'auxiliar2': auxiliar2,
          'ruta': ruta,
        },
      );

  test('_buildOtras shows distrito when provided', () {
    final text = CrtTextGenerator.build(makeOtras(distrito: '#5 MODELO'));
    expect(text, contains('*DISTRITO:* #5 MODELO'));
    expect(text, contains('*DIRECCIÓN:* Av. 9 de Octubre y 10 de Agosto'));
  });

  test('_buildOtras omits distrito line when empty', () {
    final text = CrtTextGenerator.build(makeOtras());
    expect(text, isNot(contains('*DISTRITO:*')));
    expect(text, contains('*DIRECCIÓN:* Av. 9 de Octubre y 10 de Agosto'));
  });

  test('_buildOtras includes fixed phrase after novedad', () {
    final text = CrtTextGenerator.build(makeOtras());
    expect(text, contains('Así mismo, notifico novedades para fines pertinentes.'));
  });

  test('_buildOtras ciclista shows Bicicleta prefix in REPORTA', () {
    final text = CrtTextGenerator.build(
      makeOtras(modulo: TipoModuloCartilla.ciclista, bicicleta: '042', reporta: 'ACM Torres Luis'),
    );
    expect(text, contains('*REPORTE DE CICLISTA*'));
    expect(text, contains('Bicicleta 042 - ACM Torres Luis'));
  });

  test('_buildConductor shows MÓVIL and RUTA', () {
    final text = CrtTextGenerator.build(
      makeOtras(
        modulo: TipoModuloCartilla.conductor,
        movil: '187',
        ruta: 'Circuito Centro',
        conductor: 'Ramirez Bolívar',
      ),
    );
    expect(text, contains('*REPORTE DE CONDUCTOR*'));
    expect(text, contains('*MÓVIL:* 187'));
    expect(text, contains('*RUTA/CIRCUITO:* Circuito Centro'));
    expect(text, contains('Ramirez Bolívar'));
  });

  test('_buildRadioperador uses institutional shift schedule', () {
    final morning = CrtFormData(
      modulo: TipoModuloCartilla.radioperador,
      tipo: TipoCartilla.ingreso,
      jornada: Jornada.matutina,
      horario: '06:00 A 14:30',
      fecha: '14/07/2026',
      hora: '08:00',
      values: {
        'direccion': 'Av. 9 de Octubre',
        'causa': 'CAMBIO DE PERSONAL',
        'personal': 'ACM García',
        'moviles': '187\n188',
      },
    );
    final text = CrtTextGenerator.build(morning);
    expect(text, contains('*REPORTE DE RADIOOPERADORES EAS*'));
    expect(text, matches(RegExp(r'\*HORARIO:\* 0[6-9]:00 A 1[0-4]:30|\*HORARIO:\* 2[2-3]:00 A 0[0-6]:30|\*HORARIO:\* 1[4-9]:00 A 2[2-3]:30')));
  });

  test('_buildRadioperador evening shift', () {
    final evening = CrtFormData(
      modulo: TipoModuloCartilla.radioperador,
      tipo: TipoCartilla.novedades,
      jornada: Jornada.vespertina,
      horario: '14:00 A 22:30',
      fecha: '14/07/2026',
      hora: '16:00',
      values: {
        'direccion': 'Av. 9 de Octubre',
        'causa': 'CAMBIO DE PERSONAL',
        'personal': 'ACM López',
        'moviles': '189',
      },
    );
    final text = CrtTextGenerator.build(evening);
    expect(text, contains('*HORARIO:*'));
    expect(text, contains('*PERSONAL:*'));
    expect(text, contains('ACM López'));
  });

  test('_buildRadioperador night shift', () {
    final night = CrtFormData(
      modulo: TipoModuloCartilla.radioperador,
      tipo: TipoCartilla.salida,
      jornada: Jornada.amanecida,
      horario: '22:00 A 06:30',
      fecha: '14/07/2026',
      hora: '23:00',
      values: {
        'direccion': 'Av. 9 de Octubre',
        'causa': 'CAMBIO DE PERSONAL',
      },
    );
    final text = CrtTextGenerator.build(night);
    expect(text, contains('*HORARIO:*'));
    expect(text, contains('*REPORTE DE RADIOOPERADORES EAS*'));
  });

  test('_buildOtras cuadrante shows CUADRANTE, MÓVIL, MOTORIZADO', () {
    final text = CrtTextGenerator.build(
      makeOtras(
        modulo: TipoModuloCartilla.cuadrante,
        cuadrante: 'Cuadrante Centro',
        movil: '190',
        motorizado: 'ACM Vera Carlos',
      ),
    );
    expect(text, contains('*CUADRANTE:* Cuadrante Centro'));
    expect(text, contains('*MÓVIL:* 190'));
    expect(text, contains('*MOTORIZADO:* ACM Vera Carlos'));
  });

  test('_buildOtras supervision shows movil and auxiliares', () {
    final text = CrtTextGenerator.build(
      makeOtras(
        modulo: TipoModuloCartilla.supervision,
        movil: '195',
        conductor: 'ACM Morales',
        auxiliar1: 'ACM Paredes',
        auxiliar2: 'ACM Salazar',
      ),
    );
    expect(text, contains('*MÓVIL:* 195'));
    expect(text, contains('*CONDUCTOR:* ACM Morales'));
    expect(text, contains('*AUXILIAR 1:* ACM Paredes'));
    expect(text, contains('*AUXILIAR 2:* ACM Salazar'));
  });

  test('RT in filaPedestre shows RT section with 3 fields', () {
    final data = CrtFormData(
      modulo: TipoModuloCartilla.filaPedestre,
      tipo: TipoCartilla.retiroTemporal,
      jornada: Jornada.vespertina,
      horario: '14:00 A 22:30',
      fecha: '14/07/2026',
      hora: '19:25',
      values: {
        'direccion': 'Av. 9 de Octubre',
        'causa': 'RETIRO TEMPORAL',
        'novedad': 'Se realizó el retiro.',
        'personal': 'ACM Pérez Juan',
        'reporta': 'ACM Pérez Juan',
        'actividad': 'Venta informal de alimentos',
        'elementos': 'Mesas, sillas, toldos',
        'cantidad': '5 unidades',
      },
    );
    final text = CrtTextGenerator.build(data);
    expect(text, contains('*REPORTE DE FILA/PEDESTRE*'));
    expect(text, contains('*RETIRO TEMPORAL:*'));
    expect(text, contains('Actividad comercial: Venta informal de alimentos'));
    expect(text, contains('Elementos retirados: Mesas, sillas, toldos'));
    expect(text, contains('Cantidad aproximada: 5 unidades'));
  });

  test('RT in motorizado shows RT section', () {
    final data = CrtFormData(
      modulo: TipoModuloCartilla.motorizado,
      tipo: TipoCartilla.retiroTemporal,
      jornada: Jornada.vespertina,
      horario: '14:00 A 22:30',
      fecha: '14/07/2026',
      hora: '19:25',
      values: {
        'direccion': 'Av. 9 de Octubre',
        'causa': 'RETIRO TEMPORAL',
        'novedad': 'Se realizó el retiro.',
        'personal': 'ACM Morales',
        'reporta': 'ACM Morales',
        'actividad': 'Venta de bebidas',
        'elementos': 'Refrigeradores portátiles',
        'cantidad': '2 unidades',
      },
    );
    final text = CrtTextGenerator.build(data);
    expect(text, contains('*REPORTE DE MOTORIZADO*'));
    expect(text, contains('*RETIRO TEMPORAL:*'));
    expect(text, contains('Actividad comercial: Venta de bebidas'));
  });

  test('RT in ambiente shows RT section', () {
    final data = CrtFormData(
      modulo: TipoModuloCartilla.ambiente,
      tipo: TipoCartilla.retiroTemporal,
      jornada: Jornada.vespertina,
      horario: '14:00 A 22:30',
      fecha: '14/07/2026',
      hora: '19:25',
      values: {
        'direccion': 'Av. 9 de Octubre',
        'causa': 'RETIRO TEMPORAL',
        'novedad': '',
        'personal': 'ACM López',
        'reporta': 'ACM López',
        'actividad': 'Comercio de ropa',
      },
    );
    final text = CrtTextGenerator.build(data);
    expect(text, contains('*REPORTE DE AMBIENTE GOCAM*'));
    expect(text, contains('*RETIRO TEMPORAL:*'));
    expect(text, contains('Actividad comercial: Comercio de ropa'));
    expect(text, isNot(contains('Elementos retirados')));
  });

  test('RT without fields omits RT section', () {
    final data = CrtFormData(
      modulo: TipoModuloCartilla.filaPedestre,
      tipo: TipoCartilla.retiroTemporal,
      jornada: Jornada.vespertina,
      horario: '14:00 A 22:30',
      fecha: '14/07/2026',
      hora: '19:25',
      values: {
        'direccion': 'Av. 9 de Octubre',
        'causa': 'RETIRO TEMPORAL',
        'novedad': 'Novedad cualquiera.',
        'personal': 'ACM Pérez',
        'reporta': 'ACM Pérez',
      },
    );
    final text = CrtTextGenerator.build(data);
    expect(text, isNot(contains('*RETIRO TEMPORAL:*')));
  });

  test('retiroTemporal is in commonTypes', () {
    expect(CrtCatalog.commonTypes, contains(TipoCartilla.retiroTemporal));
  });
}
