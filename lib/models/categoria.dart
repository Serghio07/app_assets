class Categoria {
  final String id;
  final String nombre;

  Categoria({
    required this.id,
    required this.nombre,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': int.tryParse(id) ?? id,
      'nombre': nombre,
    };
  }
}
