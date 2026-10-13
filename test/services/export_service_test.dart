import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/l10n/app_localizations.dart';
import 'package:spend_sync/src/features/accounts/domain/account.dart';
import 'package:spend_sync/src/features/categories/domain/category.dart';
import 'package:spend_sync/src/features/settings/data/export_service.dart';
import 'package:spend_sync/src/features/transactions/domain/transaction.dart';

Transaction tx({
  String id = 't1',
  String type = 'expense',
  double amount = 100000,
  String? categoryId = 'c1',
  String accountId = 'a1',
  String? note,
  String? payee,
  SplitMode splitMode = SplitMode.none,
  List<TransactionSplit> splits = const [],
}) {
  return Transaction(
    id: id,
    groupId: 'g1',
    accountId: accountId,
    categoryId: categoryId,
    type: type,
    amount: amount,
    transactionDate: DateTime(2026, 8, 25),
    note: note,
    payee: payee,
    createdBy: 'u1',
    paidBy: 'u1',
    paidByUserName: 'Minh',
    splitMode: splitMode,
    splits: splits,
  );
}

const category = Category(
  id: 'c1',
  name: 'Ăn uống',
  type: 'expense',
  iconName: 'restaurant',
  colorHex: '#FFD700',
);

const account = Account(
  id: 'a1',
  userId: 'u1',
  name: 'Tiền mặt',
  accountType: 'asset',
  balance: 500000,
  currency: 'VND',
);

void main() {
  // CSV xuất theo ngôn ngữ dang chon; test dung ban tieng Viet.
  final l10n = lookupAppLocalizations(const Locale('vi'));
  const categories = {'c1': category};
  const accounts = {'a1': account};

  group('ExportService.buildCsv', () {
    test('có dòng tiêu đề', () {
      final csv = ExportService.buildCsv(
        transactions: [],
        categories: categories,
        accounts: accounts,
        l10n: l10n,
      );
      expect(csv, contains('Ngày'));
      expect(csv, contains('Số tiền'));
      expect(csv, contains('Người trả'));
    });

    test('bắt đầu bằng BOM để Excel đọc đúng tiếng Việt', () {
      final csv = ExportService.buildCsv(
        transactions: [],
        categories: categories,
        accounts: accounts,
        l10n: l10n,
      );
      expect(csv.codeUnitAt(0), 0xFEFF);
    });

    test('ghi đủ thông tin một giao dịch', () {
      final csv = ExportService.buildCsv(
        transactions: [tx(note: 'Cơm trưa')],
        categories: categories,
        accounts: accounts,
        l10n: l10n,
      );
      expect(csv, contains('2026-08-25'));
      expect(csv, contains('Chi'));
      expect(csv, contains('Ăn uống'));
      expect(csv, contains('Tiền mặt'));
      expect(csv, contains('Cơm trưa'));
      expect(csv, contains('Minh'));
    });

    test('bọc dấu nháy khi ô chứa dấu phẩy', () {
      final csv = ExportService.buildCsv(
        transactions: [tx(note: 'Cà phê, bánh ngọt')],
        categories: categories,
        accounts: accounts,
        l10n: l10n,
      );
      expect(csv, contains('"Cà phê, bánh ngọt"'));
    });

    test('nhân đôi dấu nháy kép bên trong ô', () {
      final csv = ExportService.buildCsv(
        transactions: [tx(note: 'Quán "Ngon"')],
        categories: categories,
        accounts: accounts,
        l10n: l10n,
      );
      expect(csv, contains('"Quán ""Ngon"""'));
    });

    test('ghi chú xuống dòng không làm vỡ cấu trúc CSV', () {
      final csv = ExportService.buildCsv(
        transactions: [tx(note: 'Dòng 1\nDòng 2')],
        categories: categories,
        accounts: accounts,
        l10n: l10n,
      );
      expect(csv, contains('"Dòng 1\nDòng 2"'));
    });

    test('giao dịch chưa phân loại vẫn xuất được', () {
      final csv = ExportService.buildCsv(
        transactions: [tx(categoryId: null)],
        categories: categories,
        accounts: accounts,
        l10n: l10n,
      );
      expect(csv.split('\n').length, greaterThanOrEqualTo(2));
    });

    test('ví đã bị xoá không làm hỏng dòng dữ liệu', () {
      final csv = ExportService.buildCsv(
        transactions: [tx(accountId: 'khong-ton-tai')],
        categories: categories,
        accounts: accounts,
        l10n: l10n,
      );
      expect(csv, contains('2026-08-25'));
    });

    test('xuất kèm cách chia và phần đã gánh', () {
      final csv = ExportService.buildCsv(
        transactions: [
          tx(
            splitMode: SplitMode.equal,
            splits: const [
              TransactionSplit(userId: 'u1', shareAmount: 50000),
              TransactionSplit(userId: 'u2', shareAmount: 50000),
            ],
          ),
        ],
        categories: categories,
        accounts: accounts,
        l10n: l10n,
      );
      expect(csv, contains('Chia đều'));
      expect(csv, contains('100000.00'));
    });

    test('mỗi giao dịch một dòng', () {
      final csv = ExportService.buildCsv(
        transactions: [
          tx(id: 't1'),
          tx(id: 't2'),
          tx(id: 't3'),
        ],
        categories: categories,
        accounts: accounts,
        l10n: l10n,
      );
      final rows = csv.split('\n').where((l) => l.trim().isNotEmpty).toList();
      expect(rows.length, 4); // 1 tiêu đề + 3 dòng
    });
  });

  group('ExportService.suggestedFileName', () {
    test('có ngày và đuôi .csv', () {
      final name = ExportService.suggestedFileName(DateTime(2026, 8, 5));
      expect(name, 'coinsort-2026-08-05.csv');
    });
  });
}
