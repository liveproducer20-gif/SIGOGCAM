import 'package:flutter/material.dart';

import 'adm_api.dart';
import 'adm_design_tokens.dart';
import 'adm_export.dart';
import 'adm_helpers.dart';
import 'adm_widgets.dart';

class GradosTab extends StatefulWidget {
  final AdmApi api;
  const GradosTab({super.key, required this.api});

  @override
  State<GradosTab> createState() => _GradosTabState();
}

class _GradosTabState extends State<GradosTab> {
  late Future<_GradeData> future;
  String search = '';
  String status = 'Todos';
  String sort = 'Jerarquía';
  int? selectedGradeId;

  @override
  void initState() {
    super.initState();
    future = _fetch();
  }

  Future<_GradeData> _fetch() async {
    final grades = await widget.api.getGrados();
    var personnel = <Map<String, dynamic>>[];
    try {
      personnel = await widget.api.getPersonalList();
    } catch (_) {
      // La jerarquía sigue disponible aunque Personal no pueda consultarse.
    }
    return _GradeData(grades: grades, personnel: personnel);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GradeData>(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _GradeData(grades: [], personnel: []);
        final ordered = [...data.grades]..sort((a, b) => admId(a).compareTo(admId(b)));
        final filtered = ordered.where((grade) {
          final name = grade['nombre']?.toString() ?? '';
          if (search.isNotEmpty && !name.toLowerCase().contains(search.toLowerCase())) return false;
          if (status == 'Activos' && !admIsActive(grade)) return false;
          if (status == 'Inactivos' && admIsActive(grade)) return false;
          if (selectedGradeId != null && admId(grade) != selectedGradeId) return false;
          return true;
        }).toList();
        if (sort == 'Nombre A-Z') filtered.sort((a, b) => '${a['nombre']}'.compareTo('${b['nombre']}'));
        if (sort == 'Nombre Z-A') filtered.sort((a, b) => '${b['nombre']}'.compareTo('${a['nombre']}'));
        if (sort == 'Más personal') filtered.sort((a, b) => data.countFor(b).compareTo(data.countFor(a)));
        final active = ordered.where(admIsActive).length;
        final top = ordered.isEmpty ? null : ordered.last;
        final mostAssigned = ordered.isEmpty ? null : ([...ordered]..sort((a, b) => data.countFor(b).compareTo(data.countFor(a)))).first;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Administración', style: TextStyle(fontSize: 13, color: AdmTokens.grey500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Grados', style: AdmTokens.h1), SizedBox(height: 5), Text('Administración de grados jerárquicos y académicos del personal institucional.', style: AdmTokens.subtitle)])),
              _GradeIconButton(icon: Icons.refresh_rounded, tooltip: 'Refrescar', onTap: _reload), const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: () => _export(data), icon: const Icon(Icons.download_outlined, size: 18), label: const Text('Exportar')), const SizedBox(width: 8),
              FilledButton.icon(onPressed: () => _edit(null), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Nuevo grado')),
            ]),
            const SizedBox(height: 22),
            AdminSummaryRow(cards: [
              AdminSummaryCardData(icon: Icons.school_outlined, value: '${ordered.length}', label: 'Grados registrados', color: AdmTokens.primary),
              AdminSummaryCardData(icon: Icons.verified_user_outlined, value: '$active', label: 'En funcionamiento', color: AdmTokens.success),
              AdminSummaryCardData(icon: Icons.groups_outlined, value: '${data.personnel.length}', label: 'Personal asignado', color: const Color(0xFFF97316)),
              AdminSummaryCardData(icon: Icons.workspace_premium_outlined, value: top?['nombre']?.toString() ?? 'Sin grados', label: 'Grado superior', color: const Color(0xFFD4A017)),
            ]),
            const SizedBox(height: 18),
            _GradeFilters(status: status, sort: sort, onSearch: (v) => setState(() { search = v.trim(); selectedGradeId = null; }), onStatus: (v) => setState(() { status = v; selectedGradeId = null; }), onSort: (v) => setState(() => sort = v)),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const SizedBox(height: 350, child: Center(child: CircularProgressIndicator()))
            else
              LayoutBuilder(builder: (context, constraints) {
                final cards = _GradeCards(grades: filtered, allGrades: ordered, data: data, onView: (g) => _showGrade(g, data), onPersonnel: (g) => _showPersonnel(g, data), onEdit: _edit, onToggle: _toggle, onDelete: _confirmDelete);
                final hierarchy = _HierarchyPanel(grades: ordered.reversed.toList(), data: data, selectedId: selectedGradeId, onSelect: (id) => setState(() => selectedGradeId = selectedGradeId == id ? null : id));
                if (constraints.maxWidth < 1120) return Column(children: [hierarchy, const SizedBox(height: 16), cards]);
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: cards), const SizedBox(width: 16), Expanded(child: hierarchy)]);
              }),
            const SizedBox(height: 16),
            _GradeBottomStats(total: ordered.length, active: active, personnel: data.personnel.length, mostAssigned: mostAssigned?['nombre']?.toString() ?? 'Sin datos', mostCount: mostAssigned == null ? 0 : data.countFor(mostAssigned)),
          ]),
        );
      },
    );
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      future = _fetch();
    });
  }

  Future<void> _export(_GradeData data) async {
    final rows = <String>['Código,Grado,Estado,Personal asignado,Nivel'];
    final ordered = [...data.grades]..sort((a, b) => admId(a).compareTo(admId(b)));
    for (var i = 0; i < ordered.length; i++) {
      final grade = ordered[i];
      rows.add('GRD-${admId(grade).toString().padLeft(3, '0')},"${grade['nombre']}",${admIsActive(grade) ? 'Activo' : 'Inactivo'},${data.countFor(grade)},${i + 1}');
    }
    final path = await exportAdminCsv(rows.join('\n'), 'grados_sigo_gcam.csv');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Grados exportados en $path')));
  }

  Future<void> _showGrade(Map<String, dynamic> grade, _GradeData data) => _showPersonnel(grade, data);

  Future<void> _showPersonnel(Map<String, dynamic> grade, _GradeData data) => showDialog<void>(context: context, builder: (_) {
    final personnel = data.personnelFor(grade);
    return AlertDialog(title: Text('Personal — ${grade['nombre']}'), content: SizedBox(width: 560, child: personnel.isEmpty ? const Text('No existen funcionarios asignados a este grado.') : ListView(shrinkWrap: true, children: [for (final person in personnel) ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text('${person['nombres'] ?? ''} ${person['apellidos'] ?? ''}'.trim()), subtitle: Text(person['correo_institucional']?.toString() ?? 'Sin correo'))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))]);
  });

  Future<void> _edit(Map<String, dynamic>? item) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _GradoDialog(item: item),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      if (item == null) {
        await widget.api.createGrado(data);
      } else {
        await widget.api.updateGrado(admId(item), data);
      }
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await admSafeRun(context, () async {
      await widget.api.setGradoActivo(admId(item), !admIsActive(item));
      _reload();
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final ok = await admConfirm(context, 'Confirmar', '¿Eliminar grado ${item['nombre']}?');
    if (ok != true) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      await widget.api.deleteGrado(admId(item));
      _reload();
    });
  }
}

