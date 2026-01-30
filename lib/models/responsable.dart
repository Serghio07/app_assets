class Responsable {
  final String id;
  final String empresaId;
  final String tipo;
  final String nombre;
  final String? identificador;
  final DateTime? createdAt;

  Responsable({
    required this.id,
    required this.empresaId,
    required this.tipo,
    required this.nombre,
    this.identificador,
    this.createdAt,
  });

  factory Responsable.fromJson(Map<String, dynamic> json) {
    return Responsable(
      id: json['id']?.toString() ?? '',
      empresaId: json['empresa_id']?.toString() ?? '',
      tipo: json['tipo'] ?? 'PERSONA',
      nombre: json['nombre'] ?? '',
      identificador: json['identificador'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'tipo': tipo,
      'nombre': nombre,
      'identificador': identificador,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
