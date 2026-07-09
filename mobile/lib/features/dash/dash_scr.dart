import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/auth_session.dart';
import '../../core/notif/notif_read_store.dart';
import '../../core/thm/app_thm.dart';
import '../../core/auth/app_user.dart';
import '../auth/auth_scr.dart';
import '../adm/adm_home_scr.dart';
import '../evt/ann/mdl/ann_mdl.dart';
import '../evt/ann/svc/ann_svc.dart';
import '../evt/mdl/evt_mdl.dart';
import '../evt/wdg/evt_estado_style.dart';
import 'wdg/dev_card_wdg.dart';
import 'wdg/page_ttl_wdg.dart';
import 'wdg/side_menu_wdg.dart';
import 'wdg/top_bar_wdg.dart';
import '../crt/crt_home_scr.dart';
import '../evt/scr/evt_home_scr.dart';
import '../evt/svc/evt_svc.dart';
import '../ins/ins_home_scr.dart';

class DashScr extends StatefulWidget {
  final AppUser user;

  const DashScr({
    super.key,
    required this.user,
  });

  @override
  State<DashScr> createState() => _DashScrState();
}

class _DashScrState extends State<DashScr> {
  int idxSel = 0;
  bool menuOpen = true;
  late AppUser user;

  List<SideMenuItem> get items => [
        const SideMenuItem(title: 'Eventos', icon: Icons.event_outlined, enabled: true),
        const SideMenuItem(title: 'Cartillas', icon: Icons.description_outlined, enabled: true),
        const SideMenuItem(title: 'Mis insignias', icon: Icons.workspace_premium_outlined, enabled: true),
        SideMenuItem(
          title: 'Administracion',
          icon: Icons.admin_panel_settings_outlined,
          enabled: user.puedeVerAdministracion,
        ),
        const SideMenuItem(title: 'Servicios', icon: Icons.local_police_outlined, enabled: false),
        const SideMenuItem(title: 'Reportes', icon: Icons.bar_chart_outlined, enabled: false),
        const SideMenuItem(title: 'Operaciones', icon: Icons.security_outlined, enabled: false),
        const SideMenuItem(title: 'Estadísticas', icon: Icons.insights_outlined, enabled: false),
        const SideMenuItem(title: 'Configuración', icon: Icons.settings_outlined, enabled: false),
      ];

  @override
  void initState() {
    super.initState();
    user = widget.user;
    AuthSession.onSessionExpired = _logout;
  }

  @override
  void dispose() {
    if (AuthSession.onSessionExpired == _logout) {
      AuthSession.onSessionExpired = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 900;

    return isWeb
        ? _WebDash(
            items: items,
            user: user,
            idxSel: idxSel,
            menuOpen: menuOpen,
            onMenuTap: () => setState(() => menuOpen = !menuOpen),
            onSel: (i) => setState(() => idxSel = i),
            onUserChanged: (next) => setState(() => user = next),
            onLogout: _logout,
            onNotifications: _openNotifications,
          )
        : _MobDash(
            items: items,
            user: user,
            onUserChanged: (next) => setState(() => user = next),
            onLogout: _logout,
            onNotifications: _openNotifications,
          );
  }

  void _logout() {
    AuthSession.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScr()),
      (_) => false,
    );
  }

  Future<void> _openNotifications() async {
    final item = await showDialog<_NotifItem>(
      context: context,
      builder: (_) => _NotifDialog(user: user),
    );

    if (item == null || !mounted) return;

    NotifReadStore.markRead(item.readId);
    setState(() {});

    await showDialog<void>(
      context: context,
      builder: (_) => _NotifDetailDialog(item: item),
    );
  }
}

class _WebDash extends StatefulWidget {
  final List<SideMenuItem> items;
  final AppUser user;
  final int idxSel;
  final bool menuOpen;
  final VoidCallback onMenuTap;
  final ValueChanged<int> onSel;
  final ValueChanged<AppUser> onUserChanged;
  final VoidCallback onLogout;
  final VoidCallback onNotifications;

