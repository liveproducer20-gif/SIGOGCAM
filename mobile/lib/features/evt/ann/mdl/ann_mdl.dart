class AnnMdl {
  final int id;
  String ttl;
  String desc;
  String img;
  String? imgNombre;
  String? imgUrl;
  final DateTime fecPub;
  final DateTime? fecExp;
  final List<int> personalIds;
  String prioridad;
  bool publicado;
  final bool notificar;

  AnnMdl({
    required this.id,
    required this.ttl,
    required this.desc,
    required this.img,
    this.imgNombre,
    this.imgUrl,
    required this.fecPub,
    this.fecExp,
    this.personalIds = const [],
    required this.prioridad,
    required this.publicado,
    required this.notificar,
  });
}
