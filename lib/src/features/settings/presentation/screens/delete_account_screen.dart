import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';

/// Luồng người dùng tự xoá tài khoản.
///
/// Google Play và App Store đều bắt buộc phải có luồng này ngay trong app —
/// không có nó thì bản build bị từ chối.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _deleting = false;
  String? _error;

  /// Cụm xác nhận theo ngôn ngữ đang chọn ("XOA TAI KHOAN" / "DELETE ACCOUNT").
  String get _confirmPhrase => context.l10n.deleteConfirmPhrase;

  bool get _canDelete =>
      _confirmController.text.trim().toUpperCase() == _confirmPhrase;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.settingsDeleteDialogTitle),
        content: Text(context.l10n.settingsDeleteDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.settingsDeleteKeepAccount),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.settingsDeleteConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _deleting = true;
      _error = null;
    });

    // UI đã đối chiếu cụm xác nhận theo ngôn ngữ (_canDelete); RPC nhận cụm
    // CHUẨN cố định — hợp đồng server không đổi theo ngôn ngữ hiển thị.
    final result = await ref
        .read(authRepositoryProvider)
        .deleteAccount('XOA TAI KHOAN');

    if (!mounted) return;
    setState(() => _deleting = false);

    if (result.isErr) {
      setState(() => _error = result.localizedErrorOrNull(context.l10n));
      return;
    }

    await ref.read(activeGroupProvider.notifier).clear();
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(currentUserProvider);

    if (mounted) {
      showResultSnackBar(context, message: context.l10n.settingsDeleteSuccess);
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(context.l10n.settingsDeleteAccount),
        leading: IconButton(
          tooltip: context.l10n.settingsBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      // Chừa vùng cử chỉ hệ thống ở đáy để nút xác nhận không bị che.
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colors.expense.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: context.colors.expense,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.settingsDeleteWarning,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.settingsDeleteWhatRemoved,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _Bullet(context.l10n.settingsDeleteBulletProfile),
            _Bullet(context.l10n.settingsDeleteBulletPersonalTx),
            _Bullet(context.l10n.settingsDeleteBulletWallets),
            _Bullet(context.l10n.settingsDeleteBulletInvites),

            const SizedBox(height: 24),
            Text(
              context.l10n.settingsDeleteWhatKept,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _Bullet(context.l10n.settingsDeleteBulletSharedTx),
            const SizedBox(height: 8),
            Text(
              context.l10n.settingsDeleteSharedTxNote,
              style: TextStyle(
                color: context.colors.textTertiary,
                fontSize: 12,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),
            Text(
              context.l10n.settingsDeleteConfirmPrompt(_confirmPhrase),
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(hintText: _confirmPhrase),
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: context.colors.expense, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: (!_canDelete || _deleting) ? null : _delete,
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.expense,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.colors.surfaceVariant,
                minimumSize: const Size(0, 52),
              ),
              child: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.settingsDeleteMyAccountButton),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(context.l10n.settingsDeleteKeepAccount),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 10),
            child: SizedBox(
              width: 4,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
