import 'package:flutter/material.dart';

import '../core/constants/app_palette.dart';
import '../core/l10n/l10n.dart';
import '../core/utils/category_icons.dart';

/// Một dòng giao dịch.
///
/// Trái: icon danh mục trên nền `color_hex`.
/// Giữa: tên danh mục, ghi chú, người trả (khi ở nhóm chung).
/// Phải: số tiền và tên ví.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.title,
    required this.amount,
    this.type = 'expense',
    this.subtitle,
    this.accountName,
    this.colorHex,
    this.iconName,
    this.icon,
    this.paidByLabel,
    this.shareLabel,
    this.hasReceipt = false,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String amount;

  /// 'income' | 'expense' | 'transfer'.
  final String type;

  final String? subtitle;
  final String? accountName;
  final String? colorHex;
  final String? iconName;
  final IconData? icon;

  /// Tên người thanh toán — chỉ hiện ở nhóm chung.
  final String? paidByLabel;

  /// Phần mình phải gánh, VD `Phần bạn: 120.000 ₫`.
  final String? shareLabel;

  final bool hasReceipt;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  bool get _isExpense => type == 'expense';
  bool get _isTransfer => type == 'transfer';

  /// Chuyển khoản không phải thu cũng không phải chi — hiển thị trung tính,
  /// không dấu +/− và không màu đỏ/xanh.
  Color _amountColor(BuildContext context) {
    if (_isTransfer) return context.colors.textPrimary;
    return _isExpense ? context.colors.expense : context.colors.income;
  }

  String get _signedAmount {
    if (_isTransfer) return amount;
    return _isExpense ? '-$amount' : '+$amount';
  }

  IconData get _leadingIcon {
    if (icon != null) return icon!;
    if (_isTransfer) return Icons.swap_horiz;
    if (iconName != null) return iconFromName(iconName);
    return _isExpense ? Icons.arrow_upward : Icons.arrow_downward;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isTransfer
        ? context.colors.info
        : parseHexColor(colorHex, fallback: context.colors.textSecondary);

    final subtitleParts = <String>[
      if (subtitle != null && subtitle!.trim().isNotEmpty) subtitle!.trim(),
      if (paidByLabel != null && paidByLabel!.trim().isNotEmpty)
        context.l10n.commonPaidBy(paidByLabel!.trim()),
    ];

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: bgColor.withValues(alpha: 0.25),
        child: Icon(_leadingIcon, color: bgColor, size: 22),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(color: context.colors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasReceipt) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.receipt_long,
              size: 14,
              color: context.colors.textTertiary,
            ),
          ],
        ],
      ),
      subtitle: (subtitleParts.isEmpty && shareLabel == null)
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitleParts.isNotEmpty)
                  Text(
                    subtitleParts.join(' • '),
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (shareLabel != null && shareLabel!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      shareLabel!,
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _signedAmount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _amountColor(context),
            ),
          ),
          if (accountName != null && accountName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                accountName!,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
