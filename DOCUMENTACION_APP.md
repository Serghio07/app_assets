# 📦 Documentación - Sistema de Gestión de Activos

## 🎯 ¿Qué hace la aplicación?

**APP_ASSETS** es una aplicación Flutter diseñada para la **gestión de inventarios de activos fijos** mediante tecnología RFID. Permite a las empresas realizar inventarios rápidos, precisos y automáticos de sus activos.

### Funcionalidades principales:

1. **Autenticación de Usuarios**
   - Login con usuario y contraseña
   - Gestión de sesiones
   - Pantalla de bienvenida (Splash Screen)

2. **Gestión de Empresas y Sucursales**
   - Ver empresas registradas en el sistema
   - Navegar entre diferentes sucursales (oficinas/almacenes)
   - Ver información de responsables por sucursal

3. **Inventarios de Activos**
   - Crear nuevos inventarios para ubicaciones específicas
   - Escanear activos con lectores RFID
   - Realizar conteos manuales de activos
   - Ver historial de escaneos

4. **Consulta de Activos**
   - Visualizar todos los activos de una ubicación
   - Ver detalles: código, RFID UID, estado, valor, responsable
   - Buscar activos por código o RFID

---

## 🏗️ Arquitectura de la aplicación

```
lib/
├── main.dart                    # Punto de entrada, configuración de temas
├── models/                      # Modelos de datos
│   ├── activo.dart             # Representa un activo fijo
│   ├── categoria.dart          # Categorías de activos
│   ├── empresa.dart            # Empresas
│   ├── inventario.dart         # Inventarios y escaneos RFID
│   ├── responsable.dart        # Personas responsables
│   ├── sucursal.dart           # Sucursales/oficinas
│   ├── ubicacion.dart          # Ubicaciones dentro de sucursales
│   ├── usuario.dart            # Usuarios del sistema
│   └── models.dart             # Exporta todos los modelos
│
├── providers/                   # State management (Provider pattern)
│   ├── auth_provider.dart      # Gestiona autenticación y sesión
│   ├── inventario_provider.dart # Gestiona lógica de inventarios
│   └── providers.dart          # Exporta todos los providers
│
├── services/                    # Servicios de comunicación
│   ├── api_service.dart        # Conecta con backend API
│   └── services.dart           # Exporta servicios
│
└── screens/                     # Pantallas UI
    ├── login_screen.dart       # Pantalla de login
    ├── home_screen.dart        # Dashboard principal
    ├── sucursales_screen.dart  # Listado de sucursales
    ├── ubicaciones_screen.dart # Listado de ubicaciones
    ├── activos_screen.dart     # Listado de activos
    ├── inventario_screen.dart  # Pantalla de inventario + scanner
    └── screens.dart            # Exporta todas las pantallas
```

---

## 🔄 Flujo de navegación

```
┌─────────────────────┐
│  SplashScreen       │  (Pantalla inicial animada)
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  LoginScreen        │  (Usuario ingresa credenciales)
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  HomeScreen         │  (Dashboard con opciones principales)
└──────────┬──────────┘
           │
    ┌──────┴──────────────────────────┐
    │                                 │
    ↓                                 ↓
┌──────────────────┐        ┌─────────────────┐
│ SucursalesScreen │        │ InventarioScreen│
│ (Seleccionar     │        │ (Crear nuevo    │
│  sucursal)       │        │  inventario)    │
└────────┬─────────┘        └────────┬────────┘
         │                           │
         ↓                           ↓
┌──────────────────┐        ┌─────────────────┐
│ UbicacionesScreen│        │ UbicacionesScreen
│ (Seleccionar     │        │ (Seleccionar    │
│  ubicación)      │        │  ubicación)     │
└────────┬─────────┘        └────────┬────────┘
         │                           │
         ↓                           ↓
    ┌────────────────────────────────┐
    │   ActivosScreen                │
    │   (Ver activos de ubicación)   │
    └────────────────────────────────┘
                 │
                 │
         [Click en "Escanear"]
                 │
                 ↓
         ┌─────────────────────┐
         │ InventarioScreen    │
         │ (Crear inventario)  │
         └──────────┬──────────┘
                    │
         [Seleccionar sucursal]
                    │
                    ↓
         ┌─────────────────────┐
         │ UbicacionesScreen   │
         └──────────┬──────────┘
                    │
         [Seleccionar ubicación]
                    │
                    ↓
      ┌────────────────────────────┐
      │ SCANNER SCREEN             │  ← AQUÍ COMIENZA EL ESCANEO
      │ (InventarioScannerScreen)  │
      └────────────────────────────┘
```

---

## 🚀 ¿Qué necesita para iniciar el Scanner?

### Requisitos previos en la base de datos:

1. **Empresa registrada**
   - ID único
   - Nombre
   - Datos de contacto

2. **Sucursal/Oficina**
   - Asociada a una empresa
   - Nombre identificable
   - Responsable asignado

