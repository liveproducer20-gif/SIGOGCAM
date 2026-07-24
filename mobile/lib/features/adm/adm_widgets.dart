import 'dart:async';
import 'package:flutter/material.dart';
import 'adm_design_tokens.dart';

// ──────────────────────────────────────────────
// UTILITY FUNCTIONS (sin cambios)
// ──────────────────────────────────────────────

int admId(Map<String, dynamic> item) {
  final id = int.tryParse(item['id']?.toString() ?? '');
  if (id == null) {
    throw ArgumentError('Item sin id válido: ${item['nombre'] ?? item['codigo'] ?? item}');
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
  style: AdmTokens.body,
);

// ──────────────────────────────────────────────
// ADMIN HEADER
// ──────────────────────────────────────────────

class AdminHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;
  final VoidCallback? onCreate;
  final Widget? actions;

  const AdminHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRefresh,
    this.onCreate,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AdmTokens.h1),
                const SizedBox(height: 2),
                Text(subtitle, style: AdmTokens.subtitle),
              ],
            ),
          ),
          if (onRefresh != null)
            _ToolbarButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Actualizar',
              onTap: onRefresh!,
            ),
          if (onCreate != null) const SizedBox(width: 8),
          if (onCreate != null)
            _ActionButton(
              icon: Icons.add_rounded,
              label: 'Nuevo',
              onTap: onCreate!,
            ),
          if (actions != null) ...[const SizedBox(width: 12), actions!],
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ToolbarButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Tooltip(
          message: widget.tooltip,
          child: Material(
            color: _hovered ? AdmTokens.grey100 : AdmTokens.surface,
            borderRadius: BorderRadius.circular(14),
            elevation: _hovered ? 2 : 0,
            shadowColor: AdmTokens.grey300,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onTap,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(widget.icon, size: 20, color: AdmTokens.grey600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: SizedBox(
          height: 40,
          child: Material(
            color: AdmTokens.primary,
            borderRadius: BorderRadius.circular(14),
            elevation: _hovered ? 4 : 0,
            shadowColor: AdmTokens.primary.withValues(alpha: 0.3),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(widget.label, style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// SUMMARY CARDS
// ──────────────────────────────────────────────

class AdminSummaryRow extends StatelessWidget {
  final List<AdminSummaryCardData> cards;
  const AdminSummaryRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final crossAxisCount = maxW > 900 ? 4 : (maxW > 600 ? 2 : 1);
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final card in cards)
              SizedBox(
                width: (maxW - (crossAxisCount - 1) * 14) / crossAxisCount - 0.1,
                child: _AdminSummaryCardTile(data: card),
              ),
          ],
        );
      },
    );
  }
}

class AdminSummaryCardData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const AdminSummaryCardData({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}

class _AdminSummaryCardTile extends StatefulWidget {
  final AdminSummaryCardData data;
  const _AdminSummaryCardTile({required this.data});

  @override
  State<_AdminSummaryCardTile> createState() => _AdminSummaryCardTileState();
}

class _AdminSummaryCardTileState extends State<_AdminSummaryCardTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.data;
    return FadeTransition(
      opacity: _fadeAnim,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _hovered ? (Matrix4.identity()..setTranslationRaw(0, -2, 0)) : Matrix4.identity(),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AdmTokens.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _hovered ? AdmTokens.hoverShadow : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(c.icon, color: c.color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.value, style: AdmTokens.statValue),
                    const SizedBox(height: 2),
                    Text(c.label, style: AdmTokens.statLabel),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// SEARCH BAR
// ──────────────────────────────────────────────

class AdminSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onFilters;

  const AdminSearchBar({
    super.key,
    this.controller,
    required this.onChanged,
    this.hintText = 'Buscar...',
    this.onFilters,
  });

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_refreshClearButton);
  }

  void _refreshClearButton() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_refreshClearButton);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: _controller,
        style: const TextStyle(fontSize: 14, color: AdmTokens.grey800),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: AdmTokens.grey500, fontSize: 14, fontWeight: FontWeight.w400),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Icon(Icons.search_rounded, size: 20, color: AdmTokens.grey400),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear_rounded, size: 18, color: AdmTokens.grey400),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (widget.onFilters != null) ...[
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: widget.onFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AdmTokens.grey100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, size: 16, color: AdmTokens.grey600),
                          const SizedBox(width: 6),
                          Text('Filtros', style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AdmTokens.grey600,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          filled: true,
          fillColor: AdmTokens.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AdmTokens.grey200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AdmTokens.grey200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AdmTokens.primary, width: 1.5),
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// STATUS CHIP
// ──────────────────────────────────────────────

