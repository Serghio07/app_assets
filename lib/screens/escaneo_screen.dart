import 'dart:async';
import 'package:flutter/material.dart';
import '../models/rfid_tag.dart';
import '../services/api_service.dart';
import '../services/bluetooth_rfid_service.dart';
import 'resultados_screen.dart';

/// Pantalla principal de escaneo RFID
/// Muestra contador de tags, lista en tiempo real y permite finalizar inventario
class EscaneoScreen extends StatefulWidget {
  final int inventarioId;
  final int ubicacionId;
  final String ubicacionNombre;
  final int? usuarioId;

  const EscaneoScreen({
    super.key,
    required this.inventarioId,
    required this.ubicacionId,
    required this.ubicacionNombre,
    this.usuarioId,
  });

  @override
  State<EscaneoScreen> createState() => _EscaneoScreenState();
}

class _EscaneoScreenState extends State<EscaneoScreen> with SingleTickerProviderStateMixin {
  final BluetoothRfidService _bluetoothService = BluetoothRfidService();
  final ApiService _apiService = ApiService();
  
  // Estado de escaneo
  final List<RfidTag> _tagsLeidos = [];
  final Set<String> _tagsUnicos = {};
  StreamSubscription<RfidTag>? _tagSubscription;
  bool _isScanning = true;
  bool _isFinalizando = false;
  
  // Animación para contador
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Colores del tema
  static const Color primaryColor = Color(0xFF00BCD4);
  static const Color secondaryColor = Color(0xFF00838F);
  static const Color accentColor = Color(0xFF26C6DA);

  @override
  void initState() {
    super.initState();
    
    // Configurar animación de pulso para el contador
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Iniciar escucha de tags
    _startListening();
  }

  void _startListening() {
    _tagSubscription = _bluetoothService.tagStream.listen(_onTagReceived);
    
    // Simular tags para desarrollo (quitar en producción)
    _startDemoMode();
  }

