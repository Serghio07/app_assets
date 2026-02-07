import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ActivosStep extends StatefulWidget {
  final String empresaId;
  final Sucursal sucursalSeleccionada;
  final Ubicacion ubicacionSeleccionada;
  final VoidCallback onLoadStart;
  final VoidCallback onLoadComplete;
  final Function(String) onError;
  final Function(List<Activo>) onActivosLoaded;

  const ActivosStep({
    super.key,
    required this.empresaId,
    required this.sucursalSeleccionada,
    required this.ubicacionSeleccionada,
    required this.onLoadStart,
    required this.onLoadComplete,
    required this.onError,
    required this.onActivosLoaded,
  });

  @override
  State<ActivosStep> createState() => _ActivosStepState();
}

class _ActivosStepState extends State<ActivosStep> {
  final ApiService _apiService = ApiService();
  List<Activo>? _activos;
  bool _isLoading = true;

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF374151);

  @override
  void initState() {
    super.initState();
    _loadActivos();
  }

  Future<void> _loadActivos() async {
    setState(() => _isLoading = true);
    try {
      final activos = await _apiService.getActivosPorUbicacion(
        empresaId: widget.empresaId,
        ubicacionId: widget.ubicacionSeleccionada.id,
      );
      if (mounted) {
        setState(() {
          _activos = activos;
          _isLoading = false;
        });
        widget.onActivosLoaded(activos);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onError('Error al cargar activos: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badges: Sucursal + Ubicación seleccionadas
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: [
            _buildSelectedBadge(
              widget.sucursalSeleccionada.nombre,
              Icons.store_rounded,
              compact: true,
            ),
            _buildSelectedBadge(
              widget.ubicacionSeleccionada.nombre,
              Icons.location_on_rounded,
              color: const Color(0xFF22C55E),
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 20),
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
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: primaryColor),
            ),
          )
        else if (_activos == null || _activos!.isEmpty)
          _buildEmptyState('No hay activos en esta ubicación', Icons.inventory_2_outlined)
        else
          ...List.generate(_activos!.length, (index) {
            final activo = _activos![index];
            return _buildActivoCard(activo);
          }),
      ],
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

  Widget _buildSelectedBadge(
    String text,
    IconData icon, {
    Color color = const Color(0xFFE74C3C),
    bool compact = false,
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
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2_rounded, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activo.tipoActivo?.nombre ?? 'Sin tipo',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activo.codigoInterno,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
