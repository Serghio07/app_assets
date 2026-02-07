import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/bluetooth_rfid_service.dart';
import 'inventario_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryColor = Color(0xFFE74C3C);
  static const Color secondaryColor = Color(0xFFC0392B);
  
  final BluetoothRfidService _bluetoothService = BluetoothRfidService();

  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }

  void _showBluetoothDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BluetoothConnectionSheet(
        bluetoothService: _bluetoothService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Botón Bluetooth
          ListenableBuilder(
            listenable: _bluetoothService,
            builder: (context, _) {
              final isConnected = _bluetoothService.isConnected;
              final isConnecting = _bluetoothService.isConnecting;
              
              return Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: isConnected 
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                          color: isConnected ? Colors.greenAccent : Colors.white,
                        ),
                  tooltip: isConnected 
                      ? 'Conectado: ${_bluetoothService.connectedDeviceName}'
                      : 'Conectar Bluetooth',
                  onPressed: _showBluetoothDialog,
                ),
              );
            },
          ),
          // Botón Cerrar Sesión
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.logout_rounded, color: Colors.red.shade400),
                        ),
                        const SizedBox(width: 12),
                        const Text('Cerrar sesión'),
                      ],
                    ),
                    content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                }
              },
            ),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final usuario = auth.usuario;
          final empresa = auth.empresaActual;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Info simple - minimalista
                Container(
                  width: double.infinity,
                  color: primaryColor.withValues(alpha: 0.05),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usuario: ${usuario?.nombre ?? 'Usuario'}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Empresa: ${empresa?.nombre ?? 'Sin empresa asignada'}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Contenido principal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Acciones rápidas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Card de conexión Bluetooth - simplificado
                      ListenableBuilder(
                        listenable: _bluetoothService,
                        builder: (context, _) {
                          final isConnected = _bluetoothService.isConnected;
                          final isConnecting = _bluetoothService.isConnecting;
                          
                          return GestureDetector(
                            onTap: _showBluetoothDialog,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isConnecting ? Icons.hourglass_empty_rounded : (isConnected ? Icons.bluetooth_connected : Icons.bluetooth),
                                    color: isConnected ? Colors.green : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isConnected ? 'Lector Conectado' : 'Conectar Lector RFID',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          isConnected ? (_bluetoothService.connectedDeviceName ?? 'BTR') : 'Buscar dispositivos',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Botón Nuevo Inventario
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (empresa != null && usuario != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InventarioScreen(
                                      empresaId: empresa.id,
                                      usuarioId: usuario.id,
                                      usuario: usuario,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('No hay empresa asignada'),
                                      ],
                                    ),
                                    backgroundColor: Colors.orange.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 24),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Nuevo Inventario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text('Realizar conteo de activos', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==================== BLUETOOTH CONNECTION SHEET ====================

class _BluetoothConnectionSheet extends StatefulWidget {
  final BluetoothRfidService bluetoothService;

  const _BluetoothConnectionSheet({required this.bluetoothService});

  @override
  State<_BluetoothConnectionSheet> createState() => _BluetoothConnectionSheetState();
}

class _BluetoothConnectionSheetState extends State<_BluetoothConnectionSheet> {
  static const Color primaryColor = Color(0xFFE74C3C);
  static const Color secondaryColor = Color(0xFFC0392B);
  
  bool _isScanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      debugPrint('🔵 [HOME] Iniciando escaneo BLE real...');
      
      // Escanear dispositivos reales con flutter_blue_plus
      await widget.bluetoothService.scanDevices(
        timeout: const Duration(seconds: 10),
      );
      
      if (mounted) {
        setState(() => _isScanning = false);
        debugPrint('🟢 [HOME] Escaneo completado - ${widget.bluetoothService.discoveredDevices.length} dispositivos encontrados');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al escanear: $e';
          _isScanning = false;
        });
      }
      debugPrint('🔴 [HOME] Error: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDeviceInfo device) async {
    debugPrint('🔵 [HOME] Conectando a ${device.name}...');
    
    final success = await widget.bluetoothService.connect(device);
    
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bluetooth_connected, color: Colors.white),
              const SizedBox(width: 12),
              Text('Conectado a ${device.name}'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text('Error al conectar: ${widget.bluetoothService.lastError ?? 'Desconocido'}'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryColor, secondaryColor],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bluetooth_searching,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buscar Lector RFID',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bluetooth Low Energy',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
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
                        onPressed: () async {
                          await widget.bluetoothService.disconnect();
                          setState(() {});
                        },
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
                child: _isScanning && widget.bluetoothService.discoveredDevices.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: primaryColor),
                            SizedBox(height: 16),
                            Text(
                              'Buscando dispositivos...',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Asegúrate que el lector BTR esté encendido',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _startScan,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reintentar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildDevicesList(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDevicesList(ScrollController scrollController) {
    final devices = widget.bluetoothService.discoveredDevices;
    
    // Separar dispositivos BTR de otros
    final btrDevices = devices.where((d) => d.isRfidReader).toList();
    final otherDevices = devices.where((d) => !d.isRfidReader).toList();

    if (devices.isEmpty) {
      return Center(
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
              'Asegúrate de que tu lector RFID\nesté encendido y cerca',
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
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Dispositivos BTR/RFID primero
        if (btrDevices.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star_rounded, size: 16, color: Colors.orange.shade600),
              ),
              const SizedBox(width: 8),
              Text(
                'Lectores RFID (${btrDevices.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...btrDevices.map((device) => _buildDeviceCard(device, isRecommended: true)),
          const SizedBox(height: 20),
        ],

        // Otros dispositivos
        if (otherDevices.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.devices_other_rounded, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                'Otros dispositivos (${otherDevices.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...otherDevices.map((device) => _buildDeviceCard(device)),
        ],
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDeviceCard(BluetoothDeviceInfo device, {bool isRecommended = false}) {
    final isConnected = widget.bluetoothService.connectedDeviceAddress == device.address;
    final isConnecting = widget.bluetoothService.isConnecting;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isConnected ? primaryColor.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected 
              ? primaryColor.withValues(alpha: 0.3) 
              : isRecommended
                  ? Colors.orange.withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
          width: isConnected || isRecommended ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isRecommended
                ? const LinearGradient(colors: [primaryColor, secondaryColor])
                : null,
            color: isRecommended ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isRecommended ? Icons.sensors : Icons.bluetooth,
            color: isRecommended ? Colors.white : Colors.grey.shade600,
            size: 24,
          ),
        ),
        title: Text(
          device.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isConnected ? primaryColor : const Color(0xFF1E293B),
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              device.address,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRssiColor(device.rssi).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${device.rssi} dBm',
                style: TextStyle(
                  fontSize: 10,
                  color: _getRssiColor(device.rssi),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: isConnected
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.green.shade700, size: 20),
              )
            : ElevatedButton(
                onPressed: isConnecting
                    ? null
                    : () => _connectToDevice(device),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecommended ? primaryColor : Colors.grey.shade200,
                  foregroundColor: isRecommended ? Colors.white : Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Conectar'),
              ),
      ),
    );
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -70) return Colors.orange;
    return Colors.red;
  }
}
