import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/strings.dart';
import '../../shared/app_theme.dart';
import '../../shared/brand.dart';
import '../../shared/locale_switcher.dart';
import '../../shared/theme_toggle.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _registerMode = false;
  bool _remember = false;
  // Credentials of the in-flight submit, saved or cleared once it succeeds.
  String? _pendingPhone;
  String? _pendingPassword;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await ref.read(credentialsStorageProvider).read();
    if (saved == null || !mounted) return;
    setState(() {
      _phoneController.text = saved.phone;
      _passwordController.text = saved.password;
      _remember = true;
    });
  }

  Future<void> _persistCredentials() async {
    final storage = ref.read(credentialsStorageProvider);
    if (_remember && _pendingPhone != null && _pendingPassword != null) {
      await storage.save(_pendingPhone!, _pendingPassword!);
    } else {
      await storage.clear();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (phone.isEmpty || password.isEmpty) return;
    _pendingPhone = phone;
    _pendingPassword = password;

    final controller = ref.read(authControllerProvider.notifier);
    if (_registerMode) {
      controller.register(phone, password, _nameController.text.trim());
    } else {
      controller.login(phone, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final strings = ref.watch(stringsProvider);
    final c = context.saq;
    final text = Theme.of(context).textTheme;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.status != AuthStatus.authenticated && next.status == AuthStatus.authenticated && _pendingPhone != null) {
        _persistCredentials();
      }
    });

    return Scaffold(
      appBar: AppBar(
        actions: const [LocaleSwitcher(), ThemeToggleButton(), SizedBox(width: Gap.s)],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: SaqHeroShield(size: 132)),
                const SizedBox(height: Gap.l),
                Text('SaqBol', textAlign: TextAlign.center, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: Gap.xs),
                Text(strings.tagline, textAlign: TextAlign.center, style: text.bodyLarge?.copyWith(color: c.muted)),
                const SizedBox(height: Gap.xxl),
                if (_registerMode) ...[
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: strings.name,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: Gap.m),
                ],
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    labelText: strings.phone,
                    hintText: '+7...',
                    prefixIcon: const Icon(Icons.phone_rounded),
                  ),
                ),
                const SizedBox(height: Gap.m),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: strings.password,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: Gap.xs),
                CheckboxListTile(
                  value: _remember,
                  onChanged: (value) => setState(() => _remember = value ?? false),
                  title: Text(strings.rememberMe),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (state.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(Gap.m),
                    decoration: BoxDecoration(
                      color: c.scam.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Radii.control),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: c.scam),
                        const SizedBox(width: Gap.s),
                        Expanded(child: Text(state.error!, style: TextStyle(color: c.scam))),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.m),
                ],
                const SizedBox(height: Gap.s),
                FilledButton(
                  onPressed: state.submitting ? null : _submit,
                  child: state.submitting
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: c.onAccent),
                        )
                      : Text(_registerMode ? strings.register : strings.login),
                ),
                const SizedBox(height: Gap.s),
                TextButton(
                  onPressed: () => setState(() => _registerMode = !_registerMode),
                  child: Text(_registerMode ? strings.haveAccount : strings.createAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
