import 'responsable.dart';
import 'sucursal.dart';
import 'ubicacion.dart';
import 'empresa.dart';
import 'categoria.dart';

class TipoActivo {
  final String id;
  final String? empresaId;
  final String? categoriaId;
  final String? sucursalId;
  final String? ubicacionId;
  final String nombre;
  final String? naturaleza;
  final bool? depreciable;
  final int? vidaUtilMeses;
  final double? valorReferencial;
  final bool? permiteRfid;
  final Empresa? empresa;
  final Categoria? categoria;
  final Sucursal? sucursal;
  final Ubicacion? ubicacion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TipoActivo({
    required this.id,
    required this.nombre,
    this.empresaId,
    this.categoriaId,
    this.sucursalId,
    this.ubicacionId,
    this.naturaleza,
    this.depreciable,
    this.vidaUtilMeses,
    this.valorReferencial,
    this.permiteRfid,
    this.empresa,
    this.categoria,
    this.sucursal,
    this.ubicacion,
    this.createdAt,
    this.updatedAt,
  });

  factory TipoActivo.fromJson(Map<String, dynamic> json) {
    return TipoActivo(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      empresaId: json['empresa_id']?.toString(),
      categoriaId: json['categoria_id']?.toString(),
      sucursalId: json['sucursal_id']?.toString(),
      ubicacionId: json['ubicacion_id']?.toString(),
      naturaleza: json['naturaleza'],
      depreciable: json['depreciable'],
      vidaUtilMeses: json['vida_util_meses'],
      valorReferencial: json['valor_referencial'] != null
          ? double.tryParse(json['valor_referencial'].toString())
          : null,
      permiteRfid: json['permite_rfid'],
      empresa: json['empresa'] != null
          ? Empresa.fromJson(json['empresa'])
          : null,
      categoria: json['categoria'] != null
          ? Categoria.fromJson(json['categoria'])
          : null,
      sucursal: json['sucursal'] != null
          ? Sucursal.fromJson(json['sucursal'])
          : null,
      ubicacion: json['ubicacion'] != null
          ? Ubicacion.fromJson(json['ubicacion'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      if (empresaId != null) 'empresa_id': int.tryParse(empresaId!) ?? empresaId,
      if (categoriaId != null) 'categoria_id': int.tryParse(categoriaId!) ?? categoriaId,
      if (sucursalId != null) 'sucursal_id': int.tryParse(sucursalId!) ?? sucursalId,
      if (ubicacionId != null) 'ubicacion_id': int.tryParse(ubicacionId!) ?? ubicacionId,
      'nombre': nombre,
      if (naturaleza != null) 'naturaleza': naturaleza,
      if (depreciable != null) 'depreciable': depreciable,
      if (vidaUtilMeses != null) 'vida_util_meses': vidaUtilMeses,
      if (valorReferencial != null) 'valor_referencial': valorReferencial,
      if (permiteRfid != null) 'permite_rfid': permiteRfid,
    };
  }

  /// Crea una copia del TipoActivo con los campos modificados
  TipoActivo copyWith({
    String? id,
    String? empresaId,
    String? categoriaId,
    String? sucursalId,
    String? ubicacionId,
    String? nombre,
    String? naturaleza,
    bool? depreciable,
    int? vidaUtilMeses,
    double? valorReferencial,
    bool? permiteRfid,
    Empresa? empresa,
    Categoria? categoria,
    Sucursal? sucursal,
    Ubicacion? ubicacion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TipoActivo(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      categoriaId: categoriaId ?? this.categoriaId,
      sucursalId: sucursalId ?? this.sucursalId,
      ubicacionId: ubicacionId ?? this.ubicacionId,
      nombre: nombre ?? this.nombre,
      naturaleza: naturaleza ?? this.naturaleza,
      depreciable: depreciable ?? this.depreciable,
      vidaUtilMeses: vidaUtilMeses ?? this.vidaUtilMeses,
      valorReferencial: valorReferencial ?? this.valorReferencial,
      permiteRfid: permiteRfid ?? this.permiteRfid,
      empresa: empresa ?? this.empresa,
      categoria: categoria ?? this.categoria,
      sucursal: sucursal ?? this.sucursal,
      ubicacion: ubicacion ?? this.ubicacion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EstadoActivo {
  final String id;
  final String nombre;

  EstadoActivo({required this.id, required this.nombre});

  factory EstadoActivo.fromJson(Map<String, dynamic> json) {
    return EstadoActivo(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
    );
  }
}

class Activo {
  final String id;
  final String empresaId;
  final String? tipoActivoId;
  final String codigoInterno;
  final String? rfidUid;
  final String? estadoActivoId;
  final String? ubicacionActualId;
  final String? responsableActualId;
  final double? valorInicial;
  final TipoActivo? tipoActivo;
  final EstadoActivo? estadoActivo;
  final Responsable? responsable;
  final DateTime? createdAt;

  Activo({
    required this.id,
    required this.empresaId,
    required this.codigoInterno,
    this.tipoActivoId,
    this.rfidUid,
    this.estadoActivoId,
    this.ubicacionActualId,
    this.responsableActualId,
    this.valorInicial,
    this.tipoActivo,
    this.estadoActivo,
    this.responsable,
    this.createdAt,
  });

  factory Activo.fromJson(Map<String, dynamic> json) {
    return Activo(
      id: json['id']?.toString() ?? '',
      empresaId: json['empresa_id']?.toString() ?? '',
      codigoInterno: json['codigo_interno'] ?? '',
      tipoActivoId: json['tipo_activo_id']?.toString(),
      rfidUid: json['rfid_uid'],
      estadoActivoId: json['estado_activo_id']?.toString(),
      ubicacionActualId: json['ubicacion_actual_id']?.toString(),
      responsableActualId: json['responsable_actual_id']?.toString(),
      valorInicial: json['valor_inicial'] != null
          ? double.tryParse(json['valor_inicial'].toString())
          : null,
      tipoActivo: json['tipo_activo'] != null
          ? TipoActivo.fromJson(json['tipo_activo'])
          : null,
      estadoActivo: json['estado_activo'] != null
          ? EstadoActivo.fromJson(json['estado_activo'])
          : null,
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
      'codigo_interno': codigoInterno,
      'tipo_activo_id': tipoActivoId,
      'rfid_uid': rfidUid,
      'estado_activo_id': estadoActivoId,
      'ubicacion_actual_id': ubicacionActualId,
      'responsable_actual_id': responsableActualId,
      'valor_inicial': valorInicial,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
