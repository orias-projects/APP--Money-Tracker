import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../common_widgets/category_picker.dart';
import '../../../../core/constants/app_palette.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/widgets/category_editor_dialog.dart';
import '../../../groups/domain/group_member.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../domain/transaction.dart';
import '../providers/transactions_provider.dart';
import '../widgets/account_selector.dart';
import '../widgets/receipt_field.dart';
import '../widgets/split_editor.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({super.key, required this.transaction});

  final Transaction transaction;

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  Account? _fromAccount;
  Account? _toAccount;
  Category? _selectedCategory;

  /// Mở màn Sửa thì lưới thu gọn sẵn, hiện danh mục hiện tại của giao dịch.
  bool _categoryExpanded = false;

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _payeeController = TextEditingController();

  late DateTime _date;
  late String _paidBy;
  late SplitState _split;
  String? _receiptPath;

  bool _isSaving = false;
  bool _accountsInitialized = false;
  bool _categoryInitialized = false;

  Transaction get _tx => widget.transaction;

  double get _amount => FormatHelpers.parseAmount(_amountController.text) ?? 0;

  @override
  void initState() {
    super.initState();
    _amountController.text = FormatHelpers.amount(_tx.amount);
    _noteController.text = _tx.note ?? '';
    _payeeController.text = _tx.payee ?? '';
    _date = _tx.transactionDate;
    _paidBy = _tx.paidBy;
    _receiptPath = _tx.imageUrl;
    _split = _splitStateFrom(_tx);
  }

  /// Dựng lại trạng thái chia tiền từ phần chia đã lưu.
  /// Luôn đọc về chế độ `exact` để số tiền từng người giữ nguyên như khi ghi.
  static SplitState _splitStateFrom(Transaction t) {
    if (!t.splitMode.isSplit || t.splits.isEmpty) return SplitState.none;
    return SplitState(
      mode: SplitMode.exact,
      participants: t.splits.map((s) => s.userId).toSet(),
      rawValues: {for (final s in t.splits) s.userId: s.shareAmount},
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _payeeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final amount = _amount;
    if (amount <= 0) {
      showResultSnackBar(
        context,
        message: context.l10n.txAmountMustBePositive,
        isError: true,
      );
      return;
    }
    if (_tx.isTransfer) {
      if (_fromAccount == null || _toAccount == null) {
        showResultSnackBar(
          context,
          message: context.l10n.txSelectBothAccounts,
          isError: true,
        );
        return;
      }
      if (_fromAccount!.id == _toAccount!.id) {
        showResultSnackBar(
          context,
          message: context.l10n.txAccountsMustDiffer,
          isError: true,
        );
        return;
      }
    } else {
      if (_fromAccount == null) {
        showResultSnackBar(
          context,
          message: context.l10n.txSelectAccount,
          isError: true,
        );
        return;
      }
    }

    final splitError = _split.validate(amount);
    if (splitError != null) {
      showResultSnackBar(
        context,
        message: splitError.localized(context.l10n),
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    final result = await ref
        .read(transactionRepositoryProvider)
        .updateTransaction(
          transactionId: _tx.id,
          accountId: _fromAccount!.id,
          toAccountId: _tx.isTransfer ? _toAccount!.id : null,
          categoryId: _tx.isTransfer ? null : _selectedCategory?.id,
          amount: amount,
          transactionDate: _date,
          note: _noteController.text.trim(),
          payee: _payeeController.text.trim(),
          imageUrl: _receiptPath,
          paidBy: _paidBy,
          splitMode: _split.mode,
          splits: _split.resolve(amount),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.isErr) {
      showResultSnackBar(
        context,
        message: result.errorOrNull ?? context.l10n.txUpdateFailed,
        isError: true,
      );
      return;
    }

    ref.read(transactionVersionProvider.notifier).state++;
    ref.read(accountVersionProvider.notifier).state++;
    if (mounted) {
      showResultSnackBar(context, message: context.l10n.txChangesSaved);
      context.pop();
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.txDeleteTransactionTitle),
        content: Text(context.l10n.txDeleteTransactionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    final result = await ref
        .read(transactionRepositoryProvider)
        .softDeleteTransaction(_tx.id, _tx.groupId);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.isErr) {
      showResultSnackBar(
        context,
        message: result.errorOrNull ?? context.l10n.txDeleteFailed,
        isError: true,
      );
      return;
    }

    ref.read(transactionVersionProvider.notifier).state++;
    ref.read(accountVersionProvider.notifier).state++;
    if (mounted) {
      showResultSnackBar(context, message: context.l10n.txTransactionDeleted);
      context.pop();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final isSharedGroup = activeGroup?.isPersonal == false;
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;

    final accountsAsync = ref.watch(selectableAccountsProvider);
    final categoriesAsync = ref.watch(
      categoriesByTypeProvider(_tx.isTransfer ? 'expense' : _tx.type),
    );
    final membersAsync = isSharedGroup
        ? ref.watch(groupMembersProvider(activeGroup!.id))
        : const AsyncValue<List<GroupMember>>.data([]);

    // Điền ví/danh mục ban đầu ngay khi dữ liệu về, chỉ một lần.
    _syncInitialSelections(accountsAsync, categoriesAsync);

    final title = switch (_tx.type) {
      'expense' => context.l10n.txEditExpenseTitle,
      'income' => context.l10n.txEditIncomeTitle,
      _ => context.l10n.txEditTransferTitle,
    };

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: context.l10n.actionClose,
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: context.colors.expense),
            tooltip: context.l10n.actionDelete,
            onPressed: _isSaving ? null : _delete,
          ),
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    context.l10n.actionSave,
                    style: TextStyle(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [AmountInputFormatter()],
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.txAmountLabel,
                prefixText:
                    '${currencyInfo(FormatHelpers.defaultCurrency).symbol}  ',
                prefixStyle: TextStyle(
                  fontSize: 20,
                  color: context.colors.textSecondary,
                ),
              ),
              // KHÔNG setState theo phím gõ — SplitEditor tự nghe controller
              // qua ValueListenableBuilder (xem bên dưới).
            ),
            const SizedBox(height: 24),

            if (!_tx.isTransfer) ...[
              CategoryField(
                selected: _selectedCategory,
                expanded: _categoryExpanded,
                onTap: () =>
                    setState(() => _categoryExpanded = !_categoryExpanded),
              ),
              if (_categoryExpanded)
                categoriesAsync.when(
                  // Ô cuối là nút thêm danh mục — trước đây màn Edit không có,
                  // nên nếu mọi danh mục đã bị xoá thì lưới trống không lối ra.
                  data: (categories) => CategorySelectorGrid(
                    categories: categories,
                    selected: _selectedCategory,
                    onSelect: (c) => setState(() {
                      _selectedCategory = c;
                      _categoryExpanded = false;
                    }),
                    onAdd: () async {
                      final created = await CategoryEditorDialog.show(
                        context,
                        type: _tx.type,
                        orderIndex: categories.length,
                      );
                      if (created != null && mounted) {
                        setState(() {
                          _selectedCategory = created;
                          _categoryExpanded = false;
                        });
                      }
                    },
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => AsyncErrorView(
                    error: e,
                    compact: true,
                    onRetry: () =>
                        ref.read(categoryVersionProvider.notifier).state++,
                  ),
                ),
              const SizedBox(height: 24),
            ],

            accountsAsync.when(
              data: (accounts) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountSelector(
                    label: _tx.isTransfer
                        ? context.l10n.txFromAccountLabel
                        : context.l10n.txAccountLabel,
                    accounts: accounts,
                    value: _fromAccount,
                    onChanged: (a) => setState(() => _fromAccount = a),
                  ),
                  if (_tx.isTransfer) ...[
                    const SizedBox(height: 16),
                    AccountSelector(
                      label: context.l10n.txToAccountLabel,
                      accounts: accounts,
                      value: _toAccount,
                      excludeId: _fromAccount?.id,
                      onChanged: (a) => setState(() => _toAccount = a),
                    ),
                  ],
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => AccountsErrorRow(
                error: e,
                onRetry: () =>
                    ref.read(accountVersionProvider.notifier).state++,
              ),
            ),
            const SizedBox(height: 20),

            if (isSharedGroup && _tx.isExpense)
              membersAsync.when(
                data: (members) => Card(
                  color: context.colors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    // Chỉ subtree này rebuild khi gõ số tiền.
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _amountController,
                      builder: (context, _, _) => SplitEditor(
                        members: members,
                        currentUserId: currentUserId,
                        paidBy: _paidBy,
                        amount: _amount,
                        state: _split,
                        onPaidByChanged: (id) => setState(() => _paidBy = id),
                        onStateChanged: (s) => setState(() => _split = s),
                      ),
                    ),
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => AsyncErrorView(
                  error: e,
                  compact: true,
                  onRetry: () =>
                      ref.invalidate(groupMembersProvider(activeGroup!.id)),
                ),
              ),
            if (isSharedGroup && _tx.isExpense) const SizedBox(height: 20),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.calendar_today,
                color: context.colors.textSecondary,
                size: 20,
              ),
              title: Text(
                FormatHelpers.date(_date),
                style: TextStyle(color: context.colors.textPrimary),
              ),
              subtitle: Text(
                context.l10n.txTransactionDate,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(labelText: context.l10n.txNote),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            if (!_tx.isTransfer) ...[
              TextFormField(
                controller: _payeeController,
                decoration: InputDecoration(
                  labelText: _tx.isExpense
                      ? context.l10n.txPayeeExpenseLabel
                      : context.l10n.txPayeeIncomeLabel,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              ReceiptField(
                path: _receiptPath,
                onChanged: (p) => setState(() => _receiptPath = p),
              ),
              const SizedBox(height: 24),
            ],

            _AuditFooter(transaction: _tx),
          ],
        ),
      ),
    );
  }

  /// Ví và danh mục về bất đồng bộ; chọn giá trị ban đầu đúng một lần để không
  /// ghi đè lựa chọn người dùng vừa đổi.
  void _syncInitialSelections(
    AsyncValue<List<Account>> accountsAsync,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    if (!_accountsInitialized) {
      final accounts = accountsAsync.valueOrNull;
      if (accounts != null && accounts.isNotEmpty) {
        _accountsInitialized = true;
        final from = _firstWhereOrNull(accounts, _tx.accountId);
        final to = _tx.toAccountId == null
            ? null
            : _firstWhereOrNull(accounts, _tx.toAccountId!);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _fromAccount = from;
            _toAccount = to;
          });
        });
      }
    }

    if (!_categoryInitialized && _tx.categoryId != null) {
      final categories = categoriesAsync.valueOrNull;
      if (categories != null && categories.isNotEmpty) {
        _categoryInitialized = true;
        final cat = categories
            .where((c) => c.id == _tx.categoryId)
            .cast<Category?>()
            .firstWhere((c) => true, orElse: () => null);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _selectedCategory = cat);
        });
      }
    }
  }

  static Account? _firstWhereOrNull(List<Account> list, String id) {
    for (final a in list) {
      if (a.id == id) return a;
    }
    return null;
  }
}

/// Ai tạo, ai sửa gần nhất — cần thiết khi nhiều người cùng ghi vào một nhóm.
class _AuditFooter extends StatelessWidget {
  const _AuditFooter({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final creator = transaction.createdByUserName;
    if (creator == null || creator.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        context.l10n.txRecordedBy(
          creator,
          FormatHelpers.date(transaction.transactionDate),
        ),
        textAlign: TextAlign.center,
        style: TextStyle(color: context.colors.textTertiary, fontSize: 12),
      ),
    );
  }
}
