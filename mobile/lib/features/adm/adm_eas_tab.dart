import 'dart:async';

import 'package:flutter/material.dart';

import 'adm_crud_tab.dart';
import 'adm_design_tokens.dart';
import 'adm_export.dart';
import 'adm_helpers.dart';
import 'adm_lazy_tab.dart';
import 'adm_widgets.dart';

class EasTab extends AdmCrudTab {
  final int tabIndex;
  const EasTab({super.key, required super.api, this.tabIndex = 0});

  @override
  State<AdmCrudTab> createState() => _EasState();
}

class _EasState extends State<AdmCrudTab> with AdmLazyTabMixin<AdmCrudTab> {
  int _page = 1;
  int _pageSize = 10;
  String _search = '';
  String _district = 'Todos';
  String _status = 'Todos';
  String _sort = 'Código A-Z';
  String _coverage = 'Todos';
  bool _refreshing = false;
  Timer? _debounce;
  late Future<_EasDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value(const _EasDashboardData(eas: [], assignments: []));
    initLazy((widget as EasTab).tabIndex, _load);
  }

  Future<void> _load() async {
    final results = await Future.wait([widget.api.getEasList(), widget.api.getAsignacionesList()]);
    if (!mounted) return;
    setState(() {
      _future = Future.value(_EasDashboardData(eas: results[0], assignments: results[1]));
      _refreshing = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() { _refreshing = true; });
    _load().then((_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos actualizados correctamente.')));
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _refreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No fue posible actualizar la información.')));
    });
  }

  void _onPageChanged(int page) {
    setState(() { _page = page; });
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() { _search = value.trim(); _page = 1; });
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_EasDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const _EasDashboardData(eas: [], assignments: []);
          final districts = data.eas.map((e) => e['distrito']?.toString() ?? '').where((e) => e.isNotEmpty).toSet().toList()..sort();
          final filtered = data.eas.where((e) => _matches(e, data)).toList()..sort((a, b) => _compare(a, b, data));
          final pages = (filtered.length / _pageSize).ceil().clamp(1, 999999);
          final safePage = _page.clamp(1, pages);
          final visible = filtered.skip((safePage - 1) * _pageSize).take(_pageSize).toList();
          final active = data.eas.where(admIsActive).length;
          final percent = data.eas.isEmpty ? 0 : ((active / data.eas.length) * 100).round();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(color: AdmTokens.primary.withValues(alpha: .09), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.shield_outlined, color: AdmTokens.primary)), const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('EAS', style: AdmTokens.h1), Text('Estaciones de Acción Segura disponibles para servicios.', style: AdmTokens.subtitle)])),
                OutlinedButton.icon(onPressed: _refreshing ? null : _reload, icon: _refreshing ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded, size: 17), label: const Text('Actualizar')), const SizedBox(width: 8),
                PopupMenuButton<String>(onSelected: (type) => _export(type, filtered, data), itemBuilder: (_) => const [PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')), PopupMenuItem(value: 'excel', child: Text('Exportar Excel')), PopupMenuItem(value: 'csv', child: Text('Exportar CSV'))], child: const _EasHeaderButton(icon: Icons.download_outlined, label: 'Exportar')), const SizedBox(width: 8),
                FilledButton.icon(onPressed: () => _edit(null), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Nueva EAS')),
              ]),
              const SizedBox(height: 22),
              AdminSummaryRow(cards: [
                AdminSummaryCardData(icon: Icons.apartment_rounded, value: '${data.eas.length}', label: 'Estaciones registradas', color: AdmTokens.primary),
                AdminSummaryCardData(icon: Icons.shield_outlined, value: '$active ($percent %)', label: 'En funcionamiento', color: AdmTokens.success),
                AdminSummaryCardData(icon: Icons.location_on_outlined, value: '${districts.length}', label: 'Distritos operativos', color: const Color(0xFFF97316)),
                AdminSummaryCardData(icon: Icons.hub_outlined, value: '${data.assignments.length}', label: 'Asignaciones asociadas', color: const Color(0xFF7C3AED)),
              ]),
              const SizedBox(height: 18),
              _EasToolbar(search: _onSearch, district: _district, status: _status, sort: _sort, coverage: _coverage, districts: districts, onDistrict: (v) => setState(() { _district = v; _page = 1; }), onStatus: (v) => setState(() { _status = v; _page = 1; }), onSort: (v) => setState(() { _sort = v; _page = 1; }), onCoverage: (v) => setState(() { _coverage = v; _page = 1; }), onAdvanced: _showAdvancedFilters),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _EasSkeleton()
              else
                LayoutBuilder(builder: (context, constraints) {
                  final table = _EasTable(items: visible, data: data, onView: (e) => _showDetails(e, data), onServices: (e) => _showAssignments(e, data), onEdit: _edit, onToggle: _toggle, onDelete: _deleteEas);
                  final side = _EasSidePanel(data: data, onSelect: (code) => setState(() { _search = code; _page = 1; }), onOpen: _showOperationalDetail);
                  if (constraints.maxWidth < 1250) return Column(children: [table, const SizedBox(height: 16), side]);
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 72, child: table), const SizedBox(width: 16), Expanded(flex: 28, child: side)]);
                }),
              const SizedBox(height: 14),
              _EasFooter(page: safePage, totalPages: pages, total: filtered.length, visible: visible.length, pageSize: _pageSize, onPage: _onPageChanged, onPageSize: (v) => setState(() { _pageSize = v; _page = 1; })),
            ]),
          );
        },
      );

  bool _matches(Map<String, dynamic> eas, _EasDashboardData data) {
    final text = '${eas['codigo']} ${eas['nombre']} ${eas['distrito']} ${eas['direccion']}'.toLowerCase();
    if (_search.isNotEmpty && !text.contains(_search.toLowerCase())) return false;
    if (_district != 'Todos' && eas['distrito']?.toString() != _district) return false;
    if (_status == 'Activo' && !admIsActive(eas)) return false;
    if (_status == 'Inactivo' && admIsActive(eas)) return false;
    if (_coverage != 'Todos' && data.coverageFor(eas) != _coverage) return false;
    return true;
  }

  int _compare(Map<String, dynamic> a, Map<String, dynamic> b, _EasDashboardData data) {
    String value(Map<String, dynamic> e) => _sort.contains('Nombre') ? e['nombre']?.toString() ?? '' : _sort.contains('servicios') ? data.assignmentsFor(e).length.toString().padLeft(8, '0') : e['codigo']?.toString() ?? '';
    final result = value(a).toLowerCase().compareTo(value(b).toLowerCase());
    return _sort.contains('Z-A') || _sort.startsWith('Mayor') ? -result : result;
  }
  Future<void> _export(String type, List<Map<String, dynamic>> items, _EasDashboardData data) async {
    if (type == 'pdf') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La exportación PDF requiere un generador PDF que aún no está disponible en la plataforma.')));
      return;
    }
    final rows = <String>['Código,Nombre,Distrito,Ubicación,Estado,Asignaciones'];
    for (final eas in items) {
      String q(Object? value) => '"${value?.toString().replaceAll('"', '""') ?? ''}"';
      rows.add('${q(eas['codigo'])},${q(eas['nombre'])},${q(eas['distrito'])},${q(eas['direccion'])},${admIsActive(eas) ? 'Activo' : 'Inactivo'},${data.assignmentsFor(eas).length}');
    }
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:T]'), '').split('.').first;
    final extension = type == 'excel' ? 'xls' : 'csv';
    final path = await exportAdminCsv(rows.join('\n'), 'EAS_SIGOGCAM_$stamp.$extension');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exportación generada en $path')));
  }

  Future<void> _showAdvancedFilters() => showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Filtros avanzados'), content: const SizedBox(width: 440, child: Text('Los filtros disponibles actualmente son distrito, estado, cobertura y ordenamiento. Los filtros de responsable, fechas y personal se habilitarán cuando esos datos estén expuestos por la API.')), actions: [TextButton(onPressed: () { setState(() { _district = 'Todos'; _status = 'Todos'; _coverage = 'Todos'; _page = 1; }); Navigator.pop(context); }, child: const Text('Limpiar filtros')), FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Aplicar'))]));

  Future<void> _showDetails(Map<String, dynamic> eas, _EasDashboardData data) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text('${eas['codigo']} — ${eas['nombre']}'), content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [_detail('Distrito', eas['distrito']), _detail('Ubicación', eas['direccion']), _detail('Estado', admIsActive(eas) ? 'Activo' : 'Inactivo'), _detail('Responsable', 'No disponible en la API'), _detail('Personal asignado', 'No disponible en la API'), _detail('Asignaciones', data.assignmentsFor(eas).length)])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))]));

  Widget _detail(String label, Object? value) => Padding(padding: const EdgeInsets.only(bottom: 11), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), Expanded(child: Text(value?.toString() ?? '—'))]));

  Future<void> _showAssignments(Map<String, dynamic> eas, _EasDashboardData data) => showDialog<void>(context: context, builder: (_) { final items = data.assignmentsFor(eas); return AlertDialog(title: Text('Asignaciones — ${eas['codigo']}'), content: SizedBox(width: 560, child: items.isEmpty ? const Text('No existen asignaciones relacionadas con esta EAS.') : ListView(shrinkWrap: true, children: [for (final item in items) ListTile(leading: const Icon(Icons.assignment_outlined), title: Text(item['movil']?.toString() ?? item['eas']?.toString() ?? 'Asignación'), subtitle: Text(item['observacion']?.toString() ?? 'Sin detalle'))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))]); });

  Future<void> _showOperationalDetail(String title, _EasDashboardData data) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(title), content: SizedBox(width: 620, child: ListView(shrinkWrap: true, children: [for (final eas in data.eas) ListTile(leading: const Icon(Icons.apartment_outlined), title: Text('${eas['codigo']} — ${eas['nombre']}'), subtitle: Text('${eas['distrito'] ?? 'Sin distrito'} · ${data.assignmentsFor(eas).length} asignaciones'))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))]));

  Future<void> _deleteEas(Map<String, dynamic> item) => _confirmDelete(item, 'EAS ${item['nombre']}', () => widget.api.deleteEas(admId(item)));

  Future<void> _edit(Map<String, dynamic>? item) async {
    final catalogs = await CatalogCache.instance.getOrLoad(widget.api);
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EasDialog(item: item, catalogs: catalogs),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      item == null
          ? await widget.api.createEas(data)
          : await widget.api.updateEas(admId(item), data);
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await admSafeRun(context, () async {
      await widget.api.setEasActivo(admId(item), !admIsActive(item));
      _reload();
    });
  }

  Future<void> _confirmDelete(
      Map<String, dynamic> item, String label, Future<void> Function() deleteFn) async {
    final ok = await admConfirm(context, 'Confirmar', '¿Eliminar $label?');
    if (ok != true) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      await deleteFn();
      _reload();
    });
  }
}

