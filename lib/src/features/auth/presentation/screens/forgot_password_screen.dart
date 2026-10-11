import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  var _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final result = await ref
        .read(authRepositoryProvider)
        .requestPasswordReset(_emailController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isErr) {
      setState(() => _errorMessage = result.localizedErrorOrNull(context.l10n));
      return;
    }
    context.push('/recover-code', extra: _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(context.l10n.authForgotPasswordTitle),
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
                  const SizedBox(height: 32),
                  Text(
                    context.l10n.authForgotPasswordSubtitle,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.authEmailLabel,
                      hintText: context.l10n.authEmailHint,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return context.l10n.authEmailRequired;
                      }
                      if (!v.contains('@')) {
                        return context.l10n.authEmailInvalid;
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: context.colors.expense,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.authSendRecoveryCode),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(context.l10n.authBackToLogin),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
