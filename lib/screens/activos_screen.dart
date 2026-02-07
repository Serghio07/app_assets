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

  static const Color primaryColor = Color(0xFFE74C3C);
  static const Color secondaryColor = Color(0xFFC0392B);

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Activos'),
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
                Text('Empresa: ${widget.empresa.nombre}', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                const SizedBox(height: 4),
                Text('Sucursal: ${widget.sucursal.nombre}', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                const SizedBox(height: 4),
                Text('Ubicación: ${widget.ubicacion.nombre}', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                const SizedBox(height: 8),
                Text('${_activos.length} activos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
          ),
          // Lista
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)));
          try {
            final authProvider = context.read<AuthProvider>();
            final inventarioProvider = context.read<InventarioProvider>();
            final inventario = await inventarioProvider.createInventario(
              empresaId: int.parse(widget.empresa.id),
              ubicacionId: int.parse(widget.ubicacion.id),
            );
            if (!mounted) return;
            Navigator.pop(context);
            Navigator.pushNamed(context, '/escaneo', arguments: {
              'inventarioId': inventario.id,
              'empresaId': int.parse(widget.empresa.id),
              'ubicacionId': int.parse(widget.ubicacion.id),
              'ubicacionNombre': widget.ubicacion.nombre,
              'usuarioId': authProvider.usuario?.id != null ? int.tryParse(authProvider.usuario!.id) : null,
            });
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('Error: $e'))]),
                backgroundColor: Colors.red.shade400,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Escanear'),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: primaryColor));
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text('Error al cargar activos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _loadActivos, icon: const Icon(Icons.refresh_rounded), label: const Text('Reintentar'), style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white)),
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
            Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No hay activos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadActivos,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activos.length,
        itemBuilder: (context, index) {
          final activo = _activos[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showActivoDetails(activo),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getIconForActivo(activo.tipoActivo?.nombre), size: 20, color: primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(activo.tipoActivo?.nombre ?? 'Activo', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(activo.codigoInterno, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        if (activo.estadoActivo != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: _getEstadoColor(activo.estadoActivo!.nombre).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text(activo.estadoActivo!.nombre, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getEstadoColor(activo.estadoActivo!.nombre))),
                          ),
                      ],
                    ),
                    if (activo.rfidUid != null) ...[
                      const SizedBox(height: 10),
                      Text('RFID: ${activo.rfidUid}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'monospace')),
                    ],
                  ],
                ),
              ),
            ),
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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(activo.tipoActivo?.nombre ?? 'Activo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(activo.codigoInterno, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 20),
                _DetailSection('Información', [
                  ('Código', activo.codigoInterno),
                  if (activo.rfidUid != null) ('RFID', activo.rfidUid!),
                  if (activo.estadoActivo != null) ('Estado', activo.estadoActivo!.nombre),
                  if (activo.valorInicial != null) ('Valor', '\$${activo.valorInicial!.toStringAsFixed(2)}'),
                ]),
                if (activo.responsable != null) ...[
                  const SizedBox(height: 16),
                  _DetailSection('Responsable', [
                    ('Nombre', activo.responsable!.nombre),
                    ('Tipo', activo.responsable!.tipo),
                    if (activo.responsable!.identificador != null) ('ID', activo.responsable!.identificador!),
                  ]),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForActivo(String? nombre) {
    if (nombre == null) return Icons.inventory_2_rounded;
    final n = nombre.toLowerCase();
    if (n.contains('laptop') || n.contains('computador')) return Icons.laptop_rounded;
    if (n.contains('escritorio') || n.contains('mesa')) return Icons.desk_rounded;
    if (n.contains('servidor')) return Icons.dns_rounded;
    if (n.contains('monitor')) return Icons.monitor_rounded;
    return Icons.inventory_2_rounded;
  }

  Color _getEstadoColor(String estado) {
    final e = estado.toLowerCase();
    if (e.contains('servicio') || e.contains('disponible')) return const Color(0xFF10B981);
    if (e.contains('mantenimiento')) return const Color(0xFFF59E0B);
    if (e.contains('baja')) return const Color(0xFFEF4444);
    return Colors.grey;
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<(String, String)> items;

  const _DetailSection(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
          const SizedBox(height: 12),
          ...List.generate(
            items.length,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i < items.length - 1 ? 10 : 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(items[i].$1, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ),
                  Expanded(child: Text(items[i].$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
