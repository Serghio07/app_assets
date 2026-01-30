import 'package:flutter/material.dart';
import '../models/inventario.dart';

/// Pantalla de resultados del inventario RFID
/// Muestra estadísticas y detalle de activos encontrados/faltantes/sobrantes
class ResultadosScreen extends StatefulWidget {
  final int inventarioId;
  final ResultadoInventario resultados;
  final String ubicacionNombre;

  const ResultadosScreen({
    super.key,
    required this.inventarioId,
    required this.resultados,
    required this.ubicacionNombre,
  });

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Colores del tema
  static const Color primaryColor = Color(0xFF00BCD4);
  static const Color secondaryColor = Color(0xFF00838F);
  static const Color accentColor = Color(0xFF26C6DA);
  static const Color greenColor = Color(0xFF4CAF50);
  static const Color orangeColor = Color(0xFFFF9800);
  static const Color redColor = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.resultados.estadisticas;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Resultados #${widget.inventarioId}'),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _compartirResultados,
            tooltip: 'Compartir',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _exportarResultados,
            tooltip: 'Exportar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con estadísticas principales
          _buildHeader(stats),
          
          // Tabs para filtrar resultados
          _buildTabBar(),
          
          // Lista de resultados
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildResultadosList(widget.resultados.encontrados, TipoResultado.encontrado),
                _buildResultadosList(widget.resultados.faltantes, TipoResultado.faltante),
                _buildResultadosList(widget.resultados.sobrantes, TipoResultado.sobrante),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(EstadisticasInventario stats) {
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
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          children: [
            // Ubicación
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.ubicacionNombre,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Porcentaje de éxito
            _buildSuccessRate(stats),
            const SizedBox(height: 24),
            
            // Estadísticas en grid
            Row(
              children: [
                Expanded(child: _buildStatCard(
                  'Encontrados',
                  stats.encontrados.toString(),
                  Icons.check_circle_outline,
                  greenColor,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(
                  'Faltantes',
                  stats.faltantes.toString(),
                  Icons.error_outline,
                  redColor,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(
                  'Sobrantes',
                  stats.sobrantes.toString(),
                  Icons.add_circle_outline,
                  orangeColor,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRate(EstadisticasInventario stats) {
    final porcentaje = stats.porcentajeEncontrados;
    final isSuccess = porcentaje >= 90;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Círculo de progreso
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: porcentaje / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSuccess ? greenColor : orangeColor,
                  ),
                ),
                Center(
                  child: Icon(
                    isSuccess ? Icons.check : Icons.warning,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          
          // Estadísticas de texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${porcentaje.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isSuccess ? 'Inventario exitoso' : 'Revisión requerida',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.encontrados} de ${stats.totalActivosUbicacion} activos',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final stats = widget.resultados.estadisticas;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 16),
                const SizedBox(width: 4),
                Text('${stats.encontrados}'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 16),
                const SizedBox(width: 4),
                Text('${stats.faltantes}'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle, size: 16),
                const SizedBox(width: 4),
                Text('${stats.sobrantes}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadosList(List<ResultadoActivo> resultados, TipoResultado tipo) {
    if (resultados.isEmpty) {
      return _buildEmptyState(tipo);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: resultados.length,
      itemBuilder: (context, index) {
        final resultado = resultados[index];
        return _buildResultadoItem(resultado, tipo);
      },
    );
  }

  Widget _buildEmptyState(TipoResultado tipo) {
    String mensaje;
    IconData icono;
    Color color;
    
    switch (tipo) {
      case TipoResultado.encontrado:
        mensaje = 'No se encontraron activos';
        icono = Icons.search_off;
        color = Colors.grey;
        break;
      case TipoResultado.faltante:
        mensaje = '¡Excelente! No hay activos faltantes';
        icono = Icons.check_circle;
        color = greenColor;
        break;
      case TipoResultado.sobrante:
        mensaje = 'No se detectaron activos sobrantes';
        icono = Icons.inventory_2;
        color = Colors.grey;
        break;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 64, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: TextStyle(color: color, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoItem(ResultadoActivo resultado, TipoResultado tipo) {
    Color color;
    IconData icon;
    
    switch (tipo) {
      case TipoResultado.encontrado:
        color = greenColor;
        icon = Icons.check_circle;
        break;
      case TipoResultado.faltante:
        color = redColor;
        icon = Icons.error;
        break;
      case TipoResultado.sobrante:
        color = orangeColor;
        icon = Icons.add_circle;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          resultado.activoId != null 
              ? 'Activo #${resultado.activoId}'
              : 'RFID Desconocido',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: resultado.rfidUid != null
            ? Text(
                resultado.rfidUid!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tipo.value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _nuevoInventario,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Inventario'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _irAlInicio,
                icon: const Icon(Icons.home),
                label: const Text('Inicio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _compartirResultados() {
    final stats = widget.resultados.estadisticas;
    final mensaje = '''
📊 RESULTADOS DEL INVENTARIO #${widget.inventarioId}
📍 ${widget.ubicacionNombre}

✅ Encontrados: ${stats.encontrados}
❌ Faltantes: ${stats.faltantes}
➕ Sobrantes: ${stats.sobrantes}

📈 Tasa de éxito: ${stats.porcentajeEncontrados.toStringAsFixed(1)}%
''';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copiado al portapapeles'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
    
    // TODO: Implementar compartir real
    debugPrint(mensaje);
  }

  void _exportarResultados() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportando resultados...'),
      ),
    );
    
    // TODO: Implementar exportación a CSV/Excel
  }

  void _nuevoInventario() {
    // Volver a la pantalla de selección de ubicación
    Navigator.of(context).popUntil((route) => route.isFirst);
    // TODO: Navegar directamente a la pantalla de nuevo inventario
  }

  void _irAlInicio() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
