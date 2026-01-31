import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../providers/providers.dart';

class ActivosScreen extends StatefulWidget {
  final Empresa empresa;
  final Sucursal sucursal;
  final Ubicacion ubicacion;

  const ActivosScreen({
    super.key,
    required this.empresa,
    required this.sucursal,
    required this.ubicacion,
  });

  @override
  State<ActivosScreen> createState() => _ActivosScreenState();
}

class _ActivosScreenState extends State<ActivosScreen> {
  final ApiService _apiService = ApiService();
  List<Activo> _activos = [];
  bool _isLoading = true;
  String? _error;

  static const Color primaryColor = Color(0xFF00BCD4);
  static const Color secondaryColor = Color(0xFF00838F);

  @override
  void initState() {
    super.initState();
    _loadActivos();
  }

  Future<void> _loadActivos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activos = await _apiService.getActivosPorUbicacion(
        empresaId: widget.empresa.id,
        ubicacionId: widget.ubicacion.id,
      );
      setState(() {
        _activos = activos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Inventario de Activos'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header con información de la ubicación
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, Color(0xFF26C6DA), secondaryColor],
                stops: [0.0, 0.5, 1.0],
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
                  // Breadcrumb
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _BreadcrumbChip(
                        icon: Icons.business_rounded,
                        text: widget.empresa.nombre,
                      ),
                      _BreadcrumbChip(
                        icon: Icons.store_rounded,
                        text: widget.sucursal.nombre,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ubicacion.nombre,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (widget.ubicacion.responsable != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Responsable: ${widget.ubicacion.responsable!.nombre}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Contador de activos
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
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
                            Icons.inventory_2_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isLoading
                              ? 'Cargando...'
                              : '${_activos.length} activo(s) en esta ubicación',
                          style: const TextStyle(
                            fontSize: 14,
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

          // Lista de activos
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [primaryColor, secondaryColor]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            // Mostrar loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            );

            try {
              // Crear inventario primero
              final authProvider = context.read<AuthProvider>();
              final inventarioProvider = context.read<InventarioProvider>();
              
              final inventario = await inventarioProvider.createInventario(
                empresaId: int.parse(widget.empresa.id),
                ubicacionId: int.parse(widget.ubicacion.id),
              );

              if (!mounted) return;
              Navigator.pop(context); // Cerrar loading

              // Navegar a escaneo con el inventario creado
              Navigator.pushNamed(
                context,
                '/escaneo',
                arguments: {
                  'inventarioId': inventario.id,
                  'empresaId': int.parse(widget.empresa.id),
                  'ubicacionId': int.parse(widget.ubicacion.id),
                  'ubicacionNombre': widget.ubicacion.nombre,
                  'usuarioId': authProvider.usuario?.id != null 
                    ? int.tryParse(authProvider.usuario!.id)
                    : null,
                },
              );
            } catch (e) {
              if (!mounted) return;
              Navigator.pop(context); // Cerrar loading
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Error al crear inventario: $e')),
                    ],
                  ),
                  backgroundColor: Colors.red.shade400,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Escanear'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
              ),
              const SizedBox(height: 20),
              Text(
                'Error al cargar activos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primaryColor, secondaryColor]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton.icon(
                  onPressed: _loadActivos,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_activos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay activos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta ubicación no tiene activos registrados',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivos,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _activos.length,
        itemBuilder: (context, index) {
          final activo = _activos[index];
          return _ActivoCard(
            activo: activo,
            onTap: () => _showActivoDetails(activo),
          );
        },
      ),
    );
  }

