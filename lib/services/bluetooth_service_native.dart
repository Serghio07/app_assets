import 'dart:async';
import 'package:flutter/services.dart';

/// Implementación nativa para Android
/// Usa MethodChannel para comunicarse con código nativo de Android
/// Por ahora es un stub que se puede expandir con código Kotlin
class BluetoothServicePlatform {
  static const MethodChannel _channel = MethodChannel('com.app_assets/bluetooth');
  
  // Estado simulado (sin dependencia externa problemática)
  bool _isEnabled = false;
  final List<Map<String, String>> _mockDevices = [
    {'name': 'BTR-001', 'address': 'AA:BB:CC:DD:EE:01'},
    {'name': 'BTR-002', 'address': 'AA:BB:CC:DD:EE:02'},
  ];
  
  bool get isSupported => true;
  
  Future<bool> isBluetoothEnabled() async {
    try {
      // Intentar usar canal nativo primero
      final bool result = await _channel.invokeMethod('isEnabled');
      _isEnabled = result;
      return result;
    } on MissingPluginException {
      // Si no hay plugin nativo, simular
      return _isEnabled;
    } catch (e) {
      return _isEnabled;
    }
  }
  
  Future<bool> requestEnableBluetooth() async {
    try {
      final bool result = await _channel.invokeMethod('requestEnable');
      _isEnabled = result;
      return result;
    } on MissingPluginException {
      // Simular habilitación
      _isEnabled = true;
      return true;
    } catch (e) {
      _isEnabled = true;
      return true;
    }
  }
  
  Future<List<Map<String, String>>> getPairedDevices() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getPairedDevices');
      return result.map((d) => Map<String, String>.from(d)).toList();
    } on MissingPluginException {
      // Retornar dispositivos mock para desarrollo
      return _mockDevices;
    } catch (e) {
      return _mockDevices;
    }
  }
  
  Future<bool> connect(String address, Function(String) onDataReceived) async {
    try {
      // Configurar listener para datos recibidos
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onDataReceived') {
          final String data = call.arguments as String;
          onDataReceived(data);
        }
      });
      
      final bool result = await _channel.invokeMethod('connect', {'address': address});
      return result;
    } on MissingPluginException {
      // Simular conexión exitosa
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> send(String data) async {
    try {
      await _channel.invokeMethod('send', {'data': data});
    } catch (e) {
      // Ignorar errores de envío
    }
  }
  
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
    } catch (e) {
      // Ignorar errores de desconexión
    }
  }
}
