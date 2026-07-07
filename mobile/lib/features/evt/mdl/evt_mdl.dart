class EvtMdl {
  final int id;
  final String nom;
  final int tipoId;
  final String tipo;
  final String fecha;
  final String fechaFin;
  final String fechaInicioRaw;
  final String fechaFinRaw;
  final String hora;
  final String lugar;
  final String descripcion;
  final String prioridad;
  final String? imgUrl;
  final String? pdfNombre;
  final String? pdfUrl;
  final bool notificar;
  final int convocados;
  final int confirmados;
  String estado;

  EvtMdl({
    required this.id,
    required this.nom,
    this.tipoId = 0,
    required this.tipo,
    required this.fecha,
    this.fechaFin = '',
    this.fechaInicioRaw = '',
    this.fechaFinRaw = '',
    required this.hora,
    this.lugar = '',
    this.descripcion = '',
    this.prioridad = 'Normal',
    this.imgUrl,
    this.pdfNombre,
    this.pdfUrl,
    this.notificar = true,
    required this.convocados,
    required this.confirmados,
    required this.estado,
  });
}
