import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../../core/services/last_login_service.dart';
import '../providers/auth_provider.dart';
import '../providers/social_sign_in_notifier.dart';
import '../widgets/social_sign_in_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;
  var _isLoading = false;
  String? _errorMessage;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLastLogin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadLastLogin() async {
    final id = await LastLoginService.getLastLoginIdentifier();
    if (id != null && id.isNotEmpty && mounted) {
      _identifierController.text = id;
      final shouldClear = await LastLoginService.shouldClearPassword();
      if (shouldClear && mounted) {
        _passwordController.clear();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final diff = DateTime.now().difference(_pausedAt!);
        if (diff.inMinutes >= 5 && mounted) {
          _passwordController.clear();
          LastLoginService.markPasswordCleared();
        }
      }
      _pausedAt = null;
    }
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final result = await ref
        .read(authRepositoryProvider)
        .signInWithEmailOrUsername(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isErr) {
      setState(() => _errorMessage = result.localizedErrorOrNull(context.l10n));
      return;
    }
    // Báo hệ điều hành chốt phiên autofill để trình quản lý mật khẩu đề nghị lưu.
    TextInput.finishAutofillContext();
    ref.invalidate(currentUserProvider);
    await LastLoginService.saveLastLoginIdentifier(
      _identifierController.text.trim(),
    );
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialSignInProvider);
    final busy = _isLoading || social.busy != null;
    final socialError = social.error?.localizedMessage(context.l10n);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Text(
                    context.l10n.authLoginTitle,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 36),
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.authIdentifierLabel,
                      hintText: context.l10n.authIdentifierHint,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return context.l10n.authIdentifierRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => busy ? null : _submit(),
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.authPasswordLabel,
                      hintText: context.l10n.authPasswordHint,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? context.l10n.authShowPassword
                            : context.l10n.authHidePassword,
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: context.colors.textSecondary,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return context.l10n.authPasswordRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(context.l10n.authForgotPasswordLink),
                    ),
                  ),
                  if (_errorMessage != null || socialError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage ?? socialError!,
                      style: TextStyle(
                        color: context.colors.expense,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: busy ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.authLoginTitle),
                  ),
                  const SizedBox(height: 24),
                  if (social.browserWaiting)
                    _BrowserWaitingBanner(
                      onCancel: () => ref
                          .read(socialSignInProvider.notifier)
                          .cancelWaiting(),
                    )
                  else
                    SocialSignInButtons(
                      busy: social.busy,
                      enabled: !_isLoading,
                      onPressed: (p) =>
                          ref.read(socialSignInProvider.notifier).start(p),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: busy ? null : () => context.push('/register'),
                    child: Text(context.l10n.authNoAccountRegister),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowserWaitingBanner extends StatelessWidget {
  const _BrowserWaitingBanner({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.authBrowserWaiting,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onCancel,
            child: Text(context.l10n.actionCancel),
          ),
        ],
      ),
    );
  }
}