class _EasDashboardData {
  final List<Map<String, dynamic>> eas;
  final List<Map<String, dynamic>> assignments;
  const _EasDashboardData({required this.eas, required this.assignments});
  List<Map<String, dynamic>> assignmentsFor(Map<String, dynamic> station) {
    final id = admId(station);
    final code = station['codigo']?.toString().toLowerCase();
    return assignments.where((a) => int.tryParse(a['eas_id']?.toString() ?? '') == id || a['eas_codigo']?.toString().toLowerCase() == code).toList();
  }
  String coverageFor(Map<String, dynamic> station) {
    final count = assignmentsFor(station).length;
    if (count >= 5) return 'Alta';
    if (count >= 2) return 'Media';
    return 'Baja';
  }
}

class _EasHeaderButton extends StatelessWidget {
  final IconData icon; final String label;
  const _EasHeaderButton({required this.icon, required this.label});
  @override Widget build(BuildContext context) => Container(height: 46, padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AdmTokens.grey200), borderRadius: BorderRadius.circular(11)), child: Row(children: [Icon(icon, size: 17, color: AdmTokens.primary), const SizedBox(width: 7), Text(label, style: const TextStyle(fontWeight: FontWeight.w600))]));
}

class _EasToolbar extends StatelessWidget {
  final ValueChanged<String> search;
  final String district, status, sort, coverage;
  final List<String> districts;
  final ValueChanged<String> onDistrict, onStatus, onSort, onCoverage;
  final VoidCallback onAdvanced;
  const _EasToolbar({required this.search, required this.district, required this.status, required this.sort, required this.coverage, required this.districts, required this.onDistrict, required this.onStatus, required this.onSort, required this.onCoverage, required this.onAdvanced});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AdmTokens.grey100)), child: LayoutBuilder(builder: (_, c) {
    final filters = [
      _EasSelect(label: 'Distrito', value: district, values: ['Todos', ...districts], onChanged: onDistrict),
      _EasSelect(label: 'Estado', value: status, values: const ['Todos', 'Activo', 'Inactivo'], onChanged: onStatus),
      _EasSelect(label: 'Ordenar por', value: sort, values: const ['Código A-Z', 'Código Z-A', 'Nombre A-Z', 'Nombre Z-A', 'Mayor cantidad de servicios', 'Menor cantidad de servicios'], onChanged: onSort),
      _EasSelect(label: 'Cobertura', value: coverage, values: const ['Todos', 'Alta', 'Media', 'Baja'], onChanged: onCoverage),
    ];
    if (c.maxWidth < 1050) return Column(children: [AdminSearchBar(onChanged: search, hintText: 'Buscar EAS por código, nombre o distrito...'), const SizedBox(height: 9), Wrap(spacing: 8, runSpacing: 8, children: [for (final f in filters) SizedBox(width: 210, child: f), OutlinedButton.icon(onPressed: onAdvanced, icon: const Icon(Icons.filter_alt_outlined), label: const Text('Filtros'))])]);
    return Row(children: [Expanded(flex: 2, child: AdminSearchBar(onChanged: search, hintText: 'Buscar EAS por código, nombre o distrito...')), const SizedBox(width: 8), ...filters.map((f) => Expanded(child: Padding(padding: const EdgeInsets.only(left: 7), child: f))), const SizedBox(width: 8), OutlinedButton.icon(onPressed: onAdvanced, icon: const Icon(Icons.filter_alt_outlined, size: 17), label: const Text('Filtros'))]);
  }));
}

