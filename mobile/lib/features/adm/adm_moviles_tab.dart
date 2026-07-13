import 'dart:async';

import 'package:flutter/material.dart';

import 'adm_api.dart';
import 'adm_crud_tab.dart';
import 'adm_design_tokens.dart';
import 'adm_export.dart';
import 'adm_helpers.dart';
import 'adm_lazy_tab.dart';
import 'adm_widgets.dart';

class MovilesTab extends AdmCrudTab {
  final int tabIndex;
  const MovilesTab({super.key, required super.api, this.tabIndex = 0});

  @override
  State<AdmCrudTab> createState() => _MovilState();
}

class _MovilState extends State<AdmCrudTab> with AdmLazyTabMixin<AdmCrudTab> {
  int _page = 1;
  int _pageSize = 10;
  String _search = '';
  String _type = 'Todos';
  String _status = 'Todos';
  String _eas = 'Todas';
  String _alert = 'Todas';
  bool _refreshing = false;
  Timer? _debounce;
  late Future<_VehicleData> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value(const _VehicleData(vehicles: [], assignments: []));
    initLazy((widget as MovilesTab).tabIndex, _load);
  }

  Future<void> _load() async {
    final result = await Future.wait([widget.api.getMovilesList(), widget.api.getAsignacionesList()]);
    if (!mounted) return;
    setState(() {
      _future = Future.value(_VehicleData(vehicles: result[0], assignments: result[1]));
      _refreshing = false;
    });
  }

  @override void dispose(){_debounce?.cancel();super.dispose();}

  void _reload() {
    setState(() => _refreshing = true);
    _load().then((_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Datos actualizados correctamente.')));}).catchError((_){if(mounted){setState(()=>_refreshing=false);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('No se pudieron cargar los móviles.')));}});
  }

  void _onPageChanged(int page) {
    setState(() { _page = page; });
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce=Timer(const Duration(milliseconds:300),(){if(mounted)setState((){_search=value.trim();_page=1;});});
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_VehicleData>(
        future: _future,
        builder:(context,snapshot){
          final data=snapshot.data??const _VehicleData(vehicles:[],assignments:[]);
          final types=data.vehicles.map((e)=>e['tipo']?.toString()??'').where((e)=>e.isNotEmpty).toSet().toList()..sort();
          final states=data.vehicles.map((e)=>e['estado']?.toString()??'').where((e)=>e.isNotEmpty).toSet().toList()..sort();
          final easCodes=data.assignments.map((e)=>e['eas_codigo']?.toString()??'').where((e)=>e.isNotEmpty).toSet().toList()..sort();
          final filtered=data.vehicles.where((v)=>_matches(v,data)).toList();
          final pages=(filtered.length/_pageSize).ceil().clamp(1,999999);final safePage=_page.clamp(1,pages);final visible=filtered.skip((safePage-1)*_pageSize).take(_pageSize).toList();
          final operational=data.vehicles.where((v)=>_state(v).contains('OPERAT')).length;
          final maintenance=data.vehicles.where((v)=>_state(v).contains('MANTEN')).length;
          final offline=data.vehicles.where((v)=>_state(v).contains('FUERA')).length;
          return SingleChildScrollView(padding:const EdgeInsets.fromLTRB(28,8,28,28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Móviles',style:AdmTokens.h1),SizedBox(height:5),Text('Unidades, kilometraje y mantenimiento preventivo.',style:AdmTokens.subtitle)])),OutlinedButton.icon(onPressed:_refreshing?null:_reload,icon:_refreshing?const SizedBox(width:15,height:15,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.refresh_rounded,size:17),label:const Text('Actualizar')),const SizedBox(width:8),PopupMenuButton<String>(onSelected:(t)=>_export(t,filtered,data),itemBuilder:(_)=>const[PopupMenuItem(value:'pdf',child:Text('Exportar PDF')),PopupMenuItem(value:'excel',child:Text('Exportar Excel')),PopupMenuItem(value:'csv',child:Text('Exportar CSV'))],child:const _VehicleHeaderButton()),const SizedBox(width:8),FilledButton.icon(onPressed:()=>_edit(null),icon:const Icon(Icons.add_rounded,size:18),label:const Text('Nuevo móvil'))]),
            const SizedBox(height:22),AdminSummaryRow(cards:[AdminSummaryCardData(icon:Icons.directions_car_outlined,value:'${data.vehicles.length}',label:'Unidades registradas',color:AdmTokens.primary),AdminSummaryCardData(icon:Icons.build_circle_outlined,value:'$operational',label:'Operativos',color:AdmTokens.success),AdminSummaryCardData(icon:Icons.warning_amber_rounded,value:'$maintenance',label:'En mantenimiento',color:const Color(0xFFF97316)),AdminSummaryCardData(icon:Icons.remove_circle_outline,value:'$offline',label:'Fuera de servicio',color:AdmTokens.error)]),
            const SizedBox(height:18),_VehicleToolbar(onSearch:_onSearch,type:_type,status:_status,eas:_eas,alert:_alert,types:types,states:states,easCodes:easCodes,onType:(v)=>setState((){_type=v;_page=1;}),onStatus:(v)=>setState((){_status=v;_page=1;}),onEas:(v)=>setState((){_eas=v;_page=1;}),onAlert:(v)=>setState((){_alert=v;_page=1;})),const SizedBox(height:16),
            if(snapshot.connectionState==ConnectionState.waiting)const _VehicleSkeleton()else LayoutBuilder(builder:(_,c){final table=_VehicleTable(items:visible,data:data,onView:(v)=>_showVehicle(v,data),onEdit:_edit,onHistory:_showHistory,onToggle:_toggle,onDelete:_deleteVehicle);final side=_VehicleSidePanel(data:data,onOpen:(title,items)=>_showVehicleList(title,items,data),onFilter:(a)=>setState((){_alert=a;_page=1;}));if(c.maxWidth<1250)return Column(children:[table,const SizedBox(height:16),side]);return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:76,child:table),const SizedBox(width:16),Expanded(flex:24,child:side)]);}),
            const SizedBox(height:14),_VehicleFooter(page:safePage,totalPages:pages,total:filtered.length,visible:visible.length,pageSize:_pageSize,onPage:_onPageChanged,onPageSize:(v)=>setState((){_pageSize=v;_page=1;})),
          ]));
        },
      );

  String _state(Map<String,dynamic> v)=>v['estado']?.toString().toUpperCase()??'';
  bool _matches(Map<String,dynamic> v,_VehicleData data){final assignment=data.assignmentFor(v);final text='${v['numero_movil']} ${v['placa']} ${v['tipo']} ${v['estado']} ${assignment?['eas_codigo']??''} ${assignment?['eas']??''}'.toLowerCase();if(_search.isNotEmpty&&!text.contains(_search.toLowerCase()))return false;if(_type!='Todos'&&v['tipo']?.toString()!=_type)return false;if(_status!='Todos'&&v['estado']?.toString()!=_status)return false;if(_eas!='Todas'&&assignment?['eas_codigo']?.toString()!=_eas)return false;if(_alert!='Todas'&&data.alertLabel(v)!=_alert)return false;return true;}

  Future<void> _export(String type,List<Map<String,dynamic>> items,_VehicleData data)async{if(type=='pdf'){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('La exportación PDF aún no dispone de generador en la plataforma.')));return;}final rows=<String>['Móvil,Placa,Tipo,Kilometraje,Estado,EAS,Alerta'];for(final v in items){final a=data.assignmentFor(v);rows.add('"${v['numero_movil']}","${v['placa']}","${v['tipo']}",${v['kilometraje_actual']??0},"${v['estado']}","${a?['eas_codigo']??'Sin asignar'}",${data.alertLabel(v)}');}final ext=type=='excel'?'xls':'csv';final path=await exportAdminCsv(rows.join('\n'),'MOVILES_SIGOGCAM_${DateTime.now().millisecondsSinceEpoch}.$ext');if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Exportación generada en $path')));}

  Future<void> _showVehicle(Map<String,dynamic> vehicle,_VehicleData data)=>showDialog<void>(context:context,builder:(_)=>AlertDialog(title:Text('${vehicle['numero_movil']} — ${vehicle['placa']}'),content:SizedBox(width:500,child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Tipo: ${vehicle['tipo']??'—'}'),Text('Kilometraje actual: ${_formatKm(vehicle['kilometraje_actual'])}'),Text('Próximo mantenimiento: ${_formatKm(vehicle['proximo_mantenimiento'])}'),Text('Estado: ${vehicle['estado']??'—'}'),Text('EAS: ${data.assignmentFor(vehicle)?['eas_codigo']??'Sin asignar'}'),Text('Alerta: ${data.alertLabel(vehicle)}')])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cerrar'))]));
  Future<void> _showVehicleList(String title,List<Map<String,dynamic>> items,_VehicleData data)=>showDialog<void>(context:context,builder:(_)=>AlertDialog(title:Text(title),content:SizedBox(width:760,child:items.isEmpty?const Text('No existen registros para esta categoría.'):ListView(shrinkWrap:true,children:[for(final v in items)ListTile(leading:Icon(data.isOverdue(v)?Icons.warning_rounded:Icons.directions_car_outlined,color:data.isOverdue(v)?Colors.red:AdmTokens.primary),title:Text('${v['numero_movil']} — ${v['placa']}'),subtitle:Text('${v['tipo']} · ${_formatKm(v['kilometraje_actual'])} · ${data.assignmentFor(v)?['eas_codigo']??'Sin EAS'}'),trailing:Text(data.alertLabel(v)))])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cerrar'))]));
  String _formatKm(Object? value){final n=int.tryParse(value?.toString()??'')??0;return '${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'),(m)=>'.')} km';}
  Future<void> _deleteVehicle(Map<String,dynamic> item)=>_confirmDelete(item,'móvil ${item['numero_movil']}',()=>widget.api.deleteMovil(admId(item)));

  Future<void> _edit(Map<String, dynamic>? item) async {
    final catalogs = await CatalogCache.instance.getOrLoad(widget.api);
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MovilDialog(item: item, catalogs: catalogs),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      item == null
          ? await widget.api.createMovil(data)
          : await widget.api.updateMovil(admId(item), data);
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await admSafeRun(context, () async {
      await widget.api.setMovilActivo(admId(item), !admIsActive(item));
      _reload();
    });
  }

  Future<void> _showHistory(Map<String, dynamic> item) async {
    final id = admId(item);
    final catalogs = await CatalogCache.instance.getOrLoad(widget.api);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => _MantenimientoDialog(
        movilId: id,
        movilLabel: '${item['numero_movil']} ${item['placa'] ?? ''}'.trim(),
        api: widget.api,
        catalogs: catalogs,
        onChanged: _reload,
      ),
    );
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

class _VehicleData{
  static const highMileageThreshold=80000;
  final List<Map<String,dynamic>> vehicles,assignments;
  const _VehicleData({required this.vehicles,required this.assignments});
  Map<String,dynamic>? assignmentFor(Map<String,dynamic> v){final id=admId(v);for(final a in assignments){if(int.tryParse(a['movil_id']?.toString()??'')==id&&admIsActive(a))return a;}return null;}
  int remaining(Map<String,dynamic> v)=>(int.tryParse(v['kilometros_restantes']?.toString()??'')??((int.tryParse(v['proximo_mantenimiento']?.toString()??'')??0)-(int.tryParse(v['kilometraje_actual']?.toString()??'')??0)));
  bool isOverdue(Map<String,dynamic> v)=>remaining(v)<=0||v['estado_mantenimiento']?.toString()=='KILOMETRAJE_EXCEDIDO';
  bool isUpcoming(Map<String,dynamic> v)=>!isOverdue(v)&&v['estado_mantenimiento']?.toString()=='EN_ESPERA';
  bool isHighMileage(Map<String,dynamic> v)=>(int.tryParse(v['kilometraje_actual']?.toString()??'')??0)>=highMileageThreshold;
  String alertLabel(Map<String,dynamic> v){if(isOverdue(v))return 'Mantenimiento vencido';if(isUpcoming(v))return 'Próximo a mantenimiento';if(isHighMileage(v))return 'Kilometraje alto';return 'Sin alerta';}
}

class _VehicleHeaderButton extends StatelessWidget{const _VehicleHeaderButton();@override Widget build(BuildContext context)=>Container(height:46,padding:const EdgeInsets.symmetric(horizontal:15),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:AdmTokens.grey200),borderRadius:BorderRadius.circular(11)),child:const Row(children:[Icon(Icons.download_outlined,size:17,color:AdmTokens.primary),SizedBox(width:7),Text('Exportar',style:TextStyle(fontWeight:FontWeight.w600))]));}

