class SupportTicket {
  final int id;
  final String code, title, description, userName, role, area, module;
  final String priority, status;
  final String? image, assignedName;
  final DateTime createdAt, updatedAt;

  const SupportTicket({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.userName,
    required this.role,
    required this.area,
    required this.module,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.image,
    this.assignedName,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
    code: json['codigo_alerta']?.toString() ?? '',
    title: json['titulo']?.toString() ?? '',
    description: json['descripcion']?.toString() ?? '',
    userName: json['usuario_nombre']?.toString() ?? '',
    role: json['rol']?.toString() ?? '',
    area: json['area']?.toString() ?? '',
    module: json['modulo']?.toString() ?? '',
    priority: json['prioridad']?.toString() ?? 'Media',
    status: json['estado']?.toString() ?? 'Nuevo',
    image: json['imagen']?.toString(),
    assignedName: json['asignado_nombre']?.toString(),
    createdAt: DateTime.tryParse(json['fecha_creacion']?.toString() ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['fecha_actualizacion']?.toString() ?? '') ?? DateTime.now(),
  );
}

class SupportComment {
  final int id, userId;
  final String userName, role, text;
  final bool internal;
  final DateTime createdAt;
  const SupportComment({required this.id, required this.userId, required this.userName, required this.role, required this.text, required this.internal, required this.createdAt});
  factory SupportComment.fromJson(Map<String, dynamic> json) => SupportComment(
    id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
    userId: int.tryParse(json['usuario_id']?.toString() ?? '') ?? 0,
    userName: json['usuario_nombre']?.toString() ?? '',
    role: json['rol']?.toString() ?? '',
    text: json['comentario']?.toString() ?? '',
    internal: json['es_interno'] == true || json['es_interno'] == 1,
    createdAt: DateTime.tryParse(json['fecha_creacion']?.toString() ?? '') ?? DateTime.now(),
  );
}

class SupportHistory {
  final String userName, action, oldValue, newValue;
  final DateTime createdAt;
  const SupportHistory({required this.userName, required this.action, required this.oldValue, required this.newValue, required this.createdAt});
  factory SupportHistory.fromJson(Map<String, dynamic> json) => SupportHistory(
    userName: json['usuario_nombre']?.toString() ?? '',
    action: json['accion']?.toString() ?? '',
    oldValue: json['valor_anterior']?.toString() ?? '',
    newValue: json['valor_nuevo']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['fecha_creacion']?.toString() ?? '') ?? DateTime.now(),
  );
}

class SupportDetail {
  final SupportTicket ticket;
  final List<SupportComment> comments;
  final List<SupportHistory> history;
  const SupportDetail({required this.ticket, required this.comments, required this.history});
  factory SupportDetail.fromJson(Map<String, dynamic> json) => SupportDetail(
    ticket: SupportTicket.fromJson(Map<String, dynamic>.from(json['alerta'] as Map)),
    comments: (json['comentarios'] as List<dynamic>? ?? []).whereType<Map>().map((e) => SupportComment.fromJson(Map<String, dynamic>.from(e))).toList(),
    history: (json['historial'] as List<dynamic>? ?? []).whereType<Map>().map((e) => SupportHistory.fromJson(Map<String, dynamic>.from(e))).toList(),
  );
}

class SupportStats {
  final int total, critical, high, medium, low, pending, averageMinutes;
  const SupportStats({this.total=0,this.critical=0,this.high=0,this.medium=0,this.low=0,this.pending=0,this.averageMinutes=0});
  factory SupportStats.fromJson(Map<String, dynamic> json) => SupportStats(
    total: _int(json['total']), critical: _int(json['criticas']), high: _int(json['altas']), medium: _int(json['medias']), low: _int(json['bajas']), pending: _int(json['pendientes']), averageMinutes: _int(json['promedio_minutos']),
  );
  static int _int(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;
}

class SupportPage {
  final List<SupportTicket> tickets;
  final int total, page, pageSize;
  const SupportPage({required this.tickets, required this.total, required this.page, required this.pageSize});
}