class _EasSelect extends StatelessWidget {
  final String label, value; final List<String> values; final ValueChanged<String> onChanged;
  const _EasSelect({required this.label, required this.value, required this.values, required this.onChanged});
  @override Widget build(BuildContext context) => Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 11), decoration: BoxDecoration(color: const Color(0xFFFAFCFF), border: Border.all(color: AdmTokens.grey200), borderRadius: BorderRadius.circular(11)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: values.contains(value) ? value : values.first, items: [for (final item in values) DropdownMenuItem(value: item, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 9, color: AdmTokens.grey500)), Text(item, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]))], onChanged: (v) { if (v != null) onChanged(v); })));
}

class _EasTable extends StatelessWidget {
  final List<Map<String, dynamic>> items; final _EasDashboardData data;
  final ValueChanged<Map<String, dynamic>> onView, onServices, onEdit, onToggle, onDelete;
  const _EasTable({required this.items, required this.data, required this.onView, required this.onServices, required this.onEdit, required this.onToggle, required this.onDelete});
  @override Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color(0x120F172A), blurRadius: 20, offset: Offset(0, 5))]), clipBehavior: Clip.antiAlias, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
    headingRowHeight: 54, dataRowMinHeight: 74, dataRowMaxHeight: 82, horizontalMargin: 16, columnSpacing: 18,
    headingRowColor: WidgetStateProperty.all(const Color(0xFF0D3F8A)), dataRowColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.hovered) ? const Color(0xFFF3F7FC) : Colors.white),
    columns: const [DataColumn(label: _EasHead('EAS')), DataColumn(label: _EasHead('Distrito')), DataColumn(label: _EasHead('Ubicación')), DataColumn(label: _EasHead('Estado')), DataColumn(label: _EasHead('Servicios')), DataColumn(label: _EasHead('Acciones'))],
    rows: items.isEmpty ? [DataRow(cells: [const DataCell(SizedBox(width: 230, child: Text('No se encontraron EAS con los filtros seleccionados.'))), for (var i=1;i<6;i++) const DataCell(SizedBox.shrink())])] : [for (final item in items) DataRow(cells: _cells(item))],
  )));
  List<DataCell> _cells(Map<String, dynamic> item) { final id=admId(item); final color=_easColors[id.abs()%_easColors.length]; final count=data.assignmentsFor(item).length; return [
    DataCell(SizedBox(width: 220, child: Row(children: [Container(width: 4, height: 52, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 9), CircleAvatar(radius: 22, backgroundColor: color.withValues(alpha:.12), child: Icon(Icons.apartment_outlined,color:color)), const SizedBox(width:9), Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item['codigo']?.toString()??'—',style:const TextStyle(color:AdmTokens.primary,fontWeight:FontWeight.w800)),Text(item['nombre']?.toString()??'EAS',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w700)),const Text('Código interno',style:TextStyle(fontSize:9,color:AdmTokens.grey500))]))]))),
    DataCell(SizedBox(width:135,child:Row(children:[const Icon(Icons.location_on_outlined,size:16,color:AdmTokens.primary),const SizedBox(width:5),Expanded(child:Text(item['distrito']?.toString()??'Sin distrito'))]))),
    DataCell(Tooltip(message:item['direccion']?.toString()??'',child:SizedBox(width:210,child:Text(item['direccion']?.toString()??'—',maxLines:2,overflow:TextOverflow.ellipsis)))),
    DataCell(AdmStateChip(active:admIsActive(item))),
    DataCell(SizedBox(width:85,child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('$count',style:const TextStyle(fontWeight:FontWeight.w800)),InkWell(onTap:()=>onServices(item),child:const Text('Ver servicios',style:TextStyle(fontSize:10,color:AdmTokens.primary,fontWeight:FontWeight.w600)))]))),
    DataCell(Row(mainAxisSize:MainAxisSize.min,children:[_EasAction(icon:Icons.visibility_outlined,tooltip:'Ver',onTap:()=>onView(item)),const SizedBox(width:5),_EasAction(icon:Icons.edit_outlined,tooltip:'Editar',onTap:()=>onEdit(item)),PopupMenuButton<String>(tooltip:'Más opciones',icon:const Icon(Icons.more_vert_rounded,size:19),onSelected:(v){if(v=='toggle')onToggle(item);if(v=='services')onServices(item);if(v=='delete')onDelete(item);},itemBuilder:(_)=>[PopupMenuItem(value:'toggle',child:Text(admIsActive(item)?'Desactivar':'Activar')),const PopupMenuItem(value:'services',child:Text('Ver servicios')),const PopupMenuItem(value:'delete',child:Text('Eliminar',style:TextStyle(color:AdmTokens.error)))])]))
  ]; }
}