class AdminStatusChip extends StatelessWidget {
  final bool active;
  final String? label;
  final String? status;

  const AdminStatusChip({super.key, required this.active, this.label, this.status});

  @override
  Widget build(BuildContext context) {
    final resolvedStatus = status ?? (active ? 'Activo' : 'Inactivo');
    final resolvedLabel = label ?? resolvedStatus;
    final isAct = resolvedStatus == 'Activo';
    final color = isAct ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF);
    final bg = isAct ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            resolvedLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// ACTION MENU (PopupMenuButton)
// ──────────────────────────────────────────────

class AdminActionMenu extends StatefulWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onReset;
  final VoidCallback? onHistory;
  final bool active;

  const AdminActionMenu({
    super.key,
    this.onEdit,
    this.onToggle,
    this.onDelete,
    this.onReset,
    this.onHistory,
    required this.active,
  });

  @override
  State<AdminActionMenu> createState() => _AdminActionMenuState();
}

class _AdminActionMenuState extends State<AdminActionMenu> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PopupMenuButton<String>(
        offset: const Offset(-150, 4),
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        itemBuilder: (_) => [
          if (widget.onEdit != null)
            PopupMenuItem(
              value: 'edit',
              child: _MenuRow(icon: Icons.edit_outlined, text: 'Editar', color: AdmTokens.grey700),
            ),
          if (widget.onReset != null)
            PopupMenuItem(
              value: 'reset',
              child: _MenuRow(icon: Icons.lock_reset_outlined, text: 'Restablecer contraseña', color: AdmTokens.grey700),
            ),
          if (widget.onToggle != null)
            PopupMenuItem(
              value: 'toggle',
              child: _MenuRow(
                icon: widget.active ? Icons.block_outlined : Icons.check_circle_outline,
                text: widget.active ? 'Desactivar' : 'Activar',
                color: widget.active ? AdmTokens.warning : AdmTokens.success,
              ),
            ),
          if (widget.onHistory != null)
            PopupMenuItem(
              value: 'history',
              child: _MenuRow(icon: Icons.build_outlined, text: 'Mantenimientos', color: AdmTokens.grey700),
            ),
          if (widget.onDelete != null)
            PopupMenuItem(
              value: 'delete',
              child: _MenuRow(icon: Icons.delete_outline, text: 'Eliminar', color: AdmTokens.error),
            ),
        ],
        onSelected: (v) {
          switch (v) {
            case 'edit': widget.onEdit?.call();
            case 'reset': widget.onReset?.call();
            case 'toggle': widget.onToggle?.call();
            case 'history': widget.onHistory?.call();
            case 'delete': widget.onDelete?.call();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFE5E7EB) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.more_horiz_rounded, size: 20, color: AdmTokens.grey500),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MenuRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// MODERN PAGINATION
// ──────────────────────────────────────────────

class AdminPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int total;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const AdminPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = ((currentPage - 1) * pageSize) + 1;
    final end = (currentPage * pageSize).clamp(0, total);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando $start a $end de $total resultados',
            style: TextStyle(fontSize: 13, color: AdmTokens.grey500),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageBtn(
                icon: Icons.first_page_rounded,
                onTap: currentPage > 1 ? () => onPageChanged(1) : null,
              ),
              const SizedBox(width: 2),
              _PageBtn(
                icon: Icons.chevron_left_rounded,
                onTap: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
              ),
              const SizedBox(width: 4),
              for (final p in _visiblePages())
                _PageNum(
                  page: p,
                  isActive: p == currentPage,
                  onTap: () => onPageChanged(p),
                ),
              const SizedBox(width: 4),
              _PageBtn(
                icon: Icons.chevron_right_rounded,
                onTap: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
              ),
              const SizedBox(width: 2),
              _PageBtn(
                icon: Icons.last_page_rounded,
                onTap: currentPage < totalPages ? () => onPageChanged(totalPages) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<int> _visiblePages() {
    final total = totalPages;
    final cur = currentPage;
    if (total <= 7) {
      return [for (int i = 1; i <= total; i++) i];
    }
    final pages = <int>[];
    pages.add(1);
    final start = (cur - 2).clamp(2, total - 4);
    final end = (cur + 2).clamp(5, total - 1);
    if (start > 2) {
      pages.add(-1);
    }
    for (int i = start; i <= end; i++) {
      pages.add(i);
    }
    if (end < total - 1) pages.add(-1);
    pages.add(total);
    return pages;
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _PageBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap != null ? AdmTokens.surface : AdmTokens.grey50,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18,
            color: onTap != null ? AdmTokens.grey700 : AdmTokens.grey300),
        ),
      ),
    );
  }
}

