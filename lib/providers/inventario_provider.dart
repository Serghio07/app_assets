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

  // ✅ REMOVIDO: Set<String> _tagsUnicos - El backend maneja duplicados

  // Getters
  Inventario? get inventarioActual => _inventarioActual;
  List<LecturaRfid> get lecturas => _lecturas;
  List<Activo>? get activosPendientes => _activosPendientes;
  ResultadoInventario? get resultados => _resultados;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  /// ⚠️ DEPRECADO: Usa procesarRfid() en api_service directamente
  /// Enviar una lectura RFID individual (sin validación local)
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

    // ✅ SIMPLIFICADO: Envía siempre al backend
    // El backend decide si es duplicado o nuevo
    try {
      final lectura = await _apiService.enviarLecturaRfid(
        inventarioId: _inventarioActual!.id,
        rfidUid: rfidUid,
        tid: tid,
        rssi: rssi,
        antennaId: antennaId,
        usuarioId: usuarioId,
      );

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

  /// ⚠️ DEPRECADO: Usa procesarRfid() para cada tag individualmente
  /// Enviar lecturas RFID en batch (sin filtrado local)
  Future<BatchResult?> enviarLecturasBatch(List<RfidTag> tags, {int? usuarioId}) async {
    if (_inventarioActual == null) {
      throw Exception('No hay inventario activo');
    }

    if (tags.isEmpty) {
      debugPrint('⚠️ [INVENTARIO PROVIDER] Batch vacío');
      return null;
    }

    // ✅ SIMPLIFICADO: Envía todos los tags al backend
    // El backend deduplica automáticamente
    try {
      final resultado = await _apiService.enviarLecturasBatch(
        inventarioId: _inventarioActual!.id,
        lecturas: tags,
        usuarioId: usuarioId,
      );

      // Crear LecturaRfid locales para mostrar en UI
      for (var tag in tags) {
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
