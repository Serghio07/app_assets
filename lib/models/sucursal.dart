class Sucursal {
  final String id;
  final String empresaId;
  final String nombre;
  final String? ciudad;
  final String? codigo;
  final DateTime? createdAt;

  Sucursal({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.ciudad,
    this.codigo,
    this.createdAt,
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      id: json['id']?.toString() ?? '',
      empresaId: json['empresa_id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      ciudad: json['ciudad'],
      codigo: json['codigo'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'nombre': nombre,
      'ciudad': ciudad,
      'codigo': codigo,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