3. **Ubicación dentro de la sucursal**
   - Nombre (almacén, oficina 1, etc.)
   - Responsable asignado
   - Asociada a una sucursal

4. **Activos registrados en la ubicación**
   - Código interno único
   - RFID UID (etiqueta RFID asignada)
   - Tipo de activo
   - Estado actual
   - Valor inicial (opcional)
   - Responsable asignado

5. **Usuario autenticado**
   - Credenciales válidas
   - Sesión activa en la aplicación

---

## 📱 Pasos para iniciar el Scanner

### Opción 1: Desde HOME (Dashboard)

```
1. Inicia sesión
   └─ Ingresa usuario y contraseña
   └─ Toca "Iniciar Sesión"

2. Accede al Dashboard (HomeScreen)
   └─ Verás tarjetas con opciones
   └─ Busca la tarjeta "Nuevo Inventario" o "Escanear Activos"

3. Selecciona Sucursal
   └─ La app muestra lista de sucursales disponibles
   └─ Toca la sucursal deseada
   └─ Se cargan las ubicaciones

4. Selecciona Ubicación
   └─ La app muestra ubicaciones de esa sucursal
   └─ Toca la ubicación a inventariar
   └─ Se cargan los activos de esa ubicación

5. Inicia Escaneo
   └─ Verás un botón "Iniciar Escaneo"
   └─ Se abre: InventarioScannerScreen

6. ¡SCANNER ACTIVO!
   └─ Campo de entrada RFID listo para escanear
```

### Opción 2: Desde ACTIVOS (Pantalla de activos)

```
1. Navega a una ubicación
   └─ Home → Sucursal → Ubicación

2. Verás tarjeta de "ActivosScreen"
   └─ Botón flotante "Escanear" (inferior derecha)
   └─ Toca el botón

3. ¡SCANNER ACTIVO!
   └─ Se abre: InventarioScannerScreen
```

---

## 🎯 Flujo del Scanner en detalle

### InventarioScannerScreen - Pantalla principal

```
┌────────────────────────────────────────┐
│         Header Gradiente               │
│  ┌──────────────────────────────────┐ │
│  │ Ubicación: [Nombre Ubicación]    │ │
│  │ Responsable: [Nombre]            │ │
│  │ Progress: [██████░░░░░░] 40%     │ │
│  └──────────────────────────────────┘ │
└────────────────────────────────────────┘
┌────────────────────────────────────────┐
│     Campo RFID INPUT                   │
│  ┌──────────────────────────────────┐ │
│  │ 🔲 Acerca el RFID o ingresa cód  │ │
│  │                                   │ │
│  └──────────────────────────────────┘ │
└────────────────────────────────────────┘
┌────────────────────────────────────────┐
│        TABS - Escaneados/Pendientes    │
│  [✓ Escaneados (12)]  [⏳ Pendientes] │
├────────────────────────────────────────┤
│                                        │
│  [Listado de escaneos/pendientes]     │
│                                        │
└────────────────────────────────────────┘
┌────────────────────────────────────────┐
│   Barra inferior acciones              │
│  [Completar Inventario] [Salir]       │
└────────────────────────────────────────┘
```

### Proceso de escaneo paso a paso:

```
1️⃣  Usuario acerca lector RFID al activo
    └─ El lector captura el RFID UID
    └─ Ej: "E280691234567890"

2️⃣  El RFID UID se envía al campo input
    └─ Se dispara onSubmitted()
    └─ Método _onRfidScanned() se ejecuta

3️⃣  Búsqueda del activo en backend
    └─ API: GET /activos/por-rfid/{rfidUid}
    └─ Retorna objeto Activo con todos los datos
    └─ Ej: 
       {
         "id": "123",
         "codigoInterno": "ACT-2024-001",
         "rfidUid": "E280691234567890",
         "tipo_activo": "Laptop",
         "estado": "En Servicio"
       }

4️⃣  Validación del activo
    └─ Verifica que el activo pertenezca a la ubicación
    └─ Si NO pertenece: AVISO (naranja)
    └─ Si SÍ pertenece: Continuar

5️⃣  Registro del escaneo en backend
    └─ API: POST /rfid-scans
    └─ Envía: inventario_id, activo_id, rfid_uid, usuario_id, timestamp
    └─ Retorna: RfidScan object

6️⃣  Actualización de listas locales
    └─ Agrega scan a: _escaneos
    └─ Remueve activo de: _activosPendientes
    └─ Recalcula progreso

7️⃣  Feedback visual
    └─ Animación de éxito (check verde)
    └─ SnackBar: "ACT-2024-001 escaneado correctamente"
    └─ Se limpia el campo RFID
    └─ Listo para siguiente escaneo
```

---

## 🔧 API Endpoints necesarios

### Para el Scanner:

```
GET  /activos/por-rfid/{rfidUid}
     Busca un activo por su código RFID

POST /rfid-scans
     Registra un nuevo escaneo
     Body: {
       inventario_id: string,
       activo_id: string,
       rfid_uid: string,
       usuario_id: string,
       ubicacion_id?: string,
       nota?: string
     }

GET  /inventarios/{inventarioId}/escaneos
     Obtiene todos los escaneos de un inventario

POST /inventarios/{inventarioId}/completar
     Marca el inventario como completado
```

