import 'empresa.dart';
import 'ubicacion.dart';

/// Estados posibles de un inventario
enum EstadoInventario {
  abierto('ABIERTO'),
  cerrado('CERRADO');

  final String value;
  const EstadoInventario(this.value);

  static EstadoInventario fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'CERRADO':
        return EstadoInventario.cerrado;
      default:
        return EstadoInventario.abierto;
    }
  }
}

/// Modelo de Inventario alineado con el backend
class Inventario {
  final int id;
  final int empresaId;
  final int ubicacionId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final EstadoInventario estado;
  final DateTime? createdAt;
  
  // Relaciones
  final Empresa? empresa;
  final Ubicacion? ubicacion;
  final List<LecturaRfid> lecturas;
  final List<ResultadoActivo> resultados;

  Inventario({
    required this.id,
    required this.empresaId,
    required this.ubicacionId,
    required this.fechaInicio,
    this.fechaFin,
    required this.estado,
    this.createdAt,
    this.empresa,
    this.ubicacion,
    this.lecturas = const [],
    this.resultados = const [],
  });

  factory Inventario.fromJson(Map<String, dynamic> json) {
    return Inventario(
      id: json['id'] ?? 0,
      empresaId: json['empresa_id'] ?? 0,
      ubicacionId: json['ubicacion_id'] ?? 0,
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'])
          : DateTime.now(),
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'])
          : null,
      estado: EstadoInventario.fromString(json['estado']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      empresa: json['empresa'] != null
          ? Empresa.fromJson(json['empresa'])
          : null,
      ubicacion: json['ubicacion'] != null
          ? Ubicacion.fromJson(json['ubicacion'])
          : null,
      lecturas: json['lectura'] != null
          ? (json['lectura'] as List)
              .map((l) => LecturaRfid.fromJson(l))
              .toList()
          : [],
      resultados: json['resultado'] != null
          ? (json['resultado'] as List)
              .map((r) => ResultadoActivo.fromJson(r))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'empresa_id': empresaId,
      'ubicacion_id': ubicacionId,
      'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
      if (fechaFin != null) 'fecha_fin': fechaFin!.toIso8601String(),
      'estado': estado.value,
    };
  }

  /// JSON para crear un nuevo inventario
  Map<String, dynamic> toCreateJson() {
    return {
      'empresa_id': empresaId,
      'ubicacion_id': ubicacionId,
      'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
    };
  }

  bool get estaAbierto => estado == EstadoInventario.abierto;
  bool get estaCerrado => estado == EstadoInventario.cerrado;
  
  int get totalLecturas => lecturas.length;
  
  /// Copia del inventario con modificaciones
  Inventario copyWith({
    int? id,
    int? empresaId,
    int? ubicacionId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    EstadoInventario? estado,
    Empresa? empresa,
    Ubicacion? ubicacion,
    List<LecturaRfid>? lecturas,
    List<ResultadoActivo>? resultados,
  }) {
    return Inventario(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      ubicacionId: ubicacionId ?? this.ubicacionId,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
      empresa: empresa ?? this.empresa,
      ubicacion: ubicacion ?? this.ubicacion,
      lecturas: lecturas ?? this.lecturas,
      resultados: resultados ?? this.resultados,
    );
  }
}

/// Modelo de Lectura RFID
class LecturaRfid {
  final int id;
  final int inventarioId;
  final String rfidUid;
  final String? tid;
  final int? rssi;
  final int? antennaId;
  final int? usuarioId;
  final int cantidadLecturas;
  final DateTime fechaLectura;

  LecturaRfid({
    required this.id,
    required this.inventarioId,
    required this.rfidUid,
    this.tid,
    this.rssi,
    this.antennaId,
    this.usuarioId,
    this.cantidadLecturas = 1,
    required this.fechaLectura,
  });

  factory LecturaRfid.fromJson(Map<String, dynamic> json) {
    return LecturaRfid(
      id: json['id'] ?? 0,
      inventarioId: json['inventario_id'] ?? 0,
      rfidUid: json['rfid_uid'] ?? '',
      tid: json['tid'],
      rssi: json['rssi'],
      antennaId: json['antenna_id'],
      usuarioId: json['usuario_id'],
      cantidadLecturas: json['cantidad_lecturas'] ?? 1,
      fechaLectura: json['fecha_lectura'] != null
          ? DateTime.parse(json['fecha_lectura'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rfid_uid': rfidUid,
      if (tid != null) 'tid': tid,
      if (rssi != null) 'rssi': rssi,
      if (antennaId != null) 'antenna_id': antennaId,
      if (usuarioId != null) 'usuario_id': usuarioId,
    };
  }
}

/// Resultado de un activo en el inventario
enum TipoResultado {
  encontrado('ENCONTRADO'),
  faltante('FALTANTE'),
  sobrante('SOBRANTE');

  final String value;
  const TipoResultado(this.value);

  static TipoResultado fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'FALTANTE':
        return TipoResultado.faltante;
      case 'SOBRANTE':
        return TipoResultado.sobrante;
      default:
        return TipoResultado.encontrado;
    }
  }
}

class ResultadoActivo {
  final int inventarioId;
  final int? activoId;
  final TipoResultado resultado;
  final String? rfidUid; // Para sobrantes desconocidos

