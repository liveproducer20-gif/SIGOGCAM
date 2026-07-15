import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/app_user.dart';
import 'package:mobile/core/auth/auth_session.dart';
import 'package:mobile/features/dash/wdg/side_menu_config.dart';
import 'package:mobile/features/dash/wdg/side_menu_wdg.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  AppUser userWith(List<Object> permissions) => AppUser.fromJson({
    'id': 7,
    'cedula': '0900000000',
    'correo': 'user@sigo.local',
    'nombreCompleto': 'Usuario Prueba',
    'rol': 'USUARIO',
    'permisos': permissions,
  });

  test('permissions expose module metadata and assigned event scope', () {
    final user = userWith(['eventos.ver_convocado', 'cartillas.ver']);

    expect(user.permissions.forModule('eventos'), hasLength(1));
    expect(user.eventAccess, PermissionScope.assigned);
    expect(user.soloEventosConvocados, isTrue);
    expect(user.puedeVerAdministracion, isFalse);
  });

  test('administration requires its own permission and is under settings', () {
    final withoutAdmin = userWith(['personal.ver', 'catalogos.ver']);
    final withAdmin = userWith(['administracion.ver']);

    expect(
      SideMenuConfig.forUser(
        withoutAdmin,
      ).any((item) => item.destination == SideMenuDestination.administration),
      isFalse,
    );
    final adminItem = SideMenuConfig.forUser(withAdmin).singleWhere(
      (item) => item.destination == SideMenuDestination.administration,
    );
    expect(adminItem.section, SideMenuSection.settings);
  });

  test('unavailable modules are permission-driven', () {
    final withoutServices = userWith(['eventos.ver']);
    final withServices = userWith(['servicios.ver']);

    expect(
      SideMenuConfig.forUser(
        withoutServices,
      ).any((item) => item.destination == SideMenuDestination.services),
      isFalse,
    );
    final services = SideMenuConfig.forUser(
      withServices,
    ).singleWhere((item) => item.destination == SideMenuDestination.services);
    expect(services.authorized, isTrue);
    expect(services.available, isFalse);
  });

  test('API menu structure controls visible destinations and labels', () {
    final user = userWith([
      'eventos.ver',
      'administracion.ver',
      'servicios.ver',
    ]);
    final items = SideMenuConfig.fromApi([
      {
        'codigo': 'administracion',
        'nombre': 'Administración del sistema',
        'icono': 'admin_panel_settings_outlined',
      },
      {
        'codigo': 'eventos_anuncios',
        'nombre': 'Agenda institucional',
        'icono': 'event_outlined',
      },
    ], user);

    expect(items, hasLength(2));
    expect(items.first.destination, SideMenuDestination.administration);
    expect(items.first.section, SideMenuSection.settings);
    expect(items.last.title, 'Agenda institucional');
    expect(
      items.any((item) => item.destination == SideMenuDestination.services),
      isFalse,
    );
  });

  test('API menu accepts uppercase and preserves newly created modules', () {
    final items = SideMenuConfig.fromApi([
      {'codigo': 'CARTILLAS', 'nombre': 'Cartillas operativas'},
      {'codigo': 'NUEVO_MODULO', 'nombre': 'Nuevo módulo', 'ruta': '/nuevo'},
    ], userWith(['cartillas.ver']));

    expect(items, hasLength(2));
    expect(items.first.destination, SideMenuDestination.booklets);
    expect(items.last.destination, SideMenuDestination.custom);
    expect(items.last.title, 'Nuevo módulo');
    expect(items.last.moduleCode, 'NUEVO_MODULO');
    expect(items.last.route, '/nuevo');
  });

  test('session persists and restores user permission metadata', () async {
    SharedPreferences.setMockInitialValues({});
    await AuthSession.init();
    final original = userWith([
      {
        'codigo': 'administracion.ver',
        'modulo': 'administracion',
        'accion': 'ver',
        'nombre': 'Ver administración',
      },
    ]);

    AuthSession.setToken('test-token');
    AuthSession.setUser(original);
    await Future<void>.delayed(Duration.zero);
    AuthSession.token = null;
    AuthSession.user = null;

    await AuthSession.init();

    expect(AuthSession.token, 'test-token');
    expect(AuthSession.user?.id, original.id);
    expect(AuthSession.user?.puedeVerAdministracion, isTrue);
    expect(
      AuthSession.user?.permissions.forModule('administracion').single.label,
      'Ver administración',
    );
  });
}
