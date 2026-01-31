# 🔴 ANÁLISIS COMPLETO: CÓDIGO QUE DEBE MOVERSE AL BACKEND

**Fecha:** 31/01/2026  
**Proyecto:** Sistema de Control de Inventario RFID  
**Estado:** TODO EL CÓDIGO ANALIZADO - LISTO PARA REFACTORING

---

## 📋 RESUMEN EJECUTIVO

El frontend Flutter está **SOBRECARGADO DE LÓGICA DE NEGOCIO** que debe estar en el backend.

### Responsabilidades Actuales (INCORRECTAS):
- ❌ Búsqueda y matching de RFID contra base de datos (EN FRONTEND)
- ❌ Validaciones de inventario (EN FRONTEND)
- ❌ Cálculo de estadísticas (EN FRONTEND)
- ❌ Lógica de duplicados (EN FRONTEND)
- ❌ Control de permisos (EN FRONTEND)

### Lo que DEBE QUEDAR en Frontend:
- ✅ Conectar Bluetooth y leer RFID
- ✅ Enviar RFID al backend
- ✅ Mostrar respuesta visual
- ✅ Mostrar lista de pendientes

---

## 🔴 CÓDIGO A MOVER AL BACKEND - ARCHIVO POR ARCHIVO

### ═══════════════════════════════════════════════════════════════

## 1. `escaneo_screen.dart` (1784 LÍNEAS) - CRÍTICO ❌❌❌

**PROBLEMA:** Contiene toda la lógica de búsqueda y matching de activos

### Líneas 96-160: LÓGICA DE BÚSQUEDA RFID EN FRONTEND
```dart
// ❌ ESTO DEBE IR AL BACKEND
Future<void> _loadActivos() async {
  try {
    debugPrint('📦 Cargando activos de ubicación ${widget.ubicacionId}...');
    
    final activos = await _apiService.getActivosPorUbicacion(
      empresaId: widget.empresaId.toString(),
      ubicacionId: widget.ubicacionId.toString(),
    );
    
    setState(() {
      _activos = activos;
      _isLoadingActivos = false;
      debugPrint('✅ ${_activos.length} activos cargados');
    });
  } catch (e) {
    debugPrint('❌ Error cargando activos: $e');
    setState(() => _isLoadingActivos = false);
  }
}
```

**PROBLEMA:** Se cargan TODOS los activos al frontend para hacer búsqueda local.

**SOLUCIÓN:** 
- El frontend NO debe cargar activos
- Enviar RFID UID al backend
- Backend devuelve: `{ activo_encontrado: true/false, activo: {...}, razon: "..." }`

### Líneas 200-300: LÓGICA DE BÚSQUEDA Y MATCHING ❌❌❌
```dart
// ❌ CÓDIGO QUE DEBE ESTAR EN EL BACKEND
void _onTagReceived(RfidTag tag) async {
  // ... línea 200-260
  
  // BÚSQUEDA LOCAL EN FRONTEND (INCORRECTO)
  final activoDetectado = _activos.firstWhere(
    (activo) {
      final rfidActivo = activo.rfidUid?.toUpperCase().trim() ?? '';
      final rfidTag = tag.epc.toUpperCase().trim();
      
      if (rfidActivo.isNotEmpty) {
        debugPrint('   ✓ Comparando: [$rfidTag] vs [$rfidActivo] (${activo.codigoInterno})');
      }
      
      // MATCH PARCIAL: BTR lee 11 bytes (22 chars), DB puede tener 12+ bytes (24+ chars)
      // Comparar: 
      // 1. Coincidencia exacta
      // 2. Si uno es más largo, verificar si el más corto está al final del más largo
      if (rfidActivo == rfidTag) {
        return true; // Coincidencia exacta
      }
      
      // Si DB es más largo, verificar si termina con el tag leído
      if (rfidActivo.length > rfidTag.length && rfidActivo.endsWith(rfidTag)) {
        debugPrint('   ✅ MATCH PARCIAL (sufijo): DB=$rfidActivo contiene Tag=$rfidTag');
        return true;
      }
      
      // Si tag es más largo, verificar si termina con el RFID del DB
      if (rfidTag.length > rfidActivo.length && rfidTag.endsWith(rfidActivo)) {
        debugPrint('   ✅ MATCH PARCIAL (sufijo): Tag=$rfidTag contiene DB=$rfidActivo');
        return true;
      }
      
      return false;
    },
    orElse: () => Activo(
      id: '',
      empresaId: '',
      codigoInterno: '',
    ),
  );
  
  // Guardar activo detectado si existe
  if (activoDetectado.id.isNotEmpty) {
    _activosDetectados[tag.epc] = activoDetectado;
    debugPrint('✅ [ESCANEO] Activo detectado: ${activoDetectado.codigoInterno}');
    
    // Mostrar notificación visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('✅ ${activoDetectado.codigoInterno} detectado')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  } else {
    debugPrint('❌ [ESCANEO] Tag NO RECONOCIDO: ${tag.epc}');
    debugPrint('❌ [ESCANEO] Este tag no está asignado a ningún activo en esta ubicación');
  }
}
```

