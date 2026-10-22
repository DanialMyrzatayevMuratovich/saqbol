import 'package:flutter/material.dart';

import '../../shared/app_theme.dart';
import '../../shared/locale_switcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/strings.dart';
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

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.status != AuthStatus.authenticated && next.status == AuthStatus.authenticated && _pendingPhone != null) {
        _persistCredentials();
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [LocaleSwitcher()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.shield_moon, size: 64, color: AppColors.accent),
                const SizedBox(height: 12),
                Text(
                  'SaqBol',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 32),
                if (_registerMode)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: strings.name,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: strings.phone,
                    hintText: '+7...',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: strings.password,
                    border: const OutlineInputBorder(),
                  ),
                ),
                CheckboxListTile(
                  value: _remember,
                  onChanged: (value) => setState(() => _remember = value ?? false),
                  title: Text(strings.rememberMe),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(state.error!, style: const TextStyle(color: AppColors.scam)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: state.submitting ? null : _submit,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: state.submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                        )
                      : Text(_registerMode ? strings.register : strings.login),
                ),
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
