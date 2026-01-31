import 'dart:async';
import 'package:flutter/foundation.dart';

// Importación condicional para Bluetooth (solo Android)
import 'bluetooth_service_stub.dart'
    if (dart.library.io) 'bluetooth_service_native.dart';

/// Servicio de Bluetooth para conectar con lectores BTR RFID
/// Este servicio proporciona una interfaz unificada para conexión Bluetooth Classic
class BluetoothService extends ChangeNotifier {
  final BluetoothServicePlatform _platform = BluetoothServicePlatform();
  
  // Stream para recibir datos RFID
  final StreamController<String> _rfidController = StreamController<String>.broadcast();
  Stream<String> get rfidStream => _rfidController.stream;
  
  // Estado
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _lastError;
  String? _connectedDeviceName;
  String? _connectedDeviceAddress;
  List<Map<String, String>> _pairedDevices = [];
  
  // Getters
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  String? get lastError => _lastError;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceAddress => _connectedDeviceAddress;
  List<Map<String, String>> get pairedDevices => _pairedDevices;
  
  /// Verificar si la plataforma soporta Bluetooth
  bool get isPlatformSupported => _platform.isSupported;
  
  /// Verificar si Bluetooth está habilitado
  Future<bool> isBluetoothEnabled() async {
    if (!_platform.isSupported) return false;
    return await _platform.isBluetoothEnabled();
  }
  
  /// Solicitar habilitar Bluetooth
  Future<bool> requestEnableBluetooth() async {
    if (!_platform.isSupported) return false;
    return await _platform.requestEnableBluetooth();
  }
  
  /// Obtener dispositivos emparejados
  Future<List<Map<String, String>>> getPairedDevices() async {
    if (!_platform.isSupported) {
      _lastError = 'Bluetooth no soportado en esta plataforma';
      notifyListeners();
      return [];
    }
    
    try {
      _pairedDevices = await _platform.getPairedDevices();
      notifyListeners();
      return _pairedDevices;
    } catch (e) {
      _lastError = 'Error al obtener dispositivos: $e';
      notifyListeners();
      return [];
    }
  }
  
  /// Filtrar dispositivos BTR
  List<Map<String, String>> getBtrDevices() {
    return _pairedDevices.where((d) => 
      (d['name'] ?? '').toUpperCase().startsWith('BTR')
    ).toList();
  }
  
  /// Conectar a un dispositivo
  Future<bool> connectToDevice(String address, String name) async {
    if (_isConnecting) return false;
    if (!_platform.isSupported) {
      _lastError = 'Bluetooth no soportado en esta plataforma';
      notifyListeners();
      return false;
    }
    
    _isConnecting = true;
    _lastError = null;
    notifyListeners();
    
    try {
      await disconnect();
      
      debugPrint('🔵 [BLUETOOTH] Conectando a $name...');
      
      final success = await _platform.connect(address, (String data) {
        // Callback para datos recibidos
        debugPrint('🔵 [BLUETOOTH] RFID Recibido: $data');
        _rfidController.add(data);
      });
      
      if (success) {
        _connectedDeviceName = name;
        _connectedDeviceAddress = address;
        _isConnected = true;
        debugPrint('🟢 [BLUETOOTH] Conectado a $name');
      } else {
        _lastError = 'No se pudo conectar';
        debugPrint('🔴 [BLUETOOTH] Error de conexión');
      }
      
      _isConnecting = false;
      notifyListeners();
      return success;
    } catch (e) {
      _lastError = 'Error de conexión: $e';
      _isConnecting = false;
      _isConnected = false;
      _connectedDeviceName = null;
      _connectedDeviceAddress = null;
      debugPrint('🔴 [BLUETOOTH] Error: $_lastError');
      notifyListeners();
      return false;
    }
  }
  
  /// Enviar comando al dispositivo
  Future<bool> sendCommand(String command) async {
    if (!_isConnected || !_platform.isSupported) return false;
    
    try {
      await _platform.send(command + '\r\n');
      debugPrint('🔵 [BLUETOOTH] Comando enviado: $command');
      return true;
    } catch (e) {
      _lastError = 'Error al enviar: $e';
      debugPrint('🔴 [BLUETOOTH] $_lastError');
      return false;
    }
  }
  
  /// Desconectar
  Future<void> disconnect() async {
    try {
      await _platform.disconnect();
      _connectedDeviceName = null;
      _connectedDeviceAddress = null;
      _isConnected = false;
      _isConnecting = false;
      debugPrint('🔵 [BLUETOOTH] Desconectado');
      notifyListeners();
    } catch (e) {
      debugPrint('🔴 [BLUETOOTH] Error al desconectar: $e');
    }
  }
  
  @override
  void dispose() {
    _rfidController.close();
    disconnect();
    super.dispose();
  }
}

