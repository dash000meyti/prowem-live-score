import '../../domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.token, required super.user});

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    return AuthSessionModel(
      token: data['token'] as String,
      user: AuthUser(
        id: user['id'] as int,
        name: user['name'] as String,
        email: user['email'] as String,
        role: user['role'] as String,
      ),
    );
  }
}