class _GradeData {
  final List<Map<String, dynamic>> grades;
  final List<Map<String, dynamic>> personnel;
  const _GradeData({required this.grades, required this.personnel});
  List<Map<String, dynamic>> personnelFor(Map<String, dynamic> grade) {
    final name = grade['nombre']?.toString().trim().toLowerCase() ?? '';
    final id = admId(grade);
    return personnel.where((person) {
      final gradeName = person['grado']?.toString().trim().toLowerCase();
      final gradeId = int.tryParse(person['grado_id']?.toString() ?? '');
      return gradeName == name || gradeId == id;
    }).toList();
  }
  int countFor(Map<String, dynamic> grade) => personnelFor(grade).length;
}

class _GradeFilters extends StatelessWidget {
  final String status;
  final String sort;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onSort;
  const _GradeFilters({required this.status, required this.sort, required this.onSearch, required this.onStatus, required this.onSort});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AdmTokens.grey100), boxShadow: const [BoxShadow(color: Color(0x0D0F172A), blurRadius: 18, offset: Offset(0, 4))]),
    child: LayoutBuilder(builder: (_, constraints) {
      final controls = [
        _GradeSelect(label: 'Estado', value: status, values: const ['Todos', 'Activos', 'Inactivos'], onChanged: onStatus),
        _GradeSelect(label: 'Ordenar', value: sort, values: const ['Jerarquía', 'Nombre A-Z', 'Nombre Z-A', 'Más personal'], onChanged: onSort),
      ];
      if (constraints.maxWidth < 760) return Column(children: [AdminSearchBar(onChanged: onSearch, hintText: 'Buscar grado...'), const SizedBox(height: 10), Row(children: [for (final item in controls) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: item))])]);
      return Row(children: [Expanded(flex: 2, child: AdminSearchBar(onChanged: onSearch, hintText: 'Buscar grado...')), const SizedBox(width: 12), ...controls.map((item) => Expanded(child: Padding(padding: const EdgeInsets.only(left: 8), child: item))), const SizedBox(width: 8), _GradeIconButton(icon: Icons.filter_alt_outlined, tooltip: 'Filtros', onTap: () {})]);
    }),
  );
}

