import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../domain/login_methods.dart';
import '../providers/auth_provider.dart';
import '../providers/social_sign_in_notifier.dart';
import '../widgets/social_sign_in_buttons.dart';

/// Đăng ký chỉ cần tên đăng nhập + mật khẩu. Email, tên hiển thị, ảnh… thêm
/// sau trong màn Tài khoản.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _obscurePassword = true;
  var _obscureConfirm = true;
  var _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final result = await ref
        .read(authRepositoryProvider)
        .signUpWithUsername(
          username: _usernameController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isErr) {
      setState(() => _errorMessage = result.localizedErrorOrNull(context.l10n));
      return;
    }
    ref.invalidate(currentUserProvider);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialSignInProvider);
    final busy = _isLoading || social.busy != null;
    final socialError = social.error?.localizedMessage(context.l10n);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(context.l10n.authRegisterTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.authRegisterSubtitle,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newUsername],
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.authUsernameLabel,
                      hintText: context.l10n.authUsernameHint,
                      helperText: context.l10n.authUsernameRules,
                      helperMaxLines: 2,
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim().toLowerCase();
                      if (value.isEmpty) {
                        return context.l10n.authUsernameRequired;
                      }
                      if (!isValidUsername(value)) {
                        return context.l10n.errUsernameInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.authPasswordLabel,
                      hintText: context.l10n.authPasswordMinHint,
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
                      if (v == null || v.length < 6) {
                        return context.l10n.authPasswordMinLength;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => busy ? null : _submit(),
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.authConfirmPasswordLabel,
                      hintText: context.l10n.authConfirmPasswordHint,
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirm
                            ? context.l10n.authShowPassword
                            : context.l10n.authHidePassword,
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: context.colors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return context.l10n.authConfirmPasswordRequired;
                      }
                      if (v != _passwordController.text) {
                        return context.l10n.authPasswordMismatch;
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null || socialError != null) ...[
                    const SizedBox(height: 20),
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
                        : Text(context.l10n.authRegisterTitle),
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
                    onPressed: busy ? null : () => context.pop(),
                    child: Text(context.l10n.authHaveAccountLogin),
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

/// Hiện trong lúc chờ trình duyệt trả phiên về qua deep link.
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