class _VehicleToolbar extends StatelessWidget{
  final ValueChanged<String> onSearch,onType,onStatus,onEas,onAlert;final String type,status,eas,alert;final List<String> types,states,easCodes;
  const _VehicleToolbar({required this.onSearch,required this.type,required this.status,required this.eas,required this.alert,required this.types,required this.states,required this.easCodes,required this.onType,required this.onStatus,required this.onEas,required this.onAlert});
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:AdmTokens.grey100)),child:LayoutBuilder(builder:(_,c){final filters=[_VehicleSelect(label:'Tipo',value:type,values:['Todos',...types],onChanged:onType),_VehicleSelect(label:'Estado',value:status,values:['Todos',...states],onChanged:onStatus),_VehicleSelect(label:'EAS asignada',value:eas,values:['Todas',...easCodes],onChanged:onEas),_VehicleSelect(label:'Alerta',value:alert,values:const['Todas','Mantenimiento vencido','Próximo a mantenimiento','Sin alerta','Kilometraje alto'],onChanged:onAlert)];if(c.maxWidth<1050)return Column(children:[AdminSearchBar(onChanged:onSearch,hintText:'Buscar por móvil, tipo, placa o estado...'),const SizedBox(height:9),Wrap(spacing:8,runSpacing:8,children:[for(final f in filters)SizedBox(width:210,child:f)])]);return Row(children:[Expanded(flex:2,child:AdminSearchBar(onChanged:onSearch,hintText:'Buscar por móvil, tipo, placa o estado...')),const SizedBox(width:8),...filters.map((f)=>Expanded(child:Padding(padding:const EdgeInsets.only(left:7),child:f)))]);}));
}
class _VehicleSelect extends StatelessWidget{final String label,value;final List<String> values;final ValueChanged<String> onChanged;const _VehicleSelect({required this.label,required this.value,required this.values,required this.onChanged});@override Widget build(BuildContext context)=>Container(height:52,padding:const EdgeInsets.symmetric(horizontal:11),decoration:BoxDecoration(color:const Color(0xFFFAFCFF),border:Border.all(color:AdmTokens.grey200),borderRadius:BorderRadius.circular(11)),child:DropdownButtonHideUnderline(child:DropdownButton<String>(isExpanded:true,value:values.contains(value)?value:values.first,items:[for(final item in values)DropdownMenuItem(value:item,child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:9,color:AdmTokens.grey500)),Text(item,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600))]))],onChanged:(v){if(v!=null)onChanged(v);})));}

