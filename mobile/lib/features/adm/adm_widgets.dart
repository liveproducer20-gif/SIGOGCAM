import 'package:flutter/material.dart';

import '../../core/thm/app_thm.dart';
import '../dash/wdg/page_ttl_wdg.dart';

int admId(Map<String, dynamic> item) {
  final id = int.tryParse(item['id']?.toString() ?? '');
  if (id == null) {
    throw ArgumentError(
      'Item sin id válido: ${item['nombre'] ?? item['codigo'] ?? item}',
    );
  }
  return id;
}

List<Map<String, dynamic>> admParseList(Object? value) {
  final list = value as List<dynamic>? ?? [];
  return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

bool admIsActive(Map<String, dynamic> item, {String key = 'activo'}) {
  final value = item[key];
  return value == true || value == 1 || value?.toString() == '1';
}

String admFormatDate(String value) {
  if (value.length >= 10) return value.substring(0, 10);
  return value;
}

Text admText(Object? value) => Text(
      value?.toString() ?? '',
      overflow: TextOverflow.ellipsis,
    );

Widget admField(TextEditingController ctl, String label, {bool number = false}) {
  return TextField(
    controller: ctl,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
}

Widget admDropdown(
  String label,
  List<Map<String, dynamic>>? items,
  int? value,
  ValueChanged<int?> onChanged, {
  bool optional = false,
  String Function(Map<String, dynamic>)? labelBuilder,
}) {
  final data = items ?? [];
  final hasValue = data.any((item) => admId(item) == value);
  return DropdownButtonFormField<int>(
    initialValue: hasValue ? value : null,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: [
      if (optional) const DropdownMenuItem<int>(value: null, child: Text('Sin asignar')),
      for (final item in data)
        DropdownMenuItem<int>(
          value: admId(item),
          child: Text(
              labelBuilder?.call(item) ?? item['nombre']?.toString() ?? item['codigo']?.toString() ?? '${admId(item)}'),
        ),
    ],
    onChanged: onChanged,
  );
}

class AdmAsyncTable extends StatelessWidget {
  final String title;
  final String subtitle;
  final Future<List<Map<String, dynamic>>> future;
  final List<String> columns;
  final List<Widget> Function(Map<String, dynamic> item) rowBuilder;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final Widget? header;

  const AdmAsyncTable({
    super.key,
    required this.title,
    required this.subtitle,
    required this.future,
    required this.columns,
    required this.rowBuilder,
    required this.onRefresh,
    required this.onCreate,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Row(
              children: [
                Expanded(child: PageTtlWdg(ttl: title, sub: subtitle)),
                IconButton.filledTonal(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
            if (header != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: header!,
              ),
              const SizedBox(height: 12),
            ],
            if (snapshot.connectionState == ConnectionState.waiting)
              const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))
            else if (snapshot.hasError)
              SizedBox(height: 260, child: Center(child: Text('${snapshot.error}')))
            else
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      for (final column in columns) DataColumn(label: Text(column)),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(cells: [
                          for (final cell in rowBuilder(item)) DataCell(cell),
                        ]),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AdmActions extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onReset;
  final VoidCallback? onHistory;
  final bool active;

  const AdmActions({
    super.key,
    this.onEdit,
    this.onToggle,
    this.onDelete,
    this.onReset,
    this.onHistory,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
        if (onHistory != null)
          IconButton(
            onPressed: onHistory,
            icon: const Icon(Icons.build_outlined),
            tooltip: 'Mantenimientos',
          ),
        if (onToggle != null)
          IconButton(
            onPressed: onToggle,
            icon: Icon(active ? Icons.block_outlined : Icons.check_circle_outline),
            tooltip: active ? 'Inactivar' : 'Activar',
          ),
        if (onReset != null)
          IconButton(
            onPressed: onReset,
            icon: const Icon(Icons.lock_reset_outlined),
            tooltip: 'Restablecer contrasena',
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Eliminar',
          ),
      ],
    );
  }
}

class AdmStateChip extends StatelessWidget {
  final bool active;
  final String? label;
  const AdmStateChip({super.key, required this.active, this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label ?? (active ? 'Activo' : 'Inactivo')),
      backgroundColor: active
          ? AppThm.okClr.withValues(alpha: 0.12)
          : Colors.red.withValues(alpha: 0.10),
      labelStyle: TextStyle(
        color: active ? AppThm.okClr : Colors.red.shade700,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class AdmFormDialog extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final double width;

  const AdmFormDialog({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
    this.width = 540,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}

class AdmAlertText extends StatelessWidget {
  final String? text;
  const AdmAlertText({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    final estado = text;
    if (estado == null || estado.isEmpty) return const Text('Sin alerta');
    String label;
    MaterialColor color;
    switch (estado) {
      case 'KILOMETRAJE_EXCEDIDO':
        label = 'Kilometraje excedido';
        color = Colors.red;
        break;
      case 'EN_ESPERA':
        label = 'En espera';
        color = Colors.amber;
        break;
      case 'MANTENIMIENTO_COMPLETADO':
        label = 'Mantenimiento completado';
        color = Colors.green;
        break;
      default:
        label = estado;
        color = Colors.grey;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color.shade700)),
      ],
    );
  }
}
