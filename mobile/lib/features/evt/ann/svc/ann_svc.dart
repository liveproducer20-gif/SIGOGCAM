import '../../../../core/api/api_client.dart';
import '../mdl/ann_mdl.dart';

class AnnSvc {
  static final ApiClient _client = ApiClient();

  static Future<List<AnnMdl>> getLst({int? personalId}) async {
    final path = personalId == null ? 'anuncios' : 'anuncios?personalId=$personalId';
    final response = await _client.get<List<AnnMdl>>(
      path,
      (value) {
        final list = value as List<dynamic>? ?? [];
        return list
            .whereType<Map>()
            .map((item) => _fromJson(Map<String, dynamic>.from(item)))
            .toList();
      },
    );

    return response.datos ?? [];
  }

  static Future<AnnMdl> crear(AnnMdl ann, {required int creadoPor}) async {
    final response = await _client.post<int>(
      'anuncios',
      _toJson(ann, creadoPor: creadoPor),
      (value) {
        final map = value as Map<String, dynamic>? ?? {};
        return map['anuncioId'] as int? ?? 0;
      },
    );

    return AnnMdl(
      id: response.datos ?? ann.id,
      ttl: ann.ttl,
      desc: ann.desc,
      img: ann.img,
      imgNombre: ann.imgNombre,
      imgUrl: ann.imgUrl,
      fecPub: ann.fecPub,
      fecExp: ann.fecExp,
      personalIds: ann.personalIds,
      prioridad: ann.prioridad,
      publicado: ann.publicado,
      notificar: ann.notificar,
    );
  }

  static Future<void> actualizar(AnnMdl ann) {
    return _client.put<bool>(
      'anuncios/${ann.id}',
      _toJson(ann),
      (_) => true,
    ).then((_) {});
  }

  static Future<void> cambiarPublicado(int id, bool publicado) {
    return _client.put<bool>(
      'anuncios/$id/publicado',
      {'publicado': publicado},
      (_) => true,
    ).then((_) {});
  }

  static Future<void> eliminar(int id) {
    return _client.delete<bool>(
      'anuncios/$id',
      (_) => true,
    ).then((_) {});
  }

  static Map<String, dynamic> _toJson(AnnMdl ann, {int? creadoPor}) {
    return {
      'titulo': ann.ttl,
      'descripcion': ann.desc,
      'prioridad': ann.prioridad,
      'imagenNombre': ann.imgNombre,
      'imagenUrl': ann.imgUrl,
      'fechaExpiracion': ann.fecExp?.toIso8601String(),
      'personalIds': ann.personalIds,
      'publicado': ann.publicado,
      'notificar': ann.notificar,
      'creadoPor': creadoPor,
    };
  }

  static AnnMdl _fromJson(Map<String, dynamic> json) {
    return AnnMdl(
      id: _toInt(json['id']),
      ttl: json['titulo']?.toString() ?? '',
      desc: json['descripcion']?.toString() ?? '',
      img: 'assets/img/auth_bg.jpg',
      imgNombre: _nullableText(json['imagen_nombre']),
      imgUrl: _nullableText(json['imagen_url']),
      fecPub: DateTime.tryParse(json['fecha_publicacion']?.toString() ?? '') ??
          DateTime.now(),
      fecExp: DateTime.tryParse(json['fecha_expiracion']?.toString() ?? ''),
      personalIds: _parseIds(json['personal_ids']),
      prioridad: json['prioridad']?.toString() ?? 'Normal',
      publicado: _toBool(json['publicado'], fallback: true),
      notificar: _toBool(json['notificar'], fallback: true),
    );
  }

  static List<int> _parseIds(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return [];
    return text
        .split(',')
        .map((item) => int.tryParse(item.trim()))
        .whereType<int>()
        .toList();
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(Object? value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().toLowerCase();
    if (['1', 'true', 'si', 'sí'].contains(text)) return true;
    if (['0', 'false', 'no'].contains(text)) return false;
    return fallback;
  }

  static String? _nullableText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }
}