class _VehicleTable extends StatelessWidget{
  final List<Map<String,dynamic>> items;final _VehicleData data;final ValueChanged<Map<String,dynamic>> onView,onEdit,onHistory,onToggle,onDelete;
  const _VehicleTable({required this.items,required this.data,required this.onView,required this.onEdit,required this.onHistory,required this.onToggle,required this.onDelete});
  @override Widget build(BuildContext context)=>Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),boxShadow:const[BoxShadow(color:Color(0x120F172A),blurRadius:20,offset:Offset(0,5))]),clipBehavior:Clip.antiAlias,child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(headingRowHeight:54,dataRowMinHeight:76,dataRowMaxHeight:84,horizontalMargin:14,columnSpacing:16,headingRowColor:WidgetStateProperty.all(const Color(0xFF0D3F8A)),dataRowColor:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.hovered)?const Color(0xFFF3F7FC):Colors.white),columns:const[DataColumn(label:_VehicleHead('Móvil')),DataColumn(label:_VehicleHead('Tipo')),DataColumn(label:_VehicleHead('Placa')),DataColumn(label:_VehicleHead('Km actual')),DataColumn(label:_VehicleHead('Próx. mant.')),DataColumn(label:_VehicleHead('EAS asignada')),DataColumn(label:_VehicleHead('Estado')),DataColumn(label:_VehicleHead('Alertas')),DataColumn(label:_VehicleHead('Acciones'))],rows:items.isEmpty?[DataRow(cells:[const DataCell(SizedBox(width:230,child:Text('No se encontraron resultados con los filtros seleccionados.'))),for(var i=1;i<9;i++)const DataCell(SizedBox.shrink())])]:[for(final v in items)DataRow(cells:_cells(v))])));
  List<DataCell> _cells(Map<String,dynamic> v){final a=data.assignmentFor(v);final overdue=data.isOverdue(v);final upcoming=data.isUpcoming(v);return[
    DataCell(SizedBox(width:145,child:Row(children:[Container(width:4,height:50,color:overdue?Colors.red:(upcoming?Colors.orange:AdmTokens.primary)),const SizedBox(width:8),CircleAvatar(backgroundColor:AdmTokens.primary.withValues(alpha:.1),child:Icon(v['tipo']?.toString().toLowerCase().contains('moto')==true?Icons.two_wheeler:Icons.directions_car_outlined,color:AdmTokens.primary)),const SizedBox(width:8),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(v['numero_movil']?.toString()??'Móvil',style:const TextStyle(fontWeight:FontWeight.w800)),const Text('Patrullero',style:TextStyle(fontSize:9,color:AdmTokens.grey500))]))]))),
    DataCell(SizedBox(width:95,child:Text(v['tipo']?.toString()??'—'))),DataCell(Text(v['placa']?.toString()??'—',style:const TextStyle(fontWeight:FontWeight.w700))),DataCell(Text(_km(v['kilometraje_actual']))),
    DataCell(SizedBox(width:105,child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(_km(v['proximo_mantenimiento']),style:TextStyle(fontSize:11,color:overdue?Colors.red:AdmTokens.grey800)),Text(overdue?'Vencido':(upcoming?'En ${_km(data.remaining(v))}':'Sin alerta'),style:TextStyle(fontSize:9,fontWeight:FontWeight.w700,color:overdue?Colors.red:(upcoming?Colors.orange:AdmTokens.grey500)))]))),
    DataCell(SizedBox(width:105,child:a==null?const Text('Sin asignar',style:TextStyle(color:Colors.orange,fontWeight:FontWeight.w700)):Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a['eas_codigo']?.toString()??'EAS',style:const TextStyle(fontWeight:FontWeight.w800)),Text(a['eas']?.toString()??'',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:9))]))),
    DataCell(_VehicleStatus(text:v['estado']?.toString()??'Sin estado')),DataCell(_AlertBell(data:data,vehicle:v,onTap:()=>onHistory(v))),
    DataCell(Row(mainAxisSize:MainAxisSize.min,children:[_VehicleAction(icon:Icons.visibility_outlined,tooltip:'Ver',onTap:()=>onView(v)),const SizedBox(width:4),_VehicleAction(icon:Icons.edit_outlined,tooltip:'Editar',onTap:()=>onEdit(v)),PopupMenuButton<String>(tooltip:'Más opciones',icon:const Icon(Icons.more_horiz_rounded,size:19),onSelected:(x){if(x=='history')onHistory(v);if(x=='toggle')onToggle(v);if(x=='delete')onDelete(v);},itemBuilder:(_)=>[const PopupMenuItem(value:'history',child:Text('Mantenimiento e historial')),PopupMenuItem(value:'toggle',child:Text(admIsActive(v)?'Desactivar':'Activar')),const PopupMenuItem(value:'delete',child:Text('Eliminar',style:TextStyle(color:AdmTokens.error)))])]))
  ];}
  static String _km(Object? value){final n=int.tryParse(value?.toString()??'')??0;return '${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'),(m)=>'.')} km';}
}
class _VehicleHead extends StatelessWidget{final String text;const _VehicleHead(this.text);@override Widget build(BuildContext context)=>Text(text,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:11));}
class _VehicleAction extends StatelessWidget{final IconData icon;final String tooltip;final VoidCallback onTap;const _VehicleAction({required this.icon,required this.tooltip,required this.onTap});@override Widget build(BuildContext context)=>Tooltip(message:tooltip,child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(8),child:Container(width:32,height:32,decoration:BoxDecoration(color:const Color(0xFFF8FAFC),border:Border.all(color:AdmTokens.grey200),borderRadius:BorderRadius.circular(8)),child:Icon(icon,size:16,color:AdmTokens.primary))));}
class _VehicleStatus extends StatelessWidget{final String text;const _VehicleStatus({required this.text});@override Widget build(BuildContext context){final u=text.toUpperCase();final c=u.contains('FUERA')?Colors.red:(u.contains('MANTEN')?Colors.orange:Colors.green);return Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:c.withValues(alpha:.1),borderRadius:BorderRadius.circular(12)),child:Text('● $text',style:TextStyle(fontSize:9,fontWeight:FontWeight.w700,color:c)));}}
class _AlertBell extends StatelessWidget{final _VehicleData data;final Map<String,dynamic> vehicle;final VoidCallback onTap;const _AlertBell({required this.data,required this.vehicle,required this.onTap});@override Widget build(BuildContext context){final overdue=data.isOverdue(vehicle),upcoming=data.isUpcoming(vehicle);final c=overdue?Colors.red:(upcoming?Colors.orange:AdmTokens.grey300);return Tooltip(message:data.alertLabel(vehicle),child:IconButton(onPressed:onTap,icon:Icon(Icons.notifications_rounded,color:c,size:19)));}}

