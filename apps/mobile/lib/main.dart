import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/controllers/login_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final repository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(baseUrl: config.apiBaseUrl),
  );

  runApp(EventCareApp(loginController: LoginController(repository)));
}
