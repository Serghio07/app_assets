import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/rfid_tag.dart';
import '../services/api_service.dart';
import '../services/bluetooth_rfid_service.dart';
import '../providers/providers.dart';
import 'sucursales_screen.dart';
import 'ubicaciones_screen.dart';
import 'activos_screen.dart';

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
  int _currentStep = 0;

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF374151);

  @override
  void initState() {
    super.initState();
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
      _showErrorSnackBar('Selecciona una sucursal');
      return;
    }

    if (_activos == null || _activos!.isEmpty) {
      _showErrorSnackBar('No hay activos en esta ubicaciÃ³n');
      return;
    }

    try {
      final inventarioProvider = context.read<InventarioProvider>();
      
      // Debug: imprimir IDs originales
      debugPrint('ðŸ”µ [INVENTARIO SCREEN] empresaId original: "${widget.empresaId}"');
      debugPrint('ðŸ”µ [INVENTARIO SCREEN] ubicacionId original: "${_ubicacionSeleccionada!.id}"');
      
      // Parsear IDs a int (el API espera enteros)
      final empresaIdInt = int.tryParse(widget.empresaId);
      final ubicacionIdInt = int.tryParse(_ubicacionSeleccionada!.id);
      
      // Validar que los IDs se parsearon correctamente
      if (empresaIdInt == null) {
        _showErrorSnackBar('Error: empresaId no es un nÃºmero vÃ¡lido: "${widget.empresaId}"');
        return;
      }
      if (ubicacionIdInt == null) {
        _showErrorSnackBar('Error: ubicacionId no es un nÃºmero vÃ¡lido: "${_ubicacionSeleccionada!.id}"');
        return;
      }
      
      debugPrint('ðŸ”µ [INVENTARIO SCREEN] empresaId parseado: $empresaIdInt');
      debugPrint('ðŸ”µ [INVENTARIO SCREEN] ubicacionId parseado: $ubicacionIdInt');
      
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
      debugPrint('ðŸ”´ [INVENTARIO SCREEN] Error al crear inventario: $e');
      _showErrorSnackBar('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nuevo Inventario'),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Info simple - minimalista
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  primaryColor.withValues(alpha: 0.85),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuario: ${widget.usuario.nombre}',
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Empresa: ${widget.usuario.empresa?.nombre ?? 'Empresa'}',
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
                const SizedBox(height: 16),
                _buildStepper(),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentStep == 0)
                    SucursalesStep(
                      empresaId: widget.empresaId,
                      onLoadStart: () {},
                      onLoadComplete: () {},
                      onError: _showErrorSnackBar,
                      onSucursalSelected: (sucursal) {
                        setState(() {
                          _sucursalSeleccionada = sucursal;
                          _ubicacionSeleccionada = null;
                          _ubicaciones = null;
                          _activos = null;
                        });
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            setState(() => _currentStep = 1);
                          }
                        });
                      },
                    ),
                  if (_currentStep == 1)
                    UbicacionesStep(
                      empresaId: widget.empresaId,
                      sucursalSeleccionada: _sucursalSeleccionada!,
                      onLoadStart: () {},
                      onLoadComplete: () {},
                      onError: _showErrorSnackBar,
                      onUbicacionSelected: (ubicacion) {
                        setState(() {
                          _ubicacionSeleccionada = ubicacion;
                        });
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            setState(() => _currentStep = 2);
                          }
                        });
                      },
                    ),
                  if (_currentStep == 2)
                    ActivosStep(
                      empresaId: widget.empresaId,
                      sucursalSeleccionada: _sucursalSeleccionada!,
                      ubicacionSeleccionada: _ubicacionSeleccionada!,
                      onLoadStart: () {},
                      onLoadComplete: () {},
                      onError: _showErrorSnackBar,
                      onActivosLoaded: (activos) {
                        setState(() => _activos = activos);
                      },
                    ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive 
                ? Colors.white 
                : Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: isCurrent 
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Icon(
            icon,
            color: isActive ? primaryColor : Colors.white.withValues(alpha: 0.6),
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isComplete = _currentStep > step;
    return Container(
      height: 2,
      width: 20,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isComplete 
            ? Colors.white 
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1),
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
  final Map<String, ActivoInfo> _activosDetectados = {}; // rfidUid -> ActivoInfo (desde backend)
  bool _isLoading = false;
  late TabController _tabController;
  
  // âœ… REMOVIDO: _activosPendientes - El backend tiene todos los activos
  // âœ… REMOVIDO: _activosEscaneados - Usamos info del backend
  // âœ… REMOVIDO: _processedTags - El backend maneja duplicados

  static const Color primaryColor = Color(0xFFE74C3C);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color secondaryColor = Color(0xFFC0392B);

  @override
  void initState() {
    super.initState();
    debugPrint('ðŸš€ [INVENTARIO_SCANNER] initState ejecutado!');
    debugPrint('ðŸ”— [INVENTARIO_SCANNER] Servicio Bluetooth (singleton): ${_bluetoothService.hashCode}');
    
    // âœ… SIMPLIFICADO: Ya NO copiamos activos localmente
    _rfidController.addListener(_onRfidScanned);
    _tabController = TabController(length: 2, vsync: this);
    
    // â­ INICIAR ESCUCHA DE TAGS RFID
    _startBluetoothListener();
  }
  
  // âœ… REMOVIDO: _isFuzzyMatch() - El backend tiene bÃºsqueda inteligente con 3 estrategias
  
  void _startBluetoothListener() {
    debugPrint('ðŸŽ§ [INVENTARIO_SCANNER] Iniciando listener de tags Bluetooth...');
    debugPrint('ðŸ“‹ [INVENTARIO_SCANNER] Total activos en ubicaciÃ³n: ${widget.activos.length}');
    
    _tagSubscription?.cancel();
    _tagSubscription = _bluetoothService.tagStream.listen(
      _onBluetoothTagReceived,
      onError: (error) => debugPrint('âŒ [INVENTARIO_SCANNER] Error en stream: $error'),
      onDone: () => debugPrint('âš ï¸ [INVENTARIO_SCANNER] Stream cerrado'),
    );
    debugPrint('âœ… [INVENTARIO_SCANNER] Listener activo, esperando tags...');
  }
  
  /// âœ… SIMPLIFICADO: Solo envÃ­a al backend para procesamiento completo
  void _onBluetoothTagReceived(RfidTag tag) async {
    debugPrint('ðŸ”µ [INVENTARIO_SCANNER] Tag Bluetooth recibido: ${tag.epc}');
    
    // âœ… NUEVO: Enviar al backend para procesamiento completo
    await _procesarRfidEnBackend(tag);
  }
  
  /// âœ… NUEVO: Procesa RFID en backend con TODA la lÃ³gica
  Future<void> _procesarRfidEnBackend(RfidTag tag) async {
    try {
      final respuesta = await _apiService.procesarRfid(
        inventarioId: widget.inventario.id,
        rfidUid: tag.epc,
        rssi: tag.rssi,
        antennaId: tag.antenna,
        tid: tag.tid,
      );
      
      if (!mounted) return;
      
      if (respuesta.success && respuesta.activoEncontrado) {
        // âœ… Activo encontrado - ACTUALIZAR ESTADO
        setState(() {
          // Agregar activo detectado
          if (respuesta.activo != null) {
            _activosDetectados[tag.epc] = respuesta.activo!;
          }
          
          // Actualizar o agregar escaneo (evitar duplicados)
          final indiceExistente = _escaneos.indexWhere((e) => e.rfidUid == tag.epc);
          if (indiceExistente != -1) {
            // Ya existe - actualizar contador
            _escaneos[indiceExistente] = LecturaRfid(
              id: _escaneos[indiceExistente].id,
              inventarioId: widget.inventario.id,
              rfidUid: tag.epc,
              fechaLectura: DateTime.now(),
              cantidadLecturas: respuesta.vecesEscaneado ?? 1,
            );
          } else {
            // Nuevo - agregar al inicio
            _escaneos.insert(0, LecturaRfid(
              id: DateTime.now().millisecondsSinceEpoch,
              inventarioId: widget.inventario.id,
              rfidUid: tag.epc,
              fechaLectura: DateTime.now(),
              cantidadLecturas: 1,
            ));
          }
        });
        
        // Mostrar notificaciÃ³n SOLO para nuevos (no duplicados)
        if (respuesta.esDuplicado != true) {
          final mensaje = 'âœ… ${respuesta.activo?.codigoInterno ?? tag.epc} detectado';
          _mostrarNotificacion(mensaje, successColor);
        }
        
        // Mostrar warnings si existen
        if (respuesta.tieneWarnings) {
          for (var warning in respuesta.warnings) {
            debugPrint('âš ï¸ WARNING: $warning');
          }
        }
      } else {
        // âŒ Error o no encontrado
        _mostrarNotificacion(respuesta.mensaje, Colors.red);
      }
    } catch (e) {
      debugPrint('âŒ Error procesando RFID en backend: $e');
    }
  }
  
  void _mostrarNotificacion(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == successColor ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  
  // âœ… REMOVIDO: _registrarEscaneo() - El backend procesa todo
  // âœ… REMOVIDO: _enviarLecturaAlBackend() - procesarRfid() lo hace automÃ¡ticamente

  @override
  void dispose() {
    _tagSubscription?.cancel();
    _rfidController.removeListener(_onRfidScanned);
    _rfidController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// âœ… SIMPLIFICADO: Solo envÃ­a al backend
  Future<void> _onRfidScanned() async {
    if (_rfidController.text.isEmpty) return;

    final rfidUid = _rfidController.text.trim();
    _rfidController.clear();

    setState(() => _isLoading = true);

    try {
      // âœ… NUEVO: Usar procesarRfid del backend
      final respuesta = await _apiService.procesarRfid(
        inventarioId: widget.inventario.id,
        rfidUid: rfidUid,
      );
      
      if (respuesta.success && respuesta.activoEncontrado) {
        setState(() {
          // Agregar activo detectado
          if (respuesta.activo != null) {
            _activosDetectados[rfidUid] = respuesta.activo!;
          }
          
          // Actualizar o agregar escaneo (evitar duplicados)
          final indiceExistente = _escaneos.indexWhere((e) => e.rfidUid == rfidUid);
          if (indiceExistente != -1) {
            // Ya existe - actualizar contador
            _escaneos[indiceExistente] = LecturaRfid(
              id: _escaneos[indiceExistente].id,
              inventarioId: widget.inventario.id,
              rfidUid: rfidUid,
              fechaLectura: DateTime.now(),
              cantidadLecturas: respuesta.vecesEscaneado ?? 1,
            );
          } else {
            // Nuevo - agregar al inicio
            _escaneos.insert(0, LecturaRfid(
              id: DateTime.now().millisecondsSinceEpoch,
              inventarioId: widget.inventario.id,
              rfidUid: rfidUid,
              fechaLectura: DateTime.now(),
              cantidadLecturas: 1,
            ));
          }
        });
        
        // Mostrar notificaciÃ³n SOLO para nuevos (no duplicados)
        if (respuesta.esDuplicado != true) {
          _mostrarNotificacion(respuesta.mensaje, successColor);
        }
      } else {
        _mostrarNotificacion(respuesta.mensaje, Colors.red);
      }
      
      setState(() => _isLoading = false);
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

  Future<void> _completeInventario() async {
    // âœ… SIMPLIFICADO: Calcular pendientes desde datos del backend
    final escaneados = _activosDetectados.length;
    final total = widget.activos.length;
    final pendientes = total - escaneados;
    
    if (pendientes > 0) {
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
          content: Builder(
            builder: (context) {
              final pendientes = widget.activos.length - _activosDetectados.length;
              return Text(
                'Quedan $pendientes activos por escanear.\nÂ¿Deseas completar de todas formas?',
              );
            },
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
              const Text('Â¡Inventario completado exitosamente!'),
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
    // âœ… SIMPLIFICADO: Calcular estadÃ­sticas desde backend
    final int escaneados = _activosDetectados.length; // Activos Ãºnicos detectados
    final int total = widget.activos.length;
    final int pendientes = total - escaneados;
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
                const Text('Â¿Salir del inventario?'),
              ],
            ),
            content: const Text('Se perderÃ¡ el progreso del inventario actual.'),
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
                        colors: [primaryColor, Color(0xFFF39C12)],
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
                              // CÃ­rculo de progreso
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
                            ? _buildEmptyTab('No hay escaneos aÃºn', Icons.nfc_rounded, 'Acerca un activo con RFID')
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _escaneos.length,
                                itemBuilder: (context, index) {
                                  final scan = _escaneos[_escaneos.length - 1 - index];
                                  return _buildScanCard(scan, isScanned: true);
                                },
                              ),
                        // Tab pendientes - âœ… Calcular dinÃ¡micamente
                        () {
                          final activosPendientes = widget.activos
                              .where((a) => !_activosDetectados.values.any((info) => info.id == a.id))
                              .toList();
                          
                          return activosPendientes.isEmpty
                              ? _buildEmptyTab('Â¡Todos escaneados!', Icons.celebration_rounded, 'Excelente trabajo')
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: activosPendientes.length,
                                  itemBuilder: (context, index) {
                                    final activo = activosPendientes[index];
                                    return _buildPendingCard(activo);
                                  },
                                );
                        }(),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: Builder(
          builder: (context) {
            // âœ… Calcular pendientes dinÃ¡micamente
            final pendientes = widget.activos.length - _activosDetectados.length;
            final hayPendientes = pendientes > 0;
            
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hayPendientes
                      ? [warningColor, const Color(0xFFD97706)]
                      : [successColor, const Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (hayPendientes ? warningColor : successColor).withValues(alpha: 0.4),
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
                          hayPendientes ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          hayPendientes ? 'Finalizar con pendientes' : 'Completar',
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
            );
          },
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
    // âœ… Obtener info del activo desde backend
    final activoInfo = _activosDetectados[scan.rfidUid];
    final nombre = activoInfo?.tipoActivo ?? 'Activo';
    final codigo = activoInfo?.codigoInterno ?? scan.rfidUid;
    
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
                  'CÃ³digo: ${activo.codigoInterno}',
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