class _GradeSelect extends StatelessWidget {
  final String label, value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  const _GradeSelect({required this.label, required this.value, required this.values, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: const Color(0xFFFAFCFF), border: Border.all(color: AdmTokens.grey200), borderRadius: BorderRadius.circular(12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: value, icon: const Icon(Icons.expand_more_rounded, size: 18), items: [for (final item in values) DropdownMenuItem(value: item, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: AdmTokens.grey500)), Text(item, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]))], onChanged: (next) { if (next != null) onChanged(next); })));
}

class _GradeIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _GradeIconButton({required this.icon, required this.tooltip, required this.onTap});
  @override Widget build(BuildContext context) => Tooltip(message: tooltip, child: SizedBox(width: 46, height: 46, child: OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Icon(icon, size: 19))));
}

class _GradeCards extends StatelessWidget {
  final List<Map<String, dynamic>> grades;
  final List<Map<String, dynamic>> allGrades;
  final _GradeData data;
  final ValueChanged<Map<String, dynamic>> onView;
  final ValueChanged<Map<String, dynamic>> onPersonnel;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onToggle;
  final ValueChanged<Map<String, dynamic>> onDelete;
  const _GradeCards({required this.grades, required this.allGrades, required this.data, required this.onView, required this.onPersonnel, required this.onEdit, required this.onToggle, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) return const SizedBox(height: 220, child: Center(child: Text('Sin grados para mostrar')));
    return Column(children: [for (final grade in grades) Padding(padding: const EdgeInsets.only(bottom: 11), child: _GradeCard(grade: grade, level: allGrades.indexWhere((g) => admId(g) == admId(grade)) + 1, maxLevel: allGrades.length, assigned: data.countFor(grade), onView: () => onView(grade), onPersonnel: () => onPersonnel(grade), onEdit: () => onEdit(grade), onToggle: () => onToggle(grade), onDelete: () => onDelete(grade)))]);
  }
}

class _GradeCard extends StatefulWidget {
  final Map<String, dynamic> grade;
  final int level, maxLevel, assigned;
  final VoidCallback onView, onPersonnel, onEdit, onToggle, onDelete;
  const _GradeCard({required this.grade, required this.level, required this.maxLevel, required this.assigned, required this.onView, required this.onPersonnel, required this.onEdit, required this.onToggle, required this.onDelete});
  @override State<_GradeCard> createState() => _GradeCardState();
}