  void _showActivoDetails(Activo activo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActivoDetailsSheet(activo: activo),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BreadcrumbChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ActivoCard extends StatelessWidget {
  final Activo activo;
  final VoidCallback onTap;

  static const Color primaryColor = Color(0xFF00BCD4);
  static const Color secondaryColor = Color(0xFF00838F);

  const _ActivoCard({
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getColorForTipoActivo(activo.tipoActivo?.nombre),
                            _getColorForTipoActivo(activo.tipoActivo?.nombre).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _getColorForTipoActivo(activo.tipoActivo?.nombre).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIconForTipoActivo(activo.tipoActivo?.nombre),
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activo.tipoActivo?.nombre ?? 'Activo',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withValues(alpha: 0.1),
                                  secondaryColor.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              activo.codigoInterno,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (activo.estadoActivo != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(activo.estadoActivo!.nombre)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getEstadoColor(activo.estadoActivo!.nombre)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          activo.estadoActivo!.nombre,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getEstadoColor(activo.estadoActivo!.nombre),
                          ),
                        ),
                      ),
                  ],
                ),
                if (activo.rfidUid != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.nfc_rounded,
                            size: 14,
                            color: secondaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'RFID: ${activo.rfidUid}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (activo.responsable != null || activo.valorInicial != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (activo.responsable != null)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activo.responsable!.nombre,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (activo.valorInicial != null) ...[
                          if (activo.responsable != null)
                            Container(
                              width: 1,
                              height: 20,
                              color: Colors.grey.shade300,
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                size: 16,
                                color: const Color(0xFF10B981),
                              ),
                              Text(
                                '\$${activo.valorInicial!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForTipoActivo(String? nombre) {
    if (nombre == null) return Icons.inventory_2_rounded;
    final nombreLower = nombre.toLowerCase();
    if (nombreLower.contains('laptop') || nombreLower.contains('computador')) {
      return Icons.laptop_rounded;
    } else if (nombreLower.contains('escritorio') || nombreLower.contains('mesa')) {
      return Icons.desk_rounded;
    } else if (nombreLower.contains('servidor')) {
      return Icons.dns_rounded;
    } else if (nombreLower.contains('perforadora') || nombreLower.contains('maquinaria')) {
      return Icons.precision_manufacturing_rounded;
    } else if (nombreLower.contains('cargador') || nombreLower.contains('vehículo')) {
      return Icons.local_shipping_rounded;
    } else if (nombreLower.contains('monitor')) {
      return Icons.monitor_rounded;
    }
    return Icons.inventory_2_rounded;
  }

  Color _getColorForTipoActivo(String? nombre) {
    if (nombre == null) return primaryColor;
    final nombreLower = nombre.toLowerCase();
    if (nombreLower.contains('laptop') || nombreLower.contains('computador')) {
      return const Color(0xFF3B82F6);
    } else if (nombreLower.contains('escritorio') || nombreLower.contains('mesa')) {
      return const Color(0xFF92400E);
    } else if (nombreLower.contains('servidor')) {
      return const Color(0xFF8B5CF6);
    } else if (nombreLower.contains('perforadora') || nombreLower.contains('maquinaria')) {
      return const Color(0xFFF97316);
    } else if (nombreLower.contains('cargador')) {
      return const Color(0xFFD97706);
    }
    return primaryColor;
  }

  Color _getEstadoColor(String estado) {
    final estadoLower = estado.toLowerCase();
    if (estadoLower.contains('servicio') || estadoLower.contains('disponible')) {
      return const Color(0xFF10B981);
    } else if (estadoLower.contains('mantenimiento') || estadoLower.contains('reparación')) {
      return const Color(0xFFF59E0B);
    } else if (estadoLower.contains('baja') || estadoLower.contains('depreciado')) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF6B7280);
  }
}

class _ActivoDetailsSheet extends StatelessWidget {
  final Activo activo;

  static const Color primaryColor = Color(0xFF00BCD4);
  static const Color secondaryColor = Color(0xFF00838F);

  const _ActivoDetailsSheet({required this.activo});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Header con icono
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryColor, secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activo.tipoActivo?.nombre ?? 'Activo',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor.withValues(alpha: 0.15), secondaryColor.withValues(alpha: 0.15)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            activo.codigoInterno,
                            style: const TextStyle(
                              fontSize: 14,
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Detalles en tarjetas
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.qr_code_rounded,
                      label: 'Código Interno',
                      value: activo.codigoInterno,
                    ),
                    if (activo.rfidUid != null) ...[
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.nfc_rounded,
                        label: 'RFID UID',
                        value: activo.rfidUid!,
                      ),
                    ],
                    if (activo.estadoActivo != null) ...[
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.flag_rounded,
                        label: 'Estado',
                        value: activo.estadoActivo!.nombre,
                        valueColor: _getEstadoColor(activo.estadoActivo!.nombre),
                      ),
                    ],
                    if (activo.valorInicial != null) ...[
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.attach_money_rounded,
                        label: 'Valor Inicial',
                        value: '\$${activo.valorInicial!.toStringAsFixed(2)}',
                        valueColor: const Color(0xFF10B981),
                      ),
                    ],
                  ],
                ),
              ),

              if (activo.responsable != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withValues(alpha: 0.08), secondaryColor.withValues(alpha: 0.08)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_rounded, size: 18, color: primaryColor),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Responsable',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.badge_rounded,
                        label: 'Nombre',
                        value: activo.responsable!.nombre,
                      ),
                      const Divider(height: 20),
                      _DetailRow(
                        icon: Icons.work_rounded,
                        label: 'Tipo',
                        value: activo.responsable!.tipo,
                      ),
                      if (activo.responsable!.identificador != null) ...[
                        const Divider(height: 20),
                        _DetailRow(
                          icon: Icons.credit_card_rounded,
                          label: 'Identificador',
                          value: activo.responsable!.identificador!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Color _getEstadoColor(String estado) {
    final estadoLower = estado.toLowerCase();
    if (estadoLower.contains('servicio') || estadoLower.contains('disponible')) {
      return const Color(0xFF10B981);
    } else if (estadoLower.contains('mantenimiento') || estadoLower.contains('reparación')) {
      return const Color(0xFFF59E0B);
    } else if (estadoLower.contains('baja') || estadoLower.contains('depreciado')) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF6B7280);
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  static const Color primaryColor = Color(0xFF00BCD4);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: primaryColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
