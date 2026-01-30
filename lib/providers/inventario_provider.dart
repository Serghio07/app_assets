import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class InventarioProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Inventario? _inventarioActual;
  List<LecturaRfid> _lecturas = [];
  List<Activo>? _activosPendientes;
  ResultadoInventario? _resultados;
  bool _isLoading = false;
  String? _error;

  // Set para controlar tags únicos
  final Set<String> _tagsUnicos = {};

  // Getters
  Inventario? get inventarioActual => _inventarioActual;
  List<LecturaRfid> get lecturas => _lecturas;
  List<Activo>? get activosPendientes => _activosPendientes;
  ResultadoInventario? get resultados => _resultados;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get tagsUnicos => _tagsUnicos.length;

  /// Crear un nuevo inventario
  Future<Inventario> createInventario({
    required int empresaId,
    required int ubicacionId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final inventario = await _apiService.crearInventario(
        empresaId: empresaId,
        ubicacionId: ubicacionId,
      );
      _inventarioActual = inventario;
      _lecturas = [];
      _tagsUnicos.clear();
      _resultados = null;
      debugPrint('🟢 [INVENTARIO PROVIDER] Inventario creado: ${inventario.id}');
      notifyListeners();
      return inventario;
    } catch (e) {
      _error = e.toString();
      debugPrint('🔴 [INVENTARIO PROVIDER] Error: $_error');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar un inventario existente por ID
  Future<void> loadInventario(int inventarioId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final inventario = await _apiService.getInventario(inventarioId);
      _inventarioActual = inventario;
      debugPrint('🟢 [INVENTARIO PROVIDER] Inventario cargado: ${inventario.id}');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('🔴 [INVENTARIO PROVIDER] Error al cargar inventario: $_error');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enviar una lectura RFID individual
  Future<LecturaRfid?> enviarLectura({
    required String rfidUid,
    String? tid,
    int? rssi,
    int? antennaId,
    int? usuarioId,
  }) async {
    if (_inventarioActual == null) {
      throw Exception('No hay inventario activo');
    }

    // Verificar si ya se leyó este tag
    if (_tagsUnicos.contains(rfidUid)) {
      debugPrint('⚠️ [INVENTARIO PROVIDER] Tag ya leído: $rfidUid');
      return null;
    }

    try {
      final lectura = await _apiService.enviarLecturaRfid(
        inventarioId: _inventarioActual!.id,
        rfidUid: rfidUid,
        tid: tid,
        rssi: rssi,
        antennaId: antennaId,
        usuarioId: usuarioId,
      );

      _tagsUnicos.add(rfidUid);
      _lecturas.add(lectura);

      debugPrint('🟢 [INVENTARIO PROVIDER] Lectura enviada: $rfidUid');
      notifyListeners();
      return lectura;
    } catch (e) {
      _error = e.toString();
      debugPrint('🔴 [INVENTARIO PROVIDER] Error al enviar lectura: $_error');
      // No rethrow para no interrumpir el escaneo
      return null;
    }
  }

  /// Enviar lecturas RFID en batch (usa RfidTag)
  Future<BatchResult?> enviarLecturasBatch(List<RfidTag> tags, {int? usuarioId}) async {
    if (_inventarioActual == null) {
      throw Exception('No hay inventario activo');
    }

    // Filtrar solo lecturas nuevas
    final tagsNuevos = tags.where((t) => !_tagsUnicos.contains(t.epc)).toList();
    
    if (tagsNuevos.isEmpty) {
      debugPrint('⚠️ [INVENTARIO PROVIDER] No hay lecturas nuevas en el batch');
      return null;
    }

    try {
      final resultado = await _apiService.enviarLecturasBatch(
        inventarioId: _inventarioActual!.id,
        lecturas: tagsNuevos,
        usuarioId: usuarioId,
      );

      // Agregar a tags únicos y crear LecturaRfid locales
      for (var tag in tagsNuevos) {
        _tagsUnicos.add(tag.epc);
        _lecturas.add(LecturaRfid(
          id: 0,
          inventarioId: _inventarioActual!.id,
          rfidUid: tag.epc,
          tid: tag.tid,
          rssi: tag.rssi,
          antennaId: tag.antenna,
          fechaLectura: tag.timestamp,
        ));
      }

      debugPrint('🟢 [INVENTARIO PROVIDER] Batch enviado: ${resultado.nuevas} nuevas, ${resultado.actualizadas} actualizadas');
      notifyListeners();
      return resultado;
    } catch (e) {
      _error = e.toString();
      debugPrint('🔴 [INVENTARIO PROVIDER] Error al enviar batch: $_error');
      rethrow;
    }
  }

  /// Cerrar inventario
  Future<Inventario> cerrarInventario() async {
    if (_inventarioActual == null) {
      throw Exception('No hay inventario activo');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final inventario = await _apiService.cerrarInventario(_inventarioActual!.id);
      _inventarioActual = inventario;
      debugPrint('🟢 [INVENTARIO PROVIDER] Inventario cerrado: ${inventario.id}');
      notifyListeners();
      return inventario;
    } catch (e) {
      _error = e.toString();
      debugPrint('🔴 [INVENTARIO PROVIDER] Error al cerrar inventario: $_error');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtener resultados del inventario
  Future<ResultadoInventario> obtenerResultados() async {
    if (_inventarioActual == null) {
      throw Exception('No hay inventario activo');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final resultados = await _apiService.getResultadosInventario(_inventarioActual!.id);
      _resultados = resultados;
      debugPrint('🟢 [INVENTARIO PROVIDER] Resultados obtenidos');
      notifyListeners();
      return resultados;
    } catch (e) {
      _error = e.toString();
      debugPrint('🔴 [INVENTARIO PROVIDER] Error al obtener resultados: $_error');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Establecer activos pendientes
  void setActivosPendientes(List<Activo> activos) {
    _activosPendientes = List.from(activos);
    notifyListeners();
  }

  /// Obtener activos pendientes
  List<Activo> getActivosPendientes() {
    return _activosPendientes ?? [];
  }

  /// Obtener porcentaje de progreso basado en resultados
  double getProgreso() {
    if (_resultados == null) return 0;
    return _resultados!.estadisticas.porcentajeEncontrados;
  }

  /// Limpiar inventario actual
  void clearInventario() {
    _inventarioActual = null;
    _lecturas = [];
    _tagsUnicos.clear();
    _activosPendientes = null;
    _resultados = null;
    _error = null;
    notifyListeners();
  }

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