class _VehicleSidePanel extends StatelessWidget{
  final _VehicleData data;final void Function(String,List<Map<String,dynamic>>) onOpen;final ValueChanged<String> onFilter;
  const _VehicleSidePanel({required this.data,required this.onOpen,required this.onFilter});
  @override Widget build(BuildContext context){final risks=data.vehicles.where((v)=>data.isOverdue(v)||data.isUpcoming(v)).toList()..sort((a,b)=>data.remaining(a).compareTo(data.remaining(b)));final unassigned=data.vehicles.where((v)=>data.assignmentFor(v)==null).toList();final overdue=data.vehicles.where(data.isOverdue).toList(),upcoming=data.vehicles.where(data.isUpcoming).toList(),high=data.vehicles.where(data.isHighMileage).toList(),offline=data.vehicles.where((v)=>v['estado']?.toString().toUpperCase().contains('FUERA')==true).toList();return Column(children:[
    _VehicleWidget(title:'Móviles próximos a mantenimiento',child:Column(children:[if(risks.isEmpty)const Text('No existen móviles próximos a mantenimiento.',style:TextStyle(fontSize:10,color:AdmTokens.grey500))else ...[const Row(children:[Expanded(child:Text('Móvil',style:TextStyle(fontSize:9,fontWeight:FontWeight.w700))),Text('Km actual',style:TextStyle(fontSize:9,fontWeight:FontWeight.w700)),SizedBox(width:12),Text('Faltan',style:TextStyle(fontSize:9,fontWeight:FontWeight.w700))]),for(final v in risks.take(5))_MaintenanceAlertRow(vehicle:v,data:data)],TextButton(onPressed:()=>onOpen('Próximos mantenimientos',risks),child:const Text('Ver todos los próximos mantenimientos'))])),const SizedBox(height:12),
    _VehicleWidget(title:'Móviles sin EAS asignada',child:Column(children:[for(final v in unassigned.take(3))ListTile(dense:true,contentPadding:EdgeInsets.zero,leading:const Icon(Icons.directions_car_outlined,size:17),title:Text('${v['numero_movil']}',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),subtitle:Text(v['tipo']?.toString()??'',style:const TextStyle(fontSize:9)),trailing:const Text('Sin asignar',style:TextStyle(fontSize:9,color:Colors.orange))),TextButton(onPressed:()=>onOpen('Móviles sin EAS',unassigned),child:const Text('Ver todos'))])),const SizedBox(height:12),
    _VehicleWidget(title:'Alertas activas',child:Column(children:[_AlertSummary(label:'Mantenimientos vencidos',count:overdue.length,color:Colors.red,onTap:()=>onFilter('Mantenimiento vencido')),_AlertSummary(label:'Próximos a vencer',count:upcoming.length,color:Colors.orange,onTap:()=>onFilter('Próximo a mantenimiento')),_AlertSummary(label:'Kilometraje alto',count:high.length,color:Colors.blue,onTap:()=>onFilter('Kilometraje alto')),_AlertSummary(label:'Fuera de servicio',count:offline.length,color:Colors.red,onTap:()=>onOpen('Fuera de servicio',offline)),TextButton(onPressed:()=>onOpen('Todas las alertas',[...overdue,...upcoming,...high,...offline]),child:const Text('Ver todas las alertas'))]))
  ]);}
}
class _VehicleWidget extends StatelessWidget{final String title;final Widget child;const _VehicleWidget({required this.title,required this.child});@override Widget build(BuildContext context)=>Container(width:double.infinity,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:AdmTokens.grey100),boxShadow:const[BoxShadow(color:Color(0x0D0F172A),blurRadius:16,offset:Offset(0,4))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800)),const SizedBox(height:9),child]));}