  ResultadoActivo({
    required this.inventarioId,
    this.activoId,
    required this.resultado,
    this.rfidUid,
  });

  factory ResultadoActivo.fromJson(Map<String, dynamic> json) {
    return ResultadoActivo(
      inventarioId: json['inventario_id'] ?? 0,
      activoId: json['activo_id'],
      resultado: TipoResultado.fromString(json['resultado']),
      rfidUid: json['rfid_uid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventario_id': inventarioId,
      if (activoId != null) 'activo_id': activoId,
      'resultado': resultado.value,
      if (rfidUid != null) 'rfid_uid': rfidUid,
    };
  }
}

/// Estadísticas del inventario
class EstadisticasInventario {
  final int totalActivosUbicacion;
  final int totalLecturasUnicas;
  final int encontrados;
  final int faltantes;
  final int sobrantes;
  final int rfidsDesconocidos;

  EstadisticasInventario({
    required this.totalActivosUbicacion,
    required this.totalLecturasUnicas,
    required this.encontrados,
    required this.faltantes,
    required this.sobrantes,
    this.rfidsDesconocidos = 0,
  });

  factory EstadisticasInventario.fromJson(Map<String, dynamic> json) {
    return EstadisticasInventario(
      totalActivosUbicacion: json['total_activos_ubicacion'] ?? 0,
      totalLecturasUnicas: json['total_lecturas_unicas'] ?? 0,
      encontrados: json['encontrados'] ?? 0,
      faltantes: json['faltantes'] ?? 0,
      sobrantes: json['sobrantes'] ?? 0,
      rfidsDesconocidos: json['rfids_desconocidos'] ?? 0,
    );
  }

  double get porcentajeEncontrados {
    if (totalActivosUbicacion == 0) return 0;
    return (encontrados / totalActivosUbicacion) * 100;
  }

  double get porcentajeFaltantes {
    if (totalActivosUbicacion == 0) return 0;
    return (faltantes / totalActivosUbicacion) * 100;
  }
}

/// Resultado completo del inventario
class ResultadoInventario {
  final int inventarioId;
  final EstadisticasInventario estadisticas;
  final List<ResultadoActivo> resultados;

  ResultadoInventario({
    required this.inventarioId,
    required this.estadisticas,
    required this.resultados,
  });

  factory ResultadoInventario.fromJson(Map<String, dynamic> json) {
    return ResultadoInventario(
      inventarioId: json['inventario_id'] ?? 0,
      estadisticas: EstadisticasInventario.fromJson(json['estadisticas'] ?? {}),
      resultados: json['resultados'] != null
          ? (json['resultados'] as List)
              .map((r) => ResultadoActivo.fromJson(r))
              .toList()
          : [],
    );
  }

  List<ResultadoActivo> get encontrados =>
      resultados.where((r) => r.resultado == TipoResultado.encontrado).toList();

  List<ResultadoActivo> get faltantes =>
      resultados.where((r) => r.resultado == TipoResultado.faltante).toList();

  List<ResultadoActivo> get sobrantes =>
      resultados.where((r) => r.resultado == TipoResultado.sobrante).toList();
}

/// Resultado de envío de lecturas en batch
class BatchResult {
  final int totalRecibidas;
  final int nuevas;
  final int actualizadas;
  final List<String> errores;

  BatchResult({
    required this.totalRecibidas,
    required this.nuevas,
    required this.actualizadas,
    this.errores = const [],
  });

  factory BatchResult.fromJson(Map<String, dynamic> json) {
    return BatchResult(
      totalRecibidas: json['total_recibidas'] ?? 0,
      nuevas: json['nuevas'] ?? 0,
      actualizadas: json['actualizadas'] ?? 0,
      errores: json['errores'] != null
          ? List<String>.from(json['errores'])
          : [],
    );
  }

  bool get tieneErrores => errores.isNotEmpty;
}