class _EasHead extends StatelessWidget{final String text;const _EasHead(this.text);@override Widget build(BuildContext context)=>Text(text,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700));}
class _EasAction extends StatelessWidget{final IconData icon;final String tooltip;final VoidCallback onTap;const _EasAction({required this.icon,required this.tooltip,required this.onTap});@override Widget build(BuildContext context)=>Tooltip(message:tooltip,child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(9),child:Container(width:34,height:34,decoration:BoxDecoration(color:const Color(0xFFF8FAFC),border:Border.all(color:AdmTokens.grey200),borderRadius:BorderRadius.circular(9)),child:Icon(icon,size:17,color:AdmTokens.primary))));}
const _easColors=[Color(0xFF2563EB),Color(0xFF22C55E),Color(0xFFF97316),Color(0xFF8B5CF6),Color(0xFF06B6D4),Color(0xFFEC4899)];

class _EasSidePanel extends StatelessWidget {
  final _EasDashboardData data; final ValueChanged<String> onSelect; final void Function(String,_EasDashboardData) onOpen;
  const _EasSidePanel({required this.data,required this.onSelect,required this.onOpen});
  @override Widget build(BuildContext context){final ranked=[...data.eas]..sort((a,b)=>data.assignmentsFor(b).length.compareTo(data.assignmentsFor(a).length));return Column(children:[
    _OperationalCard(title:'Personal operativo por EAS',child:Column(children:[SizedBox(height:110,child:CustomPaint(painter:_EmptyDonutPainter(),child:const Center(child:Text('0\nfuncionarios',textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.w800))))),const Text('La API actual no relaciona personal con EAS.',style:TextStyle(fontSize:10,color:AdmTokens.grey500)),TextButton(onPressed:()=>onOpen('Detalle de personal por EAS',data),child:const Text('Ver detalle completo'))])),
    const SizedBox(height:12),
    _OperationalCard(title:'Últimos EAS modificados',child:Column(children:[const Text('No hay fechas de actualización ni auditoría disponibles en la respuesta actual.',style:TextStyle(fontSize:11,color:AdmTokens.grey500)),TextButton(onPressed:()=>onOpen('Historial de EAS',data),child:const Text('Ver historial completo'))])),
    const SizedBox(height:12),
    _OperationalCard(title:'Cobertura de servicios por EAS',child:Column(children:[for(final eas in ranked.take(4)) ListTile(dense:true,contentPadding:EdgeInsets.zero,title:Text('${eas['codigo']} ${eas['nombre']}',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),trailing:Text('${data.assignmentsFor(eas).length}',style:const TextStyle(fontWeight:FontWeight.w800))),TextButton(onPressed:()=>onOpen('Cobertura completa de servicios',data),child:const Text('Ver todos los servicios'))])),
    const SizedBox(height:12),
    _OperationalCard(title:'EAS con menor dotación de personal',child:Column(children:[const Text('Sin datos de dotación: Personal no contiene una relación EAS en la API disponible.',style:TextStyle(fontSize:11,color:AdmTokens.grey500)),TextButton(onPressed:()=>onOpen('Dotación completa por EAS',data),child:const Text('Ver todas las EAS'))])),
  ]);}
}