  const _WebDash({
    required this.items,
    required this.user,
    required this.idxSel,
    required this.menuOpen,
    required this.onMenuTap,
    required this.onSel,
    required this.onUserChanged,
    required this.onLogout,
    required this.onNotifications,
  });

  @override
  State<_WebDash> createState() => _WebDashState();
}

class _WebDashState extends State<_WebDash> {
  @override
  Widget build(BuildContext context) {
    final item = widget.items[widget.idxSel];
    return Scaffold(
      body: Row(
        children: [
          SideMenuWdg(
            menuOpen: widget.menuOpen,
            idxSel: widget.idxSel,
            items: widget.items,
            onMenuTap: widget.onMenuTap,
            onItemTap: widget.onSel,
            onLogout: widget.onLogout,
          ),
          Expanded(
            child: _WebContent(
              item: item,
              user: widget.user,
              idxSel: widget.idxSel,
              onUserChanged: widget.onUserChanged,
              onLogout: widget.onLogout,
              onNotifications: widget.onNotifications,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebContent extends StatefulWidget {
  final SideMenuItem item;
  final AppUser user;
  final int idxSel;
  final ValueChanged<AppUser> onUserChanged;
  final VoidCallback onLogout;
  final VoidCallback onNotifications;

  const _WebContent({
    required this.item,
    required this.user,
    required this.idxSel,
    required this.onUserChanged,
    required this.onLogout,
    required this.onNotifications,
  });

  @override
  State<_WebContent> createState() => _WebContentState();
}

class _WebContentState extends State<_WebContent> {
  List<Widget>? _children;

  List<Widget> _buildChildren() {
    final common = (
      user: widget.user,
      onUserChanged: widget.onUserChanged,
      onLogout: widget.onLogout,
      onNotifications: widget.onNotifications,
    );
    return [
      EvtHomeScr(
        user: common.user,
        onUserChanged: common.onUserChanged,
        onLogout: common.onLogout,
        onNotifications: common.onNotifications,
      ),
      CrtHomeScr(
        user: common.user,
        onUserChanged: common.onUserChanged,
        onLogout: common.onLogout,
        onNotifications: common.onNotifications,
      ),
      InsHomeScr(
        user: common.user,
        onUserChanged: common.onUserChanged,
        onLogout: common.onLogout,
        onNotifications: common.onNotifications,
      ),
      if (widget.user.puedeVerAdministracion)
        AdmHomeScr(
          user: common.user,
          onUserChanged: common.onUserChanged,
          onLogout: common.onLogout,
          onNotifications: common.onNotifications,
        )
      else
        const SizedBox.shrink(),
    ];
  }

  @override
  void didUpdateWidget(covariant _WebContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user ||
        widget.onUserChanged != oldWidget.onUserChanged ||
        widget.onLogout != oldWidget.onLogout ||
        widget.onNotifications != oldWidget.onNotifications) {
      _children = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.item.enabled) {
      return Scaffold(
        backgroundColor: AppThm.bgClr,
        appBar: TopBarWdg(
          ttl: widget.item.title,
          user: widget.user,
          onUserChanged: widget.onUserChanged,
          onLogout: widget.onLogout,
          onNotifications: widget.onNotifications,
        ),
        body: DevCardWdg(ttl: widget.item.title),
      );
    }

    _children ??= _buildChildren();
    return IndexedStack(
      index: widget.idxSel,
      children: _children!,
    );
  }
}



class _EasStation {
  final String codigo;
  final String nombre;
  final String ubicacion;
  final String direccion;

  const _EasStation({
    required this.codigo,
    required this.nombre,
    required this.ubicacion,
    required this.direccion,
  });
}

const _easStations = [
  _EasStation(
    codigo: 'ECO 1',
    nombre: 'URDESA',
    ubicacion: 'URDESA',
    direccion: 'AV. VICTOR EMILIO ESTRADA Y CIRCUNVALACION SUR',
  ),
  _EasStation(
    codigo: 'ECO 2',
    nombre: 'LOMAS DE URDESA',
    ubicacion: 'LOMAS DE URDESA',
    direccion: 'AV. CERROS Y LOMAS DE URDESA',
  ),
  _EasStation(
    codigo: 'ECO 3',
    nombre: 'KENNEDY VIEJA',
    ubicacion: 'KENNEDY VIEJA',
    direccion: 'AV. FRANCISCO URBINA Y AV. DEL PERIODISTA',
  ),
  _EasStation(
    codigo: 'ECO 4',
    nombre: 'KENNEDY NUEVA',
    ubicacion: 'KENNEDY NUEVA',
    direccion: 'AV. JOSE SANTIAGO CASTILLO Y VICTOR HUGO',
  ),
  _EasStation(
    codigo: 'ECO 5',
    nombre: 'FAE/ATARAZANA',
    ubicacion: 'FAE/ATARAZANA',
    direccion: 'AV. AL RAUL COUSIN Y CRNL LUIS LOPES',
  ),
  _EasStation(
    codigo: 'ECO 6',
    nombre: 'PUERTO SANTA ANA',
    ubicacion: 'PUERTO SANTA ANA',
    direccion: 'PUERTO SANTA ANA',
  ),
  _EasStation(
    codigo: 'ECO 7',
    nombre: 'SAMANES',
    ubicacion: 'SAMANES',
    direccion: 'AV TEODORO ALVARADO OLEAS',
  ),
  _EasStation(
    codigo: 'ECO 8',
    nombre: 'PARQUE CENTENARIO',
    ubicacion: 'PARQUE CENTENARIO',
    direccion: 'CALLE LORENZO DE GARAICOA Y VELEZ',
  ),
  _EasStation(
    codigo: 'ECO 9',
    nombre: 'PLAZA SAN FRANCISCO',
    ubicacion: 'PLAZA SAN FRANCISCO',
    direccion: 'AV. 9 DE OCTUBRE Y PEDRO CARBO',
  ),
  _EasStation(
    codigo: 'ECO 10',
    nombre: 'VIA A LA COSTA',
    ubicacion: 'VIA A LA COSTA',
    direccion: 'CDLA. TERRANOSTRA',
  ),
  _EasStation(
    codigo: 'ECO 11',
    nombre: 'BARRIO CENTENARIO',
    ubicacion: 'BARRIO CENTENARIO',
    direccion: 'AV. DOLORES SUCRE Y MARACAIBO',
  ),
  _EasStation(
    codigo: 'ECO 12',
    nombre: 'CEIBOS',
    ubicacion: 'CEIBOS',
    direccion: 'DR ALBERTO DACACH Y AV 15AVA NO',
  ),
];

const _rolesCentral = [
  'Jefe de patrulla',
  'Conductor',
  'Auxiliar',
  'Motorizado',
  'K9',
  'Radioperador',
  'Comunicaciones',
];

class _CrtHome extends StatefulWidget {
  final AppUser? user;
  final ValueChanged<AppUser>? onUserChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onNotifications;

  const _CrtHome({
    // ignore: unused_element_parameter
    this.user,
    // ignore: unused_element_parameter
    this.onUserChanged,
    // ignore: unused_element_parameter
    this.onLogout,
    // ignore: unused_element_parameter
    this.onNotifications,
  });

  @override
  State<_CrtHome> createState() => _CrtHomeState();
}

class _CrtHomeState extends State<_CrtHome> {
  late final TextEditingController horarioCtl;
  late final TextEditingController horaCtl;
  late final TextEditingController fechaCtl;
  late final TextEditingController causaCtl;
  late final TextEditingController detalleCtl;
  late final TextEditingController reportaCtl;
  _EasStation eas = _easStations.last;
  String rolCentral = _rolesCentral.first;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    horarioCtl = TextEditingController(text: _horarioPorHora(now.hour));
    horaCtl = TextEditingController(text: _fmtHora(now));
    fechaCtl = TextEditingController(text: _fmtFecha(now));
    causaCtl = TextEditingController(text: 'NOVEDADES EN ${eas.nombre}');
    detalleCtl = TextEditingController();
    reportaCtl = TextEditingController(
      text: widget.user?.nombreCompleto.isNotEmpty == true
          ? 'ACM: ${widget.user!.nombreCompleto}'
          : '',
    );

    for (final ctl in [
      horarioCtl,
      horaCtl,
      fechaCtl,
      causaCtl,
      detalleCtl,
      reportaCtl,
    ]) {
      ctl.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    horarioCtl.dispose();
    horaCtl.dispose();
    fechaCtl.dispose();
    causaCtl.dispose();
    detalleCtl.dispose();
    reportaCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1050;
    final cartilla = _cartilla;

    return Scaffold(
      backgroundColor: AppThm.bgClr,
      appBar: TopBarWdg(
        ttl: 'Cartillas',
        user: widget.user,
        onUserChanged: widget.onUserChanged,
        onLogout: widget.onLogout,
        onNotifications: widget.onNotifications,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTtlWdg(
                ttl: 'Cartilla de novedades',
                sub: 'Generador basado en el formato del bot SAC para novedades registradas en EAS CEIBOS.',
              ),
              const SizedBox(height: 26),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _CrtFormPanel(state: this)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _CrtPreviewPanel(
                        cartilla: cartilla,
                        onCopy: () => _copiar(context, cartilla),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _CrtFormPanel(state: this),
                    const SizedBox(height: 20),
                    _CrtPreviewPanel(
                      cartilla: cartilla,
                      onCopy: () => _copiar(context, cartilla),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String get _cartilla {
    final now = DateTime.now();
    final horaGeneracion = _fmtHora(now);
    final fechaGeneracion = _fmtFecha(now);

    final detalle = detalleCtl.text.trim().isEmpty
        ? '[Describa la novedad registrada en ${eas.codigo} - ${eas.nombre}]'
        : detalleCtl.text.trim();
    final reporta = reportaCtl.text.trim().isEmpty
        ? '[Nombre del ACM que reporta]'
        : reportaCtl.text.trim();

    return '''*CUERPO AGENTE DE CONTROL MUNICIPAL*
*REPORTE DE RADIOOPERADORES EAS CEIBOS*

*Distrito:* #5 MODELO
*Circuito:* ${eas.codigo} ${eas.nombre}
*Ubicación:* ${eas.ubicacion}
*Dirección:* ${eas.direccion}
*Rol en Central EAS:* $rolCentral
*Horario:* ${horarioCtl.text.trim()}
*Hora:* $horaGeneracion
*Fecha:* $fechaGeneracion
*Causa:* ${causaCtl.text.trim()}

${_saludo()}, permiso Sr. Maldonado Cabrera Freddy Jefe de Control Municipal.

Muy respetuosamente me permito informarle que en las instalaciones de ${eas.codigo} - ${eas.nombre} se registra la siguiente novedad:

$detalle

Así mismo, se le informó a la Central para que registre la novedad.

Información puesta en conocimiento para los fines pertinentes.

*Reporta:*
$reporta

*"Lealtad Valor Orden"*

*Adjunto Fotografía:*''';
  }

  Future<void> _copiar(BuildContext context, String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cartilla copiada al portapapeles')),
    );
  }

  String _saludo() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _fmtHora(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _fmtFecha(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _horarioPorHora(int hour) {
    if (hour >= 6 && hour < 14) return '06:00 A 14:30';
    if (hour >= 14 && hour < 22) return '14:00 A 22:30';
    return '22:00 A 06:30';
  }

  void setEas(_EasStation value) {
    setState(() {
      eas = value;
      causaCtl.text = 'NOVEDADES EN ${value.nombre}';
    });
  }

  void setRolCentral(String value) {
    setState(() => rolCentral = value);
  }
}

class _CrtFormPanel extends StatelessWidget {
  final _CrtHomeState state;

  const _CrtFormPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return _CrtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CrtPanelTtl(
            icon: Icons.edit_note_outlined,
            ttl: 'Datos de la novedad',
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<_EasStation>(
            initialValue: state.eas,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Estación de Acción Segura',
              prefixIcon: const Icon(Icons.location_city_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: _easStations
                .map(
                  (eas) => DropdownMenuItem(
                    value: eas,
                    child: Text('${eas.codigo} - ${eas.nombre}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              state.setEas(value);
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: state.rolCentral,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Rol que cumple en Central EAS',
              prefixIcon: const Icon(Icons.assignment_ind_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: _rolesCentral
                .map(
                  (rol) => DropdownMenuItem(
                    value: rol,
                    child: Text(rol),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              state.setRolCentral(value);
            },
          ),
          const SizedBox(height: 14),
          _CrtTextFld(
            ctl: state.horarioCtl,
            label: 'Horario',
            icon: Icons.schedule_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CrtTextFld(
                  ctl: state.horaCtl,
                  label: 'Hora',
                  icon: Icons.access_time_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _CrtTextFld(
                  ctl: state.fechaCtl,
                  label: 'Fecha',
                  icon: Icons.calendar_today_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CrtTextFld(
            ctl: state.causaCtl,
            label: 'Causa',
            icon: Icons.assignment_outlined,
          ),
          const SizedBox(height: 14),
          _CrtTextFld(
            ctl: state.detalleCtl,
            label: 'Detalle de la novedad',
            icon: Icons.report_problem_outlined,
            minLines: 5,
          ),
          const SizedBox(height: 14),
          _CrtTextFld(
            ctl: state.reportaCtl,
            label: 'Reporta',
            icon: Icons.badge_outlined,
            minLines: 2,
          ),
        ],
      ),
    );
  }
}

class _CrtPreviewPanel extends StatelessWidget {
  final String cartilla;
  final VoidCallback onCopy;

  const _CrtPreviewPanel({
    required this.cartilla,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return _CrtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _CrtPanelTtl(
                  icon: Icons.description_outlined,
                  ttl: 'Vista previa',
                ),
              ),
              FilledButton.icon(
                onPressed: cartilla.trim().isEmpty ? null : onCopy,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copiar'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 520),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: SelectableText(
              cartilla,
              style: const TextStyle(
                color: AppThm.txtClr,
                height: 1.45,
                fontFamily: 'monospace',
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrtPanel extends StatelessWidget {
  final Widget child;

  const _CrtPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CrtPanelTtl extends StatelessWidget {
  final IconData icon;
  final String ttl;

  const _CrtPanelTtl({
    required this.icon,
    required this.ttl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppThm.secClr),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            ttl,
            style: const TextStyle(
              color: AppThm.priClr,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CrtTextFld extends StatelessWidget {
  final TextEditingController ctl;
  final String label;
  final IconData icon;
  final int minLines;

  const _CrtTextFld({
    required this.ctl,
    required this.label,
    required this.icon,
    this.minLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctl,
      minLines: minLines,
      maxLines: minLines == 1 ? 1 : 8,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _NotifDialog extends StatefulWidget {
  final AppUser user;

  const _NotifDialog({required this.user});

  @override
  State<_NotifDialog> createState() => _NotifDialogState();
}

class _NotifDialogState extends State<_NotifDialog> {
  late Future<List<_NotifItem>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notificaciones'),
      content: SizedBox(
        width: 560,
        height: 420,
        child: FutureBuilder<List<_NotifItem>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('No se pudieron cargar: ${snapshot.error}'));
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Center(child: Text('No tienes notificaciones pendientes.'));
            }

            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final item = items[index];
                return _NotifCard(
                  item: item,
                  onTap: () => Navigator.pop(context, item),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Future<List<_NotifItem>> _load() async {
    final events = await _safeLoadEvents();
    final annList = await _safeLoadAnnouncements();
    final announcements = annList.where((ann) {
      if (!ann.publicado || !ann.notificar) return false;
      return !widget.user.esUsuario || ann.personalIds.contains(widget.user.id);
    });

    return [
      ...events.where((evt) => evt.notificar).map(_NotifItem.fromEvent),
      ...announcements.map((ann) => _NotifItem.fromAnnouncement(
            ann,
            widget.user.nombreCompleto,
          )),
    ].where((item) => !NotifReadStore.isRead(item.readId)).toList();
  }

  Future<List<EvtMdl>> _safeLoadEvents() async {
    try {
      return await EvtSvc.getLst(
        personalId: widget.user.soloEventosConvocados ? widget.user.id : null,
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<AnnMdl>> _safeLoadAnnouncements() async {
    try {
      return await AnnSvc.getLst(
        personalId: widget.user.esUsuario ? widget.user.id : null,
      );
    } catch (_) {
      return [];
    }
  }
}

class _NotifDetailDialog extends StatelessWidget {
  final _NotifItem item;

  const _NotifDetailDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(item.title),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final detail in item.details)
                _NotifDetailTile(detail: detail),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          label: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _NotifDetailTile extends StatelessWidget {
  final _NotifDetail detail;

  const _NotifDetailTile({required this.detail});

  @override
  Widget build(BuildContext context) {
    final isImage = detail.kind == _NotifDetailKind.image;
    final isPdf = detail.kind == _NotifDetailKind.pdf;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.label,
            style: const TextStyle(
              color: AppThm.priClr,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (isImage)
            _NotifImagePreview(value: detail.value)
          else if (isPdf)
            Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(detail.displayValue)),
              ],
            )
          else
            SelectableText(detail.displayValue),
        ],
      ),
    );
  }
}

class _NotifImagePreview extends StatelessWidget {
  final String value;

  const _NotifImagePreview({required this.value});

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeDataImage(value);

    if (bytes == null) {
      return Text(
        value.isEmpty ? 'Imagen no disponible' : value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        bytes,
        height: 260,
        width: double.infinity,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            const Text('No se pudo mostrar la imagen'),
      ),
    );
  }

  static Uint8List? _decodeDataImage(String value) {
    final marker = 'base64,';
    final index = value.indexOf(marker);
    if (!value.startsWith('data:image') || index < 0) return null;

    try {
      return base64Decode(value.substring(index + marker.length));
    } catch (_) {
      return null;
    }
  }
}

class _NotifCard extends StatelessWidget {
  final _NotifItem item;
  final VoidCallback? onTap;

  const _NotifCard({
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: item.type == 'Evento'
              ? AppThm.secClr.withValues(alpha: 0.18)
              : AppThm.accClr.withValues(alpha: 0.22),
          child: Icon(
            item.type == 'Evento'
                ? Icons.event_available_outlined
                : Icons.campaign_outlined,
            color: AppThm.priClr,
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            color: AppThm.priClr,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(item.subtitle),
        ),
        trailing: Chip(
          label: Text(item.type),
          backgroundColor: Colors.black.withValues(alpha: 0.06),
        ),
      ),
    );
  }
}

class _NotifItem {
  final int id;
  final String type;
  final String title;
  final String subtitle;
  final String readId;
  final List<_NotifDetail> details;

  const _NotifItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.readId,
    required this.details,
  });

  factory _NotifItem.fromEvent(EvtMdl evt) {
    final fechaFin = evt.fechaFin.isEmpty ? evt.fecha : evt.fechaFin;
    return _NotifItem(
      id: evt.id,
      type: 'Evento',
      title: evt.nom,
      readId: 'evento:${evt.id}',
      subtitle:
          '${evt.prioridad} | ${evt.fecha} | ${evt.estado}${evt.lugar.isEmpty ? '' : ' | ${evt.lugar}'}',
      details: [
        _NotifDetail('Tipo', evt.tipo),
        _NotifDetail('Prioridad', evt.prioridad),
        _NotifDetail('Estado', EvtEstadoStyle.label(evt.estado)),
        _NotifDetail('Fecha', '${evt.fecha} - $fechaFin'),
        _NotifDetail('Hora', evt.hora.isEmpty ? 'Sin hora' : evt.hora),
        if (evt.lugar.isNotEmpty) _NotifDetail('Lugar', evt.lugar),
        if (evt.descripcion.isNotEmpty)
          _NotifDetail('Descripción', evt.descripcion),
        _NotifDetail('Convocados', '${evt.convocados}'),
        _NotifDetail('Confirmados', '${evt.confirmados}'),
        _NotifDetail('Notificacion', evt.notificar ? 'Activa' : 'Inactiva'),
        if (evt.imgUrl?.isNotEmpty == true)
          _NotifDetail.image('Imagen', evt.imgUrl!),
        if (evt.pdfNombre?.isNotEmpty == true || evt.pdfUrl?.isNotEmpty == true)
          _NotifDetail.pdf('PDF', evt.pdfNombre ?? 'Archivo PDF'),
      ],
    );
  }

  factory _NotifItem.fromAnnouncement(AnnMdl ann, String userName) {
    final expira = ann.fecExp == null
        ? 'Sin fecha de expiración'
        : '${ann.fecExp!.day.toString().padLeft(2, '0')}/${ann.fecExp!.month.toString().padLeft(2, '0')}/${ann.fecExp!.year}';
    return _NotifItem(
      id: ann.id,
      type: 'Anuncio',
      title: ann.ttl,
      readId: 'anuncio:${ann.id}',
      subtitle:
          '${ann.prioridad} | Para ${userName.isEmpty ? 'Agente' : userName} | ${ann.desc}',
      details: [
        _NotifDetail('Prioridad', ann.prioridad),
        _NotifDetail('Publicado', ann.publicado ? 'Si' : 'No'),
        _NotifDetail('Notificacion', ann.notificar ? 'Activa' : 'Inactiva'),
        _NotifDetail('Destinatario', userName.isEmpty ? 'Agente' : userName),
        _NotifDetail('Descripcion', ann.desc),
        _NotifDetail('Fecha de publicación',
            '${ann.fecPub.day.toString().padLeft(2, '0')}/${ann.fecPub.month.toString().padLeft(2, '0')}/${ann.fecPub.year}'),
        _NotifDetail('Fecha de expiración', expira),
        if (ann.imgUrl?.isNotEmpty == true)
          _NotifDetail.image('Imagen', ann.imgUrl!),
        if (ann.imgUrl?.isNotEmpty != true && ann.imgNombre?.isNotEmpty == true)
          _NotifDetail('Imagen', ann.imgNombre!),
      ],
    );
  }
}

enum _NotifDetailKind { text, image, pdf }

class _NotifDetail {
  final String label;
  final String value;
  final _NotifDetailKind kind;

  const _NotifDetail(
    this.label,
    this.value,
  ) : kind = _NotifDetailKind.text;

  const _NotifDetail.image(this.label, this.value)
      : kind = _NotifDetailKind.image;

  const _NotifDetail.pdf(this.label, this.value)
      : kind = _NotifDetailKind.pdf;

  String get displayValue {
    if (kind == _NotifDetailKind.image) return 'Imagen adjunta';
    return value;
  }
}

class _MobDash extends StatelessWidget {
  final List<SideMenuItem> items;
  final AppUser user;
  final ValueChanged<AppUser> onUserChanged;
  final VoidCallback onLogout;
  final VoidCallback onNotifications;

  const _MobDash({
    required this.items,
    required this.user,
    required this.onUserChanged,
    required this.onLogout,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBarWdg(
        ttl: 'SIGO-GCAM',
        user: user,
        onUserChanged: onUserChanged,
        onLogout: onLogout,
        onNotifications: onNotifications,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  if (!item.enabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.title} en desarrollo')),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) {
                        if (item.title == 'Eventos') {
                          return EvtHomeScr(
                            user: user,
                            onUserChanged: onUserChanged,
                            onLogout: onLogout,
                            onNotifications: onNotifications,
                          );
                        }

                        if (item.title == 'Mis insignias') {
                          return InsHomeScr(
                            user: user,
                            onUserChanged: onUserChanged,
                            onLogout: onLogout,
                            onNotifications: onNotifications,
                          );
                        }

                        if (item.title == 'Administracion') {
                          return AdmHomeScr(
                            user: user,
                            onUserChanged: onUserChanged,
                            onLogout: onLogout,
                            onNotifications: onNotifications,
                            showBack: true,
                          );
                        }

                        return CrtHomeScr(
                          user: user,
                          onUserChanged: onUserChanged,
                          onLogout: onLogout,
                          onNotifications: onNotifications,
                        );
                      },
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.icon,
                        size: 34,
                        color: item.enabled ? AppThm.secClr : Colors.black38,
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppThm.priClr,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.enabled ? 'Disponible' : 'En desarrollo',
                        style: TextStyle(
                          color: item.enabled ? AppThm.okClr : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