class _GradeCardState extends State<_GradeCard> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final visual = _gradeVisual(widget.level, widget.maxLevel);
    final name = widget.grade['nombre']?.toString() ?? 'Grado';
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true), onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        transform: hovered ? (Matrix4.identity()..setTranslationRaw(0, -2, 0)) : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: hovered ? visual.$2.withValues(alpha: .3) : AdmTokens.grey100), boxShadow: hovered ? const [BoxShadow(color: Color(0x160F172A), blurRadius: 18, offset: Offset(0, 6))] : const [BoxShadow(color: Color(0x090F172A), blurRadius: 12, offset: Offset(0, 3))]),
        child: LayoutBuilder(builder: (_, c) {
          final main = [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: visual.$2, borderRadius: BorderRadius.circular(11)), child: Icon(visual.$1, color: Colors.white, size: 21)),
            const SizedBox(width: 12),
            Container(width: 40, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(9)), child: Text(widget.level.toString().padLeft(2, '0'), style: const TextStyle(fontWeight: FontWeight.w800, color: AdmTokens.grey700))),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: AdmTokens.grey800)), const SizedBox(height: 3), Text(_description(name, widget.level), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AdmTokens.grey500))])),
            const SizedBox(width: 12), AdmStateChip(active: admIsActive(widget.grade)),
            const SizedBox(width: 18), InkWell(onTap: widget.onPersonnel, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.all(7), child: Row(children: [const Icon(Icons.group_outlined, size: 18, color: AdmTokens.primary), const SizedBox(width: 6), Text('${widget.assigned}', style: const TextStyle(fontWeight: FontWeight.w800))]))),
            const SizedBox(width: 18), SizedBox(width: 150, child: _LevelBar(level: widget.level, maxLevel: widget.maxLevel, color: visual.$2)),
            const SizedBox(width: 12), Row(mainAxisSize: MainAxisSize.min, children: [_GradeAction(icon: Icons.visibility_outlined, tooltip: 'Ver', onTap: widget.onView), const SizedBox(width: 5), _GradeAction(icon: Icons.edit_outlined, tooltip: 'Editar', onTap: widget.onEdit), PopupMenuButton<String>(tooltip: 'Más opciones', icon: const Icon(Icons.more_vert_rounded, size: 19), onSelected: (v) { if (v == 'toggle') widget.onToggle(); if (v == 'delete') widget.onDelete(); }, itemBuilder: (_) => [PopupMenuItem(value: 'toggle', child: Text(admIsActive(widget.grade) ? 'Desactivar' : 'Activar')), const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: AdmTokens.error)))])]),
          ];
          if (c.maxWidth >= 900) return Row(children: main);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: main.take(4).toList()), const SizedBox(height: 12), Row(children: main.skip(4).toList())]);
        }),
      ),
    );
  }

  static String _description(String name, int level) => name.toLowerCase().contains('jefe') ? 'Coordinación y gestión institucional de nivel superior.' : 'Personal institucional correspondiente al nivel jerárquico $level.';
}

(IconData, Color) _gradeVisual(int level, int max) {
  if (level == max) return (Icons.account_balance_outlined, const Color(0xFFD4A017));
  const icons = [Icons.shield_outlined, Icons.star_outline_rounded, Icons.keyboard_double_arrow_up_rounded, Icons.military_tech_outlined, Icons.search_rounded, Icons.workspace_premium_outlined];
  const colors = [Color(0xFF2563EB), Color(0xFF16A34A), Color(0xFF8B5CF6), Color(0xFFF97316), Color(0xFF06B6D4), Color(0xFFEC4899)];
  final index = (level - 1).clamp(0, icons.length - 1);
  return (icons[index], colors[index]);
}

class _LevelBar extends StatelessWidget {
  final int level, maxLevel;
  final Color color;
  const _LevelBar({required this.level, required this.maxLevel, required this.color});
  @override Widget build(BuildContext context) => Row(children: [for (var i = 1; i <= maxLevel; i++) Expanded(child: Container(height: 7, margin: const EdgeInsets.only(right: 3), decoration: BoxDecoration(color: i <= level ? color : const Color(0xFFE5EAF0), borderRadius: BorderRadius.circular(5))))]);
}