class _MaintenanceAlertRow extends StatefulWidget{final Map<String,dynamic> vehicle;final _VehicleData data;const _MaintenanceAlertRow({required this.vehicle,required this.data});@override State<_MaintenanceAlertRow> createState()=>_MaintenanceAlertRowState();}
class _MaintenanceAlertRowState extends State<_MaintenanceAlertRow> with SingleTickerProviderStateMixin{late final AnimationController controller=AnimationController(vsync:this,duration:const Duration(milliseconds:1000));@override void didChangeDependencies(){super.didChangeDependencies();if(MediaQuery.disableAnimationsOf(context)){controller.stop();controller.value=1;}else if(!controller.isAnimating){controller.repeat(reverse:true);}}@override void dispose(){controller.dispose();super.dispose();}@override Widget build(BuildContext context){final overdue=widget.data.isOverdue(widget.vehicle);final c=overdue?Colors.red:Colors.orange;return FadeTransition(opacity:Tween(begin:.55,end:1.0).animate(controller),child:Container(margin:const EdgeInsets.only(top:6),padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:c.withValues(alpha:.07),borderRadius:BorderRadius.circular(8)),child:Row(children:[Icon(Icons.warning_rounded,size:15,color:c),const SizedBox(width:5),Expanded(child:Text(widget.vehicle['placa']?.toString()??widget.vehicle['numero_movil']?.toString()??'Móvil',style:const TextStyle(fontSize:9,fontWeight:FontWeight.w700))),Text(_VehicleTable._km(widget.vehicle['kilometraje_actual']),style:const TextStyle(fontSize:8)),const SizedBox(width:10),Text(_VehicleTable._km(widget.data.remaining(widget.vehicle)),style:TextStyle(fontSize:8,fontWeight:FontWeight.w800,color:c))])));}}
class _AlertSummary extends StatelessWidget{final String label;final int count;final Color color;final VoidCallback onTap;const _AlertSummary({required this.label,required this.count,required this.color,required this.onTap});@override Widget build(BuildContext context)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(8),child:Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(children:[Icon(Icons.warning_rounded,size:15,color:color),const SizedBox(width:7),Expanded(child:Text(label,style:const TextStyle(fontSize:10))),Text('$count',style:TextStyle(fontWeight:FontWeight.w800,color:color))])));}

