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

class AdmAsyncTable extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<List<Map<String, dynamic>>> future;
  final List<String> columns;
  final List<Widget> Function(Map<String, dynamic> item) rowBuilder;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final Widget? header;
  final int? total;
  final int? currentPage;
  final int? totalPages;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<String>? onSearch;
  final String? searchHint;

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
    this.total,
    this.currentPage,
    this.totalPages,
    this.onPageChanged,
    this.onSearch,
    this.searchHint,
  });

  @override
  State<AdmAsyncTable> createState() => _AdmAsyncTableState();
}

class _AdmAsyncTableState extends State<AdmAsyncTable> {
  final _searchCtl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Row(
              children: [
                Expanded(child: PageTtlWdg(ttl: widget.title, sub: widget.subtitle)),
                IconButton.filledTonal(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: widget.onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.onSearch != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: 360,
                  child: TextField(
                    controller: _searchCtl,
                    decoration: InputDecoration(
                      hintText: widget.searchHint ?? 'Buscar...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtl.clear();
                                _debounce?.cancel();
                                widget.onSearch!('');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        widget.onSearch!(v);
                      });
                    },
                  ),
                ),
              ),
            if (widget.header != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: widget.header!,
              ),
              const SizedBox(height: 12),
            ],
            if (isLoading)
              const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))
            else if (snapshot.hasError)
              SizedBox(height: 260, child: Center(child: Text('${snapshot.error}')))
            else
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 56,
                    columns: [
                      for (final column in widget.columns) DataColumn(label: Text(column, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: items.isEmpty
                        ? [
                            DataRow(cells: [
                              DataCell(SizedBox(
                                width: 600,
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(widget.total != null && widget.total! > 0 ? 'Sin resultados para esta busqueda' : 'Sin registros'),
                                  ),
                                ),
                              )),
                              for (int i = 1; i < widget.columns.length; i++) const DataCell(SizedBox.shrink()),
                            ]),
                          ]
                        : [
                            for (final item in items)
                              DataRow(cells: [
                                for (final cell in widget.rowBuilder(item)) DataCell(cell),
                              ]),
                          ],
                  ),
                ),
              ),
            if (widget.totalPages != null && widget.totalPages! > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: widget.currentPage! > 1 && widget.onPageChanged != null
                          ? () => widget.onPageChanged!(widget.currentPage! - 1)
                          : null,
                      tooltip: 'Anterior',
                    ),
                    Text('Pagina ${widget.currentPage ?? 1} de ${widget.totalPages ?? 1}  (${widget.total ?? 0} registros)'),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: widget.currentPage! < widget.totalPages! && widget.onPageChanged != null
                          ? () => widget.onPageChanged!(widget.currentPage! + 1)
                          : null,
                      tooltip: 'Siguiente',
                    ),
                  ],
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
