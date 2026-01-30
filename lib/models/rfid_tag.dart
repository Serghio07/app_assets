/// Modelo para representar un tag RFID leído por el lector
/// Formato basado en lectores Hopeland
class RfidTag {
  /// EPC (Electronic Product Code) - Identificador único del tag
  final String epc;
  
  /// TID (Tag Identifier) - Identificador opcional del tag
  final String? tid;
  
  /// RSSI - Intensidad de señal en dBm (valores típicos: -30 a -70)
  final int rssi;
  
  /// Número de antena que detectó el tag
  final int antenna;
  
  /// Timestamp de cuando se leyó el tag
  final DateTime timestamp;
  
  /// Número de veces que se ha leído este tag
  int readCount;

  RfidTag({
    required this.epc,
    this.tid,
    required this.rssi,
    required this.antenna,
    required this.timestamp,
    this.readCount = 1,
  });

  /// Crear desde bytes del lector Hopeland
  /// El formato depende del modelo específico del lector
  factory RfidTag.fromBytes(List<int> data) {
    if (data.length < 12) {
      throw FormatException('Datos RFID incompletos: ${data.length} bytes');
    }
    
    // Extraer EPC (normalmente 12 bytes = 24 caracteres hex)
    String epc = data
        .sublist(0, 12)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    
    // Extraer RSSI si está disponible (byte 12, convertir a negativo)
    int rssi = data.length > 12 ? data[12] - 256 : -50;
    
    // Extraer antena si está disponible (byte 13)
    int antenna = data.length > 13 ? data[13] : 1;
    
    return RfidTag(
      epc: epc,
      rssi: rssi,
      antenna: antenna,
      timestamp: DateTime.now(),
    );
  }

  /// Crear desde JSON del backend
  factory RfidTag.fromJson(Map<String, dynamic> json) {
    return RfidTag(
      epc: json['rfid_uid'] ?? json['epc'] ?? '',
      tid: json['tid'],
      rssi: json['rssi'] ?? -50,
      antenna: json['antenna_id'] ?? json['antenna'] ?? 1,
      timestamp: json['fecha_lectura'] != null 
          ? DateTime.parse(json['fecha_lectura'])
          : DateTime.now(),
      readCount: json['cantidad_lecturas'] ?? 1,
    );
  }

  /// Convertir a JSON para enviar al backend
  Map<String, dynamic> toJson() => {
    'rfid_uid': epc,
    if (tid != null) 'tid': tid,
    'rssi': rssi,
    'antenna_id': antenna,
  };

  /// Convertir a formato de lectura para el endpoint /lectura
  Map<String, dynamic> toLecturaJson({int? usuarioId}) => {
    'rfid_uid': epc,
    if (tid != null) 'tid': tid,
    'rssi': rssi,
    'antenna_id': antenna,
    if (usuarioId != null) 'usuario_id': usuarioId,
  };

  /// Calidad de señal basada en RSSI
  String get signalQuality {
    if (rssi >= -40) return 'Excelente';
    if (rssi >= -55) return 'Buena';
    if (rssi >= -70) return 'Regular';
    return 'Débil';
  }

  /// Color para mostrar según la calidad de señal
  int get signalColorValue {
    if (rssi >= -40) return 0xFF4CAF50; // Verde
    if (rssi >= -55) return 0xFF8BC34A; // Verde claro
    if (rssi >= -70) return 0xFFFFC107; // Amarillo
    return 0xFFF44336; // Rojo
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RfidTag && runtimeType == other.runtimeType && epc == other.epc;

  @override
  int get hashCode => epc.hashCode;

  @override
  String toString() => 'RfidTag(epc: $epc, rssi: $rssi dBm, antenna: $antenna)';
}