  /// Modo demostración para pruebas sin lector real
  void _startDemoMode() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isScanning || !mounted) {
        timer.cancel();
        return;
      }
      
      // Generar EPC aleatorio
      final now = DateTime.now();
      final epc = 'E200341201${now.millisecond.toRadixString(16).padLeft(4, '0').toUpperCase()}'
                  '${(now.second * 100 + _tagsUnicos.length).toRadixString(16).padLeft(8, '0').toUpperCase()}';
      
      // Simular lectura
      _bluetoothService.simulateTagRead(
        epc,
        rssi: -40 - (now.millisecond % 35),
        antenna: (now.second % 4) + 1,
      );
    });
  }

  void _onTagReceived(RfidTag tag) async {
    if (!_isScanning) return;
    
    setState(() {
      // Verificar si es tag nuevo
      final isNew = !_tagsUnicos.contains(tag.epc);
      
      if (isNew) {
        _tagsUnicos.add(tag.epc);
        _tagsLeidos.insert(0, tag);
        
        // Animar contador
        _pulseController.forward().then((_) => _pulseController.reverse());
        
        // Enviar al backend
        _enviarLectura(tag);
      } else {
        // Actualizar contador del tag existente
        final index = _tagsLeidos.indexWhere((t) => t.epc == tag.epc);
        if (index >= 0) {
          _tagsLeidos[index].readCount++;
          // Mover al inicio de la lista
          final existingTag = _tagsLeidos.removeAt(index);
          _tagsLeidos.insert(0, existingTag);
        }
      }
    });
  }

  Future<void> _enviarLectura(RfidTag tag) async {
    try {
      await _apiService.enviarLecturaRfid(
        inventarioId: widget.inventarioId,
        rfidUid: tag.epc,
        tid: tag.tid,
        rssi: tag.rssi,
        antennaId: tag.antenna,
        usuarioId: widget.usuarioId,
      );
    } catch (e) {
      debugPrint('Error enviando lectura: $e');
      // No mostrar error al usuario para no interrumpir el escaneo
    }
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
    });
    
    if (_isScanning) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.play_arrow, color: Colors.white),
              SizedBox(width: 8),
              Text('Escaneo reanudado'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.pause, color: Colors.white),
              SizedBox(width: 8),
              Text('Escaneo pausado'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// Mostrar diálogo para buscar y conectar lectores Bluetooth
  Future<void> _showBluetoothDialog() async {
    // Pausar escaneo mientras buscamos dispositivos
    final wasScanning = _isScanning;
    setState(() => _isScanning = false);
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BluetoothConnectionSheet(
        bluetoothService: _bluetoothService,
        onConnected: () {
          // Iniciar lectura continua después de conectar
          _bluetoothService.startContinuousRead();
          setState(() {});
        },
      ),
    );
    
    // Restaurar estado de escaneo
    setState(() => _isScanning = wasScanning);
  }

  Future<void> _finalizarEscaneo() async {
    // Mostrar confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_outline, color: primaryColor),
            ),
            const SizedBox(width: 12),
            const Text('Finalizar Inventario'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas finalizar el escaneo?',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatMini('Tags Únicos', _tagsUnicos.length.toString()),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildStatMini('Total Lecturas', _tagsLeidos.fold<int>(
                    0, (sum, tag) => sum + tag.readCount
                  ).toString()),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isFinalizando = true);
    _isScanning = false;

    try {
      // Cerrar inventario en el backend
      await ApiService().cerrarInventario(widget.inventarioId);
      
      // Obtener resultados
      final resultados = await ApiService().getResultadosInventario(widget.inventarioId);
      
      if (!mounted) return;
      
      // Navegar a pantalla de resultados
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultadosScreen(
            inventarioId: widget.inventarioId,
            resultados: resultados,
            ubicacionNombre: widget.ubicacionNombre,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isFinalizando = false);
      _isScanning = true;
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error al finalizar: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildStatMini(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: secondaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Inventario #${widget.inventarioId}'),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Botón de conexión Bluetooth (clickeable)
          GestureDetector(
            onTap: _showBluetoothDialog,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _bluetoothService.isConnected
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _bluetoothService.isConnected
                      ? Colors.green.withValues(alpha: 0.5)
                      : Colors.orange.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _bluetoothService.isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_searching,
                    size: 18,
                    color: _bluetoothService.isConnected
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _bluetoothService.isConnected 
                        ? (_bluetoothService.connectedDeviceName ?? 'Conectado')
                        : 'Conectar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _bluetoothService.isConnected
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: _bluetoothService.isConnected
                        ? Colors.green
                        : Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con información de ubicación y contador grande
          _buildHeader(),
          
          // Estado de escaneo
          _buildScanningIndicator(),
          
          // Lista de tags leídos
          Expanded(child: _buildTagsList()),
          
          // Botón de finalizar
          _buildFinalizarButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleScanning,
        backgroundColor: _isScanning ? Colors.orange : Colors.green,
        icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
        label: Text(_isScanning ? 'Pausar' : 'Reanudar'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, accentColor],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Ubicación
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.ubicacionNombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Contador grande animado
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_tagsUnicos.length}',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tags Únicos Leídos',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Estadísticas adicionales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMiniStat(
                  Icons.refresh,
                  'Lecturas totales',
                  _tagsLeidos.fold<int>(0, (sum, tag) => sum + tag.readCount).toString(),
                ),
                _buildMiniStat(
                  Icons.speed,
                  'Último RSSI',
                  _tagsLeidos.isNotEmpty ? '${_tagsLeidos.first.rssi} dBm' : '-',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isScanning) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Escaneando...',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Icon(Icons.pause_circle, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Escaneo pausado',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsList() {
    if (_tagsLeidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nfc,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Esperando lecturas RFID...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Acerca el lector a los tags',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _tagsLeidos.length > 100 ? 100 : _tagsLeidos.length,
      itemBuilder: (context, index) {
        final tag = _tagsLeidos[index];
        final isRecent = index < 3;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isRecent
                ? Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(tag.signalColorValue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.nfc,
                color: Color(tag.signalColorValue),
                size: 24,
              ),
            ),
            title: Text(
              tag.epc,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: isRecent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.router, size: 14, color: Colors.grey[400]),
                Text(
                  ' Ant ${tag.antenna}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.repeat, size: 14, color: Colors.grey[400]),
                Text(
                  ' ${tag.readCount}x',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tag.rssi} dBm',
                  style: TextStyle(
                    color: Color(tag.signalColorValue),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  tag.signalQuality,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinalizarButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isFinalizando || _tagsUnicos.isEmpty
                ? null
                : _finalizarEscaneo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isFinalizando
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Finalizando...'),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'FINALIZAR ESCANEO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tagSubscription?.cancel();
    _pulseController.dispose();
    _bluetoothService.dispose();
    super.dispose();
  }
}

/// Widget para el Bottom Sheet de conexión Bluetooth
class _BluetoothConnectionSheet extends StatefulWidget {
  final BluetoothRfidService bluetoothService;
  final VoidCallback onConnected;

  const _BluetoothConnectionSheet({
    required this.bluetoothService,
    required this.onConnected,
  });

  @override
  State<_BluetoothConnectionSheet> createState() => _BluetoothConnectionSheetState();
}

class _BluetoothConnectionSheetState extends State<_BluetoothConnectionSheet> {
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectingDevice;

  @override
  void initState() {
    super.initState();
    // Iniciar escaneo automáticamente
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    
    try {
      await widget.bluetoothService.scanDevices(
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error escaneando: $e');
    }
    
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToDevice(BluetoothDeviceInfo device) async {
    setState(() {
      _isConnecting = true;
      _connectingDevice = device.address;
    });

    try {
      final success = await widget.bluetoothService.connect(device);
      
      if (success && mounted) {
        widget.onConnected();
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.bluetooth_connected, color: Colors.white),
                const SizedBox(width: 8),
                Text('Conectado a ${device.name}'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error al conectar: ${widget.bluetoothService.lastError ?? 'Desconocido'}'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingDevice = null;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    await widget.bluetoothService.disconnect();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final devices = widget.bluetoothService.discoveredDevices;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bluetooth,
                        color: Color(0xFF00BCD4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lectores RFID',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Conecta tu lector Hopeland',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Botón refrescar
                IconButton(
                  onPressed: _isScanning ? null : _startScan,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Estado de conexión actual
          if (widget.bluetoothService.isConnected)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bluetooth_connected, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.bluetoothService.connectedDeviceName ?? 'Lector RFID',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Conectado • ${widget.bluetoothService.connectedDeviceAddress}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _disconnect,
                    child: const Text(
                      'Desconectar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          
          if (widget.bluetoothService.isConnected)
            const SizedBox(height: 16),
          
          // Lista de dispositivos
          Expanded(
            child: _isScanning && devices.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Buscando dispositivos...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth_disabled,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron dispositivos',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Asegúrate de que tu lector RFID\nesté encendido y en modo de emparejamiento',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _startScan,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Buscar de nuevo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00BCD4),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          final isCurrentlyConnecting = _connectingDevice == device.address;
                          final isConnected = widget.bluetoothService.isConnected &&
                              widget.bluetoothService.connectedDeviceAddress == device.address;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? Colors.green.withValues(alpha: 0.05)
                                  : Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isConnected
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : device.isRfidReader
                                        ? const Color(0xFF00BCD4).withValues(alpha: 0.3)
                                        : Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: device.isRfidReader
                                      ? const Color(0xFF00BCD4).withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  device.isRfidReader
                                      ? Icons.nfc
                                      : Icons.bluetooth,
                                  color: device.isRfidReader
                                      ? const Color(0xFF00BCD4)
                                      : Colors.grey,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      device.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (device.isHopeland)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Hopeland',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF00BCD4),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    device.address,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getSignalColor(device.rssi).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.signal_cellular_alt,
                                          size: 12,
                                          color: _getSignalColor(device.rssi),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          device.signalQuality,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _getSignalColor(device.rssi),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isConnected
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Conectado',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : isCurrentlyConnecting
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: _isConnecting
                                              ? null
                                              : () => _connectToDevice(device),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: device.isRfidReader
                                                ? const Color(0xFF00BCD4)
                                                : Colors.grey,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: const Text('Conectar'),
                                        ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Botón modo demo
          if (!widget.bluetoothService.isConnected)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.science, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Modo demo activado - Tags simulados'),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.science),
                  label: const Text('Continuar sin lector (Demo)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -65) return Colors.orange;
    if (rssi >= -80) return Colors.deepOrange;
    return Colors.red;
  }
}
