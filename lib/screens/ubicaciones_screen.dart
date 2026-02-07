import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class UbicacionesScreen extends StatefulWidget {
  final Empresa empresa;
  final Sucursal sucursal;

  const UbicacionesScreen({
    super.key,
    required this.empresa,
    required this.sucursal,
  });

  @override
  State<UbicacionesScreen> createState() => _UbicacionesScreenState();
}

class _UbicacionesScreenState extends State<UbicacionesScreen> {
  final ApiService _apiService = ApiService();
  List<Ubicacion> _ubicaciones = [];
  bool _isLoading = true;
  String? _error;

  static const Color primaryColor = Color(0xFFE74C3C);
  static const Color secondaryColor = Color(0xFFC0392B);

  @override
  void initState() {
    super.initState();
    _loadUbicaciones();
  }

  Future<void> _loadUbicaciones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ubicaciones = await _apiService.getUbicaciones(
        empresaId: widget.empresa.id,
        sucursalId: widget.sucursal.id,
      );
      setState(() {
        _ubicaciones = ubicaciones;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ubicaciones'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info simple
          Container(
            width: double.infinity,
            color: primaryColor.withValues(alpha: 0.05),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Empresa: ${widget.empresa.nombre}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sucursal: ${widget.sucursal.nombre}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),

          // Lista de ubicaciones
          Expanded(
            child: _buildContent(),
          ),
        ],
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
                'Error al cargar ubicaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primaryColor, secondaryColor]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton.icon(
                  onPressed: _loadUbicaciones,
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

    if (_ubicaciones.isEmpty) {
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
              child: Icon(Icons.location_off_rounded, size: 56, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay ubicaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta sucursal no tiene ubicaciones registradas',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUbicaciones,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _ubicaciones.length,
        itemBuilder: (context, index) {
          final ubicacion = _ubicaciones[index];
          return _UbicacionCard(
            ubicacion: ubicacion,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/activos',
                arguments: {
                  'empresa': widget.empresa,
                  'sucursal': widget.sucursal,
                  'ubicacion': ubicacion,
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _UbicacionCard extends StatelessWidget {
  final Ubicacion ubicacion;
  final VoidCallback onTap;

  static const Color primaryColor = Color(0xFFE74C3C);
  static const Color successColor = Color(0xFF10B981);

  const _UbicacionCard({
    required this.ubicacion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIconForUbicacion(ubicacion.nombre),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ubicacion.nombre,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ubicacion.permiteInventario
                                  ? successColor.withValues(alpha: 0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ubicacion.permiteInventario
                                    ? successColor.withValues(alpha: 0.3)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ubicacion.permiteInventario
                                      ? Icons.check_circle_rounded
                                      : Icons.block_rounded,
                                  size: 12,
                                  color: ubicacion.permiteInventario
                                      ? successColor
                                      : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ubicacion.permiteInventario
                                      ? 'Inventariable'
                                      : 'No inventariable',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: ubicacion.permiteInventario
                                        ? successColor
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (ubicacion.responsable != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                ubicacion.responsable!.nombre,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForUbicacion(String nombre) {
    final nombreLower = nombre.toLowerCase();
    if (nombreLower.contains('almacén') || nombreLower.contains('almacen')) {
      return Icons.warehouse_rounded;
    } else if (nombreLower.contains('oficina')) {
      return Icons.meeting_room_rounded;
    } else if (nombreLower.contains('tránsito') || nombreLower.contains('transito')) {
      return Icons.local_shipping_rounded;
    } else if (nombreLower.contains('bodega')) {
      return Icons.inventory_rounded;
    }
    return Icons.location_on_rounded;
  }
}

