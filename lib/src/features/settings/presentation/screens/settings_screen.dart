import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../../core/settings/app_lock.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(context.l10n.settingsTitle),
        leading: IconButton(
          tooltip: context.l10n.settingsBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          _SectionLabel(context.l10n.settingsSectionDisplay),

          ListTile(
            leading: Icon(
              Icons.payments_outlined,
              color: context.colors.textSecondary,
            ),
            title: Text(context.l10n.settingsCurrency),
            subtitle: Text(
              '${currencyInfo(settings.currency).name} '
              '(${currencyInfo(settings.currency).symbol})',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickCurrency(context, ref, settings.currency),
          ),

          ListTile(
            leading: Icon(Icons.language, color: context.colors.textSecondary),
            title: Text(context.l10n.settingsLanguage),
            subtitle: Text(
              settings.languageCode == 'vi' ? 'Tiếng Việt' : 'English',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickLanguage(context, ref, settings.languageCode),
          ),

          ListTile(
            leading: Icon(
              Icons.dark_mode_outlined,
              color: context.colors.textSecondary,
            ),
            title: Text(context.l10n.settingsTheme),
            subtitle: Text(
              switch (settings.themeMode) {
                ThemeMode.dark => context.l10n.settingsThemeDark,
                ThemeMode.light => context.l10n.settingsThemeLight,
                ThemeMode.system => context.l10n.settingsThemeSystem,
              },
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickTheme(context, ref, settings.themeMode),
          ),

          const _BiometricLockTile(),

          SwitchListTile(
            secondary: Icon(
              Icons.visibility_off_outlined,
              color: context.colors.textSecondary,
            ),
            title: Text(context.l10n.settingsHideAmounts),
            subtitle: Text(
              context.l10n.settingsHideAmountsDesc,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
            value: settings.hideAmounts,
            activeThumbColor: context.colors.primary,
            onChanged: notifier.setHideAmounts,
          ),

          const Divider(height: 32),
          _SectionLabel(context.l10n.settingsSectionPeriod),

          ListTile(
            leading: Icon(
              Icons.calendar_month_outlined,
              color: context.colors.textSecondary,
            ),
            title: Text(context.l10n.settingsFirstDayOfMonth),
            subtitle: Text(
              context.l10n.settingsFirstDayOfMonthDesc(
                settings.firstDayOfMonth,
              ),
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickFirstDay(context, ref, settings.firstDayOfMonth),
          ),

          const Divider(height: 32),
          _SectionLabel(context.l10n.settingsSectionData),

          ListTile(
            leading: Icon(
              Icons.account_balance_wallet_outlined,
              color: context.colors.textSecondary,
            ),
            title: Text(context.l10n.settingsManageWallets),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/accounts'),
          ),

          ListTile(
            leading: Icon(
              Icons.category_outlined,
              color: context.colors.textSecondary,
            ),
            title: Text(context.l10n.settingsManageCategories),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/categories'),
          ),

          ListTile(
            leading: Icon(
              Icons.savings_outlined,
              color: context.colors.textSecondary,
            ),
            title: Text(context.l10n.settingsBudgets),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/budgets'),
          ),

          ListTile(
            leading: Icon(Icons.repeat, color: context.colors.textSecondary),
            title: Text(context.l10n.settingsRecurring),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/recurring'),
          ),

          ListTile(
            leading: Icon(
              Icons.download_outlined,
              color: context.colors.textSecondary,
            ),
            title: Text(context.l10n.settingsExportData),
            subtitle: Text(
              context.l10n.settingsExportDataDesc,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/export'),
          ),

          const Divider(height: 32),
          _SectionLabel(context.l10n.settingsSectionCheck),

          const _RecalcBalancesTile(),

          const Divider(height: 32),
          _SectionLabel(context.l10n.settingsSectionAccount),

          ListTile(
            leading: Icon(
              Icons.manage_accounts_outlined,
              color: context.colors.textSecondary,
            ),
            title: Text(context.l10n.accountTitle),
            subtitle: Text(
              context.l10n.profileAccountDesc,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/account'),
          ),

          ListTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: context.colors.textSecondary,
            ),
            title: Text(context.l10n.settingsPrivacyPolicy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy'),
          ),

          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: context.colors.expense,
            ),
            title: Text(
              context.l10n.settingsDeleteAccount,
              style: TextStyle(color: context.colors.expense),
            ),
            subtitle: Text(
              context.l10n.settingsDeleteAccountDesc,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
            onTap: () => context.push('/me/delete-account'),
          ),

          const SizedBox(height: 32),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                final version = info == null
                    ? ''
                    : ' ${info.version} (${info.buildNumber})';
                return Text(
                  'Coinsort$version',
                  style: TextStyle(
                    color: context.colors.textTertiary,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------

  Future<void> _pickCurrency(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.l10n.settingsCurrency,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (final c in kSupportedCurrencies)
              _ChoiceTile(
                title: '${c.name} (${c.symbol})',
                subtitle: c.code,
                selected: c.code == current,
                onTap: () => Navigator.of(ctx).pop(c.code),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setCurrency(picked);
    }
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.settingsLanguage),
        children: [
          for (final entry in const {
            'vi': 'Tiếng Việt',
            'en': 'English',
          }.entries)
            _ChoiceTile(
              title: entry.value,
              selected: entry.key == current,
              onTap: () => Navigator.of(ctx).pop(entry.key),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setLanguage(picked);
    }
  }

  Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final picked = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.settingsTheme),
        children: [
          for (final mode in const [
            ThemeMode.dark,
            ThemeMode.light,
            ThemeMode.system,
          ])
            _ChoiceTile(
              title: switch (mode) {
                ThemeMode.dark => context.l10n.settingsThemeDark,
                ThemeMode.light => context.l10n.settingsThemeLight,
                ThemeMode.system => context.l10n.settingsThemeSystem,
              },
              selected: mode == current,
              onTap: () => Navigator.of(ctx).pop(mode),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setThemeMode(picked);
    }
  }

  Future<void> _pickFirstDay(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 320,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 28,
            itemBuilder: (_, i) {
              final day = i + 1;
              final selected = day == current;
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(ctx).pop(day),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? context.colors.primary
                        : context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: selected
                          ? context.colors.onPrimary
                          : context.colors.textPrimary,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setFirstDayOfMonth(picked);
    }
  }
}

/// Một lựa chọn trong danh sách cấu hình. Thay cho RadioListTile (đã bị
/// deprecate trong Flutter hiện tại) để không phải dựng RadioGroup cho một
/// hộp thoại chọn rồi đóng ngay.

/// Khoá app bằng vân tay / Face ID. Ẩn đi trên thiết bị không hỗ trợ, thay vì
/// hiện một công tắc bật lên rồi không có tác dụng gì. Nếu kiểm tra hỗ trợ
/// thất bại thì hiện tile bị vô hiệu kèm lỗi, không biến mất trong im lặng.
class _BiometricLockTile extends ConsumerWidget {
  const _BiometricLockTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(biometricAvailableProvider);
    final settings = ref.watch(settingsProvider);

    return available.when(
      loading: () => const SizedBox.shrink(),
      // Không kiểm tra được sinh trắc học — hiện tile vô hiệu kèm lý do.
      error: (e, _) => SwitchListTile(
        secondary: Icon(Icons.fingerprint, color: context.colors.textTertiary),
        title: Text(context.l10n.settingsBiometricLock),
        subtitle: Text(
          localizedError(context.l10n, e),
          style: TextStyle(color: context.colors.expense, fontSize: 12),
        ),
        value: settings.biometricLock,
        activeThumbColor: context.colors.primary,
        onChanged: null,
      ),
      data: (canUse) {
        if (!canUse) return const SizedBox.shrink();
        return SwitchListTile(
          secondary: Icon(
            Icons.fingerprint,
            color: context.colors.textSecondary,
          ),
          title: Text(context.l10n.settingsBiometricLock),
          subtitle: Text(
            context.l10n.settingsBiometricLockDesc,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
          value: settings.biometricLock,
          activeThumbColor: context.colors.primary,
          onChanged: ref.read(settingsProvider.notifier).setBiometricLock,
        );
      },
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(
          color: selected ? context.colors.primary : context.colors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
      trailing: selected
          ? Icon(Icons.check, color: context.colors.primary)
          : null,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: context.colors.textTertiary,
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Đối soát số dư — dựng lại số dư mọi ví từ sổ giao dịch.
class _RecalcBalancesTile extends ConsumerStatefulWidget {
  const _RecalcBalancesTile();

  @override
  ConsumerState<_RecalcBalancesTile> createState() =>
      _RecalcBalancesTileState();
}

class _RecalcBalancesTileState extends ConsumerState<_RecalcBalancesTile> {
  bool _running = false;

  Future<void> _run() async {
    setState(() => _running = true);
    final result = await ref
        .read(accountRepositoryProvider)
        .recalcAllBalances();
    if (!mounted) return;
    setState(() => _running = false);

    if (result.isErr) {
      showResultSnackBar(
        context,
        message: result.errorOrNull ?? context.l10n.settingsRecalcFailed,
        isError: true,
      );
      return;
    }

    final drifts = result.valueOrNull ?? const [];
    ref.read(accountVersionProvider.notifier).state++;

    if (!mounted) return;
    if (drifts.isEmpty) {
      showResultSnackBar(context, message: context.l10n.settingsRecalcAllMatch);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.settingsRecalcFixedCount(drifts.length)),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final d in drifts.take(10))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${d.accountName}: ${FormatHelpers.currency(d.oldBalance)} '
                    '→ ${FormatHelpers.currency(d.newBalance)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              if (drifts.length > 10)
                Text(
                  context.l10n.settingsRecalcMoreWallets(drifts.length - 10),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.actionClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _running
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.fact_check_outlined,
              color: context.colors.textSecondary,
            ),
      title: Text(context.l10n.settingsRecalcTitle),
      subtitle: Text(
        context.l10n.settingsRecalcDesc,
        style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
      ),
      onTap: _running ? null : _run,
    );
  }
}