class _PageNum extends StatelessWidget {
  final int page;
  final bool isActive;
  final VoidCallback onTap;

  const _PageNum({required this.page, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (page == -1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('...', style: TextStyle(color: AdmTokens.grey400, fontSize: 13)),
      );
    }
    return Material(
      color: isActive ? AdmTokens.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      elevation: isActive ? 2 : 0,
      shadowColor: isActive ? AdmTokens.primary.withValues(alpha: 0.3) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActive ? null : onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              '$page',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : AdmTokens.grey600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// MODERN TABLE
// ──────────────────────────────────────────────

class AdminTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final List<String> columns;
  final List<Widget> Function(Map<String, dynamic> item) rowBuilder;
  final bool isLoading;

  const AdminTable({
    super.key,
    required this.items,
    required this.columns,
    required this.rowBuilder,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(
        strokeWidth: 3, color: AdmTokens.primary,
      )));
    }
    const headerColor = Color(0xFF0D3F8A);
    return Container(
      decoration: BoxDecoration(
        color: AdmTokens.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 54,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 64,
          horizontalMargin: 24,
          columnSpacing: 32,
          showCheckboxColumn: false,
          headingRowColor: WidgetStateProperty.all(headerColor),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return const Color(0xFFEEF5FF);
            return null;
          }),
          border: TableBorder(
            horizontalInside: BorderSide(color: AdmTokens.grey100.withValues(alpha: 0.3), width: 0.5),
          ),
          columns: [
            for (int ci = 0; ci < columns.length; ci++)
              DataColumn(
                label: Text(
                  columns[ci],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
          ],
          rows: items.isEmpty
              ? [
                  DataRow(cells: [
                    DataCell(SizedBox(
                      width: 600,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_rounded, size: 40, color: AdmTokens.grey300),
                              const SizedBox(height: 12),
                              Text('Sin registros', style: TextStyle(
                                fontSize: 14, color: AdmTokens.grey400,
                              )),
                            ],
                          ),
                        ),
                      ),
                    )),
                    for (int i = 1; i < columns.length; i++) const DataCell(SizedBox.shrink()),
                  ]),
                ]
              : [
                  for (int ri = 0; ri < items.length; ri++)
                    DataRow(
                      color: WidgetStateProperty.all(
                        ri.isEven ? const Color(0xFFFFFFFF) : const Color(0xFFF7FAFF),
                      ),
                      cells: [
                        for (final cell in rowBuilder(items[ri])) DataCell(cell),
                      ],
                    ),
                ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// FORM FIELD
// ──────────────────────────────────────────────

Widget admField(TextEditingController ctl, String label, {bool number = false}) {
  return TextField(
    controller: ctl,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AdmTokens.grey500, fontSize: 14),
      filled: true,
      fillColor: AdmTokens.grey50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AdmTokens.grey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AdmTokens.grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AdmTokens.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    style: const TextStyle(fontSize: 14, color: AdmTokens.grey700),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AdmTokens.grey500, fontSize: 14),
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AdmTokens.grey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AdmTokens.grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AdmTokens.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    items: [
      if (optional) const DropdownMenuItem<int>(value: null, child: Text('Sin asignar')),
      for (final item in data)
        DropdownMenuItem<int>(
          value: admId(item),
          child: Text(
            labelBuilder?.call(item) ?? item['nombre']?.toString() ?? item['codigo']?.toString() ?? '${admId(item)}',
            style: const TextStyle(fontSize: 14),
          ),
        ),
    ],
    onChanged: onChanged,
  );
}

