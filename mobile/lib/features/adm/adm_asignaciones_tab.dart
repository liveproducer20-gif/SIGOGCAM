import 'dart:async';

import 'package:flutter/material.dart';

import 'adm_api.dart';
import 'adm_crud_tab.dart';
import 'adm_design_tokens.dart';
import 'adm_export.dart';
import 'adm_helpers.dart';
import 'adm_lazy_tab.dart';
import 'adm_widgets.dart';

class AsignacionesTab extends AdmCrudTab {
  final int tabIndex;
  const AsignacionesTab({super.key, required super.api, this.tabIndex = 0});

  @override
  State<AdmCrudTab> createState() => _AsignacionState();
}

class _AsignacionState extends State<AdmCrudTab> with AdmLazyTabMixin<AdmCrudTab> {
  int _page = 1;
  int _pageSize = 10;
  String _search = '';
  String _eas = 'Todas';
  String _mobile = 'Todos';
  String _status = 'Todos';
  bool _refreshing = false;
  Timer? _debounce;
  late Future<_AssignmentData> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value(const _AssignmentData(assignments: [], eas: [], vehicles: []));
    initLazy((widget as AsignacionesTab).tabIndex, _load);
  }

  Future<void> _load() async {
    final result = await Future.wait([widget.api.getAsignacionesList(),widget.api.getEasList(),widget.api.getMovilesList()]);
    if (!mounted) return;
    setState(() {
      _future = Future.value(_AssignmentData(assignments:result[0],eas:result[1],vehicles:result[2]));
      _refreshing=false;
    });
  }

  @override void dispose(){_debounce?.cancel();super.dispose();}

  void _reload() {
    setState(()=>_refreshing=true);_load().then((_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Asignaciones actualizadas correctamente.')));}).catchError((_){if(mounted){setState(()=>_refreshing=false);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('No fue posible actualizar las asignaciones.')));}});
  }

  void _onPageChanged(int page) {
    setState(() { _page = page; });
  }

  void _onSearch(String value) {
    _debounce?.cancel();_debounce=Timer(const Duration(milliseconds:300),(){if(mounted)setState((){_search=value.trim();_page=1;});});
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_AssignmentData>(
        future: _future,
        builder:(context,snapshot){final data=snapshot.data??const _AssignmentData(assignments:[],eas:[],vehicles:[]);final filtered=data.assignments.where(_matches).toList()..sort((a,b)=>'${b['fecha_asignacion']}'.compareTo('${a['fecha_asignacion']}'));final pages=(filtered.length/_pageSize).ceil().clamp(1,999999),safePage=_page.clamp(1,pages);final visible=filtered.skip((safePage-1)*_pageSize).take(_pageSize).toList();final active=data.assignments.where(admIsActive).length,historical=data.assignments.where((a)=>!admIsActive(a)&&!_isCancelled(a)).length,cancelled=data.assignments.where(_isCancelled).length;return SingleChildScrollView(padding:const EdgeInsets.fromLTRB(28,8,28,28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Asignaciones',style:AdmTokens.h1),SizedBox(height:5),Text('Historial y gestión de asignaciones de móviles a Estaciones de Acción Segura.',style:AdmTokens.subtitle)])),OutlinedButton.icon(onPressed:_refreshing?null:_reload,icon:_refreshing?const SizedBox(width:15,height:15,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.refresh_rounded,size:17),label:const Text('Actualizar')),const SizedBox(width:8),PopupMenuButton<String>(onSelected:(t)=>_export(t,filtered),itemBuilder:(_)=>const[PopupMenuItem(value:'pdf',child:Text('Exportar PDF')),PopupMenuItem(value:'excel',child:Text('Exportar Excel')),PopupMenuItem(value:'csv',child:Text('Exportar CSV'))],child:const _AssignmentExportButton()),const SizedBox(width:8),FilledButton.icon(onPressed:()=>_edit(null),icon:const Icon(Icons.add_rounded,size:18),label:const Text('Nueva asignación'))]),
          const SizedBox(height:22),AdminSummaryRow(cards:[AdminSummaryCardData(icon:Icons.assignment_outlined,value:'${data.assignments.length}',label:'Registros en total',color:AdmTokens.primary),AdminSummaryCardData(icon:Icons.check_circle_outline,value:'$active',label:'Activas',color:AdmTokens.success),AdminSummaryCardData(icon:Icons.history_rounded,value:'$historical',label:'Históricas',color:const Color(0xFFF97316)),AdminSummaryCardData(icon:Icons.cancel_outlined,value:'$cancelled',label:'Canceladas',color:AdmTokens.error)]),const SizedBox(height:18),
          _AssignmentToolbar(onSearch:_onSearch,eas:_eas,mobile:_mobile,status:_status,easValues:data.eas.map((e)=>e['eas_codigo']?.toString()??e['codigo']?.toString()??'').where((e)=>e.isNotEmpty).toSet().toList(),mobileValues:data.vehicles.map((e)=>e['numero_movil']?.toString()??'').where((e)=>e.isNotEmpty).toSet().toList(),onEas:(v)=>setState((){_eas=v;_page=1;}),onMobile:(v)=>setState((){_mobile=v;_page=1;}),onStatus:(v)=>setState((){_status=v;_page=1;}),onAdvanced:_advancedFilters),const SizedBox(height:16),
          if(snapshot.connectionState==ConnectionState.waiting)const _AssignmentSkeleton()else LayoutBuilder(builder:(_,c){final table=_AssignmentTable(items:visible,data:data,onView:(a)=>_showDetail(a,data),onEdit:_edit,onDelete:_deleteAssignment);final side=_AssignmentSide(data:data,status:_status,eas:_eas,mobile:_mobile,onStatus:(v)=>setState((){_status=v;_page=1;}),onEas:(v)=>setState((){_eas=v;_page=1;}),onClear:()=>setState((){_eas='Todas';_mobile='Todos';_status='Todos';_search='';_page=1;}),onOpen:(title,items)=>_showList(title,items,data));if(c.maxWidth<1200)return Column(children:[table,const SizedBox(height:16),side]);return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:72,child:table),const SizedBox(width:16),Expanded(flex:28,child:side)]);}),const SizedBox(height:14),_AssignmentFooter(page:safePage,totalPages:pages,total:filtered.length,visible:visible.length,pageSize:_pageSize,onPage:_onPageChanged,onPageSize:(v)=>setState((){_pageSize=v;_page=1;}))
        ]));},
      );

  bool _isCancelled(Map<String,dynamic>a)=>a['estado']?.toString().toUpperCase().contains('CANCEL')==true;
  bool _matches(Map<String,dynamic>a){final text='${a['eas_codigo']} ${a['eas']} ${a['numero_movil']} ${a['placa']} ${a['estado']}'.toLowerCase();if(_search.isNotEmpty&&!text.contains(_search.toLowerCase()))return false;if(_eas!='Todas'&&a['eas_codigo']?.toString()!=_eas)return false;if(_mobile!='Todos'&&a['numero_movil']?.toString()!=_mobile)return false;if(_status=='Activa'&&!admIsActive(a))return false;if(_status=='Histórica'&&(admIsActive(a)||_isCancelled(a)))return false;if(_status=='Cancelada'&&!_isCancelled(a))return false;return true;}

  Future<void> _export(String type,List<Map<String,dynamic>> items)async{if(type=='pdf'){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('La exportación PDF aún no dispone de generador en la plataforma.')));return;}final rows=<String>['EAS,Móvil,Placa,Fecha,Estado,Observación'];for(final a in items){rows.add('"${a['eas_codigo']} ${a['eas']}","${a['numero_movil']}","${a['placa']}","${a['fecha_asignacion']}","${a['estado']}","${a['observacion']??''}"');}final ext=type=='excel'?'xls':'csv';final path=await exportAdminCsv(rows.join('\n'),'ASIGNACIONES_SIGOGCAM_${DateTime.now().millisecondsSinceEpoch}.$ext');if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Exportación generada en $path')));}
  Future<void> _advancedFilters()=>showDialog<void>(context:context,builder:(_)=>AlertDialog(title:const Text('Filtros avanzados'),content:const SizedBox(width:440,child:Text('La API disponible permite filtrar por EAS, móvil, estado y fecha de asignación. Usuario asignador, distrito y tipo no forman parte de la respuesta actual.')),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Aplicar filtros'))]));
  Future<void> _showDetail(Map<String,dynamic>a,_AssignmentData data)=>showDialog<void>(context:context,builder:(_)=>AlertDialog(title:Text('${a['numero_movil']} → ${a['eas_codigo']}'),content:SizedBox(width:500,child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('EAS: ${a['eas_codigo']} ${a['eas']}'),Text('Móvil: ${a['numero_movil']} · ${a['placa']}'),Text('Fecha de asignación: ${_date(a['fecha_asignacion'])}'),Text('Fecha de finalización: —'),Text('Tiempo asignado: ${data.duration(a)}'),Text('Estado: ${a['estado']}'),const Text('Asignado por: No disponible en la API'),Text('Observación: ${a['observacion']??'—'}')])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cerrar'))]));
  Future<void> _showList(String title,List<Map<String,dynamic>>items,_AssignmentData data)=>showDialog<void>(context:context,builder:(_)=>AlertDialog(title:Text(title),content:SizedBox(width:700,child:items.isEmpty?const Text('No existen asignaciones para mostrar.'):ListView(shrinkWrap:true,children:[for(final a in items)ListTile(leading:const Icon(Icons.swap_horiz_rounded),title:Text('${a['numero_movil']} → ${a['eas_codigo']}'),subtitle:Text('${_date(a['fecha_asignacion'])} · ${a['estado']} · ${data.duration(a)}'))])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cerrar'))]));
  String _date(Object?v){final s=v?.toString()??'';return s.length>=16?s.substring(0,16).replaceFirst('T',' '):s;}
  Future<void> _deleteAssignment(Map<String,dynamic>item)=>_confirmDelete(item,'asignación',()=>widget.api.deleteAsignacion(admId(item)));

  Future<void> _edit(Map<String, dynamic>? item) async {
    final loaded = await Future.wait([
      widget.api.getEasList(),
      widget.api.getMovilesList(),
      widget.api.getCatalogo('ESTADOS_ASIGNACION_MOVIL', limit: 200),
      widget.api.getAsignacionesList(),
    ]);
    final eas = loaded[0] as List<Map<String, dynamic>>;
    final moviles = loaded[1] as List<Map<String, dynamic>>;
    final estados = (loaded[2] as AdmPaginatedResult).datos;
    final asignaciones = loaded[3] as List<Map<String, dynamic>>;
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AsignacionDialog(
        item: item,
        eas: eas,
        moviles: moviles,
        estados: estados,
        asignaciones: asignaciones,
      ),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      item == null
          ? await widget.api.createAsignacion(data)
          : await widget.api.updateAsignacion(admId(item), data);
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

class _AssignmentData{
  final List<Map<String,dynamic>>assignments,eas,vehicles;const _AssignmentData({required this.assignments,required this.eas,required this.vehicles});
  String duration(Map<String,dynamic>a){final start=DateTime.tryParse(a['fecha_asignacion']?.toString()??'');if(start==null)return'—';final d=DateTime.now().difference(start);if(d.inDays>=60)return'${(d.inDays/30).floor()} meses';if(d.inDays>0)return'${d.inDays} días';return'${d.inHours.clamp(0,9999)} horas';}
  List<Map<String,dynamic>>forEas(String code)=>assignments.where((a)=>a['eas_codigo']?.toString()==code).toList();
}
class _AssignmentExportButton extends StatelessWidget{const _AssignmentExportButton();@override Widget build(BuildContext context)=>Container(height:46,padding:const EdgeInsets.symmetric(horizontal:15),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:AdmTokens.grey200),borderRadius:BorderRadius.circular(11)),child:const Row(children:[Icon(Icons.download_outlined,size:17,color:AdmTokens.primary),SizedBox(width:7),Text('Exportar',style:TextStyle(fontWeight:FontWeight.w600))]));}
class _AssignmentToolbar extends StatelessWidget{final ValueChanged<String>onSearch,onEas,onMobile,onStatus;final String eas,mobile,status;final List<String>easValues,mobileValues;final VoidCallback onAdvanced;const _AssignmentToolbar({required this.onSearch,required this.eas,required this.mobile,required this.status,required this.easValues,required this.mobileValues,required this.onEas,required this.onMobile,required this.onStatus,required this.onAdvanced});@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:AdmTokens.grey100)),child:LayoutBuilder(builder:(_,c){final filters=[_AssignmentSelect(label:'EAS',value:eas,values:['Todas',...easValues],onChanged:onEas),_AssignmentSelect(label:'Móvil',value:mobile,values:['Todos',...mobileValues],onChanged:onMobile),_AssignmentSelect(label:'Estado',value:status,values:const['Todos','Activa','Histórica','Cancelada'],onChanged:onStatus)];if(c.maxWidth<900)return Column(children:[AdminSearchBar(onChanged:onSearch,hintText:'Buscar asignación...'),const SizedBox(height:9),Wrap(spacing:8,runSpacing:8,children:[for(final f in filters)SizedBox(width:210,child:f),OutlinedButton.icon(onPressed:onAdvanced,icon:const Icon(Icons.filter_alt_outlined),label:const Text('Filtros'))])]);return Row(children:[Expanded(flex:2,child:AdminSearchBar(onChanged:onSearch,hintText:'Buscar asignación...')),const SizedBox(width:8),...filters.map((f)=>Expanded(child:Padding(padding:const EdgeInsets.only(left:7),child:f))),const SizedBox(width:8),OutlinedButton.icon(onPressed:onAdvanced,icon:const Icon(Icons.filter_alt_outlined,size:17),label:const Text('Filtros'))]);}));}
class _AssignmentSelect extends StatelessWidget{final String label,value;final List<String>values;final ValueChanged<String>onChanged;const _AssignmentSelect({required this.label,required this.value,required this.values,required this.onChanged});@override Widget build(BuildContext context)=>Container(height:52,padding:const EdgeInsets.symmetric(horizontal:11),decoration:BoxDecoration(color:const Color(0xFFFAFCFF),border:Border.all(color:AdmTokens.grey200),borderRadius:BorderRadius.circular(11)),child:DropdownButtonHideUnderline(child:DropdownButton<String>(isExpanded:true,value:values.contains(value)?value:values.first,items:[for(final item in values)DropdownMenuItem(value:item,child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:9,color:AdmTokens.grey500)),Text(item,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600))]))],onChanged:(v){if(v!=null)onChanged(v);})));}