class _OperationalCard extends StatelessWidget{final String title;final Widget child;const _OperationalCard({required this.title,required this.child});@override Widget build(BuildContext context)=>Container(width:double.infinity,padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:AdmTokens.grey100),boxShadow:const[BoxShadow(color:Color(0x0D0F172A),blurRadius:16,offset:Offset(0,4))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:13)),const SizedBox(height:10),child]));}

class _EmptyDonutPainter extends CustomPainter{@override void paint(Canvas canvas,Size size){final center=Offset(size.width/2,size.height/2);canvas.drawCircle(center,42,Paint()..color=const Color(0xFFE5EAF0)..style=PaintingStyle.stroke..strokeWidth=14);}@override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;}

class _EasFooter extends StatelessWidget{final int page,totalPages,total,visible,pageSize;final ValueChanged<int> onPage,onPageSize;const _EasFooter({required this.page,required this.totalPages,required this.total,required this.visible,required this.pageSize,required this.onPage,required this.onPageSize});@override Widget build(BuildContext context){final start=total==0?0:((page-1)*pageSize)+1;final end=total==0?0:(start+visible-1).clamp(0,total);return Wrap(alignment:WrapAlignment.spaceBetween,crossAxisAlignment:WrapCrossAlignment.center,spacing:14,children:[Text('Mostrando $start a $end de $total EAS',style:const TextStyle(fontSize:12,color:AdmTokens.grey500)),Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:page>1?()=>onPage(1):null,icon:const Icon(Icons.first_page)),IconButton(onPressed:page>1?()=>onPage(page-1):null,icon:const Icon(Icons.chevron_left)),Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:AdmTokens.primary,borderRadius:BorderRadius.circular(9)),child:Text('$page',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700))),IconButton(onPressed:page<totalPages?()=>onPage(page+1):null,icon:const Icon(Icons.chevron_right)),IconButton(onPressed:page<totalPages?()=>onPage(totalPages):null,icon:const Icon(Icons.last_page)),DropdownButton<int>(value:pageSize,underline:const SizedBox.shrink(),items:const[DropdownMenuItem(value:10,child:Text('10 por página')),DropdownMenuItem(value:20,child:Text('20 por página')),DropdownMenuItem(value:50,child:Text('50 por página')),DropdownMenuItem(value:100,child:Text('100 por página'))],onChanged:(v){if(v!=null)onPageSize(v);})])]);}}