**PROBLEMAS IDENTIFICADOS:**
1. **Búsqueda lineal** sobre todos los activos (O(n))
2. **Sin validación** de duplicados en la ubicación
3. **Sin verificación** de permisos del usuario
4. **Sin logging** de operaciones
5. **Sin manejo de timeout** o reintentos
6. **Match parcial hardcodeado** (no es flexible)
7. **Respuesta instantánea** sin validación real

**SOLUCIÓN - NUEVO ENDPOINT:**
```
POST /api/v1/inventarios/{inventarioId}/leer-rfid
Body: {
  "rfid_uid": "E200341201...",
  "rssi": -50,
  "antenna_id": 1
}

Response: {
  "success": true,
  "activo_encontrado": true,
  "activo": {
    "id": 123,
    "codigo_interno": "ACT-2025-001",
    "nombre": "Laptop Dell",
    ...
  },
  "mensaje": "Activo encontrado y validado",
  "warnings": []
}
```

### Líneas 305-315: ENVÍO DE LECTURA (INCORRECTO)
```dart
// ❌ ENVÍO INCOMPLETO - Backend NO valida
Future<void> _enviarLectura(RfidTag tag) async {
  try {
    await _apiService.enviarLecturaRfid(
      inventarioId: widget.inventarioId,
      rfidUid: tag.epc,
      tid: tag.tid,
      rssi: tag.rssi,
      antennaId: tag.antenna,
      usuarioId: widget.usuarioId,
    );
  } catch (e) {
    debugPrint('Error enviando lectura: $e');
    // No mostrar error al usuario para no interrumpir el escaneo
  }
}
```

**PROBLEMA:** Solo envía datos sin esperar validación.

---

## 2. `api_service.dart` (873 LÍNEAS) - CRÍTICO ❌❌

### Líneas 660-750: BÚSQUEDA POR RFID INCOMPLETA ❌
```dart
// ❌ MÉTODO LEGACY QUE NO VALIDA NADA
Future<Activo> searchActivoByRfid(String rfidUid) async {
  _log('RFID: Buscando activo por RFID: $rfidUid');
  
  final response = await http.get(
    Uri.parse('$baseUrl/activos/por-rfid/$rfidUid'),
    headers: _headers,
  );

  _log('RFID: Status Code: ${response.statusCode}');

  if (response.statusCode == 200) {
    final activo = Activo.fromJson(jsonDecode(response.body));
    _logSuccess('RFID: Activo encontrado: ${activo.codigoInterno}');
    return activo;
  } else if (response.statusCode == 404) {
    _logError('RFID: Activo no encontrado con RFID: $rfidUid');
    throw Exception('Activo no encontrado');
  } else {
    _logError('RFID: Error ${response.statusCode}');
    throw Exception('Error al buscar activo por RFID');
  }
}
```

**PROBLEMAS:**
1. No valida que el RFID pertenezca a la ubicación del inventario
2. No verifica si ya fue leído (no valida duplicados)
3. No valida permisos del usuario
4. No hace logging de la operación
5. No maneja reintentos
6. Búsqueda global sin filtros

