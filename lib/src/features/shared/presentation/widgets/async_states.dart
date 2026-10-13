import 'package:flutter/material.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/l10n/l10n.dart';

/// Hiển thị lỗi kèm nút thử lại.
///
/// Trước đây tầng data nuốt hết lỗi và trả về danh sách rỗng, nên mất mạng
/// trông hệt như "chưa có dữ liệu". Widget này là nơi lỗi thật hiện ra.
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final e = error is AppException ? error as AppException : mapError(error);
    final message = e.localizedMessage(context.l10n);

    final icon = switch (e.kind) {
      AppErrorKind.network => Icons.wifi_off_rounded,
      AppErrorKind.auth => Icons.lock_outline_rounded,
      AppErrorKind.permission => Icons.block_rounded,
      AppErrorKind.notFound => Icons.search_off_rounded,
      _ => Icons.error_outline_rounded,
    };

    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: context.colors.expense, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(context.l10n.actionRetry),
              ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: context.colors.textTertiary, size: 44),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(context.l10n.actionRetry),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.primary,
                  side: BorderSide(color: context.colors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Trạng thái rỗng có hướng dẫn bước tiếp theo, thay cho một dòng chữ xám.
class AsyncEmptyView extends StatelessWidget {
  const AsyncEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: context.colors.textTertiary, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// SnackBar thống nhất cho thành công / thất bại.
void showResultSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? context.colors.expense
            : context.colors.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
}
