import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remoteDataSource, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'event_care_token';
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    final session = await remoteDataSource.login(email: email, password: password);
    await _storage.write(key: _tokenKey, value: session.token);
    return session;
  }

  @override
  Future<void> logout() => _storage.delete(key: _tokenKey);
}