### Líneas 600-650: LECTURA INDIVIDUAL SIN VALIDACIÓN ❌
```dart
// ❌ ENVÍO SIMPLE SIN VALIDACIONES
Future<LecturaRfid> enviarLecturaRfid({
  required int inventarioId,
  required String rfidUid,
  String? tid,
  int? rssi,
  int? antennaId,
  int? usuarioId,
}) async {
  _log('RFID: Enviando lectura al inventario $inventarioId');
  _log('RFID: RFID UID: $rfidUid');
  
  final body = {
    'rfid_uid': rfidUid,
    if (tid != null) 'tid': tid,
    if (rssi != null) 'rssi': rssi,
    if (antennaId != null) 'antenna_id': antennaId,
    if (usuarioId != null) 'usuario_id': usuarioId,
  };

  final response = await http.post(
    Uri.parse('$baseUrl/inventarios/$inventarioId/lectura'),
    headers: _headers,
    body: jsonEncode(body),
  );

  _log('RFID: Status Code: ${response.statusCode}');
  _log('RFID: Response Body: ${response.body}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    final lectura = LecturaRfid.fromJson(jsonDecode(response.body));
    _logSuccess('RFID: Lectura registrada exitosamente');
    return lectura;
  } else {
    _logError('RFID: Error ${response.statusCode}: ${response.body}');
    throw Exception('Error al enviar lectura RFID');
  }
}
```

**PROBLEMAS:**
- Backend debería validar todo
- Frontend asume que el backend valida (RIESGOSO)
- No hay manejo de errores específicos
- No hay reintentos

---

## 3. `inventario_provider.dart` (250 LÍNEAS) - CRÍTICO ❌

### Líneas 95-130: CONTROL LOCAL DE DUPLICADOS ❌
```dart
// ❌ ESTO DEBERÍA ESTAR EN EL BACKEND
Future<LecturaRfid?> enviarLectura({
  required String rfidUid,
  String? tid,
  int? rssi,
  int? antennaId,
  int? usuarioId,
}) async {
  if (_inventarioActual == null) {
    throw Exception('No hay inventario activo');
  }

  // ❌ VALIDACIÓN LOCAL (INCORRECTO)
  // Verificar si ya se leyó este tag
  if (_tagsUnicos.contains(rfidUid)) {
    debugPrint('⚠️ [INVENTARIO PROVIDER] Tag ya leído: $rfidUid');
    return null;
  }

  try {
    final lectura = await _apiService.enviarLecturaRfid(
      inventarioId: _inventarioActual!.id,
      rfidUid: rfidUid,
      tid: tid,
      rssi: rssi,
      antennaId: antennaId,
      usuarioId: usuarioId,
    );

    _tagsUnicos.add(rfidUid);
    _lecturas.add(lectura);

    debugPrint('🟢 [INVENTARIO PROVIDER] Lectura enviada: $rfidUid');
    notifyListeners();
    return lectura;
  } catch (e) {
    _error = e.toString();
    debugPrint('🔴 [INVENTARIO PROVIDER] Error al enviar lectura: $_error');
    // No rethrow para no interrumpir el escaneo
    return null;
  }
}
```

**PROBLEMAS:**
1. Validación de duplicados EN CLIENTE (puede falla si hay timeout)
2. Si se reinicia la app, pierde el set de únicos
3. No sincroniza con el backend
4. No maneja edge cases

### Líneas 130-170: BATCH SIN VALIDACIONES ❌
```dart
// ❌ BATCH INCOMPLETO
Future<BatchResult?> enviarLecturasBatch(List<RfidTag> tags, {int? usuarioId}) async {
  if (_inventarioActual == null) {
    throw Exception('No hay inventario activo');
  }

  // ❌ VALIDACIÓN LOCAL INCOMPLETA
  final tagsNuevos = tags.where((t) => !_tagsUnicos.contains(t.epc)).toList();
  
  if (tagsNuevos.isEmpty) {
    debugPrint('⚠️ [INVENTARIO PROVIDER] No hay lecturas nuevas en el batch');
    return null;
  }

  try {
    final resultado = await _apiService.enviarLecturasBatch(
      inventarioId: _inventarioActual!.id,
      lecturas: tagsNuevos,
      usuarioId: usuarioId,
    );

    // Agregar a tags únicos y crear LecturaRfid locales
    for (var tag in tagsNuevos) {
      _tagsUnicos.add(tag.epc);
      _lecturas.add(LecturaRfid(
        id: 0,
        inventarioId: _inventarioActual!.id,
        rfidUid: tag.epc,
        tid: tag.tid,
        rssi: tag.rssi,
        antennaId: tag.antenna,
        fechaLectura: tag.timestamp,
      ));
    }

    debugPrint('🟢 [INVENTARIO PROVIDER] Batch enviado: ${resultado.nuevas} nuevas, ${resultado.actualizadas} actualizadas');
    notifyListeners();
    return resultado;
  } catch (e) {
    _error = e.toString();
    debugPrint('🔴 [INVENTARIO PROVIDER] Error al enviar batch: $_error');
    rethrow;
  }
}
```

