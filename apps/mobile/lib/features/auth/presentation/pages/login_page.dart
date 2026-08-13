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
    final success = await widget.controller.login(email: _email.text, password: _password.text);
    if (!mounted || !success) return;
    final remote = EventsRemoteDataSource(baseUrl: AppConfig.fromEnvironment().apiBaseUrl, token: widget.controller.session!.token);
    final workspace = EventWorkspaceRepository(ApiClient(baseUrl: AppConfig.fromEnvironment().apiBaseUrl, token: widget.controller.session!.token));
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => EventsPage(controller: EventsController(EventsRepositoryImpl(remote)), workspaceRepository: workspace)));
  }

  void _useDemoAccount() {
    _email.text = 'organizer@prowem.test';
    _password.text = 'password';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/event-care-stadium.png', fit: BoxFit.cover, alignment: Alignment.topCenter),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x16000000), Color(0x59000000), AppColors.background], stops: [0, .45, .82]))),
            SafeArea(
              child: LayoutBuilder(builder: (context, constraints) {
                final compact = constraints.maxHeight < 720;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 52),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(height: compact ? 235 : 330, child: Center(child: ProwemBrand(compact: compact))),
                        _LoginCard(controller: widget.controller, formKey: _formKey, email: _email, password: _password, showPassword: _showPassword, onTogglePassword: () => setState(() => _showPassword = !_showPassword), onDemo: _useDemoAccount, onSubmit: _submit),
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

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.controller, required this.formKey, required this.email, required this.password, required this.showPassword, required this.onTogglePassword, required this.onDemo, required this.onSubmit});

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
        width: 560,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 50, offset: Offset(0, 22))],
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Email', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextFormField(controller: email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline), hintText: 'Enter your email'), validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email.' : null),
                const SizedBox(height: 24),
                const Text('Password', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextFormField(controller: password, obscureText: !showPassword, autofillHints: const [AutofillHints.password], decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline), hintText: 'Enter your password', suffixIcon: IconButton(onPressed: onTogglePassword, icon: Icon(showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined))), validator: (value) => value == null || value.isEmpty ? 'Enter your password.' : null, onFieldSubmitted: (_) => onSubmit()),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: onDemo,
                  child: const Text('Use organizer demo account'),
                ),
                if (controller.errorMessage case final message?) ...[
                  Text(message, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 58,
                  child: FilledButton(
                    onPressed: controller.isLoading ? null : onSubmit,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white, shape: const StadiumBorder()),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(controller.isLoading ? 'Signing in…' : 'Sign In', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const Spacer(), const Icon(Icons.arrow_forward)]),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(children: [Expanded(child: Divider(color: Color(0x337D8790))), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Icon(Icons.shield_outlined, color: AppColors.muted), SizedBox(width: 8), Text('Secure access', style: TextStyle(color: AppColors.muted))])), Expanded(child: Divider(color: Color(0x337D8790)))]),
              ],
            ),
          ),
        ),
      );
}