// ──────────────────────────────────────────────
// FORM DIALOG
// ──────────────────────────────────────────────

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AdmTokens.h2),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final child in children) ...[
                        child,
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Cancelar', style: TextStyle(color: AdmTokens.grey500)),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: AdmTokens.primary,
                    borderRadius: BorderRadius.circular(10),
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: onSave,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.save_outlined, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Guardar', style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// ALERT TEXT (mantenimientos)
// ──────────────────────────────────────────────

class AdmAlertText extends StatelessWidget {
  final String? text;
  const AdmAlertText({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    final estado = text;
    if (estado == null || estado.isEmpty) return Text('Sin alerta', style: TextStyle(color: AdmTokens.grey400, fontSize: 13));
    String label;
    Color color;
    switch (estado) {
      case 'KILOMETRAJE_EXCEDIDO':
        label = 'Kilometraje excedido';
        color = AdmTokens.error;
        break;
      case 'EN_ESPERA':
        label = 'En espera';
        color = AdmTokens.warning;
        break;
      case 'MANTENIMIENTO_COMPLETADO':
        label = 'Mantenimiento completado';
        color = AdmTokens.success;
        break;
      default:
        label = estado;
        color = AdmTokens.grey500;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color,
          fontSize: 12,
        )),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// BACKWARD COMPATIBILITY ALIASES
// ──────────────────────────────────────────────

// Keep old names so existing tab code still compiles
class AdmAsyncTable extends StatelessWidget {
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
  final List<AdminSummaryCardData>? Function(List<Map<String, dynamic>> items)? summaryBuilder;
  final String? contentTitle;
  final String? contentSubtitle;

  const AdmAsyncTable({
    super.key,
    this.title = '',
    this.subtitle = '',
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
    this.summaryBuilder,
    this.contentTitle,
    this.contentSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final summaryCards = summaryBuilder?.call(items);

        // New layout with content header separate from toolbar
        if (contentTitle != null) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content title + subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contentTitle!, style: AdmTokens.h1),
                    if (contentSubtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(contentSubtitle!, style: AdmTokens.subtitle),
                    ],
                  ],
                ),
                // Summary cards
                if (summaryCards != null && summaryCards.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  AdminSummaryRow(cards: summaryCards),
                ],
                // Search bar + toolbar buttons
                if (onSearch != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: AdminSearchBar(
                          onChanged: onSearch!,
                          hintText: searchHint ?? 'Buscar...',
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ToolbarButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Actualizar',
                        onTap: onRefresh,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.add_rounded,
                        label: 'Nuevo',
                        onTap: onCreate,
                      ),
                    ],
                  ),
                ],
                // Table
                const SizedBox(height: 24),
                AdminTable(
                  items: items,
                  columns: columns,
                  rowBuilder: rowBuilder,
                  isLoading: snapshot.connectionState == ConnectionState.waiting,
                ),
                // Pagination
                if (totalPages != null && totalPages! > 1) ...[
                  const SizedBox(height: 4),
                  AdminPagination(
                    currentPage: currentPage ?? 1,
                    totalPages: totalPages ?? 1,
                    total: total ?? items.length,
                    pageSize: 25,
                    onPageChanged: (p) => onPageChanged?.call(p),
                  ),
                ],
              ],
            ),
          );
        }

        // Legacy layout (backward compatible)
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminHeader(
                title: title,
                subtitle: subtitle,
                onRefresh: onRefresh,
                onCreate: onCreate,
              ),
              if (summaryCards != null && summaryCards.isNotEmpty) ...[
                const SizedBox(height: 14),
                AdminSummaryRow(cards: summaryCards),
              ],
              if (onSearch != null) ...[
                const SizedBox(height: 12),
                AdminSearchBar(
                  onChanged: onSearch!,
                  hintText: searchHint ?? 'Buscar...',
                ),
              ],
              if (header != null) ...[
                const SizedBox(height: 12),
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: header!),
              ],
              const SizedBox(height: 14),
              AdminTable(
                items: items,
                columns: columns,
                rowBuilder: rowBuilder,
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              ),
              if (totalPages != null && totalPages! > 1) ...[
                AdminPagination(
                  currentPage: currentPage ?? 1,
                  totalPages: totalPages ?? 1,
                  total: total ?? items.length,
                  pageSize: 25,
                  onPageChanged: (p) => onPageChanged?.call(p),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Backward-compatible alias for AdmActions → delegates to AdminActionMenu
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
    return AdminActionMenu(
      onEdit: onEdit,
      onToggle: onToggle,
      onDelete: onDelete,
      onReset: onReset,
      onHistory: onHistory,
      active: active,
    );
  }
}

/// Backward-compatible alias for AdmStateChip → delegates to AdminStatusChip
class AdmStateChip extends StatelessWidget {
  final bool active;
  final String? label;
  const AdmStateChip({super.key, required this.active, this.label});

  @override
  Widget build(BuildContext context) {
    return AdminStatusChip(active: active, label: label);
  }
}