**PROBLEMA:** Validación de duplicados también es local.

### Líneas 180-210: CÁLCULO DE RESULTADOS ❌
```dart
// ❌ ESTADÍSTICAS PARCIALES
Future<ResultadoInventario> obtenerResultados() async {
  if (_inventarioActual == null) {
    throw Exception('No hay inventario activo');
  }

  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    // ❌ Backend devuelve resultados, pero los cálculos complejos
    // deberían estar aquí, no en el cliente
    final resultados = await _apiService.getResultadosInventario(_inventarioActual!.id);
    _resultados = resultados;
    debugPrint('🟢 [INVENTARIO PROVIDER] Resultados obtenidos');
    notifyListeners();
    return resultados;
  } catch (e) {
    _error = e.toString();
    debugPrint('🔴 [INVENTARIO PROVIDER] Error al obtener resultados: $_error');
    notifyListeners();
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**PROBLEMA:** Los cálculos de estadísticas deberían estar 100% en backend.

---

## 4. `resultados_screen.dart` (561 LÍNEAS) - CRÍTICO ❌

El frontend RECIBE los resultados y los muestra. Esto está CORRECTO.

**PERO:** Los cálculos de:
- Encontrados vs Total
- Faltantes
- Sobrantes
- Porcentaje
- Coincidencias

Deberían venir DEL BACKEND, no calcularse aquí.

---

## 5. `inventario_service.dart` (316 LÍNEAS) - INCORRECTO ❌

### Líneas 100-180: LÓGICA LOCAL DE ESTADO ❌
```dart
// ❌ ESTADO LOCAL DESINCRONIZADO
Future<LecturaRfid?> enviarLectura({
  required RfidTag tag,
  int? usuarioId,
}) async {
  if (_inventarioActivo == null) {
    _lastError = 'No hay inventario activo';
    notifyListeners();
    return null;
  }

  try {
    // ❌ VALIDACIÓN LOCAL
    final esNuevo = !_tagsUnicos.contains(tag.epc);
    
    _log('Enviando lectura: ${tag.epc} (${esNuevo ? "nuevo" : "repetido"})');
    
    final lectura = await _apiService.enviarLecturaRfid(
      inventarioId: _inventarioActivo!.id,
      rfidUid: tag.epc,
      tid: tag.tid,
      rssi: tag.rssi,
      antennaId: tag.antenna,
      usuarioId: usuarioId,
    );
    
    // ❌ ACTUALIZAR ESTADO LOCAL
    if (esNuevo) {
      _tagsUnicos.add(tag.epc);
      _tagsLeidos.insert(0, tag);
    } else {
      // Actualizar contador
      final index = _tagsLeidos.indexWhere((t) => t.epc == tag.epc);
      if (index >= 0) {
        _tagsLeidos[index].readCount++;
      }
    }
    
    notifyListeners();
    return lectura;
  } catch (e) {
    _logError('Error enviando lectura: $e');
    // No propagar error para no interrumpir el escaneo
    return null;
  }
}
```

**PROBLEMAS:**
1. Estado local es SINGLE SOURCE OF TRUTH (incorrecto)
2. Backend devuelve datos pero cliente no los usa
3. Si el backend rechaza el duplicado, el cliente no sabe
4. Sin sincronización real

---

## 📋 RESUMEN DE TODO LO QUE FALTA EN EL BACKEND

## VALIDACIONES NECESARIAS

### 1. **Validación de Duplicados Exacta**
```
- RFID ya fue leído en ESTE inventario?
  → Sí: Rechazar con HTTP 409 (Conflict)
     Response: { success: false, error: "DUPLICATE_RFID", message: "Este RFID ya fue leído" }
  → No: Continuar
```

**Ubicación Actual:** `escaneo_screen.dart` línea 230, `inventario_provider.dart` línea 110

---

### 2. **Validación de Pertenencia de Ubicación**
```
- RFID pertenece a un activo en ESTA ubicación?
  → No: Rechazar con HTTP 400
     Response: { success: false, error: "WRONG_LOCATION", 
                 message: "Este activo no pertenece a esta ubicación",
                 ubicacion_esperada: "...", ubicacion_asignada: "..." }
  → Sí: Continuar
