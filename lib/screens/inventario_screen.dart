import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/rfid_tag.dart';
import '../services/api_service.dart';
import '../services/bluetooth_rfid_service.dart';
import '../providers/providers.dart';

class InventarioScreen extends StatefulWidget {
  final String empresaId;
  final String usuarioId;
  final Usuario usuario;

  const InventarioScreen({
    super.key,
    required this.empresaId,
    required this.usuarioId,
    required this.usuario,
  });

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final ApiService _apiService = ApiService();
  List<Sucursal>? _sucursales;
  List<Ubicacion>? _ubicaciones;
  List<Activo>? _activos;

  Sucursal? _sucursalSeleccionada;
  Ubicacion? _ubicacionSeleccionada;
  bool _isLoading = false;
  int _currentStep = 0;

  static const Color primaryColor = Color(0xFF00BCD4);
  static const Color secondaryColor = Color(0xFF00838F);

  @override
  void initState() {
    super.initState();
    _loadSucursales();
  }

  Future<void> _loadSucursales() async {
    setState(() => _isLoading = true);
    try {
      final sucursales = await _apiService.getSucursales(
        empresaId: widget.empresaId,
      );
      setState(() {
        _sucursales = sucursales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar sucursales: $e');
    }
  }

  Future<void> _loadUbicaciones(String sucursalId) async {
    setState(() => _isLoading = true);
    try {
      final ubicaciones = await _apiService.getUbicaciones(
        empresaId: widget.empresaId,
        sucursalId: sucursalId,
      );
      setState(() {
        _ubicaciones = ubicaciones;
        _activos = null;
        _isLoading = false;
        _currentStep = 1;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar ubicaciones: $e');
    }
  }

  Future<void> _loadActivos(String sucursalId, String ubicacionId) async {
    setState(() => _isLoading = true);
    try {
      final activos = await _apiService.getActivosPorUbicacion(
        empresaId: widget.empresaId,
        ubicacionId: ubicacionId,
      );
      setState(() {
        _activos = activos;
        _isLoading = false;
        _currentStep = 2;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar activos: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _startInventario() async {
    if (_sucursalSeleccionada == null || _ubicacionSeleccionada == null) {
      _showErrorSnackBar('Selecciona sucursal y ubicación');
      return;
    }

    if (_activos == null || _activos!.isEmpty) {
      _showErrorSnackBar('No hay activos en esta ubicación');
      return;
    }

    try {
      final inventarioProvider = context.read<InventarioProvider>();
      
      // Debug: imprimir IDs originales
      debugPrint('🔵 [INVENTARIO SCREEN] empresaId original: "${widget.empresaId}"');
      debugPrint('🔵 [INVENTARIO SCREEN] ubicacionId original: "${_ubicacionSeleccionada!.id}"');
      
      // Parsear IDs a int (el API espera enteros)
      final empresaIdInt = int.tryParse(widget.empresaId);
      final ubicacionIdInt = int.tryParse(_ubicacionSeleccionada!.id);
      
      // Validar que los IDs se parsearon correctamente
      if (empresaIdInt == null) {
        _showErrorSnackBar('Error: empresaId no es un número válido: "${widget.empresaId}"');
        return;
      }
      if (ubicacionIdInt == null) {
        _showErrorSnackBar('Error: ubicacionId no es un número válido: "${_ubicacionSeleccionada!.id}"');
        return;
      }
      
      debugPrint('🔵 [INVENTARIO SCREEN] empresaId parseado: $empresaIdInt');
      debugPrint('🔵 [INVENTARIO SCREEN] ubicacionId parseado: $ubicacionIdInt');
      
      final inventario = await inventarioProvider.createInventario(
        empresaId: empresaIdInt,
        ubicacionId: ubicacionIdInt,
      );

      inventarioProvider.setActivosPendientes(_activos!);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InventarioScannerScreen(
            inventario: inventario,
            activos: _activos!,
            usuario: widget.usuario,
          ),
        ),
      );
    } catch (e) {
      debugPrint('🔴 [INVENTARIO SCREEN] Error al crear inventario: $e');
      _showErrorSnackBar('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Nuevo Inventario'),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header con gradiente
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, Color(0xFF26C6DA)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info del usuario
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.usuario.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.usuario.empresa?.nombre ?? 'Empresa',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stepper visual
                  _buildStepper(),
                ],
              ),
            ),
          ),
          
          // Contenido
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentStep == 0) _buildSucursalesSection(),
                        if (_currentStep >= 1) _buildUbicacionesSection(),
                        if (_currentStep >= 2) _buildActivosSection(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _buildStepIndicator(0, 'Sucursal', Icons.store_rounded),
        _buildStepLine(0),
        _buildStepIndicator(1, 'Ubicación', Icons.location_on_rounded),
        _buildStepLine(1),
        _buildStepIndicator(2, 'Activos', Icons.inventory_2_rounded),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive 
                  ? Colors.white 
                  : Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: isCurrent 
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isActive 
                  ? [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )]
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? primaryColor : Colors.white.withValues(alpha: 0.6),
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isComplete = _currentStep > step;
    return Container(
      height: 3,
      width: 30,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isComplete 
            ? Colors.white 
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildSucursalesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Selecciona una Sucursal', Icons.store_rounded),
        const SizedBox(height: 16),
        if (_sucursales == null || _sucursales!.isEmpty)
          _buildEmptyState('No hay sucursales disponibles', Icons.store_mall_directory_outlined)
        else
          ...List.generate(_sucursales!.length, (index) {
            final sucursal = _sucursales![index];
            final isSelected = _sucursalSeleccionada?.id == sucursal.id;
            return _buildSelectionCard(
              title: sucursal.nombre,
              subtitle: sucursal.ciudad ?? 'Sin ciudad',
              icon: Icons.store_rounded,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _sucursalSeleccionada = sucursal;
                  _ubicacionSeleccionada = null;
                  _ubicaciones = null;
                  _activos = null;
                });
                _loadUbicaciones(sucursal.id);
              },
            );
          }),
      ],
    );
  }

  Widget _buildUbicacionesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Selected sucursal badge
        if (_sucursalSeleccionada != null) ...[
          _buildSelectedBadge(
            _sucursalSeleccionada!.nombre,
            Icons.store_rounded,
            onClear: () {
              setState(() {
                _sucursalSeleccionada = null;
                _ubicacionSeleccionada = null;
                _ubicaciones = null;
                _activos = null;
                _currentStep = 0;
              });
            },
          ),
          const SizedBox(height: 20),
        ],
        _buildSectionTitle('Selecciona una Ubicación', Icons.location_on_rounded),
        const SizedBox(height: 16),
        if (_ubicaciones == null || _ubicaciones!.isEmpty)
          _buildEmptyState('No hay ubicaciones disponibles', Icons.location_off_outlined)
        else
          ...List.generate(_ubicaciones!.length, (index) {
            final ubicacion = _ubicaciones![index];
            final isSelected = _ubicacionSeleccionada?.id == ubicacion.id;
            return _buildSelectionCard(
              title: ubicacion.nombre,
              subtitle: ubicacion.responsable?.nombre ?? 'Sin responsable',
              icon: Icons.location_on_rounded,
              isSelected: isSelected,
              color: const Color(0xFFF59E0B),
              onTap: () {
                setState(() {
                  _ubicacionSeleccionada = ubicacion;
                });
                _loadActivos(_sucursalSeleccionada!.id, ubicacion.id);
              },
            );
          }),
      ],
    );
  }

  Widget _buildActivosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Selected badges
        if (_sucursalSeleccionada != null && _ubicacionSeleccionada != null) ...[
          Row(
            children: [
              Expanded(
                child: _buildSelectedBadge(
                  _sucursalSeleccionada!.nombre,
                  Icons.store_rounded,
                  compact: true,
                  onClear: () {
                    setState(() {
                      _sucursalSeleccionada = null;
                      _ubicacionSeleccionada = null;
                      _ubicaciones = null;
                      _activos = null;
                      _currentStep = 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSelectedBadge(
                  _ubicacionSeleccionada!.nombre,
                  Icons.location_on_rounded,
                  color: const Color(0xFFF59E0B),
                  compact: true,
                  onClear: () {
                    setState(() {
                      _ubicacionSeleccionada = null;
                      _activos = null;
                      _currentStep = 1;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Activos a Inventariar', Icons.inventory_2_rounded),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryColor, secondaryColor],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_activos?.length ?? 0} activos',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_activos == null || _activos!.isEmpty)
          _buildEmptyState('No hay activos en esta ubicación', Icons.inventory_2_outlined)
        else
          ...List.generate(_activos!.length, (index) {
            final activo = _activos![index];
            return _buildActivoCard(activo);
          }),
      ],
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color color = primaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle_rounded : icon,
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_rounded, color: color, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedBadge(String text, IconData icon, {
    Color color = primaryColor,
    bool compact = false,
    VoidCallback? onClear,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Icon(icon, color: color, size: compact ? 16 : 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 12 : 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close_rounded, color: color, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivoCard(Activo activo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: secondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: secondaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activo.tipoActivo?.nombre ?? activo.codigoInterno,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildActivoTag('Código: ${activo.codigoInterno}', Icons.qr_code_rounded),
                    if (activo.rfidUid != null) ...[
                      const SizedBox(width: 8),
                      _buildActivoTag('RFID', Icons.nfc_rounded),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivoTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_sucursalSeleccionada == null || _ubicacionSeleccionada == null || _activos == null) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryColor, secondaryColor],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _activos!.isNotEmpty ? _startInventario : null,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                    const SizedBox(width: 10),
                    const Text(
                      'Iniciar Escaneo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== PANTALLA DE SCANNER ====================

class InventarioScannerScreen extends StatefulWidget {
  final Inventario inventario;
  final List<Activo> activos;
  final Usuario usuario;

  const InventarioScannerScreen({
    super.key,
    required this.inventario,
    required this.activos,
    required this.usuario,
  });

  @override
  State<InventarioScannerScreen> createState() =>
      _InventarioScannerScreenState();
}

class _InventarioScannerScreenState extends State<InventarioScannerScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _rfidController = TextEditingController();
  final ApiService _apiService = ApiService();
  final BluetoothRfidService _bluetoothService = BluetoothRfidService();
  StreamSubscription<RfidTag>? _tagSubscription;

  final List<LecturaRfid> _escaneos = [];
  final Map<int, Activo> _activosEscaneados = {}; // Mapa: lecturaId -> Activo
  List<Activo> _activosPendientes = [];
  final Set<String> _processedTags = {}; // Para evitar duplicados
  bool _isLoading = false;
  late TabController _tabController;

  static const Color primaryColor = Color(0xFF00BCD4);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color secondaryColor = Color(0xFF00838F);

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 [INVENTARIO_SCANNER] initState ejecutado!');
    debugPrint('🔗 [INVENTARIO_SCANNER] Servicio Bluetooth (singleton): ${_bluetoothService.hashCode}');
    
    _activosPendientes = List.from(widget.activos);
    _rfidController.addListener(_onRfidScanned);
    _tabController = TabController(length: 2, vsync: this);
    
    // ⭐ INICIAR ESCUCHA DE TAGS RFID
    _startBluetoothListener();
  }
  
  /// Match fuzzy: compara EPCs con tolerancia a pequeñas diferencias
  /// Útil cuando el EPC en DB está truncado o tiene errores menores
  bool _isFuzzyMatch(String tag, String dbRfid) {
    // Si uno está contenido en el otro con pequeña diferencia de longitud
    final lenDiff = (tag.length - dbRfid.length).abs();
    if (lenDiff <= 3) {
      // Comparar caracteres comunes
      final shorter = tag.length < dbRfid.length ? tag : dbRfid;
      final longer = tag.length >= dbRfid.length ? tag : dbRfid;
      
      // Verificar si el más corto está "casi" contenido en el más largo
      // Buscar la mejor alineación
      for (int offset = 0; offset <= lenDiff; offset++) {
        int matches = 0;
        for (int i = 0; i < shorter.length && i + offset < longer.length; i++) {
          if (shorter[i] == longer[i + offset]) matches++;
        }
        // Si más del 85% coincide, es un match
        if (matches >= shorter.length * 0.85) {
          debugPrint('      🔍 Fuzzy: $matches/${shorter.length} chars match (${(matches/shorter.length*100).toStringAsFixed(1)}%)');
          return true;
        }
      }
    }
    
    // Verificar si comparten un substring largo (mínimo 16 caracteres)
    if (tag.length >= 16 && dbRfid.length >= 16) {
      for (int i = 0; i <= tag.length - 16; i++) {
        final substring = tag.substring(i, i + 16);
        if (dbRfid.contains(substring)) {
          debugPrint('      🔍 Fuzzy: substring match de 16 chars: $substring');
          return true;
        }
      }
      for (int i = 0; i <= dbRfid.length - 16; i++) {
        final substring = dbRfid.substring(i, i + 16);
        if (tag.contains(substring)) {
          debugPrint('      🔍 Fuzzy: substring match de 16 chars: $substring');
          return true;
        }
      }
    }
    
    return false;
  }
  
  void _startBluetoothListener() {
    debugPrint('🎧 [INVENTARIO_SCANNER] Iniciando listener de tags Bluetooth...');
    
    // ⭐ LOG: Mostrar todos los activos pendientes y sus EPCs
    debugPrint('📋 [INVENTARIO_SCANNER] ============ ACTIVOS PENDIENTES ============');
    debugPrint('📋 [INVENTARIO_SCANNER] Total: ${_activosPendientes.length} activos');
    for (int i = 0; i < _activosPendientes.length; i++) {
      final a = _activosPendientes[i];
      final rfid = a.rfidUid?.toUpperCase().trim() ?? 'SIN RFID';
      debugPrint('📋 [INVENTARIO_SCANNER] ${i+1}. ${a.codigoInterno}: RFID=[$rfid] (${rfid.length} chars)');
    }
    debugPrint('📋 [INVENTARIO_SCANNER] ==========================================');
    
    _tagSubscription?.cancel();
    _tagSubscription = _bluetoothService.tagStream.listen(
      _onBluetoothTagReceived,
      onError: (error) => debugPrint('❌ [INVENTARIO_SCANNER] Error en stream: $error'),
      onDone: () => debugPrint('⚠️ [INVENTARIO_SCANNER] Stream cerrado'),
    );
    debugPrint('✅ [INVENTARIO_SCANNER] Listener activo, esperando tags...');
  }
  
  void _onBluetoothTagReceived(RfidTag tag) {
    debugPrint('🔵 [INVENTARIO_SCANNER] Tag Bluetooth recibido: ${tag.epc}');
    
    // Evitar procesar tags duplicados
    if (_processedTags.contains(tag.epc)) {
      debugPrint('⏭️ [INVENTARIO_SCANNER] Tag ya procesado, ignorando');
      return;
    }
    
    // Buscar match con activos pendientes
    _processBluetoothTag(tag.epc);
  }
  
  void _processBluetoothTag(String tagEpc) {
    final tagUpper = tagEpc.toUpperCase().trim();
    debugPrint('📋 [INVENTARIO_SCANNER] Buscando match para: $tagUpper (${tagUpper.length} chars)');
    debugPrint('📋 [INVENTARIO_SCANNER] Activos pendientes: ${_activosPendientes.length}');
    
    // Buscar activo que coincida (match flexible)
    Activo? activoMatch;
    for (final activo in _activosPendientes) {
      final rfidActivo = activo.rfidUid?.toUpperCase().trim() ?? '';
      if (rfidActivo.isEmpty) continue;
      
      debugPrint('   ✓ Comparando: [$tagUpper] vs [$rfidActivo] (${activo.codigoInterno})');
      
      // Match exacto
      if (rfidActivo == tagUpper) {
        debugPrint('   ✅ MATCH EXACTO: ${activo.codigoInterno}');
        activoMatch = activo;
        break;
      }
      
      // Match parcial: uno contiene al otro
      if (rfidActivo.contains(tagUpper) || tagUpper.contains(rfidActivo)) {
        debugPrint('   ✅ MATCH PARCIAL (contains): ${activo.codigoInterno}');
        activoMatch = activo;
        break;
      }
      
      // Match por sufijo
      if (rfidActivo.endsWith(tagUpper) || tagUpper.endsWith(rfidActivo)) {
        debugPrint('   ✅ MATCH SUFIJO: ${activo.codigoInterno}');
        activoMatch = activo;
        break;
      }
      
      // Match por substring significativo (últimos 16 caracteres)
      final minLen = tagUpper.length < rfidActivo.length ? tagUpper.length : rfidActivo.length;
      if (minLen >= 16) {
        final tagSuffix = tagUpper.substring(tagUpper.length - 16);
        final rfidSuffix = rfidActivo.substring(rfidActivo.length - 16);
        if (tagSuffix == rfidSuffix) {
          debugPrint('   ✅ MATCH SUFIJO-16: ${activo.codigoInterno}');
          activoMatch = activo;
          break;
        }
      }
      
      // Match fuzzy: si la diferencia es de pocos caracteres (1-2)
      // Útil cuando el EPC en DB está truncado o tiene un typo
      if (_isFuzzyMatch(tagUpper, rfidActivo)) {
        debugPrint('   ✅ MATCH FUZZY: ${activo.codigoInterno}');
        activoMatch = activo;
        break;
      }
    }
    
    if (activoMatch != null) {
      _processedTags.add(tagEpc);
      _registrarEscaneo(activoMatch, tagEpc);
    } else {
      debugPrint('❌ [INVENTARIO_SCANNER] Tag NO coincide con ningún activo pendiente');
    }
  }
  
  void _registrarEscaneo(Activo activo, String rfidUid) {
    debugPrint('✅ [INVENTARIO_SCANNER] Registrando escaneo: ${activo.codigoInterno}');
    
    setState(() {
      final lecturaId = DateTime.now().millisecondsSinceEpoch;
      final lectura = LecturaRfid(
        id: lecturaId,
        inventarioId: widget.inventario.id,
        rfidUid: rfidUid,
        fechaLectura: DateTime.now(),
      );
      
      _escaneos.add(lectura);
      _activosEscaneados[lecturaId] = activo; // Guardar referencia al activo
      _activosPendientes.removeWhere((a) => a.id == activo.id);
    });
    
    // Mostrar feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('✅ ${activo.codigoInterno} detectado')),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    
    // Enviar al backend
    _enviarLecturaAlBackend(activo, rfidUid);
  }
  
  Future<void> _enviarLecturaAlBackend(Activo activo, String rfidUid) async {
    try {
      await _apiService.enviarLecturaRfid(
        inventarioId: widget.inventario.id,
        rfidUid: rfidUid,
        rssi: -50,
        antennaId: 1,
      );
      debugPrint('📤 [INVENTARIO_SCANNER] Lectura enviada al backend');
    } catch (e) {
      debugPrint('❌ [INVENTARIO_SCANNER] Error enviando lectura: $e');
    }
  }

  @override
  void dispose() {
    _tagSubscription?.cancel();
    _rfidController.removeListener(_onRfidScanned);
    _rfidController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRfidScanned() async {
    if (_rfidController.text.isEmpty) return;

    final rfidUid = _rfidController.text.trim();
    _rfidController.clear();

    setState(() => _isLoading = true);

    try {
      // Buscar activo por RFID
      final activo = await _apiService.searchActivoByRfid(rfidUid);

      // Verificar que el activo pertenece a la ubicación del inventario
      if (activo.ubicacionActualId != widget.inventario.ubicacionId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text('Activo en ubicación diferente: ${activo.codigoInterno}'),
              ],
            ),
            backgroundColor: warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Registrar escaneo usando el nuevo endpoint
      final lectura = await _apiService.enviarLecturaRfid(
        inventarioId: widget.inventario.id,
        rfidUid: rfidUid,
      );

      // Actualizar listas
      setState(() {
        _escaneos.add(lectura);
        _activosPendientes.removeWhere((a) => a.id == activo.id);
        _isLoading = false;
      });

      // Mostrar éxito
      _showSuccessAnimation(activo.codigoInterno);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showSuccessAnimation(String codigo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text('$codigo escaneado correctamente'),
          ],
        ),
        backgroundColor: successColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _completeInventario() async {
    if (_activosPendientes.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warning_amber_rounded, color: warningColor),
              ),
              const SizedBox(width: 12),
              const Text('Inventario Incompleto'),
            ],
          ),
          content: Text(
            'Quedan ${_activosPendientes.length} activos por escanear.\n¿Deseas completar de todas formas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Continuar escaneando', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: warningColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Completar igual'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final inventarioProvider = context.read<InventarioProvider>();
      await inventarioProvider.cerrarInventario();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('¡Inventario completado exitosamente!'),
            ],
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int pendientes = _activosPendientes.length;
    final int escaneados = _escaneos.length;
    final int total = escaneados + pendientes;
    final double porcentaje = total > 0 ? (escaneados / total) : 0;

    return PopScope(
      canPop: _escaneos.isEmpty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.exit_to_app_rounded, color: Colors.red.shade400),
                ),
                const SizedBox(width: 12),
                const Text('¿Salir del inventario?'),
              ],
            ),
            content: const Text('Se perderá el progreso del inventario actual.'),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Salir'),
              ),
            ],
          ),
        );
        if (context.mounted && confirm == true) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Escaneando'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 16),
                    Text('Procesando...', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              )
            : Column(
                children: [
                  // Header con progreso
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, Color(0xFF26C6DA)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                      child: Column(
                        children: [
                          // Progreso circular
                          Row(
                            children: [
                              // Círculo de progreso
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: CircularProgressIndicator(
                                        value: porcentaje,
                                        strokeWidth: 8,
                                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        '${(porcentaje * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$escaneados de $total',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'activos escaneados',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Barra de progreso
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: porcentaje,
                              minHeight: 10,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                porcentaje == 1.0 ? successColor : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Campo RFID
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _rfidController,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Acerca el RFID o ingresa código',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.nfc_rounded, color: primaryColor, size: 22),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        ),
                        onSubmitted: (_) => _onRfidScanned(),
                      ),
                    ),
                  ),
                  
                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: primaryColor,
                      unselectedLabelColor: Colors.grey.shade500,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.all(4),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text('Escaneados ($escaneados)'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pending_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text('Pendientes ($pendientes)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de activos
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab escaneados
                        _escaneos.isEmpty
                            ? _buildEmptyTab('No hay escaneos aún', Icons.nfc_rounded, 'Acerca un activo con RFID')
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _escaneos.length,
                                itemBuilder: (context, index) {
                                  final scan = _escaneos[_escaneos.length - 1 - index];
                                  return _buildScanCard(scan, isScanned: true);
                                },
                              ),
                        // Tab pendientes
                        _activosPendientes.isEmpty
                            ? _buildEmptyTab('¡Todos escaneados!', Icons.celebration_rounded, 'Excelente trabajo')
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _activosPendientes.length,
                                itemBuilder: (context, index) {
                                  final activo = _activosPendientes[index];
                                  return _buildPendingCard(activo);
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _activosPendientes.isEmpty 
                  ? [successColor, const Color(0xFF059669)]
                  : [warningColor, const Color(0xFFD97706)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_activosPendientes.isEmpty ? successColor : warningColor).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _completeInventario,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _activosPendientes.isEmpty ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _activosPendientes.isEmpty ? 'Completar' : 'Finalizar con pendientes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildEmptyTab(String title, IconData icon, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard(LecturaRfid scan, {bool isScanned = false}) {
    final activo = _activosEscaneados[scan.id];
    final nombre = activo?.tipoActivo?.nombre ?? activo?.codigoInterno ?? 'Activo';
    final codigo = activo?.codigoInterno ?? scan.rfidUid;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: successColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_rounded, color: successColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  codigo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(scan.fechaLectura),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.done_all_rounded, color: successColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildPendingCard(Activo activo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pending_rounded, color: warningColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activo.tipoActivo?.nombre ?? activo.codigoInterno,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Código: ${activo.codigoInterno}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (activo.rfidUid != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.nfc_rounded, size: 12, color: secondaryColor),
                  const SizedBox(width: 4),
                  Text('RFID', style: TextStyle(fontSize: 10, color: secondaryColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}min';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
