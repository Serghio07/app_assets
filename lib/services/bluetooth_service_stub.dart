/// Implementación stub para plataformas no soportadas (Web)
class BluetoothServicePlatform {
  bool get isSupported => false;
  
  Future<bool> isBluetoothEnabled() async => false;
  
  Future<bool> requestEnableBluetooth() async => false;
  
  Future<List<Map<String, String>>> getPairedDevices() async => [];
  
  Future<bool> connect(String address, Function(String) onDataReceived) async => false;
  
  Future<void> send(String data) async {}
  
  Future<void> disconnect() async {}
}
