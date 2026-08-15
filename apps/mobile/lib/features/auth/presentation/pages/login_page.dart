import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/login_controller.dart';
import '../widgets/prowem_brand.dart';
import '../../../events/data/datasources/events_remote_data_source.dart';
import '../../../events/data/repositories/events_repository_impl.dart';
import '../../../events/presentation/controllers/events_controller.dart';
import '../../../events/presentation/pages/events_page.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../event_workspace/data/event_workspace_repository.dart';
import '../../../event_workspace/presentation/widgets/event_navigation_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.controller, super.key});

  final LoginController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final success = await widget.controller
        .login(email: _email.text, password: _password.text);
    if (!mounted || !success) return;
    final remote = EventsRemoteDataSource(
        baseUrl: AppConfig.fromEnvironment().apiBaseUrl,
        token: widget.controller.session!.token);
    final workspace = EventWorkspaceRepository(ApiClient(
        baseUrl: AppConfig.fromEnvironment().apiBaseUrl,
        token: widget.controller.session!.token));
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        settings: const RouteSettings(name: eventsRouteName),
        builder: (_) => EventsPage(
            controller: EventsController(EventsRepositoryImpl(remote)),
            workspaceRepository: workspace,
            user: widget.controller.session!.user,
            onLogout: widget.controller.logout)));
  }

  void _useDemoAccount() {
    _email.text = 'organizer@prowem.test';
    _password.text = 'password';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final backgroundCacheWidth = (media.size.width * media.devicePixelRatio)
        .round()
        .clamp(720, 1440)
        .toInt();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/event-care-stadium.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: backgroundCacheWidth,
              filterQuality: FilterQuality.low,
              color: const Color(0x33000000),
              colorBlendMode: BlendMode.darken),
          Image.asset('assets/images/event-care-stadium.png',
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              cacheWidth: backgroundCacheWidth,
              filterQuality: FilterQuality.low),
          const DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                Color(0x16000000),
                Color(0x4D000000),
                Color(0x8F05070A)
              ],
                      stops: [
                0,
                .42,
                1
              ]))),
          SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 480 || constraints.maxHeight < 800;
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                    16, compact ? 18 : 30, 16, compact ? 18 : 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (compact ? 36 : 54)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            tooltip: 'Back to home',
                            style: IconButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              backgroundColor: const Color(0x9912161E),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Expanded(
                            child: Center(
                              child:
                                  ProwemBrand(compact: true, horizontal: true),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      SizedBox(height: compact ? 24 : 32),
                      _LoginCard(
                          controller: widget.controller,
                          formKey: _formKey,
                          email: _email,
                          password: _password,
                          showPassword: _showPassword,
                          onTogglePassword: () =>
                              setState(() => _showPassword = !_showPassword),
                          onDemo: _useDemoAccount,
                          onSubmit: _submit),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard(
      {required this.controller,
      required this.formKey,
      required this.email,
      required this.password,
      required this.showPassword,
      required this.onTogglePassword,
      required this.onDemo,
      required this.onSubmit});

  final LoginController controller;
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onDemo;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Container(
        width: 460,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x99000000), blurRadius: 50, offset: Offset(0, 22))
          ],
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Email',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        prefixIcon: Icon(Icons.mail_outline),
                        hintText: 'Enter your email'),
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Enter a valid email.'
                        : null),
                const SizedBox(height: 14),
                const Text('Password',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                    controller: password,
                    obscureText: !showPassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: 'Enter your password',
                        suffixIcon: IconButton(
                            onPressed: onTogglePassword,
                            icon: Icon(showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined))),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password.'
                        : null,
                    onFieldSubmitted: (_) => onSubmit()),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onDemo,
                  child: const Text('Use organizer demo account'),
                ),
                if (controller.errorMessage case final message?) ...[
                  Text(message,
                      style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: controller.isLoading ? null : onSubmit,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder()),
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                              controller.isLoading ? 'Signing in…' : 'Sign In',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 2),
                            child: Icon(Icons.arrow_forward),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Row(children: [
                  Expanded(child: Divider(color: Color(0x337D8790))),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        Icon(Icons.shield_outlined, color: AppColors.muted),
                        SizedBox(width: 8),
                        Text('Secure access',
                            style: TextStyle(color: AppColors.muted))
                      ])),
                  Expanded(child: Divider(color: Color(0x337D8790)))
                ]),
              ],
            ),
          ),
        ),
      );
}
