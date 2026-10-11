import '../../../core/errors/app_exception.dart';
import '../../../core/result.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/account.dart';
import 'account_repository.dart';

/// Các thao tác trên ví cần đi kèm ghi sổ giao dịch.
class AccountService {
  AccountService({
    required AccountRepository accountRepository,
    required TransactionRepository transactionRepository,
  }) : _accounts = accountRepository,
       _transactions = transactionRepository;

  final AccountRepository _accounts;
  final TransactionRepository _transactions;

  /// Đặt lại số dư ví về [targetBalance] bằng cách GHI MỘT GIAO DỊCH ĐIỀU CHỈNH,
  /// không bao giờ ghi thẳng vào `accounts.balance`.
  ///
  /// Ghi thẳng sẽ phá bất biến `balance == opening_balance + tổng sổ cái` mà
  /// migration 001 vừa lập lại, và lần đối soát kế tiếp sẽ xoá mất thay đổi đó.
  Future<Result<void>> adjustBalance({
    required Account account,
    required double targetBalance,
    required String groupId,
    String? note,
  }) {
    return Result.guard(() async {
      final diff = targetBalance - account.balance;
      if (diff.abs() < 0.005) {
        throw const AppException(
          'Số dư mới trùng số dư hiện tại.',
          kind: AppErrorKind.validation,
          code: AppErrorCode.balanceUnchanged,
        );
      }

      // Ví nợ đảo dấu: nợ tăng nghĩa là tiền ra.
      final moneyIn = account.isLiability ? -diff : diff;

      final result = await _transactions.createTransaction(
        groupId: groupId,
        accountId: account.id,
        type: moneyIn > 0 ? 'income' : 'expense',
        amount: moneyIn.abs(),
        transactionDate: DateTime.now(),
        note: note ?? 'Điều chỉnh số dư',
        splitMode: SplitMode.none,
      );

      if (result.isErr) {
        throw (result as Err<Transaction>).error;
      }
    });
  }

  /// Lưu trữ ví. Giao dịch cũ giữ nguyên nên sổ cái không thủng.
  Future<Result<void>> archive(String accountId) =>
      _accounts.archiveAccount(accountId);

  Future<Result<void>> restore(String accountId) =>
      _accounts.restoreAccount(accountId);
}
