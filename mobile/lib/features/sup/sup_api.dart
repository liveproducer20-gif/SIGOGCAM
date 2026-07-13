import 'dart:convert';

import '../../core/api/api_client.dart';
import '../../core/file/file_pick_result.dart';
import 'sup_mdl.dart';

class SupportApi {
  final ApiClient _client;
  SupportApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<SupportPage> list({int page=1,int pageSize=20,String search='',String status='',String priority='',String module='',String user='',String area='',String since=''}) async {
    final query = <String,String>{'page':'$page','pageSize':'$pageSize'};
    if(search.trim().isNotEmpty) query['buscar']=search.trim();
    if(status.isNotEmpty) query['estado']=status;
    if(priority.isNotEmpty) query['prioridad']=priority;
    if(module.isNotEmpty) query['modulo']=module;
    if(user.isNotEmpty) query['usuario']=user;
    if(area.isNotEmpty) query['area']=area;
    if(since.isNotEmpty) query['desde']=since;
    final raw = await _client.getFull(Uri(path:'soporte',queryParameters:query).toString());
    return SupportPage(
      tickets: (raw['datos'] as List<dynamic>? ?? []).whereType<Map>().map((e)=>SupportTicket.fromJson(Map<String,dynamic>.from(e))).toList(),
      total: int.tryParse(raw['total']?.toString()??'')??0,
      page: int.tryParse(raw['page']?.toString()??'')??1,
      pageSize: int.tryParse(raw['pageSize']?.toString()??'')??pageSize,
    );
  }

  Future<SupportStats> stats() async => (await _client.get('soporte/estadisticas',(v)=>SupportStats.fromJson(Map<String,dynamic>.from(v as Map)))).datos!;
  Future<SupportDetail> detail(int id) async => (await _client.get('soporte/$id',(v)=>SupportDetail.fromJson(Map<String,dynamic>.from(v as Map)))).datos!;

  Future<void> create({required String title,required String module,required String description,String priority='Media',FilePickResult? image}) async {
    String? imagePath;
    if(image?.dataUrl != null){
      final value=image!.dataUrl!;
      final comma=value.indexOf(',');
      if(comma<0) throw Exception('No se pudo leer la imagen');
      final bytes=base64Decode(value.substring(comma+1));
      final uploaded=await _client.postBytes('soporte/imagenes',bytes,image.mimeType??'image/jpeg',(v)=>Map<String,dynamic>.from(v as Map));
      imagePath=uploaded.datos?['ruta']?.toString();
    }
    await _client.post('soporte',{'titulo':title,'modulo':module,'descripcion':description,'prioridad':priority,'imagen':imagePath},(_)=>true);
  }

  Future<void> update(int id,{String? status,String? priority,int? assignedTo,String? assignedName,bool assign=false}) async {
    final body=<String,dynamic>{};
    if(status!=null) body['estado']=status;
    if(priority!=null) body['prioridad']=priority;
    if(assign){body['asignadoA']=assignedTo;body['asignadoNombre']=assignedName;}
    await _client.put('soporte/$id',body,(_)=>true);
  }
  Future<void> comment(int id,String text,{bool internal=false}) async => _client.post('soporte/$id/comentarios',{'comentario':text,'esInterno':internal},(_)=>true);
  Stream<String> realtime() => _client.streamLines('soporte/stream');
}