class _VehicleFooter extends StatelessWidget{final int page,totalPages,total,visible,pageSize;final ValueChanged<int> onPage,onPageSize;const _VehicleFooter({required this.page,required this.totalPages,required this.total,required this.visible,required this.pageSize,required this.onPage,required this.onPageSize});@override Widget build(BuildContext context){final start=total==0?0:(page-1)*pageSize+1,end=total==0?0:(start+visible-1).clamp(0,total);return Wrap(alignment:WrapAlignment.spaceBetween,crossAxisAlignment:WrapCrossAlignment.center,children:[Text('Mostrando $start a $end de $total móviles',style:const TextStyle(fontSize:12,color:AdmTokens.grey500)),Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:page>1?()=>onPage(1):null,icon:const Icon(Icons.first_page)),IconButton(onPressed:page>1?()=>onPage(page-1):null,icon:const Icon(Icons.chevron_left)),Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:AdmTokens.primary,borderRadius:BorderRadius.circular(9)),child:Text('$page',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700))),IconButton(onPressed:page<totalPages?()=>onPage(page+1):null,icon:const Icon(Icons.chevron_right)),IconButton(onPressed:page<totalPages?()=>onPage(totalPages):null,icon:const Icon(Icons.last_page)),DropdownButton<int>(value:pageSize,underline:const SizedBox.shrink(),items:const[DropdownMenuItem(value:10,child:Text('10 por página')),DropdownMenuItem(value:20,child:Text('20 por página')),DropdownMenuItem(value:50,child:Text('50 por página')),DropdownMenuItem(value:100,child:Text('100 por página'))],onChanged:(v){if(v!=null)onPageSize(v);})])]);}}
class _VehicleSkeleton extends StatelessWidget{const _VehicleSkeleton();@override Widget build(BuildContext context)=>Column(children:[for(var i=0;i<6;i++)Container(height:68,margin:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(color:const Color(0xFFF1F5F9),borderRadius:BorderRadius.circular(12)))]);}