class _EasSkeleton extends StatelessWidget{const _EasSkeleton();@override Widget build(BuildContext context)=>Column(children:[for(var i=0;i<6;i++)Container(height:68,margin:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(color:const Color(0xFFF1F5F9),borderRadius:BorderRadius.circular(12)))]);}

abstract class _BaseCatalogDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Map<String, List<Map<String, dynamic>>> catalogs;
  const _BaseCatalogDialog({this.item, required this.catalogs});
}

class _EasDialog extends _BaseCatalogDialog {
  const _EasDialog({super.item, required super.catalogs});
  @override
  State<_EasDialog> createState() => _EasDialogState();
}

class _EasDialogState extends State<_EasDialog> {
  late final codigo = TextEditingController(text: _s('codigo'));
  late final nombre = TextEditingController(text: _s('nombre'));
  late final direccion = TextEditingController(text: _s('direccion'));
  int? distritoId;
  @override
  void initState() {
    super.initState();
    distritoId = _int('distrito_id');
  }

  @override
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Nueva EAS' : 'Editar EAS',
        children: [
          admField(codigo, 'Código'),
          admField(nombre, 'Nombre'),
          admField(direccion, 'Dirección'),
          admDropdown('Distrito', widget.catalogs['DISTRITOS'], distritoId, (v) => setState(() => distritoId = v)),
        ],
        onSave: () => Navigator.pop(context, {
          'codigo': codigo.text.trim(),
          'nombre': nombre.text.trim(),
          'direccion': direccion.text.trim(),
          'distritoId': distritoId,
        }),
      );
  String _s(String key) => widget.item?[key]?.toString() ?? '';
  int? _int(String key) => int.tryParse(widget.item?[key]?.toString() ?? '');
}
