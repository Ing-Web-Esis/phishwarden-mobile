import 'package:flutter/foundation.dart';

import '../data/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._repository);
  final ProfileRepository _repository;
  EmployeeProfile? profile;
  bool isLoading = false;
  String? errorMessage;
  bool _disposed = false;

  Future<void> load() async {
    if (isLoading || _disposed) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await _repository.load();
    } catch (_) {
      errorMessage = 'No se pudo cargar el perfil. Vuelve a intentarlo.';
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
