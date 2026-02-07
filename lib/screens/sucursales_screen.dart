import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class SucursalesStep extends StatefulWidget {
  final String empresaId;
  final VoidCallback onLoadStart;
  final VoidCallback onLoadComplete;
  final Function(String) onError;
  final Function(Sucursal) onSucursalSelected;

  const SucursalesStep({
    super.key,
    required this.empresaId,
    required this.onLoadStart,
    required this.onLoadComplete,
    required this.onError,
    required this.onSucursalSelected,
  });

  @override
  State<SucursalesStep> createState() => _SucursalesStepState();
}

class _SucursalesStepState extends State<SucursalesStep> {
  final ApiService _apiService = ApiService();
  List<Sucursal>? _sucursales;
  Sucursal? _sucursalSeleccionada;
  bool _isLoading = true;

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF374151);

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
      if (mounted) {
        setState(() {
          _sucursales = sucursales;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onError('Error al cargar sucursales: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Selecciona una Sucursal', Icons.store_rounded),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: primaryColor),
            ),
          )
        else if (_sucursales == null || _sucursales!.isEmpty)
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
                });
                widget.onSucursalSelected(sucursal);
              },
            );
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