class _AssignmentTable extends StatelessWidget{final List<Map<String,dynamic>>items;final _AssignmentData data;final ValueChanged<Map<String,dynamic>>onView,onEdit,onDelete;const _AssignmentTable({required this.items,required this.data,required this.onView,required this.onEdit,required this.onDelete});@override Widget build(BuildContext context)=>Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),boxShadow:const[BoxShadow(color:Color(0x120F172A),blurRadius:20,offset:Offset(0,5))]),clipBehavior:Clip.antiAlias,child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(headingRowHeight:54,dataRowMinHeight:72,dataRowMaxHeight:82,horizontalMargin:15,columnSpacing:20,headingRowColor:WidgetStateProperty.all(const Color(0xFF0D3F8A)),dataRowColor:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.hovered)?const Color(0xFFF3F7FC):Colors.white),columns:const[DataColumn(label:_AssignmentHead('EAS')),DataColumn(label:_AssignmentHead('Móvil')),DataColumn(label:_AssignmentHead('Fecha asignación')),DataColumn(label:_AssignmentHead('Fecha finalización')),DataColumn(label:_AssignmentHead('Tiempo asignado')),DataColumn(label:_AssignmentHead('Estado')),DataColumn(label:_AssignmentHead('Asignado por')),DataColumn(label:_AssignmentHead('Acciones'))],rows:items.isEmpty?[DataRow(cells:[const DataCell(SizedBox(width:220,child:Text('No se encontraron asignaciones.'))),for(var i=1;i<8;i++)const DataCell(SizedBox.shrink())])]:[for(final a in items)DataRow(cells:_cells(a))])));
List<DataCell>_cells(Map<String,dynamic>a)=>[DataCell(SizedBox(width:160,child:Row(children:[const Icon(Icons.location_on_outlined,color:AdmTokens.primary),const SizedBox(width:7),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a['eas_codigo']?.toString()??'EAS',style:const TextStyle(fontWeight:FontWeight.w800)),Text(a['eas']?.toString()??'',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10))]))]))),DataCell(SizedBox(width:155,child:Row(children:[const CircleAvatar(radius:18,child:Icon(Icons.directions_car_outlined,size:18)),const SizedBox(width:7),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a['numero_movil']?.toString()??'Móvil',style:const TextStyle(fontWeight:FontWeight.w800)),Text(a['placa']?.toString()??'',style:const TextStyle(fontSize:10))]))]))),DataCell(Text(_date(a['fecha_asignacion']))),const DataCell(Text('—')),DataCell(Text(data.duration(a),style:const TextStyle(fontWeight:FontWeight.w700))),DataCell(AdmStateChip(active:admIsActive(a),label:a['estado']?.toString())),const DataCell(Text('No disponible',style:TextStyle(fontSize:10,color:AdmTokens.grey500))),DataCell(Row(mainAxisSize:MainAxisSize.min,children:[_AssignmentAction(icon:Icons.visibility_outlined,tooltip:'Ver',onTap:()=>onView(a)),const SizedBox(width:5),_AssignmentAction(icon:Icons.edit_outlined,tooltip:'Editar',onTap:()=>onEdit(a)),PopupMenuButton<String>(tooltip:'Más opciones',icon:const Icon(Icons.more_vert_rounded,size:19),onSelected:(v){if(v=='delete')onDelete(a);if(v=='view')onView(a);},itemBuilder:(_)=>const[PopupMenuItem(value:'view',child:Text('Ver historial')),PopupMenuItem(value:'delete',child:Text('Eliminar',style:TextStyle(color:AdmTokens.error)))])]))];
static String _date(Object?v){final s=v?.toString()??'';return s.length>=16?s.substring(0,16).replaceFirst('T',' '):s;}}
class _AssignmentHead extends StatelessWidget{final String text;const _AssignmentHead(this.text);@override Widget build(BuildContext context)=>Text(text,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:10));}
class _AssignmentAction extends StatelessWidget{final IconData icon;final String tooltip;final VoidCallback onTap;const _AssignmentAction({required this.icon,required this.tooltip,required this.onTap});@override Widget build(BuildContext context)=>Tooltip(message:tooltip,child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(8),child:Container(width:33,height:33,decoration:BoxDecoration(color:const Color(0xFFF8FAFC),border:Border.all(color:AdmTokens.grey200),borderRadius:BorderRadius.circular(8)),child:Icon(icon,size:16,color:AdmTokens.primary))));}

