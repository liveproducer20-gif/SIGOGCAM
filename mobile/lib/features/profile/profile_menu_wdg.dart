import 'package:flutter/material.dart';

import '../../core/auth/app_user.dart';
import '../../core/file/file_pick.dart';
import '../../core/notif/notif_read_store.dart';
import '../../core/thm/app_thm.dart';
import '../evt/ann/svc/ann_svc.dart';
import '../evt/svc/evt_svc.dart';
import 'profile_api.dart';

class ProfileMenuWdg extends StatefulWidget {
  final AppUser user;
  final ValueChanged<AppUser>? onUserChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onNotifications;

  const ProfileMenuWdg({
    super.key,
    required this.user,
    this.onUserChanged,
    this.onLogout,
    this.onNotifications,
  });

  @override
  State<ProfileMenuWdg> createState() => _ProfileMenuWdgState();
}

class _ProfileMenuWdgState extends State<ProfileMenuWdg> {
  late Future<int> _notifCountFuture;

  @override
  void initState() {
    super.initState();
    _notifCountFuture = _notificationCount();
  }

  @override
  void didUpdateWidget(ProfileMenuWdg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user.id != oldWidget.user.id) {
      _notifCountFuture = _notificationCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ProfileAction>(
      tooltip: 'Perfil',
      offset: const Offset(0, 48),
      onSelected: (action) {
        if (action == _ProfileAction.view) {
          _openProfile(context, editMode: false);
        } else if (action == _ProfileAction.edit) {
          _openProfile(context, editMode: true);
        } else if (action == _ProfileAction.notifications) {
          widget.onNotifications?.call();
        } else {
          widget.onLogout?.call();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _ProfileAction.view,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.account_circle_outlined),
            title: Text('Ver perfil'),
          ),
        ),
        PopupMenuItem(
          value: _ProfileAction.edit,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar perfil'),
          ),
        ),
        PopupMenuItem(
          value: _ProfileAction.notifications,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.notifications_outlined),
            title: Text('Notificaciones'),
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _ProfileAction.logout,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.logout_outlined),
            title: Text('Cerrar sesión'),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: FutureBuilder<int>(
          future: _notifCountFuture,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/img/sigo_gcam.png',
                  height: 340,
                  width: 340,
                ),
                const SizedBox(width: 8),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _ProfileAvatar(
                      imageUrl: widget.user.fotoPerfilUrl,
                      initials: _initials(widget.user),
                      radius: 21,
                    ),
                    if (count > 0)
                      Positioned(
                        right: -4,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<int> _notificationCount() async {
    final events = await _safeLoadEvents();
    final annList = await _safeLoadAnnouncements();
    final announcements = annList.where((ann) {
      if (!ann.publicado || !ann.notificar) return false;
      return !widget.user.esUsuario || ann.personalIds.contains(widget.user.id);
    });
    final unreadEvents = events.where(
      (evt) => evt.notificar && !NotifReadStore.isRead('evento:${evt.id}'),
    );
    final unreadAnnouncements = announcements.where(
      (ann) => !NotifReadStore.isRead('anuncio:${ann.id}'),
    );

    return unreadEvents.length + unreadAnnouncements.length;
  }

  Future<List<dynamic>> _safeLoadEvents() async {
    try {
      return await EvtSvc.getLst(
        personalId: widget.user.soloEventosConvocados ? widget.user.id : null,
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> _safeLoadAnnouncements() async {
    try {
      return await AnnSvc.getLst(
        personalId: widget.user.esUsuario ? widget.user.id : null,
      );
    } catch (_) {
      return [];
    }
  }

  Future<void> _openProfile(
    BuildContext context, {
    required bool editMode,
  }) async {
    final updated = await showDialog<AppUser>(
      context: context,
      builder: (_) => ProfileDialog(
        user: widget.user,
        editMode: editMode,
      ),
    );

    if (updated != null) {
      widget.onUserChanged?.call(updated);
    }
  }

  String _initials(AppUser user) {
    final parts = user.nombreCompleto
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }

    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
    return 'U';
  }
}

class ProfileDialog extends StatefulWidget {
  final AppUser user;
  final bool editMode;

  const ProfileDialog({
    super.key,
    required this.user,
    required this.editMode,
  });

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final api = ProfileApi();
  final cedulaCtl = TextEditingController();
  final nombresCtl = TextEditingController();
  final apellidosCtl = TextEditingController();
  final correoCtl = TextEditingController();
  final telefonoCtl = TextEditingController();
  String? fechaNacimiento;
  String? fotoPerfilUrl;
  bool editando = false;
  bool guardando = false;
  String? error;

  @override
  void initState() {
    super.initState();
    editando = widget.editMode;
    _load(widget.user);
    _refresh();
  }

  @override
  void dispose() {
    cedulaCtl.dispose();
    nombresCtl.dispose();
    apellidosCtl.dispose();
    correoCtl.dispose();
    telefonoCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          _ProfileAvatar(
            imageUrl: fotoPerfilUrl,
            initials: _initials(),
            radius: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(editando ? 'Editar perfil' : 'Perfil de usuario'),
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null) ...[
                _ErrorBox(error: error!),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: nombresCtl,
                      label: 'Nombres',
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: apellidosCtl,
                      label: 'Apellidos',
                      enabled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                controller: cedulaCtl,
                label: 'Cédula',
                icon: Icons.badge_outlined,
                enabled: editando,
              ),
              const SizedBox(height: 12),
              _field(
                controller: correoCtl,
                label: 'Correo institucional',
                icon: Icons.mail_outline,
                enabled: editando,
              ),
              const SizedBox(height: 12),
              _field(
                controller: telefonoCtl,
                label: 'Teléfono',
                icon: Icons.phone_outlined,
                enabled: editando,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: editando ? _pickDate : null,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de nacimiento',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    fechaNacimiento?.split('T').first ?? 'Sin registrar',
                    style: TextStyle(
                      color: editando ? Colors.black87 : Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _readOnlyInfo('Rol', widget.user.rol),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _readOnlyInfo(
                      'Estado operativo',
                      widget.user.estadoPersonal ?? 'Sin estado',
                    ),
                  ),
                ],
              ),
              if (editando) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Cambiar foto'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: guardando ? null : () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        if (!editando)
          FilledButton.icon(
            onPressed: () => setState(() => editando = true),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          )
        else
          FilledButton.icon(
            onPressed: guardando ? null : _save,
            icon: guardando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Guardar'),
          ),
      ],
    );
  }

  TextField _field({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _readOnlyInfo(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      child: Text(value),
    );
  }

  Future<void> _refresh() async {
    try {
      final remote = await api.getMe();
      if (!mounted) return;
      setState(() => _load(remote));
    } catch (_) {
      // El diálogo puede trabajar con la sesión local si el refresco falla.
    }
  }

  void _load(AppUser user) {
    cedulaCtl.text = user.cedula;
    nombresCtl.text = user.nombres;
    apellidosCtl.text = user.apellidos;
    correoCtl.text = user.correo;
    telefonoCtl.text = user.telefono ?? '';
    fechaNacimiento = user.fechaNacimiento;
    fotoPerfilUrl = user.fotoPerfilUrl;
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(fechaNacimiento ?? '') ?? DateTime(1990);
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (date == null) return;
    setState(() {
      fechaNacimiento = date.toIso8601String().split('T').first;
    });
  }

  Future<void> _pickImage() async {
    final file = await pickImage();
    if (file == null) return;

    setState(() {
      fotoPerfilUrl = file.dataUrl ?? file.previewUrl;
    });
  }

  Future<void> _save() async {
    setState(() {
      guardando = true;
      error = null;
    });

    try {
      final updated = await api.updateMe(
        cedula: cedulaCtl.text.trim(),
        correo: correoCtl.text.trim(),
        telefono: telefonoCtl.text.trim().isEmpty ? null : telefonoCtl.text.trim(),
        fechaNacimiento: fechaNacimiento,
        fotoPerfilUrl: fotoPerfilUrl,
      );

      if (!mounted) return;
      Navigator.pop(
        context,
        widget.user.copyWith(
          cedula: updated.cedula,
          nombres: updated.nombres,
          apellidos: updated.apellidos,
          correo: updated.correo,
          telefono: updated.telefono,
          fechaNacimiento: updated.fechaNacimiento,
          fotoPerfilUrl: fotoPerfilUrl ?? updated.fotoPerfilUrl,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        guardando = false;
      });
    }
  }

  String _initials() {
    final name = '${nombresCtl.text} ${apellidosCtl.text}'.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}';
    return parts.first[0].toUpperCase();
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;

  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        error,
        style: TextStyle(color: Colors.red.shade800),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double radius;

  const _ProfileAvatar({
    required this.imageUrl,
    required this.initials,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final size = radius * 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppThm.secClr,
      child: ClipOval(
        child: url == null || url.isEmpty
            ? _Initials(initials: initials)
            : Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _Initials(initials: initials),
              ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initials;

  const _Initials({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Future<bool> showPasswordCooldownNotice(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Atención'),
      content: const Text(
        'Esta opción se puede volver a utilizar después de 72h.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );

  return ok == true;
}

enum _ProfileAction { view, edit, notifications, logout }

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final api = ProfileApi();
  final oldCtl = TextEditingController();
  final newCtl = TextEditingController();
  final confirmCtl = TextEditingController();
  bool saving = false;
  bool showOld = false;
  bool showNew = false;
  bool showConfirm = false;
  String? error;

  @override
  void dispose() {
    oldCtl.dispose();
    newCtl.dispose();
    confirmCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null) ...[
              _ErrorBox(error: error!),
              const SizedBox(height: 12),
            ],
            _passwordField(
              controller: oldCtl,
              label: 'Vieja contraseña',
              visible: showOld,
              onToggle: () => setState(() => showOld = !showOld),
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: newCtl,
              label: 'Nueva contraseña',
              visible: showNew,
              onToggle: () => setState(() => showNew = !showNew),
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: confirmCtl,
              label: 'Verifique nueva contraseña',
              visible: showConfirm,
              onToggle: () => setState(() => showConfirm = !showConfirm),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
      error = null;
    });

    try {
      await api.changePassword(
        oldPassword: oldCtl.text.trim(),
        newPassword: newCtl.text.trim(),
        confirmPassword: confirmCtl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        saving = false;
      });
    }
  }
}
