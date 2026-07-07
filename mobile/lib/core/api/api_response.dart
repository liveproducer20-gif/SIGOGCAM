class ApiResponse<T> {
  final bool ok;
  final String? mensaje;
  final T? datos;

  const ApiResponse({
    required this.ok,
    this.mensaje,
    this.datos,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseDatos,
  ) {
    return ApiResponse<T>(
      ok: json['ok'] == true,
      mensaje: json['mensaje']?.toString(),
      datos: parseDatos(json.containsKey('datos') ? json['datos'] : json),
    );
  }
}
