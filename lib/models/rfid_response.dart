/// Respuesta del nuevo endpoint POST /inventarios/:id/procesar-rfid
class RfidResponse {
  final bool success;
  final String rfidUid;
  final bool activoEncontrado;
  final ActivoInfo? activo;
  final String? errorTipo;
  final String mensaje;
  final List<String> warnings;
  final bool? esDuplicado;
  final int? vecesEscaneado;
  final int? tiempoProcesamiento;

  RfidResponse({
    required this.success,
    required this.rfidUid,
    required this.activoEncontrado,
    this.activo,
    this.errorTipo,
    required this.mensaje,
    required this.warnings,
    this.esDuplicado,
    this.vecesEscaneado,
    this.tiempoProcesamiento,
  });

  factory RfidResponse.fromJson(Map<String, dynamic> json) {
    return RfidResponse(
      success: json['success'] ?? false,
      rfidUid: json['rfid_uid'] ?? '',
      activoEncontrado: json['activo_encontrado'] ?? false,
      activo: json['activo'] != null ? ActivoInfo.fromJson(json['activo']) : null,
      errorTipo: json['error_tipo'],
      mensaje: json['mensaje'] ?? '',
      warnings: json['warnings'] != null 
        ? List<String>.from(json['warnings']) 
        : [],
      esDuplicado: json['es_duplicado'],
      vecesEscaneado: json['veces_escaneado'],
      tiempoProcesamiento: json['tiempo_procesamiento_ms'],
    );
  }

  bool get tieneWarnings => warnings.isNotEmpty;
  bool get esError => !success;
}

/// Información básica del activo en la respuesta RFID
class ActivoInfo {
  final String id;
  final String codigoInterno;
  final String? nombre;
  final String? ubicacionId;
  final String? responsable;
  final String? tipoActivo;

  ActivoInfo({
    required this.id,
    required this.codigoInterno,
    this.nombre,
    this.ubicacionId,
    this.responsable,
    this.tipoActivo,
  });

  factory ActivoInfo.fromJson(Map<String, dynamic> json) {
    return ActivoInfo(
      id: json['id']?.toString() ?? '',
      codigoInterno: json['codigo_interno'] ?? '',
      nombre: json['nombre'],
      ubicacionId: json['ubicacion_id']?.toString(),
      responsable: json['responsable'],
      tipoActivo: json['tipo_activo'],
    );
  }
}