abstract class _BaseCatalogDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Map<String, List<Map<String, dynamic>>> catalogs;
  const _BaseCatalogDialog({this.item, required this.catalogs});
}

class _MovilDialog extends _BaseCatalogDialog {
  const _MovilDialog({super.item, required super.catalogs});
  @override
  State<_MovilDialog> createState() => _MovilDialogState();
}

class _MovilDialogState extends State<_MovilDialog> {
  late final numero = TextEditingController(text: _s('numero_movil'));
  late final placa = TextEditingController(text: _s('placa'));
  late final km = TextEditingController(text: _s('kilometraje_actual', fallback: '0'));
  late final kmMant = TextEditingController(text: _s('kilometraje_ultimo_mantenimiento', fallback: '0'));
  late final obs = TextEditingController(text: _s('observacion'));
  late final obsEstado = TextEditingController(text: _s('observacion_estado'));
  int? tipoId;
  int? estadoId;
  @override
  void initState() {
    super.initState();
    tipoId = _int('tipo_movil_id');
    estadoId = _int('estado_movil_id');
  }

  @override
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Nuevo movil' : 'Editar movil',
        children: [
          admField(numero, 'Número de móvil'),
          admField(placa, 'Placa'),
          admDropdown('Tipo', widget.catalogs['TIPOS_MOVIL'], tipoId, (v) => setState(() => tipoId = v)),
          admField(km, 'Kilometraje actual', number: true),
          admField(kmMant, 'Kilometraje último mantenimiento', number: true),
          admDropdown('Estado', widget.catalogs['ESTADOS_MOVIL'], estadoId, (v) => setState(() => estadoId = v)),
          admField(obsEstado, 'Observación del estado'),
          admField(obs, 'Observación general'),
        ],
        onSave: () => Navigator.pop(context, {
          'numeroMovil': numero.text.trim(),
          'placa': placa.text.trim(),
          'tipoMovilId': tipoId,
          'kilometrajeActual': int.tryParse(km.text) ?? 0,
          'kilometrajeUltimoMantenimiento': int.tryParse(kmMant.text) ?? 0,
          'estadoMovilId': estadoId,
          'observacion': obs.text.trim(),
          'observacionEstado': obsEstado.text.trim(),
        }),
      );
  String _s(String key, {String fallback = ''}) => widget.item?[key]?.toString() ?? fallback;
  int? _int(String key) => int.tryParse(widget.item?[key]?.toString() ?? '');
}

