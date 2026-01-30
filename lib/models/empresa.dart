import 'sucursal.dart';

class Empresa {
  final String id;
  final String nombre;
  final String? identificadorFiscal;
  final String? monedaBase;
  final bool activa;
  final List<Sucursal>? sucursales;
  final DateTime? createdAt;

  Empresa({
    required this.id,
    required this.nombre,
    this.identificadorFiscal,
    this.monedaBase,
    this.activa = true,
    this.sucursales,
    this.createdAt,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      identificadorFiscal: json['identificador_fiscal'],
      monedaBase: json['moneda_base'],
      activa: json['activa'] ?? true,
      sucursales: json['sucursales'] != null
          ? (json['sucursales'] as List)
              .map((s) => Sucursal.fromJson(s))
              .toList()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'identificador_fiscal': identificadorFiscal,
      'moneda_base': monedaBase,
      'activa': activa,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
