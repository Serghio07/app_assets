import 'empresa.dart';

class Usuario {
  final String id;
  final String email;
  final String nombre;
  final String tipo;
  final String? whatsapp;
  final String? empresaId;
  final Empresa? empresa;
  final String? accessToken;
  final DateTime? createdAt;

  Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.tipo,
    this.whatsapp,
    this.empresaId,
    this.empresa,
    this.accessToken,
    this.createdAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      whatsapp: json['whatsapp'],
      empresaId: json['empresa_id']?.toString(),
      empresa: json['empresa'] != null
          ? Empresa.fromJson(json['empresa'])
          : null,
      accessToken: json['access_token'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'tipo': tipo,
      'whatsapp': whatsapp,
      'empresa_id': empresaId,
      'access_token': accessToken,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
