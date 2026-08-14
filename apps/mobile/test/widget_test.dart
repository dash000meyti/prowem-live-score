import 'package:event_care_mobile/app/app.dart';
import 'package:event_care_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:event_care_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:event_care_mobile/features/auth/presentation/controllers/login_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens on home and enters the organizer login', (tester) async {
    await tester.pumpWidget(
        EventCareApp(loginController: LoginController(_FakeAuthRepository())));

    expect(find.text('CONTROL EVERY\nMOMENT.'), findsOneWidget);
    expect(find.text('Enter Event Care'), findsOneWidget);

    await tester.tap(find.text('Enter Event Care'));
    await tester.pumpAndSettle();

    expect(find.text('Use organizer demo account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login(
          {required String email, required String password}) async =>
      AuthSession(
          token: 'test-token',
          user: AuthUser(
              id: 1, name: 'Organizer', email: email, role: 'organizer'));

  @override
  Future<void> logout() async {}
}