class _MantenimientoDialog extends StatefulWidget {
  final int movilId;
  final String movilLabel;
  final AdmApi api;
  final Map<String, List<Map<String, dynamic>>> catalogs;
  final VoidCallback onChanged;
  const _MantenimientoDialog({
    required this.movilId,
    required this.movilLabel,
    required this.api,
    required this.catalogs,
    required this.onChanged,
  });
  @override
  State<_MantenimientoDialog> createState() => _MantenimientoDialogState();
}

class _MantenimientoDialogState extends State<_MantenimientoDialog> {
  late Future<List<Map<String, dynamic>>> _mantenimientos;

  @override
  void initState() {
    super.initState();
    _mantenimientos = widget.api.getMantenimientos(widget.movilId);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Mantenimientos - ${widget.movilLabel}'),
        content: SizedBox(
          width: 600,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _mantenimientos,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final items = snap.data ?? [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Historial de mantenimiento',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _nuevo,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nuevo'),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Sin registros de mantenimiento'),
                    )
                  else
                    Flexible(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Km')),
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('Descripción')),
                          ],
                          rows: items.map((r) => DataRow(cells: [
                            DataCell(admText(r['fecha_mantenimiento']?.toString().substring(0, 10) ?? '')),
                            DataCell(admText(r['kilometraje']?.toString() ?? '')),
                            DataCell(admText(r['tipo_mantenimiento']?.toString())),
                            DataCell(admText(r['descripcion']?.toString())),
                          ])).toList(),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      );

  void _nuevo() async {
    final tipos = widget.catalogs['TIPOS_MANTENIMIENTO'] ?? [];
    final fechaCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final kmCtrl = TextEditingController(text: '0');
    final descCtrl = TextEditingController();
    int? tipoId;

    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar mantenimiento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fechaCtrl,
                decoration: const InputDecoration(labelText: 'Fecha (yyyy-mm-dd)'),
              ),
              TextField(
                controller: kmCtrl,
                decoration: const InputDecoration(labelText: 'Kilometraje'),
                keyboardType: TextInputType.number,
              ),
              if (tipos.isNotEmpty)
                admDropdown('Tipo mantenimiento', tipos, tipoId, (v) => tipoId = v, optional: true),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {
              'fechaMantenimiento': fechaCtrl.text.trim(),
              'kilometraje': int.tryParse(kmCtrl.text) ?? 0,
              'tipoMantenimientoId': tipoId,
              'descripcion': descCtrl.text.trim(),
            }),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      await widget.api.createMantenimiento(widget.movilId, data);
      setState(() {
        _mantenimientos = widget.api.getMantenimientos(widget.movilId);
      });
      widget.onChanged();
    });
  }
}