```

**Ubicación Actual:** NO VALIDADO EN CLIENTE, FALTA EN BACKEND

---

### 3. **Búsqueda Fuzzy de RFID**
Tipos de matching:
1. **Exacto:** `E200341201AAAA === E200341201AAAA`
2. **Sufijo:** BTR lee 22 chars pero DB tiene 24+ chars
3. **Fuzzy:** Aproximado con tolerance

```
Debe hacer búsqueda:
  - Exacta primero
  - Sufijo si exacta falla
  - Fuzzy si las anteriores fallan (opcional, configurable)
```

**Ubicación Actual:** `escaneo_screen.dart` líneas 246-263

---

### 4. **Validación de Permisos del Usuario**
```
- Usuario tiene permiso para inventariar esta ubicación?
- Usuario tiene permiso para leer este tipo de activo?
- Usuario tiene permiso para este inventario?
```

**Ubicación Actual:** NO VALIDADO EN CLIENTE

---

### 5. **Manejo de Timeouts y Reintentos**
```
- Si el backend no responde en 5 segundos: reintentar
- Máximo 3 reintentos
- Exponential backoff: 1s, 2s, 4s
- Si falla después de 3 reintentos: encolar y procesar después
```

**Ubicación Actual:** NO EXISTE EN CLIENTE

---

### 6. **Logging de Operaciones**
Cada lectura RFID debe generar un log:
```json
{
  "timestamp": "2025-01-31T10:30:45Z",
  "inventario_id": 123,
  "usuario_id": 456,
  "rfid_uid": "E200341201...",
  "tipo_operacion": "LECTURA_EXITOSA|RECHAZO_DUPLICADO|RECHAZO_UBICACION|ERROR_BUSQUEDA",
  "datos": {
    "activo_encontrado": true,
    "activo_id": 789,
    "motivo_rechazo": null,
    "tiempo_procesamiento_ms": 245
  },
  "ip_origen": "192.168.1.100",
  "dispositivo": "BTR-800201220017"
}
```

**Ubicación Actual:** Logs solo en consola del cliente (líneas 241, 265 en escaneo_screen.dart)

---

### 7. **Cálculo de Estadísticas Finales**
```
Backend DEBE calcular:
- Total activos en ubicación
- Encontrados (RFID leído)
- Faltantes (No se leyó)
- Sobrantes (Se leyó pero no existe)
- Porcentaje de cobertura
- Tiempo promedio por activo
- Tasa de éxito
```

**Ubicación Actual:** `resultados_screen.dart` línea 39-100 (frontend lee datos del backend, pero cálculos deberían estar en backend)

---

## 🛠️ REFACTORING REQUERIDO POR ARCHIVO

### ARCHIVO: `escaneo_screen.dart`

**ELIMINAR (TODO A BACKEND):**
- Líneas 1-50: Imports de servicios innecesarios
- Líneas 80-160: `_loadActivos()` - NO CARGAR ACTIVOS AL FRONTEND
- Líneas 200-300: `_onTagReceived()` - LÓGICA DE BÚSQUEDA/MATCHING (MOVER AL BACKEND)
- Líneas 305-315: `_enviarLectura()` - SIMPLIFICAR
- Líneas 80-100: `_activos`, `_activosDetectados` (ESTADO LOCAL INNECESARIO)

**MANTENER (FRONTEND):**
- Conexión Bluetooth
- Lectura de stream de tags
- Mostrar UI de escaneo
- Pausar/reanudar escaneo
- Finalizar inventario

**NUEVO FLUJO:**
```dart
void _onTagReceived(RfidTag tag) async {
  setState(() {
    _tagsLeidos.insert(0, tag);  // Mostrar en pantalla
  });
  
  // Enviar al backend y esperar respuesta
  final respuesta = await _apiService.procesarRfid(
    inventarioId: widget.inventarioId,
    rfidUid: tag.epc,
    rssi: tag.rssi,
    antenna: tag.antenna,
  );
  
  setState(() {
    if (respuesta.exitoso) {
      // ✅ RFID válido - Mostrar notificación
      _mostrarNotificacion(
        '✅ ${respuesta.activo?.codigoInterno} detectado',
        Colors.green
      );
    } else {
      // ❌ RFID rechazado - Mostrar motivo
      _mostrarNotificacion(
        '❌ ${respuesta.mensaje}',
        Colors.red
      );
    }
  });
}
```

---

### ARCHIVO: `api_service.dart`

**ELIMINAR:**
- Línea 660-750: `searchActivoByRfid()` - MÉTODO LEGACY

**REEMPLAZAR:**
- Líneas 600-650: `enviarLecturaRfid()` → `procesarRfidCompleto()`

**NUEVO ENDPOINT:**
```dart
Future<RfidResponse> procesarRfidCompleto({
  required int inventarioId,
  required String rfidUid,
  required int rssi,
  required int antenna,
}) async {
  final body = {
    'rfid_uid': rfidUid,
    'rssi': rssi,
    'antenna_id': antenna,
  };

  final response = await http.post(
    Uri.parse('$baseUrl/inventarios/$inventarioId/procesar-rfid'),
    headers: _headers,
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    return RfidResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Error: ${response.body}');
  }
}
```

**RESPUESTA ESPERADA:**
```json
{
  "success": true,
  "rfid_uid": "E200341201...",
  "activo_encontrado": true,
  "activo": {
    "id": 123,
    "codigo_interno": "ACT-2025-001",
    "nombre": "Laptop Dell",
    "ubicacion_id": 456,
    "responsable": {...}
  },
  "mensaje": "Activo registrado en inventario",
  "warnings": [],
  "tiempo_procesamiento_ms": 245
}
```

O si hay error:
```json
{
  "success": false,
  "rfid_uid": "E200341201...",
  "activo_encontrado": false,
  "error_tipo": "DUPLICATE_RFID|WRONG_LOCATION|NOT_FOUND|PERMISSION_DENIED",
  "mensaje": "Este RFID ya fue leído en este inventario",
  "warnings": ["El RFID podría estar dañado"],
  "tiempo_procesamiento_ms": 150
}
```

---

### ARCHIVO: `inventario_provider.dart`

**ELIMINAR COMPLETAMENTE:**
- Líneas 110-130: `_tagsUnicos` - VALIDACIÓN LOCAL
- Líneas 95-130: `enviarLectura()` - SIMPLIFICAR
- Líneas 130-170: `enviarLecturasBatch()` - SIMPLIFICAR
- Línea 115-120: Validación de duplicados

**REEMPLAZAR CON:**
```dart
// Solo gestionar estado de UI, no lógica de negocio
Future<RfidResponse> procesarRfid(RfidTag tag) async {
  return await _apiService.procesarRfidCompleto(
    inventarioId: _inventarioActual!.id,
    rfidUid: tag.epc,
    rssi: tag.rssi,
    antenna: tag.antenna,
  );
}
```

---

### ARCHIVO: `inventario_service.dart`

**ELIMINAR:**
- Líneas 100-180: Toda la lógica de validación local
- Líneas 19-20: `_tagsUnicos`, `_tagsLeidos`
- Método `enviarLectura()`
- Método `enviarLecturasBatch()`

**MANTENER:**
- Estado del inventario actual
- Carga/creación de inventarios

---

## 🔴 CHECKLIST DE IMPLEMENTACIÓN BACKEND

### FASE 1: Endpoints Base (CRÍTICO)
- [ ] `POST /api/v1/inventarios/{id}/procesar-rfid` - LEER + VALIDAR + BUSCAR (TODO EN 1)
  - Input: `{ rfid_uid, rssi, antenna_id }`
  - Output: `{ success, activo, error_tipo, mensaje }`
  - Validaciones: Duplicados, pertenencia, permisos
  - Logging: Todas las operaciones
  - Timeout: 5s con reintentos

- [ ] `POST /api/v1/inventarios/{id}/cerrar` - CALCULAR RESULTADOS
  - Input: `{ }`
  - Output: `{ inventario, estadisticas, resultados_detallados }`
  - Cálculos: encontrados, faltantes, sobrantes, porcentaje
  - Logging: Cierre de inventario

- [ ] `GET /api/v1/inventarios/{id}/resultados` - RETORNAR RESULTADOS
  - Output: `{ estadisticas, encontrados[], faltantes[], sobrantes[] }`

### FASE 2: Validaciones (CRÍTICO)
- [ ] Duplicados exactos (mismo inventario, mismo RFID)
- [ ] Duplicados por sufijo (BTR 22 chars vs DB 24 chars)
- [ ] Pertenencia de ubicación (activo.ubicacion_id == inventario.ubicacion_id)
- [ ] Permisos del usuario (verficar roles)
- [ ] Activo existe en base de datos

### FASE 3: Búsqueda Fuzzy (IMPORTANTE)
- [ ] Búsqueda exacta: `RFID == RFID`
- [ ] Búsqueda por sufijo: `DB.endsWith(RFID)`
- [ ] Búsqueda fuzzy opcional: Levenshtein distance < 3

### FASE 4: Reintentos y Resilencia (IMPORTANTE)
- [ ] Implementar retry logic con exponential backoff
- [ ] Timeout configurable (default 5s)
- [ ] Queue para peticiones fallidas
- [ ] Health check del dispositivo RFID

### FASE 5: Logging (IMPORTANTE)
- [ ] Tabla `logs_rfid` con toda la información
- [ ] Timestamps precisos (microsegundos)
- [ ] IP del cliente
- [ ] ID del dispositivo RFID
- [ ] Todos los errores y rechazos

### FASE 6: Cálculo de Estadísticas (CRÍTICO)
- [ ] Encontrados: `COUNT(lecturas.rfid_uid)`
- [ ] Total: `COUNT(activos en ubicación)`
- [ ] Faltantes: `Total - Encontrados`
- [ ] Sobrantes: `Lecturas RFID sin activo`
- [ ] Porcentaje: `(Encontrados / Total) * 100`
- [ ] Tiempo promedio: `AVG(tiempo procesamiento)`

---

## 📊 TABLA: QIÉN HACE QUÉ (ANTES vs DESPUÉS)

| Tarea | Antes (INCORRECTO) | Después (CORRECTO) |
|-------|-------|--------|
| **Leer RFID** | Frontend (Bluetooth) | Frontend (Bluetooth) ✅ |
| **Buscar activo** | Frontend (SQL local simulado) | Backend (SQL + índices) ✅ |
| **Validar duplicado** | Frontend (Set local) | Backend (DB constraint) ✅ |
| **Validar ubicación** | ❌ FALTA | Backend (foreign key) ✅ |
| **Validar permisos** | ❌ FALTA | Backend (middleware) ✅ |
| **Matching parcial** | Frontend (hardcodeado) | Backend (configurable) ✅ |
| **Reintentos** | ❌ FALTA | Backend (exponential backoff) ✅ |
| **Logging** | Frontend (console) | Backend (DB table) ✅ |
| **Estadísticas** | Frontend (local) | Backend (aggregate SQL) ✅ |
| **Mostrar resultado** | Frontend | Frontend ✅ |

---

## 🚀 BENEFICIOS DEL REFACTORING

1. **Seguridad:** Backend valida todo (no confiar en cliente)
2. **Integridad:** DB constraints garantizan datos válidos
3. **Escalabilidad:** Lógica centralizada = más fácil mantener
4. **Auditabilidad:** Logs completos de todas las operaciones
5. **Resilencia:** Reintentos automáticos, manejo de errores
6. **Performance:** Índices en DB, búsquedas optimizadas
7. **Mantenibilidad:** Un solo lugar para cambiar reglas de negocio

---

## ⚠️ RIESGOS ACTUALES (SI NO SE CAMBIA)

1. **Data Loss:** Validaciones perdidas si el cliente falla
2. **Duplicados:** Sin garantía de no-duplicación
3. **Inconsistencia:** Estado local ≠ estado servidor
4. **Seguridad:** Cliente NO debe confiar en sí mismo
5. **Auditoría:** No hay logs confiables de operaciones
6. **Timeout:** Sin reintentos = pérdida de RFID válidos

---

## 📝 PRÓXIMOS PASOS

1. **Crear endpoints en backend** (lista de verificación arriba)
2. **Testear con datos reales** (RFID con varios formats)
3. **Agregar retry logic** (exponential backoff)
4. **Implementar logging** (tabla en DB)
5. **Refactorizar frontend** (eliminar lógica de negocio)
6. **Verificar estadísticas** (cálculos en backend)
7. **QA completo** (edge cases, timeouts, errores)

---

**Documento preparado para refactoring completo del sistema.**  
**Arquitectura final: Frontend SOLO UI/UX, Backend TODA LA LÓGICA.**
