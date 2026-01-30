import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Usuario? _usuario;
  Empresa? _empresaActual;
  bool _isLoading = false;
  String? _error;

  Usuario? get usuario => _usuario;
  Empresa? get empresaActual => _empresaActual;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _usuario != null;

  // Logger helper
  void _log(String message) {
    debugPrint('🟣 [AUTH] $message');
  }

  // Inicializar - cargar token guardado
  Future<void> initialize() async {
    _log('Inicializando AuthProvider...');
    await _apiService.loadToken();
    _log('Token cargado: ${_apiService.isAuthenticated}');
    
    if (_apiService.isAuthenticated) {
      try {
        _log('Obteniendo perfil del usuario...');
        _usuario = await _apiService.getProfile();
        _log('Usuario cargado: ${_usuario?.nombre}');
        
        // Cargar la empresa vinculada al usuario
        await _loadEmpresaDelUsuario();
        notifyListeners();
      } catch (e) {
        _log('Error al inicializar: $e');
        await _apiService.clearToken();
      }
    }
  }

  // Cargar la empresa del usuario
  Future<void> _loadEmpresaDelUsuario() async {
    _log('Cargando empresa del usuario...');
    
    if (_usuario == null) {
      _log('Usuario es null, no se puede cargar empresa');
      return;
    }
    
    _log('Usuario empresaId: ${_usuario!.empresaId}');
    _log('Usuario empresa object: ${_usuario!.empresa?.nombre}');
    
    // Si el usuario ya tiene la empresa cargada en el response
    if (_usuario!.empresa != null) {
      _empresaActual = _usuario!.empresa;
      _log('Empresa cargada desde response: ${_empresaActual?.nombre}');
      return;
    }
    
    // Si solo tiene el empresa_id, cargar la empresa
    if (_usuario!.empresaId != null) {
      try {
        _log('Cargando empresa por ID: ${_usuario!.empresaId}');
        _empresaActual = await _apiService.getEmpresa(_usuario!.empresaId!);
        _log('Empresa cargada: ${_empresaActual?.nombre}');
      } catch (e) {
        _log('Error al cargar empresa del usuario: $e');
      }
    } else {
      _log('No hay empresa_id ni empresa en el usuario');
    }
  }

  // Login
  Future<bool> login(String email, String contrasena) async {
    _log('========================================');
    _log('INICIO LOGIN');
    _log('Email: $email');
    _log('========================================');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _usuario = await _apiService.login(email, contrasena);
      _log('Login exitoso, usuario: ${_usuario?.nombre}');
      
      // Cargar la empresa vinculada al usuario
      await _loadEmpresaDelUsuario();
      
      _log('Empresa actual después de login: ${_empresaActual?.nombre}');
      _log('========================================');
      _log('FIN LOGIN EXITOSO');
      _log('========================================');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _log('========================================');
      _log('ERROR EN LOGIN: $e');
      _log('========================================');
      
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _log('Cerrando sesión...');
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } finally {
      _usuario = null;
      _empresaActual = null;
      _isLoading = false;
      _log('Sesión cerrada');
      notifyListeners();
    }
  }

  // Seleccionar empresa
  void setEmpresa(Empresa empresa) {
    _log('Cambiando empresa a: ${empresa.nombre}');
    _empresaActual = empresa;
    notifyListeners();
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