class _AssignmentSide extends StatelessWidget{final _AssignmentData data;final String status,eas,mobile;final ValueChanged<String>onStatus,onEas;final VoidCallback onClear;final void Function(String,List<Map<String,dynamic>>)onOpen;const _AssignmentSide({required this.data,required this.status,required this.eas,required this.mobile,required this.onStatus,required this.onEas,required this.onClear,required this.onOpen});@override Widget build(BuildContext context){final active=data.assignments.where(admIsActive).length,cancelled=data.assignments.where((a)=>a['estado']?.toString().toUpperCase().contains('CANCEL')==true).length,historical=data.assignments.length-active-cancelled;final recent=[...data.assignments]..sort((a,b)=>'${b['fecha_asignacion']}'.compareTo('${a['fecha_asignacion']}'));final codes=data.assignments.map((a)=>a['eas_codigo']?.toString()??'').where((e)=>e.isNotEmpty).toSet();final ranking=[for(final code in codes)(code,data.forEas(code).where(admIsActive).length)]..sort((a,b)=>b.$2.compareTo(a.$2));return Column(children:[_AssignmentWidget(title:'Resumen por estado',child:Column(children:[SizedBox(height:110,child:CustomPaint(painter:_AssignmentDonutPainter(active:active,historical:historical,cancelled:cancelled),child:Center(child:Text('${data.assignments.length}\nTotal',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w800))))),Wrap(spacing:5,children:[TextButton(onPressed:()=>onStatus('Activa'),child:Text('Activas $active')),TextButton(onPressed:()=>onStatus('Histórica'),child:Text('Históricas $historical')),TextButton(onPressed:()=>onStatus('Cancelada'),child:Text('Canceladas $cancelled'))]),TextButton(onPressed:()=>onOpen('Resumen completo',data.assignments),child:const Text('Ver detalle completo'))])),const SizedBox(height:12),_AssignmentWidget(title:'Asignaciones recientes',child:Column(children:[for(final a in recent.take(5))ListTile(dense:true,contentPadding:EdgeInsets.zero,title:Text(a['numero_movil']?.toString()??'Móvil',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),subtitle:Text('→ ${a['eas_codigo']} · ${_AssignmentTable._date(a['fecha_asignacion'])}',style:const TextStyle(fontSize:9))),TextButton(onPressed:()=>onOpen('Historial cronológico',recent),child:const Text('Ver todas las recientes'))])),const SizedBox(height:12),_AssignmentWidget(title:'Filtros activos',child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Wrap(spacing:6,runSpacing:6,children:[if(status!='Todos')InputChip(label:Text('Estado: $status'),onDeleted:()=>onStatus('Todos')),if(eas!='Todas')InputChip(label:Text('EAS: $eas'),onDeleted:()=>onEas('Todas')),if(mobile!='Todos')InputChip(label:Text('Móvil: $mobile'))]),TextButton(onPressed:onClear,child:const Text('Limpiar filtros'))])),const SizedBox(height:12),_AssignmentWidget(title:'EAS con mayor cantidad de móviles',child:Column(children:[for(var i=0;i<ranking.take(3).length;i++)ListTile(dense:true,contentPadding:EdgeInsets.zero,leading:Text(['🥇','🥈','🥉'][i]),title:Text(ranking[i].$1,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),trailing:Text('${ranking[i].$2} móviles')),TextButton(onPressed:()=>onOpen('Distribución completa',data.assignments),child:const Text('Ver distribución completa'))]))]);}}
class _AssignmentWidget extends StatelessWidget{final String title;final Widget child;const _AssignmentWidget({required this.title,required this.child});@override Widget build(BuildContext context)=>Container(width:double.infinity,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:AdmTokens.grey100),boxShadow:const[BoxShadow(color:Color(0x0D0F172A),blurRadius:16,offset:Offset(0,4))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:12)),const SizedBox(height:8),child]));}
class _AssignmentDonutPainter extends CustomPainter{final int active,historical,cancelled;const _AssignmentDonutPainter({required this.active,required this.historical,required this.cancelled});@override void paint(Canvas canvas,Size size){final total=active+historical+cancelled;final center=Offset(size.width/2,size.height/2),rect=Rect.fromCircle(center:center,radius:42),paint=Paint()..style=PaintingStyle.stroke..strokeWidth=14;double start=-1.57;if(total==0){canvas.drawArc(rect,0,6.28,false,paint..color=AdmTokens.grey200);return;}for(final part in [(active,Colors.green),(historical,Colors.orange),(cancelled,Colors.red)]){final sweep=6.28*part.$1/total;canvas.drawArc(rect,start,sweep,false,paint..color=part.$2);start+=sweep;}}@override bool shouldRepaint(covariant _AssignmentDonutPainter old)=>old.active!=active||old.historical!=historical||old.cancelled!=cancelled;}
class _AssignmentFooter extends StatelessWidget{final int page,totalPages,total,visible,pageSize;final ValueChanged<int>onPage,onPageSize;const _AssignmentFooter({required this.page,required this.totalPages,required this.total,required this.visible,required this.pageSize,required this.onPage,required this.onPageSize});@override Widget build(BuildContext context){final start=total==0?0:(page-1)*pageSize+1,end=total==0?0:(start+visible-1).clamp(0,total);return Wrap(alignment:WrapAlignment.spaceBetween,crossAxisAlignment:WrapCrossAlignment.center,children:[Text('Mostrando $start a $end de $total asignaciones',style:const TextStyle(fontSize:12,color:AdmTokens.grey500)),Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:page>1?()=>onPage(1):null,icon:const Icon(Icons.first_page)),IconButton(onPressed:page>1?()=>onPage(page-1):null,icon:const Icon(Icons.chevron_left)),Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:AdmTokens.primary,borderRadius:BorderRadius.circular(9)),child:Text('$page',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700))),IconButton(onPressed:page<totalPages?()=>onPage(page+1):null,icon:const Icon(Icons.chevron_right)),IconButton(onPressed:page<totalPages?()=>onPage(totalPages):null,icon:const Icon(Icons.last_page)),DropdownButton<int>(value:pageSize,underline:const SizedBox.shrink(),items:const[DropdownMenuItem(value:10,child:Text('10 por página')),DropdownMenuItem(value:20,child:Text('20 por página')),DropdownMenuItem(value:50,child:Text('50 por página')),DropdownMenuItem(value:100,child:Text('100 por página'))],onChanged:(v){if(v!=null)onPageSize(v);})])]);}}
class _AssignmentSkeleton extends StatelessWidget{const _AssignmentSkeleton();@override Widget build(BuildContext context)=>Column(children:[for(var i=0;i<6;i++)Container(height:68,margin:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(color:const Color(0xFFF1F5F9),borderRadius:BorderRadius.circular(12)))]);}

