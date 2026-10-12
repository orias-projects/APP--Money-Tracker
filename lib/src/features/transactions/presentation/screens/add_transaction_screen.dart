import '../../../../common_widgets/category_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../common_widgets/custom_tab_bar.dart';
import '../../../../core/constants/app_palette.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../../shell/shell_app_bar_provider.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/widgets/category_editor_dialog.dart';
import '../../../groups/domain/group_member.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';

import '../providers/add_screen_bar_provider.dart';
import '../providers/transactions_provider.dart';
import '../widgets/account_selector.dart';
import '../widgets/receipt_field.dart';
import '../widgets/split_editor.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  int _tabIndex = 0; // 0 = Chi, 1 = Thu, 2 = Chuyển
  Category? _selectedCategory;

  /// Lưới danh mục thu gọn khi mở màn: chọn xong là thu lại ngay.
  bool _categoryExpanded = false;
  Account? _fromAccount;
  Account? _toAccount;

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _payeeController = TextEditingController();

  DateTime _date = DateTime.now();
  String? _paidBy;
  SplitState _split = SplitState.none;
  String? _receiptPath;
  bool _isSaving = false;

  String get _type => switch (_tabIndex) {
    0 => 'expense',
    1 => 'income',
    _ => 'transfer',
  };

  double get _amount => FormatHelpers.parseAmount(_amountController.text) ?? 0;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _payeeController.dispose();
    super.dispose();
  }

  void _onTabChanged(int i) {
    setState(() {
      _tabIndex = i;
      _selectedCategory = null;
      _toAccount = null;
      // Chuyển khoản và khoản thu không tính vào công nợ nhóm.
      if (i != 0) _split = SplitState.none;
    });
  }

  // ---------------------------------------------------------------------------
  // Lưu
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

    if (_type == 'transfer') {
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

    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) {
      showResultSnackBar(
        context,
        message: context.l10n.txNoGroupSelected,
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    final result = await ref
        .read(transactionRepositoryProvider)
        .createTransaction(
          groupId: activeGroup.id,
          accountId: _fromAccount!.id,
          type: _type,
          amount: amount,
          transactionDate: _date,
          toAccountId: _type == 'transfer' ? _toAccount!.id : null,
          categoryId: _type == 'transfer' ? null : _selectedCategory?.id,
          note: _trimmedOrNull(_noteController.text),
          payee: _trimmedOrNull(_payeeController.text),
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
        message: result.errorOrNull ?? context.l10n.txCreateFailed,
        isError: true,
      );
      return;
    }

    // Một lần bump là đủ: mọi provider đọc giao dịch đều watch biến này.
    ref.read(transactionVersionProvider.notifier).state++;
    ref.read(accountVersionProvider.notifier).state++;

    _resetForm();
    if (mounted) context.go('/');
  }

  void _resetForm() {
    _amountController.clear();
    _noteController.clear();
    _payeeController.clear();
    setState(() {
      _selectedCategory = null;
      _toAccount = null;
      _receiptPath = null;
      _split = SplitState.none;
      _date = DateTime.now();
    });
  }

  static String? _trimmedOrNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  /// Tearoff ổn định cho thanh shell — closure mới mỗi build sẽ làm
  /// `AddScreenBarState.==` luôn sai và shell rebuild theo từng phím gõ.
  void _cancel() => context.go('/');

  // ---------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _showCategoryActions(Category c) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(context.l10n.txEditCategory),
              onTap: () async {
                Navigator.of(ctx).pop();
                final updated = await CategoryEditorDialog.show(
                  context,
                  type: _type,
                  existing: c,
                );
                if (updated != null && mounted) {
                  setState(() => _selectedCategory = updated);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: context.colors.expense),
              title: Text(
                context.l10n.txDeleteCategory,
                style: TextStyle(color: context.colors.expense),
              ),
              onTap: () async {
                Navigator.of(ctx).pop();
                final deleted = await confirmDeleteCategory(context, ref, c);
                if (deleted && mounted && _selectedCategory?.id == c.id) {
                  setState(() => _selectedCategory = null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final isSharedGroup = activeGroup?.isPersonal == false;
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;

    final categoriesAsync = ref.watch(
      categoriesByTypeProvider(_type == 'transfer' ? 'expense' : _type),
    );
    final accountsAsync = ref.watch(selectableAccountsProvider);
    final membersAsync = isSharedGroup
        ? ref.watch(groupMembersProvider(activeGroup!.id))
        : const AsyncValue<List<GroupMember>>.data([]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(shellAppBarTitleProvider.notifier)
          .setTitle(2, const AddScreenBarContent());
      ref
          .read(addScreenBarProvider.notifier)
          .update(onCancel: _cancel, onSave: _save, isLoading: _isSaving);
    });

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTabBar(selectedIndex: _tabIndex, onChanged: _onTabChanged),
            const SizedBox(height: 24),

            // --- Số tiền: đưa lên trên cùng, là việc người dùng làm đầu tiên ---
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
              // KHÔNG setState theo phím gõ — phần duy nhất phụ thuộc số tiền
              // (SplitEditor) tự nghe controller qua ValueListenableBuilder.
            ),
            const SizedBox(height: 24),

            // --- Danh mục ---
            if (_type != 'transfer') ...[
              CategoryField(
                selected: _selectedCategory,
                expanded: _categoryExpanded,
                onTap: () =>
                    setState(() => _categoryExpanded = !_categoryExpanded),
              ),
              if (_categoryExpanded)
                categoriesAsync.when(
                  data: (categories) => CategorySelectorGrid(
                    categories: categories,
                    selected: _selectedCategory,
                    onSelect: (c) => setState(() {
                      _selectedCategory = c;
                      _categoryExpanded = false;
                    }),
                    onLongPress: _showCategoryActions,
                    onAdd: () async {
                      final created = await CategoryEditorDialog.show(
                        context,
                        type: _type,
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

            // --- Ví ---
            accountsAsync.when(
              data: (accounts) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountSelector(
                    label: _type == 'transfer'
                        ? context.l10n.txFromAccountLabel
                        : context.l10n.txAccountLabel,
                    accounts: accounts,
                    value: _fromAccount,
                    onChanged: (a) => setState(() => _fromAccount = a),
                  ),
                  if (_type == 'transfer') ...[
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

            // --- Chia tiền (chỉ khoản chi trong nhóm chung) ---
            if (isSharedGroup && _type == 'expense')
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
                        paidBy: _paidBy ?? currentUserId,
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
            if (isSharedGroup && _type == 'expense') const SizedBox(height: 20),

            // --- Ngày ---
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

            if (_type != 'transfer') ...[
              TextFormField(
                controller: _payeeController,
                decoration: InputDecoration(
                  labelText: _type == 'expense'
                      ? context.l10n.txPayeeExpenseLabel
                      : context.l10n.txPayeeIncomeLabel,
                  hintText: _type == 'expense'
                      ? context.l10n.txPayeeExpenseHint
                      : context.l10n.txPayeeIncomeHint,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              ReceiptField(
                path: _receiptPath,
                onChanged: (p) => setState(() => _receiptPath = p),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
