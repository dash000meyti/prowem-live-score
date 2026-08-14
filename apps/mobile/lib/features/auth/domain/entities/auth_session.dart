class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class AuthUser {
  const AuthUser(
      {required this.id,
      required this.name,
      required this.email,
      required this.role});

  final int id;
  final String name;
  final String email;
  final String role;
}
