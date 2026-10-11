import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(supabaseClientProvider));
});

/// Tăng sau mỗi lần thêm/sửa/xoá giao dịch. Mọi provider đọc giao dịch đều
/// `watch` biến này nên tự nạp lại — không cần rải `invalidate` khắp nơi.
final transactionVersionProvider = StateProvider<int>((ref) => 0);

/// Gọi sau mỗi thao tác ghi thành công.
void bumpTransactions(Ref ref) {
  ref.read(transactionVersionProvider.notifier).state++;
}

void bumpTransactionsFrom(WidgetRef ref) {
  ref.read(transactionVersionProvider.notifier).state++;
}

/// Một trang giao dịch (dùng cho Tìm kiếm và các màn không cần cuộn vô hạn).
///
/// `autoDispose`: mỗi chuỗi tìm kiếm là một entry family riêng — không dọn thì
/// mỗi lần gõ phím giữ lại vĩnh viễn tới 100 giao dịch trong bộ nhớ.
final transactionsListProvider = FutureProvider.autoDispose
    .family<List<Transaction>, TransactionQuery>((ref, q) async {
      ref.watch(transactionVersionProvider);
      if (q.groupId.isEmpty) return const [];
      return ref.read(transactionRepositoryProvider).getTransactions(q);
    });

/// Tổng thu/chi trong kỳ — tính ở server, không tải danh sách về.
final periodSummaryProvider = FutureProvider.autoDispose
    .family<PeriodSummary, TransactionQuery>((ref, q) async {
      ref.watch(transactionVersionProvider);
      if (q.groupId.isEmpty) return PeriodSummary.empty;
      return ref.read(transactionRepositoryProvider).getPeriodSummary(q);
    });

// -----------------------------------------------------------------------------
// Danh sách có phân trang (màn Giao dịch)
// -----------------------------------------------------------------------------

class PagedTransactions {
  const PagedTransactions({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<Transaction> items;
  final bool hasMore;
  final bool isLoadingMore;

  static const empty = PagedTransactions(items: [], hasMore: false);

  PagedTransactions copyWith({
    List<Transaction>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PagedTransactions(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Kích thước một trang. Thay cho `limit: 500` gắn cứng trước đây.
const kTransactionPageSize = 40;

class TransactionListNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<PagedTransactions, TransactionQuery> {
  @override
  Future<PagedTransactions> build(TransactionQuery arg) async {
    // Nạp lại khi có thao tác ghi ở bất kỳ đâu trong app.
    ref.watch(transactionVersionProvider);
    if (arg.groupId.isEmpty) return PagedTransactions.empty;

    final first = arg.copyWith(offset: 0, limit: kTransactionPageSize);
    final items = await ref
        .read(transactionRepositoryProvider)
        .getTransactions(first);
    return PagedTransactions(
      items: items,
      hasMore: items.length == kTransactionPageSize,
    );
  }

  /// Nạp trang tiếp theo và nối vào cuối danh sách hiện có.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = arg.copyWith(
        offset: current.items.length,
        limit: kTransactionPageSize,
      );
      final more = await ref
          .read(transactionRepositoryProvider)
          .getTransactions(next);
      state = AsyncData(
        PagedTransactions(
          items: [...current.items, ...more],
          hasMore: more.length == kTransactionPageSize,
        ),
      );
    } catch (e, st) {
      // Giữ lại dữ liệu đã có, chỉ báo lỗi lần nạp thêm này.
      state = AsyncError<PagedTransactions>(
        e,
        st,
      ).copyWithPrevious(AsyncData(current.copyWith(isLoadingMore: false)));
    }
  }
}

/// `autoDispose`: đổi bộ lọc/nhóm tạo entry mới — entry cũ (và cả trăm giao
/// dịch đã cuộn qua) phải được thả khi không còn ai xem. Màn Giao dịch nằm
/// trong IndexedStack của shell nên vẫn giữ state khi chuyển tab.
final pagedTransactionsProvider = AsyncNotifierProvider.autoDispose
    .family<TransactionListNotifier, PagedTransactions, TransactionQuery>(
      TransactionListNotifier.new,
    );