class _AsignacionDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final List<Map<String, dynamic>> eas;
  final List<Map<String, dynamic>> moviles;
  final List<Map<String, dynamic>> estados;
  final List<Map<String, dynamic>> asignaciones;
  const _AsignacionDialog(
      {this.item, required this.eas, required this.moviles, required this.estados, required this.asignaciones});
  @override
  State<_AsignacionDialog> createState() => _AsignacionDialogState();
}

class _AsignacionDialogState extends State<_AsignacionDialog> {
  late final fecha = TextEditingController(
      text: admFormatDate(widget.item?['fecha_asignacion']?.toString() ??
          DateTime.now().toIso8601String()));
  late final obs = TextEditingController(text: widget.item?['observacion']?.toString() ?? '');
  int? easId;
  int? movilId;
  int? estadoId;
  @override
  void initState() {
    super.initState();
    easId = int.tryParse(widget.item?['eas_id']?.toString() ?? '');
    movilId = int.tryParse(widget.item?['movil_id']?.toString() ?? '');
    estadoId = int.tryParse(widget.item?['estado_asignacion_id']?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Nueva asignacion' : 'Editar asignacion',
        onSave: _save,
        children: [
          admDropdown('EAS', widget.eas, easId, (v) => setState(() => easId = v)),
          admDropdown('Movil', widget.moviles, movilId, (v) => setState(() => movilId = v),
              labelBuilder: (m) => '${m['numero_movil']} ${m['placa'] ?? ''}'),
          admField(fecha, 'Fecha asignación (yyyy-mm-dd)'),
          admDropdown('Estado', widget.estados, estadoId, (v) => setState(() => estadoId = v)),
          admField(obs, 'Observación'),
        ],
      );

  void _save() {
    final selectedState = widget.estados.cast<Map<String, dynamic>?>().firstWhere(
      (state) => admId(state!) == estadoId,
      orElse: () => null,
    );
    final isActive = selectedState?['codigo']?.toString().toUpperCase() == 'ACTIVA';
    final hasActive = widget.asignaciones.any((assignment) {
      final sameMobile = int.tryParse(assignment['movil_id']?.toString() ?? '') == movilId;
      final otherRecord = widget.item == null || admId(assignment) != admId(widget.item!);
      return sameMobile && otherRecord && admIsActive(assignment);
    });
    if (isActive && hasActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este móvil ya posee una asignación activa. Finalícela antes de crear otra.')),
      );
      return;
    }
    Navigator.pop(context, {
          'easId': easId,
          'movilId': movilId,
          'fechaAsignacion': fecha.text.trim(),
          'estadoAsignacionId': estadoId,
          'observacion': obs.text.trim(),
        });
  }
}
