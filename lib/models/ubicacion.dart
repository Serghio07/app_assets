import 'responsable.dart';

class Ubicacion {
  final String id;
  final String empresaId;
  final String? sucursalId;
  final String nombre;
  final String? tipoUbicacionId;
  final bool permiteInventario;
  final Responsable? responsable;
  final DateTime? createdAt;

  Ubicacion({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.sucursalId,
    this.tipoUbicacionId,
    this.permiteInventario = true,
    this.responsable,
    this.createdAt,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      id: json['id']?.toString() ?? '',
      empresaId: json['empresa_id']?.toString() ?? '',
      sucursalId: json['sucursal_id']?.toString(),
      nombre: json['nombre'] ?? '',
      tipoUbicacionId: json['tipo_ubicacion_id']?.toString(),
      permiteInventario: json['permite_inventario'] ?? true,
      responsable: json['responsable'] != null
          ? Responsable.fromJson(json['responsable'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'sucursal_id': sucursalId,
      'nombre': nombre,
      'tipo_ubicacion_id': tipoUbicacionId,
      'permite_inventario': permiteInventario,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