class _GradeAction extends StatelessWidget {
  final IconData icon; final String tooltip; final VoidCallback onTap;
  const _GradeAction({required this.icon, required this.tooltip, required this.onTap});
  @override Widget build(BuildContext context) => Tooltip(message: tooltip, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(9), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: AdmTokens.grey200), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 17, color: AdmTokens.primary))));
}

class _HierarchyPanel extends StatelessWidget {
  final List<Map<String, dynamic>> grades;
  final _GradeData data;
  final int? selectedId;
  final ValueChanged<int> onSelect;
  const _HierarchyPanel({required this.grades, required this.data, required this.selectedId, required this.onSelect});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdmTokens.grey100), boxShadow: const [BoxShadow(color: Color(0x0D0F172A), blurRadius: 18, offset: Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Jerarquía institucional', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('Selecciona un nivel para filtrar', style: TextStyle(fontSize: 11, color: AdmTokens.grey500)), const SizedBox(height: 16), for (var i = 0; i < grades.length; i++) _HierarchyLevel(grade: grades[i], data: data, widthFactor: 1 - (i * .055).clamp(0, .38), selected: selectedId == admId(grades[i]), top: i == 0, onTap: () => onSelect(admId(grades[i])))]));
}

class _HierarchyLevel extends StatelessWidget {
  final Map<String, dynamic> grade;
  final _GradeData data;
  final double widthFactor;
  final bool selected, top;
  final VoidCallback onTap;
  const _HierarchyLevel({required this.grade, required this.data, required this.widthFactor, required this.selected, required this.top, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = top ? const Color(0xFFD4A017) : AdmTokens.primary;
    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? color : color.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: selected ? 1 : .18)),
              ),
              child: Row(children: [
                Icon(top ? Icons.workspace_premium_rounded : Icons.shield_outlined, size: 18, color: selected ? Colors.white : color),
                const SizedBox(width: 7),
                Expanded(child: Text(grade['nombre']?.toString() ?? 'Grado', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? Colors.white : AdmTokens.grey800))),
                Text('${data.countFor(grade)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? Colors.white : color)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeBottomStats extends StatelessWidget {
  final int total, active, personnel, mostCount; final String mostAssigned;
  const _GradeBottomStats({required this.total, required this.active, required this.personnel, required this.mostAssigned, required this.mostCount});
  @override Widget build(BuildContext context) { final now = DateTime.now(); final stats = [(Icons.donut_large_rounded, 'Cobertura', total == 0 ? '0 %' : '${((active / total) * 100).round()} %', 'Grados activos'), (Icons.groups_outlined, 'Funcionarios', '$personnel', 'Asignados'), (Icons.trending_up_rounded, 'Mayor personal', mostAssigned, '$mostCount funcionarios'), (Icons.update_rounded, 'Última actualización', '${now.day}/${now.month}/${now.year}', '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}')]; return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AdmTokens.grey100)), child: LayoutBuilder(builder: (_, c) { final count = c.maxWidth >= 900 ? 4 : 2; final width = (c.maxWidth - ((count - 1) * 14)) / count; return Wrap(spacing: 14, runSpacing: 14, children: [for (final s in stats) SizedBox(width: width, child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: AdmTokens.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(11)), child: Icon(s.$1, color: AdmTokens.primary, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.$2, style: const TextStyle(fontSize: 10, color: AdmTokens.grey500)), Text(s.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), Text(s.$4, style: const TextStyle(fontSize: 10, color: AdmTokens.grey500))]))]))]); })); }
}

class _GradoDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  const _GradoDialog({this.item});
  @override
  State<_GradoDialog> createState() => _GradoDialogState();
}

class _GradoDialogState extends State<_GradoDialog> {
  late final nombre = TextEditingController(text: _s('nombre'));
  @override
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Nuevo Grado' : 'Editar Grado',
        children: [
          admField(nombre, 'Nombre'),
        ],
        onSave: () => Navigator.pop(context, {
          'nombre': nombre.text.trim(),
        }),
      );
  String _s(String key) => widget.item?[key]?.toString() ?? '';
}
