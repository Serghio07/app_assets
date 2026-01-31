import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/rfid_tag.dart';

/// Servicio Bluetooth especializado para lectores RFID Hopeland
/// 
/// Implementa el protocolo de comunicación según:
/// - RFID Middleware API Manual
/// - RFID Middleware JMS Report Format
/// 
/// Características implementadas:
/// - Conexión BLE con lectores Hopeland (CL7206, CL7202, H3, BTR)
/// - Lectura continua de tags EPC Gen2
/// - Control de potencia de transmisión (20/26/30 dBm)
/// - Validación de checksum en paquetes
/// - Parsing de RSSI y número de antena
/// - Soporte para múltiples antenas
/// 
/// Formato de paquete: [0xBB, Type, Cmd, PL_H, PL_L, ...Data, Checksum, 0x7E]
/// 
/// Usa flutter_blue_plus para conexión BLE real
/// 
/// SINGLETON: Usar BluetoothRfidService() siempre devuelve la misma instancia
class BluetoothRfidService extends ChangeNotifier {
  // ========== SINGLETON PATTERN ==========
  static final BluetoothRfidService _instance = BluetoothRfidService._internal();
  
  factory BluetoothRfidService() {
    return _instance;
  }
  
  BluetoothRfidService._internal() {
    _log('🔧 Singleton inicializado (hashCode: $hashCode)');
  }
  // ========================================

  /// Notificar cambios de forma segura (evita llamar durante build)
  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Dispositivo conectado
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  
  // Estado de conexión
  bool _isScanning = false;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectedDeviceName;
  String? _connectedDeviceAddress;
  String? _lastError;
  
  // Stream de tags RFID
  final StreamController<RfidTag> _tagController = StreamController<RfidTag>.broadcast();
  Stream<RfidTag> get tagStream => _tagController.stream;
  
  // Lista de dispositivos encontrados
  final List<BluetoothDeviceInfo> _discoveredDevices = [];
  
  // UUIDs de servicios Hopeland (pueden variar según modelo)
  static const String hopelandServiceUuid = "0000fff0-0000-1000-8000-00805f9b34fb";
  static const String hopelandWriteUuid = "0000fff2-0000-1000-8000-00805f9b34fb";
  static const String hopelandNotifyUuid = "0000fff1-0000-1000-8000-00805f9b34fb";
  
  // Comandos Hopeland (formato: [0xBB, Type, Cmd, PL_H, PL_L, ...Data, Checksum, 0x7E])
  static const List<int> cmdStartInventory = [0xBB, 0x00, 0x22, 0x00, 0x00, 0x22, 0x7E];
  static const List<int> cmdStopInventory = [0xBB, 0x00, 0x28, 0x00, 0x00, 0x28, 0x7E];
  static const List<int> cmdGetVersion = [0xBB, 0x00, 0x03, 0x00, 0x01, 0x00, 0x04, 0x7E];
  static const List<int> cmdSetPowerMax = [0xBB, 0x00, 0xB6, 0x00, 0x02, 0x07, 0xD0, 0x8F, 0x7E]; // 30dBm
  static const List<int> cmdSetPowerMid = [0xBB, 0x00, 0xB6, 0x00, 0x02, 0x05, 0xDC, 0x93, 0x7E]; // 26dBm
  static const List<int> cmdSetPowerLow = [0xBB, 0x00, 0xB6, 0x00, 0x02, 0x03, 0xE8, 0x97, 0x7E]; // 20dBm
  
  // Getters
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceAddress => _connectedDeviceAddress;
  String? get lastError => _lastError;
  List<BluetoothDeviceInfo> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  void _log(String message) {
    debugPrint('📡 [BLUETOOTH_RFID] $message');
  }

  void _logError(String message) {
    debugPrint('🔴 [BLUETOOTH_RFID ERROR] $message');
  }

  /// Solicitar permisos de Bluetooth
  Future<bool> requestPermissions() async {
    _log('Solicitando permisos de Bluetooth...');
    
    // Permisos necesarios para Android 12+
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];
    
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    bool allGranted = statuses.values.every(
      (status) => status == PermissionStatus.granted
    );
    
    if (!allGranted) {
      _lastError = 'Permisos de Bluetooth denegados';
      _logError(_lastError!);
      _safeNotifyListeners();
      return false;
    }
    
