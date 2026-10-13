import '../../categories/domain/category_label.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/result.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction.dart';

/// Xuất giao dịch ra CSV rồi mở hộp thoại chia sẻ.
///
/// Người dùng phải lấy được dữ liệu của mình ra — đây là điều kiện để họ tin
/// tưởng giao dữ liệu tài chính cho app. Tiêu đề cột và nhãn đi theo ngôn ngữ
/// đang chọn (truyền [AppLocalizations] từ nơi gọi).
class ExportService {
  /// Tạo nội dung CSV. Tách riêng khỏi phần ghi file để test được.
  static String buildCsv({
    required List<Transaction> transactions,
    required Map<String, Category> categories,
    required Map<String, Account> accounts,
    required AppLocalizations l10n,
    Map<String, String> userNames = const {},
  }) {
    final buffer = StringBuffer();

    // BOM để Excel trên Windows đọc đúng tiếng Việt.
    buffer.write('﻿');

    final headers = [
      l10n.csvHeaderDate,
      l10n.csvHeaderType,
      l10n.csvHeaderCategory,
      l10n.csvHeaderAmount,
      l10n.csvHeaderCurrency,
      l10n.csvHeaderWallet,
      l10n.csvHeaderTargetWallet,
      l10n.csvHeaderNote,
      l10n.csvHeaderPlace,
      l10n.csvHeaderPayer,
      l10n.csvHeaderSplitMode,
      l10n.csvHeaderMyShare,
    ];
    buffer.writeln(headers.map(_escape).join(','));

    for (final t in transactions) {
      final account = accounts[t.accountId];
      final row = [
        _isoDate(t.transactionDate),
        switch (t.type) {
          'expense' => l10n.commonTabExpense,
          'income' => l10n.commonTabIncome,
          _ => l10n.csvTransfer,
        },
        t.categoryId == null
            ? ''
            : (categories[t.categoryId] == null
                  ? l10n.csvUncategorized
                  : categoryLabel(l10n, categories[t.categoryId]!.name)),
        t.amount.toStringAsFixed(2),
        account?.currency ?? 'VND',
        account?.name ?? '',
        t.toAccountId == null ? '' : (accounts[t.toAccountId]?.name ?? ''),
        t.note ?? '',
        t.payee ?? '',
        t.paidByUserName ?? userNames[t.paidBy] ?? '',
        t.splitMode.isSplit ? t.splitMode.localizedLabelOf(l10n) : '',
        t.splitMode.isSplit
            ? t.splits
                  .fold<double>(0, (s, x) => s + x.shareAmount)
                  .toStringAsFixed(2)
            : '',
      ];
      buffer.writeln(row.map(_escape).join(','));
    }

    return buffer.toString();
  }

  /// Ghi CSV ra file tạm và mở hộp thoại chia sẻ của hệ điều hành.
  static Future<Result<String>> shareCsv({
    required String csv,
    required String fileName,
    required AppLocalizations l10n,
  }) {
    return Result.guard(() async {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);

      final result = await Share.shareXFiles([
        XFile(file.path, mimeType: 'text/csv'),
      ], subject: l10n.exportShareSubject);

      if (result.status == ShareResultStatus.unavailable) {
        throw const AppException(
          'Thiết bị không hỗ trợ chia sẻ file.',
          kind: AppErrorKind.unknown,
          code: AppErrorCode.shareUnsupported,
        );
      }
      return file.path;
    });
  }

  /// `coinsort-2026-08-25.csv`
  static String suggestedFileName([DateTime? now]) {
    final d = now ?? DateTime.now();
    return 'coinsort-${_isoDate(d)}.csv';
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Bọc trong dấu nháy kép khi ô có dấu phẩy, nháy kép hoặc xuống dòng.
  static String _escape(String value) {
    if (value.isEmpty) return '';
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
