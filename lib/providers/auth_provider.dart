import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, this._notificationService) {
    initialize();
  }

  final AuthService _authService;
  final NotificationService _notificationService;

  AuthStatus _status = AuthStatus.loading;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _notificationService.initialize();

    final hasToken = await _authService.hasToken();
    if (!hasToken) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    await fetchProfile();
  }

  Future<bool> login(String email, String password) async {
    _clearError();
    try {
      _currentUser = await _authService.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();

      // Best effort sync with profile endpoint if available.
      try {
        _currentUser = await _authService.me();
      } catch (_) {}

      try {
        await _notificationService.syncToken();
      } catch (_) {
        // Do not fail login when FCM token sync fails.
      }

      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } catch (e) {
      _errorMessage = e.toString();
    }

    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _clearError();
    try {
      _currentUser = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();

      try {
        _currentUser = await _authService.me();
      } catch (_) {}

      try {
        await _notificationService.syncToken();
      } catch (_) {
        // Do not fail registration when FCM token sync fails.
      }

      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } catch (e) {
      _errorMessage = e.toString();
    }

    notifyListeners();
    return false;
  }

  Future<bool> loginWithGoogle() async {
    _clearError();
    try {
      _currentUser = await _authService.loginWithGoogle();
      _status = AuthStatus.authenticated;
      notifyListeners();

      try {
        _currentUser = await _authService.me();
      } catch (_) {}

      try {
        await _notificationService.syncToken();
      } catch (_) {
        // Do not fail Google login when FCM token sync fails.
      }
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } catch (e) {
      _errorMessage = e.toString();
    }

    notifyListeners();
    return false;
  }

  Future<void> fetchProfile() async {
    try {
      _currentUser = await _authService.me();
      _status = AuthStatus.authenticated;
      try {
        await _notificationService.syncToken();
      } catch (_) {
        // Keep session alive even if FCM endpoint is temporarily unavailable.
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        await _authService.logout();
      } else {
        // Preserve token/session for transient server/network failures.
        _status = AuthStatus.authenticated;
      }
    } catch (_) {
      // Preserve existing session on non-auth related failures.
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _notificationService.deleteTokenRegistration();
    } catch (_) {
      // Keep logout flow even if token unregister fails.
    }
    await _authService.logout();
    _status = AuthStatus.unauthenticated;
    _currentUser = null;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? 'Terjadi kesalahan.';
    }
    return 'Terjadi kesalahan jaringan.';
  }
}
