import 'package:flutter/material.dart';

import '../../core/thm/app_thm.dart';
import '../../core/auth/app_user.dart';
import '../../core/wdg/load/load_wdg.dart';
import '../dash/wdg/top_bar_wdg.dart';
import 'config_api.dart';
import 'config_mdl.dart';
import 'wdg/arbol_modulos_wdg.dart';
import 'wdg/panel_config_wdg.dart';
import 'wdg/preview_menu_wdg.dart';
import 'wdg/alcance_rol_wdg.dart';
import 'wdg/campos_rol_wdg.dart';
import 'wdg/versiones_wdg.dart';
import 'wdg/auditoria_wdg.dart';

class ConfigEditorScr extends StatefulWidget {
  final AppUser user;
  final ValueChanged<AppUser>? onUserChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onNotifications;

  const ConfigEditorScr({
    super.key,
    required this.user,
    this.onUserChanged,
    this.onLogout,
    this.onNotifications,
  });

  @override
  State<ConfigEditorScr> createState() => _ConfigEditorScrState();
}

class _ConfigEditorScrState extends State<ConfigEditorScr>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final ConfigApi _api = ConfigApi();
  bool _loading = true;
  String? _error;

  List<ModuloModel> _modulos = [];
  List<RolModel> _roles = [];
  ModuloModel? _selectedModulo;
  RolModel? _selectedRol;
  List<RolMenuConfigModel> _menuConfig = [];
  bool _menuDirty = false;
  bool _savingMenu = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getEstructura();
      if (!mounted) return;
      setState(() {
        _modulos = data.modulos;
        _roles = data.roles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMenuConfig() async {
    if (_selectedRol == null) return;
    try {
      final config = await _api.getMenuRol(_selectedRol!.id);
      if (mounted) {
        setState(() {
          _menuConfig = config;
          _menuDirty = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _onRolSelected(RolModel rol) async {
    setState(() {
      _selectedRol = rol;
      _menuConfig = [];
      _menuDirty = false;
    });
    await _loadMenuConfig();
  }

  void _onAddModulo(int moduloId) {
    if (_selectedRol == null) return;
    if (_menuConfig.any((m) => m.moduloId == moduloId)) return;
    final modulo = _modulos.firstWhere((m) => m.id == moduloId);
    final maxOrden = _menuConfig.isEmpty
        ? 0
        : _menuConfig.map((m) => m.orden).reduce((a, b) => a > b ? a : b);
    setState(() {
      _menuConfig = [
        ..._menuConfig,
        RolMenuConfigModel(
          id: 0,
          rolId: _selectedRol!.id,
          moduloId: modulo.id,
          nivel: 0,
          orden: maxOrden + 1,
          visible: 1,
          moduloNombre: modulo.nombre,
          moduloCodigo: modulo.codigo,
          icono: modulo.icono,
          ruta: modulo.ruta,
        ),
      ];
      _menuDirty = true;
    });
  }

  void _onRemoveModulo(int moduloId) {
    if (_selectedRol == null) return;
    setState(() {
      _menuConfig = _menuConfig.where((m) => m.moduloId != moduloId).toList();
      _menuDirty = true;
    });
  }

  Future<void> _guardarMenuRol() async {
    final rol = _selectedRol;
    if (rol == null || !_menuDirty || _savingMenu) return;
    setState(() => _savingMenu = true);
    try {
      await _api.guardarMenuRol(rol.id, _menuPayload());
      await _loadMenuConfig();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menú guardado para el rol ${rol.nombre}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el menú: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingMenu = false);
    }
  }

  List<Map<String, dynamic>> _menuPayload() => _menuConfig
      .map(
        (m) => {
          'modulo_id': m.moduloId,
          'nivel': m.nivel,
          'orden': m.orden,
          'visible': m.visible,
          'etiqueta_personalizada': m.etiquetaPersonalizada,
        },
      )
      .toList();

  void _onEditItem(RolMenuConfigModel item) {
    final ctrlEtiqueta = TextEditingController(
      text: item.etiquetaPersonalizada ?? '',
    );
    int nivel = item.nivel;
    int orden = item.orden;
    int visible = item.visible;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Editar item del menú'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrlEtiqueta,
                  decoration: const InputDecoration(
                    labelText: 'Etiqueta personalizada',
                    hintText: 'Dejar vacío para usar nombre del módulo',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: nivel,
                  decoration: const InputDecoration(labelText: 'Nivel'),
                  items: [0, 1, 2]
                      .map(
                        (n) =>
                            DropdownMenuItem(value: n, child: Text('Nivel $n')),
                      )
                      .toList(),
                  onChanged: (v) => setDlgState(() => nivel = v ?? 0),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Orden'),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                          text: orden.toString(),
                        ),
                        onChanged: (v) => orden = int.tryParse(v) ?? orden,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: visible == 1,
                      onChanged: (v) => setDlgState(() => visible = v ? 1 : 0),
                    ),
                    Text(
                      visible == 1 ? 'Visible' : 'Oculto',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final items = _menuConfig.map((m) {
                  if (m.moduloId == item.moduloId) {
                    return RolMenuConfigModel(
                      id: m.id,
                      rolId: m.rolId,
                      moduloId: m.moduloId,
                      nivel: nivel,
                      orden: orden,
                      visible: visible,
                      etiquetaPersonalizada: ctrlEtiqueta.text.trim().isEmpty
                          ? null
                          : ctrlEtiqueta.text.trim(),
                      moduloNombre: m.moduloNombre,
                      moduloCodigo: m.moduloCodigo,
                      icono: m.icono,
                      ruta: m.ruta,
                    );
                  }
                  return m;
                }).toList();
                setState(() {
                  _menuConfig = items;
                  _menuDirty = true;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showModuloDialog({ModuloModel? existing}) async {
    final ctrlNombre = TextEditingController(text: existing?.nombre ?? '');
    final ctrlCodigo = TextEditingController(text: existing?.codigo ?? '');
    final ctrlRuta = TextEditingController(text: existing?.ruta ?? '');
    final ctrlIcono = TextEditingController(text: existing?.icono ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Editar módulo' : 'Nuevo módulo'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrlNombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: ctrlCodigo,
                decoration: const InputDecoration(labelText: 'Código'),
              ),
              TextField(
                controller: ctrlRuta,
                decoration: const InputDecoration(labelText: 'Ruta (opcional)'),
              ),
              TextField(
                controller: ctrlIcono,
                decoration: const InputDecoration(
                  labelText: 'Icono (opcional)',
                  helperText: 'Ej: event_outlined, settings_outlined',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {
              'nombre': ctrlNombre.text.trim(),
              'codigo': ctrlCodigo.text.trim().toUpperCase(),
              'ruta': ctrlRuta.text.trim().isEmpty
                  ? null
                  : ctrlRuta.text.trim(),
              'icono': ctrlIcono.text.trim().isEmpty
                  ? null
                  : ctrlIcono.text.trim(),
            }),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == null) return;
    try {
      ModuloModel saved;
      if (existing != null) {
        saved = await _api.actualizarModulo(existing.id, result);
      } else {
        saved = await _api.crearModulo(result);
      }
      await _loadData();
      if (!mounted) return;
      setState(() => _selectedModulo = saved);
      if (existing == null && _selectedRol != null) {
        _onAddModulo(saved.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Módulo creado y agregado al borrador. Presione Guardar menú del rol.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThm.bgClr,
      appBar: TopBarWdg(
        ttl: 'Roles, permisos y estructura',
        user: widget.user,
        onUserChanged: widget.onUserChanged,
        onLogout: widget.onLogout,
        onNotifications: widget.onNotifications,
      ),
      body: _loading
          ? const Center(child: LoadWdg())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $_error', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  labelColor: AppThm.accClr,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(icon: Icon(Icons.menu_outlined), text: 'Menú'),
                    Tab(icon: Icon(Icons.visibility_outlined), text: 'Alcance'),
                    Tab(icon: Icon(Icons.view_column_outlined), text: 'Campos'),
                    Tab(icon: Icon(Icons.history_outlined), text: 'Versiones'),
                    Tab(
                      icon: Icon(Icons.receipt_long_outlined),
                      text: 'Auditoría',
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildMenuEditor(),
                      AlcanceRolWdg(roles: _roles),
                      CamposRolWdg(roles: _roles),
                      VersionesWdg(roles: _roles),
                      AuditoriaWdg(roles: _roles),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMenuEditor() {
    final isWide = MediaQuery.of(context).size.width >= 1100;
    if (isWide) {
      return Row(
        children: [
          SizedBox(
            width: 260,
            child: ArbolModulosWdg(
              modulos: _modulos,
              selectedId: _selectedModulo?.id,
              onSelect: (m) => setState(() => _selectedModulo = m),
              onAdd: () => _showModuloDialog(),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: PanelConfigWdg(
              modulo: _selectedModulo,
              roles: _roles,
              selectedRolId: _selectedRol?.id,
              menuConfig: _menuConfig,
              onRolSelected: _onRolSelected,
              onAddModulo: _onAddModulo,
              onRemoveModulo: _onRemoveModulo,
              onEditItem: _onEditItem,
              hasChanges: _menuDirty,
              saving: _savingMenu,
              onSave: _guardarMenuRol,
            ),
          ),
          const VerticalDivider(width: 1),
          SizedBox(
            width: 280,
            child: PreviewMenuWdg(
              items: _menuConfig,
              rolNombre: _selectedRol?.nombre,
            ),
          ),
        ],
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: ArbolModulosWdg(
              modulos: _modulos,
              selectedId: _selectedModulo?.id,
              onSelect: (m) => setState(() => _selectedModulo = m),
              onAdd: () => _showModuloDialog(),
            ),
          ),
          const SizedBox(height: 12),
          PanelConfigWdg(
            modulo: _selectedModulo,
            roles: _roles,
            selectedRolId: _selectedRol?.id,
            menuConfig: _menuConfig,
            onRolSelected: _onRolSelected,
            onAddModulo: _onAddModulo,
            onRemoveModulo: _onRemoveModulo,
            onEditItem: _onEditItem,
            hasChanges: _menuDirty,
            saving: _savingMenu,
            onSave: _guardarMenuRol,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 400,
            child: PreviewMenuWdg(
              items: _menuConfig,
              rolNombre: _selectedRol?.nombre,
            ),
          ),
        ],
      ),
    );
  }
}