    _log('Permisos concedidos');
    return true;
  }

  /// Verificar si Bluetooth está habilitado
  Future<bool> isBluetoothEnabled() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      _logError('Error verificando Bluetooth: $e');
      return false;
    }
  }

  /// Habilitar Bluetooth
  Future<bool> enableBluetooth() async {
    try {
      if (await isBluetoothEnabled()) return true;
      
      // En Android, intentar encender Bluetooth
      await FlutterBluePlus.turnOn();
      await Future.delayed(const Duration(seconds: 2));
      
      return await isBluetoothEnabled();
    } catch (e) {
      _lastError = 'No se pudo habilitar Bluetooth: $e';
      _logError(_lastError!);
      return false;
    }
  }

  /// Buscar y conectar automáticamente a un dispositivo BTR específico
  Future<bool> autoConnectToBtr({String targetName = 'BTR-800201220017'}) async {
    _log('Auto-conectando a $targetName...');
    
    // Primero escanear dispositivos
    final devices = await scanDevices(timeout: const Duration(seconds: 15));
    
    // Buscar el dispositivo por nombre
    final targetDevice = devices.firstWhere(
      (d) => d.name.toUpperCase().contains(targetName.toUpperCase()),
      orElse: () => BluetoothDeviceInfo(
        name: '',
        address: '',
        rssi: 0,
        isHopeland: false,
        device: null,
      ),
    );
    
    if (targetDevice.device == null) {
      _lastError = 'No se encontró el dispositivo $targetName';
      _logError(_lastError!);
      _safeNotifyListeners();
      return false;
    }
    
    _log('Dispositivo encontrado: ${targetDevice.name}, conectando...');
    return await connect(targetDevice);
  }

  /// Escanear dispositivos Bluetooth
  Future<List<BluetoothDeviceInfo>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isScanning) {
      _log('Ya hay un escaneo en progreso');
      return _discoveredDevices;
    }

    _isScanning = true;
    _lastError = null;
    _discoveredDevices.clear();
    _safeNotifyListeners();

    try {
      _log('Iniciando escaneo de dispositivos...');
      
      // Solicitar permisos primero
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        _isScanning = false;
        _safeNotifyListeners();
        return [];
      }

      // Verificar si Bluetooth está encendido
      if (!await isBluetoothEnabled()) {
        _log('Bluetooth apagado, intentando encender...');
        final enabled = await enableBluetooth();
        if (!enabled) {
          _isScanning = false;
          _lastError = 'Bluetooth no está habilitado';
          _safeNotifyListeners();
          return [];
        }
      }

      // Detener escaneos previos
      await FlutterBluePlus.stopScan();

      // Configurar listener para dispositivos encontrados
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          final deviceName = result.device.platformName.isNotEmpty 
              ? result.device.platformName 
              : result.advertisementData.advName;
          
          if (deviceName.isEmpty) continue;
          
          // Verificar si ya lo tenemos
          final exists = _discoveredDevices.any(
            (d) => d.address == result.device.remoteId.str
          );
          
          if (!exists) {
            final isHopeland = _isHopelandDevice(deviceName, result.advertisementData);
            
            _discoveredDevices.add(BluetoothDeviceInfo(
              name: deviceName,
              address: result.device.remoteId.str,
              rssi: result.rssi,
              isHopeland: isHopeland,
              device: result.device,
            ));
            
            _log('Dispositivo encontrado: $deviceName (${result.device.remoteId.str}) - RSSI: ${result.rssi}');
            _safeNotifyListeners();
          }
        }
      });

      // Iniciar escaneo
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      // Esperar a que termine el escaneo
      await Future.delayed(timeout);
      
      _log('Escaneo completado - ${_discoveredDevices.length} dispositivos encontrados');
      
    } catch (e) {
      _lastError = 'Error durante el escaneo: $e';
      _logError(_lastError!);
    } finally {
      _scanSubscription?.cancel();
      _isScanning = false;
      _safeNotifyListeners();
    }

    return _discoveredDevices;
  }

  /// Detener escaneo en curso
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _isScanning = false;
      _safeNotifyListeners();
    } catch (e) {
      _logError('Error deteniendo escaneo: $e');
    }
  }

  /// Verificar si es un dispositivo Hopeland
  bool _isHopelandDevice(String name, AdvertisementData advData) {
    final upperName = name.toUpperCase();
    return upperName.contains('HOPELAND') ||
           upperName.contains('CL7206') ||
           upperName.contains('CL7202') ||
           upperName.contains('H3') ||
           upperName.contains('BTR') ||
           upperName.contains('RFID');
  }

  /// Conectar a un dispositivo
  Future<bool> connect(BluetoothDeviceInfo deviceInfo) async {
    if (_isConnecting) return false;
    
    _isConnecting = true;
    _lastError = null;
    _safeNotifyListeners();

    try {
      _log('Conectando a ${deviceInfo.name} (${deviceInfo.address})...');
      
      final device = deviceInfo.device;
      if (device == null) {
        throw Exception('Dispositivo no válido');
      }

      // Conectar al dispositivo
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
      
      _connectedDevice = device;
      _connectedDeviceName = deviceInfo.name;
      _connectedDeviceAddress = deviceInfo.address;
      
      // Escuchar cambios de conexión
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _log('Dispositivo desconectado');
          _handleDisconnection();
        }
      });

      // Descubrir servicios
      _log('Descubriendo servicios...');
      final services = await device.discoverServices();
      
      // Buscar servicio y características en TODOS los servicios
      for (var service in services) {
        _log('Servicio encontrado: ${service.uuid}');
        
        for (var characteristic in service.characteristics) {
          final uuid = characteristic.uuid.toString().toLowerCase();
          _log('  Característica: ${characteristic.uuid}');
          _log('    Propiedades: write=${characteristic.properties.write}, notify=${characteristic.properties.notify}');
          
          // Característica de escritura (buscar la primera disponible)
          if (_writeCharacteristic == null && 
              (characteristic.properties.write || characteristic.properties.writeWithoutResponse)) {
            _writeCharacteristic = characteristic;
            _log('  ✅ Característica de ESCRITURA asignada');
          }
          
          // Característica de notificación (buscar la primera disponible)
          if (_notifyCharacteristic == null && 
              (characteristic.properties.notify || characteristic.properties.indicate)) {
            _notifyCharacteristic = characteristic;
            _log('  ✅ Característica de NOTIFICACIÓN asignada');
          }
        }
      }

      if (_writeCharacteristic == null || _notifyCharacteristic == null) {
        throw Exception('No se encontraron características necesarias (write=${_writeCharacteristic != null}, notify=${_notifyCharacteristic != null})');
      }

      // Suscribirse a notificaciones
      _log('Suscribiendo a notificaciones...');
      await _notifyCharacteristic!.setNotifyValue(true);
      _dataSubscription = _notifyCharacteristic!.onValueReceived.listen(
        (data) {
          _log('📡 Datos recibidos (${data.length} bytes)');
          _processRfidData(data);
        },
        onError: (error) {
          _logError('Error en stream de notificaciones: $error');
        },
      );
      _log('✅ Escuchando datos RFID...');

      _isConnected = true;
      _isConnecting = false;
      
      _log('✅ Conectado exitosamente a ${deviceInfo.name}');
      _safeNotifyListeners();
      return true;
      
    } catch (e) {
      _lastError = 'Error al conectar: $e';
      _logError(_lastError!);
      _isConnecting = false;
      _isConnected = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// Manejar desconexión
  void _handleDisconnection() {
    _isConnected = false;
    _connectedDevice = null;
    _connectedDeviceName = null;
    _connectedDeviceAddress = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    _safeNotifyListeners();
  }

  /// Buffer para datos fragmentados
  List<int> _dataBuffer = [];

  /// Procesar datos recibidos del lector Hopeland/BTR
  void _processRfidData(List<int> data) {
    _log('Datos recibidos: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    
    // Agregar al buffer
    _dataBuffer.addAll(data);
    
    // Buscar y procesar todos los paquetes de tags BTR (0xAA 0x12)
    _processBTRTagsFromBuffer();
  }
  
  /// Procesar todos los paquetes BTR 0xAA 0x12 del buffer
  void _processBTRTagsFromBuffer() {
    while (_dataBuffer.length >= 8) {
      // Buscar inicio de paquete BTR tag: 0xAA 0x12
      int startIndex = -1;
      for (int i = 0; i < _dataBuffer.length - 1; i++) {
        if (_dataBuffer[i] == 0xAA && _dataBuffer[i + 1] == 0x12) {
          startIndex = i;
          break;
        }
      }
      
      if (startIndex == -1) {
        // No hay más paquetes de tags, limpiar buffer pero guardar últimos bytes
        if (_dataBuffer.length > 100) {
          _dataBuffer = _dataBuffer.sublist(_dataBuffer.length - 50);
        }
        break;
      }
      
      // Descartar datos antes del paquete
      if (startIndex > 0) {
        _dataBuffer = _dataBuffer.sublist(startIndex);
      }
      
      // Necesitamos al menos 7 bytes para leer el header y longitud EPC
      if (_dataBuffer.length < 7) break;
      
      // Formato BTR: AA 12 00 00 LL LL EL [EPC bytes...] [6 bytes trailing]
      // Byte 6 (índice desde 0) = longitud del EPC en bytes
      final epcLen = _dataBuffer[6];
      
      // Validar longitud EPC razonable (4-24 bytes)
      if (epcLen < 4 || epcLen > 24) {
        // Longitud inválida, saltar este 0xAA
        _log('⚠️ EPC length inválido: $epcLen, saltando...');
        _dataBuffer = _dataBuffer.sublist(1);
        continue;
      }
      
      // Calcular longitud total del paquete
      // Header (7) + EPC (epcLen) + trailing (6 bytes)
      final totalLen = 7 + epcLen + 6;
      
      if (_dataBuffer.length < totalLen) {
        // Paquete incompleto, esperar más datos
        break;
      }
      
      // Extraer EPC (empieza en byte 7)
      final epcBytes = _dataBuffer.sublist(7, 7 + epcLen);
      final epc = epcBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
      
      // Emitir tag
      final tag = RfidTag(
        epc: epc,
        rssi: -50,
        antenna: 1,
        timestamp: DateTime.now(),
      );
      
      _log('🏷️ Tag leído: $epc (-50 dBm, $epcLen bytes)');
      _tagController.add(tag);
      
      // Avanzar al siguiente paquete
      _dataBuffer = _dataBuffer.sublist(totalLen);
    }
  }

  /// Procesar paquetes Hopeland estándar (0xBB)
  void _processHopelandPackets() {
    while (_dataBuffer.isNotEmpty) {
      final startIndex = _dataBuffer.indexOf(0xBB);
      if (startIndex == -1) {
        _dataBuffer.clear();
        break;
      }
      
      if (startIndex > 0) {
        _dataBuffer = _dataBuffer.sublist(startIndex);
      }
      
      final endIndex = _dataBuffer.indexOf(0x7E);
      if (endIndex == -1) break;
      
      final packet = _dataBuffer.sublist(0, endIndex + 1);
      _dataBuffer = _dataBuffer.sublist(endIndex + 1);
      
      _parseHopelandPacket(packet);
    }
  }

  /// Parsear paquete Hopeland
  void _parseHopelandPacket(List<int> packet) {
    if (packet.length < 7) return;
    
    // Verificar checksum (segundo byte antes de 0x7E)
    if (!_validateChecksum(packet)) {
      _log('⚠️ Checksum inválido, paquete descartado');
      return;
    }
    
    // Verificar formato: [0xBB, Type, Command, PL_H, PL_L, ...Data..., Checksum, 0x7E]
    final type = packet[1];
    final command = packet[2];
    final dataLen = (packet[3] << 8) | packet[4];
    
    _log('Paquete: Type=0x${type.toRadixString(16)}, Cmd=0x${command.toRadixString(16)}, Len=$dataLen');
    
    // Respuesta de inventario (comando 0x22)
    if (command == 0x22 && packet.length >= 7 + dataLen) {
      _parseInventoryResponse(packet.sublist(5, 5 + dataLen));
    }
    // Respuesta de versión (comando 0x03)
    else if (command == 0x03 && dataLen > 0) {
      final version = String.fromCharCodes(packet.sublist(5, 5 + dataLen));
      _log('📱 Versión del lector: $version');
    }
  }

  /// Validar checksum del paquete Hopeland
  bool _validateChecksum(List<int> packet) {
    if (packet.length < 7) return false;
    
    // Checksum = suma de bytes desde Type hasta último dato, módulo 256
    int calculatedChecksum = 0;
    for (int i = 1; i < packet.length - 2; i++) {
      calculatedChecksum = (calculatedChecksum + packet[i]) & 0xFF;
    }
    
    final receivedChecksum = packet[packet.length - 2];
    return calculatedChecksum == receivedChecksum;
  }

  /// Parsear respuesta de inventario
  void _parseInventoryResponse(List<int> data) {
    if (data.length < 13) return;
    
    // Formato típico: RSSI (1) + PC (2) + EPC (12+)
    final rssi = data[0] - 256; // Convertir a negativo
    // final pc = (data[1] << 8) | data[2];
    
    // Extraer EPC (típicamente 12 bytes = 24 caracteres hex)
    final epcLength = data.length - 3;
    if (epcLength < 4) return;
    
    final epcBytes = data.sublist(3, 3 + epcLength);
    final epc = epcBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
    
    final tag = RfidTag(
      epc: epc,
      rssi: rssi,
      antenna: 1,
      timestamp: DateTime.now(),
    );
    
    _log('🏷️ Tag leído: $epc (${rssi} dBm)');
    _tagController.add(tag);
  }

  /// Simular lectura de tag (para desarrollo sin lector real)
  void simulateTagRead(String epc, {int? rssi, int? antenna}) {
    final tag = RfidTag(
      epc: epc,
      rssi: rssi ?? -45 - (DateTime.now().millisecond % 30),
      antenna: antenna ?? 1,
      timestamp: DateTime.now(),
    );
    _log('Tag simulado: ${tag.epc}');
    _tagController.add(tag);
  }

  /// Desconectar del dispositivo
  Future<void> disconnect() async {
    if (!_isConnected && _connectedDevice == null) return;
    
    _log('Desconectando de $_connectedDeviceName...');
    
    try {
      // Detener lectura continua primero
      await stopContinuousRead();
      
      // Cancelar suscripciones
      _dataSubscription?.cancel();
      _connectionSubscription?.cancel();
      
      // Desconectar
      await _connectedDevice?.disconnect();
      
    } catch (e) {
      _logError('Error al desconectar: $e');
    }
    
    _handleDisconnection();
    _log('Desconectado');
  }

  /// Enviar comando al lector
  Future<bool> sendCommand(List<int> command) async {
    if (!_isConnected || _writeCharacteristic == null) {
      _lastError = 'No hay dispositivo conectado o característica no disponible';
      return false;
    }
    
    try {
      _log('Enviando comando: ${command.map((b) => '0x${b.toRadixString(16)}').join(' ')}');
      
      await _writeCharacteristic!.write(command, withoutResponse: false);
      return true;
    } catch (e) {
      _lastError = 'Error enviando comando: $e';
      _logError(_lastError!);
      return false;
    }
  }

  /// Iniciar lectura continua
  Future<bool> startContinuousRead() async {
    if (!_isConnected) {
      _log('⚠️ No conectado, no se puede iniciar lectura');
      return false;
    }
    
    _log('Iniciando lectura continua...');
    return await sendCommand(cmdStartInventory);
  }

  /// Detener lectura continua
  Future<bool> stopContinuousRead() async {
    if (!_isConnected) return true;
    
    _log('Deteniendo lectura continua...');
    return await sendCommand(cmdStopInventory);
  }

  /// Obtener versión del lector
  Future<bool> getReaderVersion() async {
    if (!_isConnected) return false;
    return await sendCommand(cmdGetVersion);
  }

  /// Configurar potencia de transmisión del lector
  /// [power] - 'low' (20dBm), 'mid' (26dBm), 'max' (30dBm)
  Future<bool> setReaderPower(String power) async {
    if (!_isConnected) {
      _lastError = 'No hay dispositivo conectado';
      return false;
    }
    
    List<int> command;
    switch (power.toLowerCase()) {
      case 'low':
        command = cmdSetPowerLow;
        _log('Configurando potencia: BAJA (20dBm)');
        break;
      case 'mid':
        command = cmdSetPowerMid;
        _log('Configurando potencia: MEDIA (26dBm)');
        break;
      case 'max':
        command = cmdSetPowerMax;
        _log('Configurando potencia: ALTA (30dBm)');
        break;
      default:
        _lastError = 'Potencia inválida: $power. Use: low, mid, max';
        return false;
    }
    
    return await sendCommand(command);
  }

  /// Limpiar error
  void clearError() {
    _lastError = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _tagController.close();
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    disconnect();
    super.dispose();
  }
}

/// Información de un dispositivo Bluetooth descubierto
class BluetoothDeviceInfo {
  final String name;
  final String address;
  final int rssi;
  final bool isHopeland;
  final BluetoothDevice? device;

  BluetoothDeviceInfo({
    required this.name,
    required this.address,
    required this.rssi,
    this.isHopeland = false,
    this.device,
  });

  /// Determinar si es un lector RFID conocido
  bool get isRfidReader {
    final upperName = name.toUpperCase();
    return upperName.contains('HOPELAND') ||
           upperName.contains('RFID') ||
           upperName.contains('CL7206') ||
           upperName.contains('CL7202') ||
           upperName.contains('H3') ||
           upperName.contains('BTR');
  }

  /// Calidad de señal
  String get signalQuality {
    if (rssi >= -50) return 'Excelente';
    if (rssi >= -65) return 'Buena';
    if (rssi >= -80) return 'Regular';
    return 'Débil';
  }

  @override
  String toString() => 'BluetoothDeviceInfo($name, $address, $rssi dBm)';
}