### Datos necesarios en el Scanner:

```
✅ ANTES de iniciar:
   - Empresa ID (del usuario autenticado)
   - Sucursal ID (seleccionada por usuario)
   - Ubicación ID (seleccionada por usuario)
   - Usuario ID (autenticado)
   - Lista de activos en esa ubicación

❌ ERRORES comunes:
   - No hay activos registrados en la ubicación
   - Activos sin RFID UID asignado
   - Backend API no responde
   - Usuario no tiene permisos en esa empresa
```

---

## 📊 Modelos de datos principales

### Inventario
```dart
class Inventario {
  String id;              // ID único
  String empresaId;       // Empresa donde se hace inventario
  String sucursalId;      // Sucursal específica
  String ubicacionId;     // Ubicación específica
  String usuarioId;       // Usuario que realiza
  int totalActivos;       // Total de activos a inventariar
  int activosEscaneados;  // Activos ya escaneados
  String estado;          // PENDIENTE, EN_PROGRESO, COMPLETADO
  DateTime fechaInicio;
  DateTime? fechaFin;
}
```

### RfidScan (Escaneo)
```dart
class RfidScan {
  String id;              // ID del escaneo
  String inventarioId;    // A qué inventario pertenece
  String activoId;        // Qué activo se escaneó
  String rfidUid;         // Código RFID del lector
  String usuarioId;       // Quién lo escaneó
  DateTime timestamp;     // Cuándo se escaneó
}
```

### Activo
```dart
class Activo {
  String id;
  String codigoInterno;   // Código único de la empresa
  String? rfidUid;        // Código RFID ⚠️ OBLIGATORIO para scanner
  String? tipoActivo;
  String? estado;
  double? valorInicial;
  Responsable? responsable;
  String? ubicacionActualId;  // Validación en scanner
}
```

---

## ⚙️ Configuración técnica

### Dependencias principales:
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0           # State management
  http: ^1.1.0               # HTTP requests
  
dev_dependencies:
  flutter_test:
    sdk: flutter
```

### Puertos y URLs:
- Base URL del API: Definida en `api_service.dart` (baseUrl)
- Port: Típicamente 8080 o 3000
- Protocolo: HTTP/HTTPS

---

## 🐛 Troubleshooting - Problemas comunes

### El scanner no inicia
```
❌ Problema: "No hay activos en esta ubicación"
✅ Solución: 
   1. Verificar que la ubicación tenga activos registrados
   2. Verificar que los activos tengan RFID UID asignado
   3. Sincronizar datos desde el backend
```

### RFID no escanea
```
❌ Problema: "Activo no encontrado"
✅ Solución:
   1. Verificar que el RFID UID está correcto en BD
   2. Verificar que el hardware del lector funciona
   3. Revisar logs en consola
```

### Escaneo exitoso pero se marca como "ubicación diferente"
```
❌ Problema: "Activo en ubicación diferente"
✅ Solución:
   1. El activo está asignado a otra ubicación en BD
   2. Actualizar ubicacionActualId en BD del activo
   3. Sincronizar cambios
```

### Inventario se queda pegado
```
❌ Problema: Aplicación lenta
✅ Solución:
   1. Revisar conexión a internet
   2. Revisar estado del backend API
   3. Hacer hot restart (R en terminal)
   4. Cerrar app y reabrir
```

---

## 📝 Ejemplo de uso real

```
ESCENARIO: Inventariar Almacén de Laptops

1. Usuario: María García
   Empresa: TechCorp S.A.
   Rol: Responsable de Inventario

2. María inicia sesión con sus credenciales

3. Dashboard: Ve opción "Nuevo Inventario"

4. Selecciona:
   - Sucursal: "Oficina Central"
   - Ubicación: "Almacén A"

5. Se cargan 15 laptops pendientes:
   - ACT-2024-001: Laptop Dell
   - ACT-2024-002: Laptop HP
   - ... (13 más)

6. Se abre scanner:
   - Acerca lector RFID a laptop 1
   - Se escanea automáticamente
   - Muestra ✓ ACT-2024-001 escaneado
   - Progress: 1/15

7. Repite con las 14 laptops restantes

8. Progress llega a 15/15 (100%)

9. María toca "Completar Inventario"

10. Sistema registra todos los escaneos
    - Fecha y hora
    - Usuario responsable
    - Tiempo total

11. Inventario finalizado ✓
    - Datos guardados en backend
    - Historial disponible
```

---

## 📞 Contacto y Soporte

Para problemas técnicos o consultas sobre el scanner:
- Revisar logs en consola (Flutter DevTools)
- Verificar estado de backend API
- Consultar documentación de API
- Revisar estado de conexión de red

---

**Documento generado:** 30 Enero 2026  
**Versión:** 1.0  
**Estado:** Documentación completa del scanner RFID
