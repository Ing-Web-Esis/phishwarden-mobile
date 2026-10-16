import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../data/models/link_models.dart';

class WelcomeViewModel extends ChangeNotifier {
  WelcomeViewModel(this._repository);
  final AuthRepository _repository;
  bool isLoading = false;
  String? errorMessage;
  bool _disposed = false;

  static String? validateCode(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Ingresa el código de tu sala o empresa.';
    }
    return null;
  }

  static String? validateEmail(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Ingresa tu correo corporativo.';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(input.trim())) {
      return 'Escribe un correo válido, como nombre@empresa.com.';
    }
    // El dominio corporativo permitido se verificará en el servidor.
    return null;
  }

  Future<LinkResult?> submit(String code, String email) async {
    if (_disposed || isLoading) return null;
    errorMessage = validateCode(code) ?? validateEmail(email);
    if (errorMessage != null) {
      notifyListeners();
      return null;
    }
    isLoading = true;
    notifyListeners();
    try {
      return await _repository.linkDevice(
        LinkRequest(companyCode: code.trim(), email: email.trim()),
      );
    } on LinkFailure catch (failure) {
      errorMessage = failure.message;
      return null;
    } catch (_) {
      errorMessage = 'Ocurrió un problema. Inténtalo nuevamente.';
      return null;
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
