import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // URL Base del Backend
  //  IMPORTANTE: Usando IP local de la PC para dispositivos físicos Android
  // - El dispositivo debe estar conectado a la misma red WiFi que la PC
  // - El backend debe estar corriendo en 0.0.0.0:3000
  static const String baseUrl = 'http://192.168.100.142:3000/api/v1';
  
  // Logger helper
  void _log(String message) {
    debugPrint('🔵 [API] $message');
  }
  
  void _logError(String message) {
    debugPrint('🔴 [API ERROR] $message');
  }
  
  void _logSuccess(String message) {
    debugPrint('🟢 [API SUCCESS] $message');
  }
  
  String? _token;

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Headers con autenticación
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Guardar token
  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // Cargar token guardado
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
  }

  // Limpiar token
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  bool get isAuthenticated => _token != null;

  // ==================== AUTH ====================

  Future<Usuario> login(String email, String contrasena) async {
    _log('LOGIN: Intentando iniciar sesión con email: $email');
    _log('LOGIN: URL: $baseUrl/auth/login');
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'contrasena': contrasena,
      }),
    );

    _log('LOGIN: Status Code: ${response.statusCode}');
    _log('LOGIN: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final usuario = Usuario.fromJson(data);
      _logSuccess('LOGIN: Usuario: ${usuario.nombre}');
      _logSuccess('LOGIN: Empresa ID: ${usuario.empresaId}');
      _logSuccess('LOGIN: Empresa: ${usuario.empresa?.nombre}');
      
      if (usuario.accessToken != null) {
        await _saveToken(usuario.accessToken!);
        _logSuccess('LOGIN: Token guardado correctamente');
      }
      return usuario;
    } else {
      _logError('LOGIN: Error ${response.statusCode}: ${response.body}');
      throw Exception('Error al iniciar sesión: ${response.body}');
    }
  }

  Future<Usuario> getProfile() async {
    _log('PROFILE: Obteniendo perfil del usuario');
    _log('PROFILE: URL: $baseUrl/auth/profile');
    
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _headers,
    );

    _log('PROFILE: Status Code: ${response.statusCode}');
    _log('PROFILE: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final usuario = Usuario.fromJson(jsonDecode(response.body));
      _logSuccess('PROFILE: Usuario: ${usuario.nombre}');
      return usuario;
    } else {
      _logError('PROFILE: Error ${response.statusCode}');
      throw Exception('Error al obtener perfil');
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _headers,
      );
    } finally {
      await clearToken();
    }
  }

  // ==================== EMPRESAS ====================

  Future<List<Empresa>> getEmpresas({int skip = 0, int take = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/empresas?skip=$skip&take=$take'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> empresasJson = data['data'] ?? [];
      return empresasJson.map((e) => Empresa.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener empresas');
    }
  }

  Future<Empresa> getEmpresa(String id) async {
    _log('EMPRESA: Obteniendo empresa con ID: $id');
    _log('EMPRESA: URL: $baseUrl/empresas/$id');
    
    final response = await http.get(
      Uri.parse('$baseUrl/empresas/$id'),
      headers: _headers,
    );

    _log('EMPRESA: Status Code: ${response.statusCode}');
    _log('EMPRESA: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final empresa = Empresa.fromJson(jsonDecode(response.body));
      _logSuccess('EMPRESA: Nombre: ${empresa.nombre}');
      return empresa;
    } else {
      _logError('EMPRESA: Error ${response.statusCode}');
      throw Exception('Error al obtener empresa');
    }
  }

  // ==================== SUCURSALES ====================

  Future<List<Sucursal>> getSucursales({
    String? empresaId,
    int skip = 0,
    int take = 20,
  }) async {
    String url = '$baseUrl/sucursales?skip=$skip&take=$take';
    if (empresaId != null) {
      url += '&empresa_id=$empresaId';
    }

    _log('SUCURSALES: Obteniendo sucursales');
    _log('SUCURSALES: URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    _log('SUCURSALES: Status Code: ${response.statusCode}');
    _log('SUCURSALES: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> sucursalesJson = data['data'] ?? [];
      final sucursales = sucursalesJson.map((s) => Sucursal.fromJson(s)).toList();
      _logSuccess('SUCURSALES: Total encontradas: ${sucursales.length}');
      return sucursales;
    } else {
      _logError('SUCURSALES: Error ${response.statusCode}');
      throw Exception('Error al obtener sucursales');
    }
  }

  Future<Sucursal> getSucursal(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sucursales/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Sucursal.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener sucursal');
    }
  }

  // ==================== UBICACIONES ====================

  Future<List<Ubicacion>> getUbicaciones({
    String? empresaId,
    String? sucursalId,
    int skip = 0,
    int take = 20,
  }) async {
    String url = '$baseUrl/ubicaciones?skip=$skip&take=$take&permite_inventario=true';
    if (empresaId != null) {
      url += '&empresa_id=$empresaId';
    }
    if (sucursalId != null) {
      url += '&sucursal_id=$sucursalId';
    }

    _log('UBICACIONES: Obteniendo ubicaciones');
    _log('UBICACIONES: URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    _log('UBICACIONES: Status Code: ${response.statusCode}');
    _log('UBICACIONES: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> ubicacionesJson = data['data'] ?? data;
      final ubicaciones = ubicacionesJson.map((u) => Ubicacion.fromJson(u)).toList();
      _logSuccess('UBICACIONES: Total encontradas: ${ubicaciones.length}');
      return ubicaciones;
    } else {
      _logError('UBICACIONES: Error ${response.statusCode}');
      throw Exception('Error al obtener ubicaciones');
    }
  }

  Future<Ubicacion> getUbicacion(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ubicaciones/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Ubicacion.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener ubicación');
    }
  }

  // ==================== ACTIVOS ====================

  Future<List<Activo>> getActivos({
    String? empresaId,
    int skip = 0,
    int take = 20,
  }) async {
    String url = '$baseUrl/activos?skip=$skip&take=$take';
    if (empresaId != null) {
      url += '&empresa_id=$empresaId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> activosJson = data['data'] ?? [];
      return activosJson.map((a) => Activo.fromJson(a)).toList();
    } else {
      throw Exception('Error al obtener activos');
    }
  }

  Future<List<Activo>> getActivosPorUbicacion({
    required String empresaId,
    required String ubicacionId,
    int skip = 0,
    int take = 100,
  }) async {
    final url = '$baseUrl/activos?ubicacion_id=$ubicacionId&empresa_id=$empresaId&skip=$skip&take=$take';
    
    _log('ACTIVOS: Obteniendo activos por ubicación');
    _log('ACTIVOS: Empresa ID: $empresaId');
    _log('ACTIVOS: Ubicación ID: $ubicacionId');
    _log('ACTIVOS: URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    _log('ACTIVOS: Status Code: ${response.statusCode}');
    _log('ACTIVOS: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> activosJson = data['data'] ?? [];
      final activos = activosJson.map((a) => Activo.fromJson(a)).toList();
      _logSuccess('ACTIVOS: Total encontrados: ${activos.length}');
      for (var activo in activos) {
        _log('ACTIVOS: - ${activo.codigoInterno} | ${activo.tipoActivo?.nombre ?? "Sin tipo"}');
        _log('ACTIVOS:   RFID: ${activo.rfidUid ?? "SIN RFID"} ⚠️');
      }
      return activos;
    } else {
      _logError('ACTIVOS: Error ${response.statusCode}');
      throw Exception('Error al obtener activos por ubicación');
    }
  }

  Future<Activo> getActivo(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/activos/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Activo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener activo');
    }
  }

  // ==================== RESPONSABLES ====================

  Future<List<Responsable>> getResponsables({
    String? empresaId,
    int skip = 0,
    int take = 20,
  }) async {
    String url = '$baseUrl/responsables?skip=$skip&take=$take';
    if (empresaId != null) {
      url += '&empresa_id=$empresaId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> responsablesJson = data['data'] ?? [];
      return responsablesJson.map((r) => Responsable.fromJson(r)).toList();
    } else {
      throw Exception('Error al obtener responsables');
    }
  }

  // ==================== TIPO ACTIVO ====================

  /// Listar tipos de activo con filtros opcionales
  Future<List<TipoActivo>> getTiposActivo({
    String? empresaId,
    String? sucursalId,
    String? ubicacionId,
    int skip = 0,
    int take = 20,
  }) async {
    String url = '$baseUrl/tipo-activo?skip=$skip&take=$take';
    if (empresaId != null) {
      url += '&empresa_id=$empresaId';
    }
    if (sucursalId != null) {
      url += '&sucursal_id=$sucursalId';
    }
    if (ubicacionId != null) {
      url += '&ubicacion_id=$ubicacionId';
    }

    _log('TIPO_ACTIVO: Obteniendo tipos de activo');
    _log('TIPO_ACTIVO: URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    _log('TIPO_ACTIVO: Status Code: ${response.statusCode}');
    _log('TIPO_ACTIVO: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> tiposJson = data['data'] ?? [];
      final tipos = tiposJson.map((t) => TipoActivo.fromJson(t)).toList();
      _logSuccess('TIPO_ACTIVO: Total encontrados: ${tipos.length}');
      return tipos;
    } else {
      _logError('TIPO_ACTIVO: Error ${response.statusCode}');
      throw Exception('Error al obtener tipos de activo');
    }
  }

  /// Obtener un tipo de activo por ID
  Future<TipoActivo> getTipoActivo(String id) async {
    _log('TIPO_ACTIVO: Obteniendo tipo de activo ID: $id');
    
    final response = await http.get(
      Uri.parse('$baseUrl/tipo-activo/$id'),
      headers: _headers,
    );

    _log('TIPO_ACTIVO: Status Code: ${response.statusCode}');
    _log('TIPO_ACTIVO: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final tipoActivo = TipoActivo.fromJson(jsonDecode(response.body));
      _logSuccess('TIPO_ACTIVO: Obtenido: ${tipoActivo.nombre}');
      return tipoActivo;
    } else {
      _logError('TIPO_ACTIVO: Error ${response.statusCode}');
      throw Exception('Error al obtener tipo de activo');
    }
  }

  /// Crear un nuevo tipo de activo
  Future<TipoActivo> createTipoActivo({
    required int empresaId,
    required int categoriaId,
    required int sucursalId,
    required int ubicacionId,
    required String nombre,
    required String naturaleza,
    required bool depreciable,
    int? vidaUtilMeses,
    double? valorReferencial,
    bool permiteRfid = false,
  }) async {
    _log('TIPO_ACTIVO: Creando nuevo tipo de activo');
    
    final body = {
      'empresa_id': empresaId,
      'categoria_id': categoriaId,
      'sucursal_id': sucursalId,
      'ubicacion_id': ubicacionId,
      'nombre': nombre,
      'naturaleza': naturaleza,
      'depreciable': depreciable,
      if (vidaUtilMeses != null) 'vida_util_meses': vidaUtilMeses,
      if (valorReferencial != null) 'valor_referencial': valorReferencial,
      'permite_rfid': permiteRfid,
    };

    _log('TIPO_ACTIVO: Body: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse('$baseUrl/tipo-activo'),
      headers: _headers,
      body: jsonEncode(body),
    );

    _log('TIPO_ACTIVO: Status Code: ${response.statusCode}');
    _log('TIPO_ACTIVO: Response Body: ${response.body}');

    if (response.statusCode == 201) {
      final tipoActivo = TipoActivo.fromJson(jsonDecode(response.body));
      _logSuccess('TIPO_ACTIVO: Creado exitosamente: ${tipoActivo.nombre} (ID: ${tipoActivo.id})');
      return tipoActivo;
    } else {
      _logError('TIPO_ACTIVO: Error ${response.statusCode}: ${response.body}');
      throw Exception('Error al crear tipo de activo: ${response.body}');
    }
  }

  /// Actualizar un tipo de activo existente
  Future<TipoActivo> updateTipoActivo(String id, Map<String, dynamic> updates) async {
    _log('TIPO_ACTIVO: Actualizando tipo de activo ID: $id');
    _log('TIPO_ACTIVO: Updates: ${jsonEncode(updates)}');

    final response = await http.patch(
      Uri.parse('$baseUrl/tipo-activo/$id'),
      headers: _headers,
      body: jsonEncode(updates),
    );

    _log('TIPO_ACTIVO: Status Code: ${response.statusCode}');
    _log('TIPO_ACTIVO: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final tipoActivo = TipoActivo.fromJson(jsonDecode(response.body));
      _logSuccess('TIPO_ACTIVO: Actualizado exitosamente: ${tipoActivo.nombre}');
      return tipoActivo;
    } else {
      _logError('TIPO_ACTIVO: Error ${response.statusCode}: ${response.body}');
      throw Exception('Error al actualizar tipo de activo: ${response.body}');
    }
  }

  /// Eliminar un tipo de activo
  Future<void> deleteTipoActivo(String id) async {
    _log('TIPO_ACTIVO: Eliminando tipo de activo ID: $id');

    final response = await http.delete(
      Uri.parse('$baseUrl/tipo-activo/$id'),
      headers: _headers,
    );

    _log('TIPO_ACTIVO: Status Code: ${response.statusCode}');

    if (response.statusCode == 204 || response.statusCode == 200) {
      _logSuccess('TIPO_ACTIVO: Eliminado exitosamente ID: $id');
    } else {
      _logError('TIPO_ACTIVO: Error ${response.statusCode}: ${response.body}');
      throw Exception('Error al eliminar tipo de activo');
    }
  }

  // ==================== CATEGORÍAS ====================

  /// Listar categorías
  Future<List<Categoria>> getCategorias({
    String? empresaId,
    int skip = 0,
    int take = 20,
  }) async {
    String url = '$baseUrl/categorias?skip=$skip&take=$take';
    if (empresaId != null) {
      url += '&empresa_id=$empresaId';
    }

    _log('CATEGORIAS: Obteniendo categorías');
    _log('CATEGORIAS: URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    _log('CATEGORIAS: Status Code: ${response.statusCode}');
    _log('CATEGORIAS: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> categoriasJson = data['data'] ?? data;
      final categorias = categoriasJson.map((c) => Categoria.fromJson(c)).toList();
      _logSuccess('CATEGORIAS: Total encontradas: ${categorias.length}');
      return categorias;
    } else {
      _logError('CATEGORIAS: Error ${response.statusCode}');
      throw Exception('Error al obtener categorías');
    }
  }

  // ==================== INVENTARIOS RFID ====================

  /// Crear un nuevo inventario (nuevo formato según documentación)
  Future<Inventario> crearInventario({
    required int empresaId,
    required int ubicacionId,
    int? usuarioId,
  }) async {
    _log('INVENTARIO: Creando inventario RFID');
    _log('INVENTARIO: empresaId=$empresaId, ubicacionId=$ubicacionId, usuarioId=$usuarioId');
    
    // Formato del body según DTO del backend (snake_case)
    final body = {
      'empresa_id': empresaId,
      'ubicacion_id': ubicacionId,
      'fecha_inicio': DateTime.now().toIso8601String().split('T')[0],
    };

    _log('INVENTARIO: Body: ${jsonEncode(body)}');
    _log('INVENTARIO: Headers: $_headers');

    final response = await http.post(
      Uri.parse('$baseUrl/inventarios'),
      headers: _headers,
      body: jsonEncode(body),
    );

    _log('INVENTARIO: Status Code: ${response.statusCode}');
    _log('INVENTARIO: Response Body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final inventario = Inventario.fromJson(jsonDecode(response.body));
      _logSuccess('INVENTARIO: Creado exitosamente ID: ${inventario.id}');
      return inventario;
    } else {
      _logError('INVENTARIO: Error ${response.statusCode}: ${response.body}');
      // Intentar extraer mensaje de error del backend
      try {
        final errorData = jsonDecode(response.body);
        final message = errorData['message'] ?? errorData['error'] ?? 'Error desconocido';
        throw Exception('Error al crear inventario: $message');
      } catch (e) {
        throw Exception('Error al crear inventario: ${response.body}');
      }
    }
  }

  /// Crear inventario (método legacy para compatibilidad)
  Future<Inventario> createInventario({
    required String empresaId,
    required String sucursalId,
    required String ubicacionId,
    required String usuarioId,
    required int totalActivos,
  }) async {
    return crearInventario(
      empresaId: int.parse(empresaId),
      ubicacionId: int.parse(ubicacionId),
    );
  }

  /// Obtener un inventario por ID
  Future<Inventario> getInventario(int id) async {
    _log('INVENTARIO: Obteniendo inventario ID: $id');
    
    final response = await http.get(
      Uri.parse('$baseUrl/inventarios/$id'),
      headers: _headers,
    );

    _log('INVENTARIO: Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final inventario = Inventario.fromJson(jsonDecode(response.body));
      _logSuccess('INVENTARIO: Obtenido exitosamente');
      return inventario;
    } else {
      _logError('INVENTARIO: Error ${response.statusCode}');
      throw Exception('Error al obtener inventario');
    }
  }

  /// Listar inventarios con filtros
  Future<List<Inventario>> getInventarios({
    int? empresaId,
    int? ubicacionId,
    String? estado,
    int skip = 0,
    int take = 20,
  }) async {
    String url = '$baseUrl/inventarios?skip=$skip&take=$take';
    if (empresaId != null) url += '&empresa_id=$empresaId';
    if (ubicacionId != null) url += '&ubicacion_id=$ubicacionId';
    if (estado != null) url += '&estado=$estado';

    _log('INVENTARIO: Listando inventarios');
    _log('INVENTARIO: URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    _log('INVENTARIO: Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> inventariosJson = data['data'] ?? data;
      final inventarios = inventariosJson.map((i) => Inventario.fromJson(i)).toList();
      _logSuccess('INVENTARIO: Total encontrados: ${inventarios.length}');
      return inventarios;
    } else {
      _logError('INVENTARIO: Error ${response.statusCode}');
      throw Exception('Error al obtener inventarios');
    }
  }

  /// Enviar UNA lectura RFID al inventario
  Future<LecturaRfid> enviarLecturaRfid({
    required int inventarioId,
    required String rfidUid,
    String? tid,
    int? rssi,
    int? antennaId,
    int? usuarioId,
  }) async {
    _log('RFID: Enviando lectura al inventario $inventarioId');
    _log('RFID: RFID UID: $rfidUid');
    
    final body = {
      'rfid_uid': rfidUid,
      if (tid != null) 'tid': tid,
      if (rssi != null) 'rssi': rssi,
      if (antennaId != null) 'antenna_id': antennaId,
      if (usuarioId != null) 'usuario_id': usuarioId,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/inventarios/$inventarioId/lectura'),
      headers: _headers,
      body: jsonEncode(body),
    );

    _log('RFID: Status Code: ${response.statusCode}');
    _log('RFID: Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final lectura = LecturaRfid.fromJson(jsonDecode(response.body));
      _logSuccess('RFID: Lectura registrada exitosamente');
      return lectura;
    } else {
      _logError('RFID: Error ${response.statusCode}: ${response.body}');
      throw Exception('Error al enviar lectura RFID');
    }
  }

  /// Enviar MÚLTIPLES lecturas RFID (batch)
  Future<BatchResult> enviarLecturasBatch({
    required int inventarioId,
    required List<RfidTag> lecturas,
    int? usuarioId,
    int? readerId,
  }) async {
    _log('RFID: Enviando batch de ${lecturas.length} lecturas');
    
    final body = {
      'lecturas': lecturas.map((l) => {
        'rfid_uid': l.epc,
        'rssi': l.rssi,
        'antenna_id': l.antenna,
      }).toList(),
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (readerId != null) 'reader_id': readerId,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/inventarios/$inventarioId/lecturas/batch'),
      headers: _headers,
      body: jsonEncode(body),
    );

    _log('RFID: Status Code: ${response.statusCode}');
    _log('RFID: Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final result = BatchResult.fromJson(jsonDecode(response.body));
      _logSuccess('RFID: Batch procesado - Nuevas: ${result.nuevas}, Actualizadas: ${result.actualizadas}');
      return result;
    } else {
      _logError('RFID: Error ${response.statusCode}: ${response.body}');
      throw Exception('Error al enviar batch de lecturas');
    }
  }

  /// ✅ NUEVO: Procesar RFID con validación completa en el backend
  /// Este método REEMPLAZA la lógica que estaba en el frontend
  /// El backend hace:
  /// - Búsqueda del activo
  /// - Validación de duplicados
  /// - Validación de ubicación
  /// - Logging completo
  /// - Retorna información completa del activo
  Future<RfidResponse> procesarRfid({
    required int inventarioId,
    required String rfidUid,
    int? rssi,
    int? antennaId,
    String? tid,
  }) async {
    _log('✅ NUEVO ENDPOINT: Procesando RFID $rfidUid en inventario $inventarioId');
    
    final body = {
      'rfid_uid': rfidUid,
      if (rssi != null) 'rssi': rssi,
      if (antennaId != null) 'antenna_id': antennaId,
      if (tid != null) 'tid': tid,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/inventarios/$inventarioId/procesar-rfid'),
      headers: _headers,
      body: jsonEncode(body),
    );

    _log('RFID: Status Code: ${response.statusCode}');
    _log('RFID: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final rfidResponse = RfidResponse.fromJson(jsonDecode(response.body));
      
      if (rfidResponse.success) {
        _logSuccess(
          'RFID: ${rfidResponse.mensaje} - '
          '${rfidResponse.esDuplicado == true ? "DUPLICADO (${rfidResponse.vecesEscaneado}x)" : "NUEVO"} - '
          'Tiempo: ${rfidResponse.tiempoProcesamiento}ms'
        );
      } else {
        _logError('RFID: ${rfidResponse.mensaje} - Error: ${rfidResponse.errorTipo}');
      }
      
      return rfidResponse;
    } else {
      _logError('RFID: Error ${response.statusCode}: ${response.body}');
      throw Exception('Error al procesar RFID: ${response.body}');
    }
  }

  /// Cerrar inventario y procesar resultados
  Future<Inventario> cerrarInventario(int inventarioId) async {
    _log('INVENTARIO: Cerrando inventario $inventarioId');
    
    final response = await http.patch(
      Uri.parse('$baseUrl/inventarios/$inventarioId/cerrar'),
      headers: _headers,
    );

    _log('INVENTARIO: Status Code: ${response.statusCode}');
    _log('INVENTARIO: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final inventario = Inventario.fromJson(data['inventario'] ?? data);
      _logSuccess('INVENTARIO: Cerrado exitosamente');
      return inventario;
    } else {
      _logError('INVENTARIO: Error ${response.statusCode}: ${response.body}');
      throw Exception('Error al cerrar inventario');
    }
  }

  /// Obtener resultados del inventario
  Future<ResultadoInventario> getResultadosInventario(int inventarioId) async {
    _log('INVENTARIO: Obteniendo resultados del inventario $inventarioId');
    
    final response = await http.get(
      Uri.parse('$baseUrl/inventarios/$inventarioId/resultados'),
      headers: _headers,
    );

    _log('INVENTARIO: Status Code: ${response.statusCode}');
    _log('INVENTARIO: Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final resultado = ResultadoInventario.fromJson(jsonDecode(response.body));
      _logSuccess('INVENTARIO: Resultados obtenidos - Encontrados: ${resultado.estadisticas.encontrados}');
      return resultado;
    } else {
      _logError('INVENTARIO: Error ${response.statusCode}');
      throw Exception('Error al obtener resultados del inventario');
    }
  }

  // ==================== LECTORES RFID (Opcional) ====================

  /// Registrar lector RFID
  Future<Map<String, dynamic>> registrarLector({
    required String nombre,
    required String macAddress,
    String? modelo,
    int? empresaId,
  }) async {
    _log('RFID_READER: Registrando lector $nombre');
    
    final body = {
      'nombre': nombre,
      'mac_address': macAddress,
      if (modelo != null) 'modelo': modelo,
      if (empresaId != null) 'empresa_id': empresaId,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/rfid-readers'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      _logSuccess('RFID_READER: Lector registrado exitosamente');
      return jsonDecode(response.body);
    } else {
      _logError('RFID_READER: Error ${response.statusCode}');
      throw Exception('Error al registrar lector');
    }
  }

  /// Enviar heartbeat del lector
  Future<void> enviarHeartbeat(int readerId) async {
    await http.post(
      Uri.parse('$baseUrl/rfid-readers/heartbeat'),
      headers: _headers,
      body: jsonEncode({'reader_id': readerId}),
    );
  }

  // ==================== RFID SCANS (Legacy) ====================

  /// Buscar activo por RFID UID
  Future<Activo> searchActivoByRfid(String rfidUid) async {
    _log('RFID: Buscando activo por RFID: $rfidUid');
    
    final response = await http.get(
      Uri.parse('$baseUrl/activos/por-rfid/$rfidUid'),
      headers: _headers,
    );

    _log('RFID: Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final activo = Activo.fromJson(jsonDecode(response.body));
      _logSuccess('RFID: Activo encontrado: ${activo.codigoInterno}');
      return activo;
    } else if (response.statusCode == 404) {
      _logError('RFID: Activo no encontrado con RFID: $rfidUid');
      throw Exception('Activo no encontrado');
    } else {
      _logError('RFID: Error ${response.statusCode}');
      throw Exception('Error al buscar activo por RFID');
    }
  }
}
