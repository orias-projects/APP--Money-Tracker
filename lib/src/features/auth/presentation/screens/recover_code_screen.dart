import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../providers/auth_provider.dart';

class RecoverCodeScreen extends ConsumerStatefulWidget {
  const RecoverCodeScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<RecoverCodeScreen> createState() => _RecoverCodeScreenState();
}

class _RecoverCodeScreenState extends ConsumerState<RecoverCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  var _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _errorMessage = null;
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = context.l10n.authEnterAllSixDigits);
      return;
    }
    setState(() => _isLoading = true);
    final result = await ref
        .read(authRepositoryProvider)
        .verifyRecoveryOtp(email: widget.email, token: code);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isErr) {
      setState(() => _errorMessage = result.localizedErrorOrNull(context.l10n));
      return;
    }
    context.go('/reset-password', extra: widget.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(context.l10n.authRecoverCodeTitle),
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
                    context.l10n.authCodeSentTo(widget.email),
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 18,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.authVerificationCodeLabel,
                      hintText: '123456',
                    ),
                    onChanged: (_) => setState(() => _errorMessage = null),
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
                        : Text(context.l10n.actionConfirm),
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
