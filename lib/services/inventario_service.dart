import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/inventario.dart';
import '../models/rfid_tag.dart';
import 'api_service.dart';

/// Servicio especializado para gestión de inventarios RFID
/// Maneja la comunicación con los endpoints del backend
class InventarioService extends ChangeNotifier {
  final ApiService _api;
  
  // Estado del inventario activo
  Inventario? _inventarioActivo;
  final List<RfidTag> _tagsLeidos = [];
  bool _isLoading = false;
  String? _lastError;
  
  // ✅ REMOVIDO: Set<String> _tagsUnicos - El backend maneja duplicados
  
  // Getters
  Inventario? get inventarioActivo => _inventarioActivo;
  List<RfidTag> get tagsLeidos => List.unmodifiable(_tagsLeidos);
  int get totalTagsUnicos => _tagsLeidos.length; // Contador de UI solamente
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get tieneInventarioActivo => _inventarioActivo != null && _inventarioActivo!.estaAbierto;

  InventarioService(this._api);

  void _log(String message) {
    debugPrint('📦 [INVENTARIO_SERVICE] $message');
  }

  void _logError(String message) {
    debugPrint('🔴 [INVENTARIO_SERVICE ERROR] $message');
  }

  /// Crear un nuevo inventario
  Future<Inventario> crearInventario({
    required int empresaId,
    required int ubicacionId,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      _log('Creando inventario - Empresa: $empresaId, Ubicación: $ubicacionId');
      
      final inventario = await _api.crearInventario(
        empresaId: empresaId,
        ubicacionId: ubicacionId,
      );
      
      // Inicializar estado
      _inventarioActivo = inventario;
      _tagsLeidos.clear();
      
      _log('Inventario creado con ID: ${inventario.id}');
      _isLoading = false;
      notifyListeners();
      return inventario;
    } catch (e) {
      _lastError = 'Error al crear inventario: $e';
      _logError(_lastError!);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Cargar un inventario existente
  Future<Inventario> cargarInventario(int inventarioId) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      _log('Cargando inventario ID: $inventarioId');
      
      final inventario = await _api.getInventario(inventarioId);
      
      _inventarioActivo = inventario;
      
      // Cargar tags ya leídos (solo para UI)
      _tagsLeidos.clear();
      for (final lectura in inventario.lecturas) {
        _tagsLeidos.add(RfidTag(
          epc: lectura.rfidUid,
          tid: lectura.tid,
          rssi: lectura.rssi ?? -50,
          antenna: lectura.antennaId ?? 1,
          timestamp: lectura.fechaLectura,
          readCount: lectura.cantidadLecturas,
        ));
      }
      
      _log('Inventario cargado - ${_tagsLeidos.length} tags previos');
      _isLoading = false;
      notifyListeners();
      return inventario;
    } catch (e) {
      _lastError = 'Error al cargar inventario: $e';
      _logError(_lastError!);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// ⚠️ DEPRECADO: Usa procesarRfid() en api_service directamente
  /// Enviar una lectura RFID al backend (sin validación local)
  Future<LecturaRfid?> enviarLectura({
    required RfidTag tag,
    int? usuarioId,
  }) async {
    if (_inventarioActivo == null) {
      _lastError = 'No hay inventario activo';
      notifyListeners();
      return null;
    }

    try {
      // ✅ SIMPLIFICADO: Siempre envía al backend
      // El backend decide si es nuevo o duplicado
      _log('Enviando lectura: ${tag.epc}');
      
      final lectura = await _api.enviarLecturaRfid(
        inventarioId: _inventarioActivo!.id,
        rfidUid: tag.epc,
        tid: tag.tid,
        rssi: tag.rssi,
        antennaId: tag.antenna,
        usuarioId: usuarioId,
      );
      
      // Agregar a lista local para UI
      _tagsLeidos.insert(0, tag);
      
      notifyListeners();
      return lectura;
    } catch (e) {
      _logError('Error enviando lectura: $e');
      // No propagar error para no interrumpir el escaneo
      return null;
    }
  }

  /// ⚠️ DEPRECADO: Usa procesarRfid() para cada tag
  /// Enviar múltiples lecturas en batch (sin filtrado local)
  Future<BatchResult?> enviarLecturasBatch({
    required List<RfidTag> tags,
    int? usuarioId,
    int? readerId,
  }) async {
    if (_inventarioActivo == null) {
      _lastError = 'No hay inventario activo';
      notifyListeners();
      return null;
    }

    if (tags.isEmpty) return null;

    try {
      _log('Enviando batch de ${tags.length} lecturas');
      
      // ✅ SIMPLIFICADO: Envía todos al backend sin filtrar
      final result = await _api.enviarLecturasBatch(
        inventarioId: _inventarioActivo!.id,
        lecturas: tags,
        usuarioId: usuarioId,
        readerId: readerId,
      );
      
      // Actualizar estado local para UI
      for (final tag in tags) {
        _tagsLeidos.insert(0, tag);
      }
      
      _log('Batch completado - Nuevas: ${result.nuevas}, Actualizadas: ${result.actualizadas}');
      notifyListeners();
      return result;
    } catch (e) {
      _logError('Error en batch: $e');
      return null;
    }
  }

  /// ⚠️ DEPRECADO: No usar - escaneo_screen.dart llama directamente a procesarRfid()
  /// Procesar un tag recibido del lector Bluetooth
  Future<void> procesarTagBluetooth(RfidTag tag, {int? usuarioId}) async {
    if (_inventarioActivo == null) return;

    // ✅ SIMPLIFICADO: Siempre envía al backend
    await enviarLectura(tag: tag, usuarioId: usuarioId);
  }

  /// Cerrar el inventario actual
  Future<Inventario?> cerrarInventario() async {
    if (_inventarioActivo == null) {
      _lastError = 'No hay inventario activo';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _log('Cerrando inventario ID: ${_inventarioActivo!.id}');
      
      final inventarioCerrado = await _api.cerrarInventario(_inventarioActivo!.id);
      
      _inventarioActivo = inventarioCerrado;
      
      _log('Inventario cerrado exitosamente');
      _isLoading = false;
      notifyListeners();
      return inventarioCerrado;
    } catch (e) {
      _lastError = 'Error al cerrar inventario: $e';
      _logError(_lastError!);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Obtener los resultados del inventario
  Future<ResultadoInventario> obtenerResultados([int? inventarioId]) async {
    final id = inventarioId ?? _inventarioActivo?.id;
    if (id == null) {
      throw Exception('No hay inventario especificado');
    }

    _isLoading = true;
    notifyListeners();

    try {
      _log('Obteniendo resultados del inventario ID: $id');
      
      final resultados = await _api.getResultadosInventario(id);
      
      _log('Resultados obtenidos - Encontrados: ${resultados.estadisticas.encontrados}, '
           'Faltantes: ${resultados.estadisticas.faltantes}, '
           'Sobrantes: ${resultados.estadisticas.sobrantes}');
      
      _isLoading = false;
      notifyListeners();
      return resultados;
    } catch (e) {
      _lastError = 'Error al obtener resultados: $e';
      _logError(_lastError!);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Listar inventarios
  Future<List<Inventario>> listarInventarios({
    int? empresaId,
    int? ubicacionId,
    String? estado,
  }) async {
    try {
      return await _api.getInventarios(
        empresaId: empresaId,
        ubicacionId: ubicacionId,
        estado: estado,
      );
    } catch (e) {
      _logError('Error listando inventarios: $e');
      rethrow;
    }
  }

  /// Limpiar el estado actual
  void limpiarEstado() {
    _inventarioActivo = null;
    _tagsLeidos.clear();
    _lastError = null;
    notifyListeners();
  }

  /// Cancelar inventario sin guardar
  void cancelarInventario() {
    _log('Inventario cancelado');
    limpiarEstado();
  }
}
