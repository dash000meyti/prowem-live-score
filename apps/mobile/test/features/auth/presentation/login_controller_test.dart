import 'package:event_care_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:event_care_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:event_care_mobile/features/auth/presentation/controllers/login_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes a successful authenticated session', () async {
    final controller = LoginController(_FakeAuthRepository());
    final result = await controller.login(email: 'organizer@prowem.test', password: 'password');
    expect(result, isTrue);
    expect(controller.session?.user.role, 'organizer');
    expect(controller.isLoading, isFalse);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({required String email, required String password}) async => AuthSession(token: 'token', user: AuthUser(id: 1, name: 'Organizer', email: email, role: 'organizer'));

  @override
  Future<void> logout() async {}
}
