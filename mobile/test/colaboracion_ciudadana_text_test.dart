import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/crt/svc/colaboracion_ciudadana_text.dart';

void main() {
  ColaboracionCiudadanaData data({
    String servicio = 'EAS',
    String motivo = 'Robo o hurto',
    bool conNovedades = false,
    String detalleNovedad = '',
    String accion = 'la verificación correspondiente y brindó apoyo',
    String resultado = 'coordinar la atención del requerimiento',
    String? moto,
    String? can,
    String? movil,
    String? bicicleta,
    String? videoperador,
    List<String> moviles = const [],
  }) {
    return ColaboracionCiudadanaData(
      servicio: servicio,
      distrito: 'DISTRITO 5 MODELO',
      circuito: 'EAS 12 CEIBOS',
      fechaHora: DateTime(2026, 7, 19, 11, 25),
      direccion: 'Av. del Bombero y Calle Primera',
      jefe: 'Maldonado Cabrera Freddy',
      reporta: 'CALDERÓN AGUIRRE JORGE',
      nombreCiudadano: 'Carlos Carpio',
      cedula: '0912345678',
      contacto: '0991234567',
      motivo: motivo,
      accion: accion,
      resultado: resultado,
      conNovedades: conNovedades,
      detalleNovedad: detalleNovedad,
      moto: moto,
      can: can,
      movil: movil,
      bicicleta: bicicleta,
      videoperador: videoperador,
      movilesEnCirculacion: moviles,
    );
  }

  test('genera el encabezado dinámico y los datos del ciudadano', () {
    final text = ColaboracionCiudadanaText.build(data());

    expect(text, contains('*REPORTE DE EAS*'));
    expect(text, contains('*DISTRITO:* DISTRITO 5 MODELO'));
    expect(text, contains('*CIRCUITO:* EAS 12 CEIBOS'));
    expect(text, contains('*HORA:* 11:25'));
    expect(text, contains('*FECHA:* 19/07/2026'));
    expect(text, contains('*DIRECCIÓN:* Av. del Bombero y Calle Primera'));
    expect(text, contains('Carlos Carpio'));
    expect(text, contains('0912345678 y número de contacto 0991234567'));
  });

  test('mantiene todo el procedimiento en un solo párrafo', () {
    final text = ColaboracionCiudadanaText.build(
      data(
        accion: 'se realizó\nla verificación correspondiente.',
        resultado: 'coordinar\nla atención.',
      ),
    );
    final start = text.indexOf('Muy respetuosamente');
    final end = text.indexOf('\n\n*REPORTA:*');
    final body = text.substring(start, end);

    expect(body, isNot(contains('\n')));
    expect(
      body,
      contains(
        'realizó se realizó la verificación correspondiente, permitiendo coordinar la atención.',
      ),
    );
  });

  for (final motivo in const [
    'Persona extraviada',
    'Adulto mayor',
    'Menor de edad',
    'Primeros auxilios',
  ]) {
    test('integra el motivo $motivo', () {
      final text = ColaboracionCiudadanaText.build(data(motivo: motivo));
      expect(text, contains('por motivo de ${motivo.toLowerCase()}.'));
    });
  }

  test('otro motivo usa la descripción específica', () {
    final text = ColaboracionCiudadanaText.build(
      data(motivo: 'acompañamiento para recuperar una mascota'),
    );

    expect(
      text,
      contains('por motivo de acompañamiento para recuperar una mascota.'),
    );
    expect(text, isNot(contains('Otro motivo')));
  });

  test('genera el cierre sin novedades', () {
    final text = ColaboracionCiudadanaText.build(data());
    expect(text, contains('La colaboración culminó sin novedades.'));
    expect(text, isNot(contains('registrándose')));
  });

  test('genera el cierre con novedades y su detalle', () {
    final text = ColaboracionCiudadanaText.build(
      data(conNovedades: true, detalleNovedad: 'una alerta médica'),
    );
    expect(
      text,
      contains(
        'La colaboración culminó con novedades, registrándose una alerta médica.',
      ),
    );
  });

  test('radioperador muestra EAS, móviles activos y videoperador', () {
    final text = ColaboracionCiudadanaText.build(
      data(
        servicio: 'RADIOPERADOR',
        videoperador: 'Ana Pérez',
        moviles: const ['187', '189'],
      ),
    );

    expect(text, contains('*REPORTE DE RADIOPERADOR*'));
    expect(text, contains('*CIRCUITO:* EAS 12 CEIBOS'));
    expect(text, contains('*MÓVILES EN CIRCULACIÓN:* Móvil 187, Móvil 189'));
    expect(text, contains('*VIDEOPERADOR:* Ana Pérez'));
    expect(text, isNot(contains('*EAS:*')));
  });

  test('incluye únicamente el dato específico del servicio actual', () {
    final motorizado = ColaboracionCiudadanaText.build(
      data(servicio: 'MOTORIZADO', moto: 'M-25'),
    );
    final k9 = ColaboracionCiudadanaText.build(
      data(servicio: 'K9', can: 'Rex'),
    );

    expect(motorizado, contains('*MOTO:* M-25'));
    expect(motorizado, isNot(contains('*CAN:*')));
    expect(k9, contains('*CAN:* Rex'));
    expect(k9, isNot(contains('*MOTO:*')));
  });

  test('omite opcionales vacíos y valores inválidos de presentación', () {
    final text = ColaboracionCiudadanaText.build(data());
    expect(text, isNot(contains('null')));
    expect(text, isNot(contains('undefined')));
    expect(text, isNot(contains('[]')));
    expect(text, isNot(contains('*VIDEOPERADOR:*')));
  });

  test('valida cédula y teléfono con el formato usado por la aplicación', () {
    expect(ColaboracionCiudadanaText.cedulaValida('0912345678'), isTrue);
    expect(ColaboracionCiudadanaText.cedulaValida('123'), isFalse);
    expect(ColaboracionCiudadanaText.telefonoValido('0991234567'), isTrue);
    expect(ColaboracionCiudadanaText.telefonoValido('991234567'), isFalse);
  });
}
