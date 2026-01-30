import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/bluetooth_service.dart';
import 'inventario_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryColor = Color(0xFF00BCD4);
  static const Color secondaryColor = Color(0xFF00838F);
  static const Color accentColor = Color(0xFF06B6D4);
  
  final BluetoothService _bluetoothService = BluetoothService();

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
      backgroundColor: const Color(0xFFF8FAFC),
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
                // Header con información del usuario - Diseño moderno
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor,
                        Color(0xFF0891B2),
                        secondaryColor,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      children: [
                        // Avatar con borde
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white,
                            child: Text(
                              usuario?.nombre.isNotEmpty == true
                                  ? usuario!.nombre[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nombre del usuario
                        Text(
                          usuario?.nombre ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Email
                        Text(
                          usuario?.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Empresa - Badge moderno
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.business_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                empresa?.nombre ?? 'Sin empresa asignada',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

                      // Botón Nuevo Inventario - Card principal
                      _ModernActionCard(
                        icon: Icons.inventory_2_rounded,
                        title: 'Nuevo Inventario',
                        subtitle: 'Realizar un nuevo conteo de activos',
                        gradientColors: const [primaryColor, Color(0xFF26C6DA)],
                        isMain: true,
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
                      ),
                      const SizedBox(height: 16),

                      // Grid de opciones secundarias
                      Row(
                        children: [
                          Expanded(
                            child: _ModernActionCard(
                              icon: Icons.history_rounded,
                              title: 'Historial',
                              subtitle: 'Ver anteriores',
                              gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.info_outline_rounded, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Próximamente...'),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ModernActionCard(
                              icon: Icons.qr_code_scanner_rounded,
                              title: 'Escanear',
                              subtitle: 'Buscar activo',
                              gradientColors: const [secondaryColor, Color(0xFF00ACC1)],
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.info_outline_rounded, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Próximamente...'),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tercera opción
                      _ModernActionCard(
                        icon: Icons.analytics_rounded,
                        title: 'Reportes y Estadísticas',
                        subtitle: 'Visualiza métricas de inventario',
                        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Próximamente...'),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
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

class _ModernActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool isMain;

  const _ModernActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(isMain ? 24.0 : 20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: isMain
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ==================== BLUETOOTH CONNECTION SHEET ====================

class _BluetoothConnectionSheet extends StatefulWidget {
  final BluetoothService bluetoothService;

  const _BluetoothConnectionSheet({required this.bluetoothService});

  @override
  State<_BluetoothConnectionSheet> createState() => _BluetoothConnectionSheetState();
}

class _BluetoothConnectionSheetState extends State<_BluetoothConnectionSheet> {
  static const Color primaryColor = Color(0xFF00BCD4);
  static const Color secondaryColor = Color(0xFF00838F);
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('🔵 [HOME] Iniciando búsqueda de Bluetooth...');
      final isEnabled = await widget.bluetoothService.isBluetoothEnabled();
      if (!isEnabled) {
        debugPrint('🔴 [HOME] Bluetooth no habilitado, solicitando...');
        final enabled = await widget.bluetoothService.requestEnableBluetooth();
        if (!enabled) {
          setState(() {
            _error = 'Bluetooth no está habilitado. Habilítalo en la configuración del dispositivo.';
            _isLoading = false;
          });
          debugPrint('🔴 [HOME] Usuario rechazó habilitar Bluetooth');
          return;
        }
      }

      debugPrint('🟢 [HOME] Bluetooth habilitado, buscando dispositivos...');
      final devices = await widget.bluetoothService.getPairedDevices();
      setState(() => _isLoading = false);
      
      debugPrint('🟢 [HOME] Se encontraron ${devices.length} dispositivos');
      for (var device in devices) {
        debugPrint('   - ${device['name']} (${device['address']})');
      }
    } catch (e) {
      setState(() {
        _error = 'Error al buscar dispositivos: $e';
        _isLoading = false;
      });
      debugPrint('🔴 [HOME] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
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
                        Icons.bluetooth_rounded,
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
                            'Conectar Dispositivo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bluetooth Classic',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.bluetoothService.isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Conectado',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Parámetro de conexión
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.settings_bluetooth, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parámetro de conexión',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'BTR-...............',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              
              // Verificar si la plataforma soporta Bluetooth
              if (!widget.bluetoothService.isPlatformSupported)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange.shade600),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Bluetooth no disponible',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'La conexión Bluetooth solo está disponible en dispositivos Android.\n\nPor favor, ejecuta la aplicación en un dispositivo Android para conectar el lector BTR.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.android, color: Colors.green.shade600, size: 24),
                                const SizedBox(width: 12),
                                const Text(
                                  'Requiere Android',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
              // Contenido
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryColor),
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
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _initBluetooth,
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
    final btrDevices = widget.bluetoothService.getBtrDevices();
    final allDevices = widget.bluetoothService.pairedDevices;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Dispositivos BTR
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
                'Dispositivos BTR',
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
        Row(
          children: [
            Icon(Icons.devices_other_rounded, size: 18, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(
              'Otros dispositivos emparejados',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (allDevices.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.bluetooth_searching, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No hay dispositivos emparejados',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Empareja tu lector BTR desde la configuración de Bluetooth del dispositivo',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          ...allDevices
              .where((d) => !((d['name'] ?? '').toUpperCase().startsWith('BTR')))
              .map((device) => _buildDeviceCard(device)),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDeviceCard(Map<String, String> device, {bool isRecommended = false}) {
    final isConnected = widget.bluetoothService.connectedDeviceAddress == device['address'];
    final isConnecting = widget.bluetoothService.isConnecting;
    final deviceName = device['name'] ?? 'Dispositivo desconocido';
    final deviceAddress = device['address'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isConnected ? primaryColor.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected 
              ? primaryColor.withValues(alpha: 0.3) 
              : const Color(0xFFE2E8F0),
          width: isConnected ? 2 : 1,
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
            Icons.bluetooth,
            color: isRecommended ? Colors.white : Colors.grey.shade600,
            size: 24,
          ),
        ),
        title: Text(
          deviceName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isConnected ? primaryColor : const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          deviceAddress,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontFamily: 'monospace',
          ),
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
                    : () async {
                        final success = await widget.bluetoothService.connectToDevice(deviceAddress, deviceName);
                        if (success && mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.bluetooth_connected, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Text('Conectado a $deviceName'),
                                ],
                              ),
                              backgroundColor: Colors.green.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Conectar'),
              ),
      ),
    );
  }
}
