import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/crt/mdl/crt_enums.dart';
import 'package:mobile/features/crt/mdl/crt_special_models.dart';
import 'package:mobile/features/crt/svc/crt_special_text_generator.dart';

void main() {
  final date = DateTime(2026, 7, 14, 22, 30);

  FormacionData formation({
    TipoFormacion tipo = TipoFormacion.saliente,
    String novedades = '',
    List<String> policias = const ['Policía Guamán Lucas'],
    List<String> moviles = const ['187', '188', '189'],
  }) => FormacionData(
    tipo: tipo,
    distrito: '#5 MODELO',
    circuito: 'EAS 12 CEIBOS',
    direccion: 'Calle 15 ava y Dr Alberto Dacach Saman',
    horario: '14:00 A 22:30',
    fechaHora: date,
    novedades: novedades,
    radiooperadores: 2,
    acmOperativos: 6,
    personalPolicial: policias,
    moviles: moviles,
    reportantes: const ['CALDERON JORGE', 'ZUÑIGA GUILLERMO'],
    jefe: 'Maldonado Cabrera Freddy Jefe de Control Municipal',
  );

  test('formación saliente usa causa, cierre, saludo y móviles correctos', () {
    final text = CrtSpecialTextGenerator.formacion(formation());
    expect(text, contains('*CAUSA:* FORMACION SALIENTE'));
    expect(text, contains('Forma Personal Saliente'));
    expect(text, contains('se CULMINA LA JORNADA LABORAL'));
    expect(text, contains('Muy buenas noches'));
    expect(text, contains('187-188-189'));
  });

  test('formación entrante inicia jornada', () {
    final text = CrtSpecialTextGenerator.formacion(
      formation(tipo: TipoFormacion.entrante),
    );
    expect(text, contains('*CAUSA:* FORMACION ENTRANTE'));
    expect(text, contains('Forma Personal Entrante'));
    expect(text, contains('se INICIA LA JORNADA LABORAL'));
  });

  test('sin novedades aparece una sola vez', () {
    final text = CrtSpecialTextGenerator.formacion(
      formation(novedades: 'Sin Novedades\nSin novedades'),
    );
    expect('Sin Novedades'.allMatches(text), hasLength(1));
  });

  test('varias novedades conservan líneas y sin policía omite sección', () {
    final text = CrtSpecialTextGenerator.formacion(
      formation(novedades: 'Primera\nSegunda', policias: const []),
    );
    expect(text, contains('Primera\nSegunda'));
    expect(text, isNot(contains('Personal Policial')));
  });

  test('saludos dependen de la hora seleccionada', () {
    expect(
      CrtSpecialTextGenerator.saludo(DateTime(2026, 7, 14, 7)),
      'Muy buenos días',
    );
    expect(
      CrtSpecialTextGenerator.saludo(DateTime(2026, 7, 14, 15)),
      'Muy buenas tardes',
    );
    expect(
      CrtSpecialTextGenerator.saludo(DateTime(2026, 7, 14, 22)),
      'Muy buenas noches',
    );
  });

  test('conductor conserva cédula con cero y agrega Km solo en texto', () {
    final data = ConductorData(
      conductor: 'Ramirez Mosquera Bolívar',
      cedulaUltimos4: '0191',
      opcion: OpcionConductor.entradaPersonal,
      lugar: 'EAS 12 Los Ceibos',
      disco: '189',
      fechaHora: DateTime(2026, 7, 14, 14, 5),
      combustible: 'Full',
      kilometraje: 11216,
      servicio: 'EAS 12 Los Ceibos',
      horario: '14:00-22:30',
      encargado: 'ACM Vernaza Valencia Michelle',
      observaciones: '',
    );
    final text = CrtSpecialTextGenerator.conductor(data);
    expect(text, contains('*REGISTRO VEHICULAR*'));
    expect(text, contains('0191'));
    expect(text, contains('11216 Km'));
    expect(text, contains('Sin novedades'));
    expect(data.toJson()['kilometraje'], 11216);
  });

  test(
    'otras cartillas respeta plantilla institucional y hora de 12 horas',
    () {
      final data = OtrasCartillasData(
        distrito: '#5 MODELO',
        circuito: 'EAS 12 CEIBOS',
        direccion: 'Calle 15 ava y Dr Alberto Dacach Saman',
        horario: '14:00 A 22:00',
        fechaHora: DateTime(2026, 7, 14, 19, 25),
        causa: 'NOVEDAD EN INSTALACIONES',
        novedad: 'Se registra una novedad de prueba.',
        modulo: TipoModuloCartilla.eas,
        reportantes: const ['CALDERON JORGE', 'ZUÑIGA GUILLERMO'],
        jefe: 'Maldonado Cabrera Freddy',
      );

      final text = CrtSpecialTextGenerator.otras(data);
      expect(text, contains('*REPORTE DE EAS*'));
      expect(text, contains('*HORA:* 07:25 p. m.'));
      expect(text, contains('*FECHA:* 14/7/2026'));
      expect(text, contains('permiso Sr. Maldonado Cabrera Freddy'));
      expect(text, contains('ACM. CALDERON JORGE\nACM. ZUÑIGA GUILLERMO'));
      expect(text, contains('*"LEALTAD, VALOR Y ORDEN"*'));
    },
  );
}
