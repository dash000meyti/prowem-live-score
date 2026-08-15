import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class LoginController extends ChangeNotifier {
  LoginController(this._repository);

  final AuthRepository _repository;
  bool isLoading = false;
  String? errorMessage;
  AuthSession? session;

  Future<bool> login({required String email, required String password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      session =
          await _repository.login(email: email.trim(), password: password);
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Unable to reach the sign-in service.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    session = null;
    errorMessage = null;
    notifyListeners();
  }
}
