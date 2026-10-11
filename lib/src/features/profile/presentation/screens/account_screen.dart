import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/login_methods.dart';
import '../../../auth/domain/social_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/social_sign_in_buttons.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../providers/social_sync_controller.dart';
import '../widgets/editable_avatar.dart';

/// Màn Tài khoản: avatar · tên hiển thị · tên đăng nhập · email (xác minh) ·
/// mật khẩu · liên kết Google / Facebook / X.
///
/// Nhiều thao tác kết thúc ngoài app (link xác minh email, OAuth trong trình
/// duyệt) nên màn này làm mới dữ liệu khi có sự kiện auth hoặc khi app quay
/// lại foreground.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSub;
  SocialProvider? _linking;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub = ref.read(authRepositoryProvider).onAuthStateChange.listen((
      event,
    ) {
      switch (event.event) {
        case AuthChangeEvent.userUpdated:
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          _refresh();
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _linking = null);
    ref.invalidate(loginMethodsProvider);
    ref.invalidate(currentUserProvider);
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    showResultSnackBar(context, message: message, isError: isError);
  }

  // ---------------------------------------------------------------------------
  // Hồ sơ
  // ---------------------------------------------------------------------------

  Future<void> _editName(AppUser? user) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _TextPromptDialog(
        title: context.l10n.profileEditNameTitle,
        label: context.l10n.profileDisplayNameLabel,
        helper: context.l10n.accountDisplayNameHint,
        initial: user?.fullName ?? '',
        textCapitalization: TextCapitalization.words,
      ),
    );
    if (value == null || !mounted) return;
    final result = await ref
        .read(authRepositoryProvider)
        .updateProfile(fullName: value.isEmpty ? null : value);
    if (!mounted) return;
    if (result.isOk) ref.invalidate(currentUserProvider);
    _toast(
      result.localizedErrorOrNull(context.l10n) ?? context.l10n.profileUpdated,
      isError: result.isErr,
    );
  }

  Future<void> _editUsername(AppUser? user) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _TextPromptDialog(
        title: context.l10n.accountEditUsernameTitle,
        label: context.l10n.authUsernameLabel,
        helper: context.l10n.authUsernameRules,
        initial: user?.username ?? '',
        lowercase: true,
        validator: (v) =>
            isValidUsername(v) ? null : context.l10n.errUsernameInvalid,
      ),
    );
    if (value == null || value.isEmpty || !mounted) return;
    final result = await ref.read(authRepositoryProvider).updateUsername(value);
    if (!mounted) return;
    if (result.isOk) ref.invalidate(currentUserProvider);
    _toast(
      result.localizedErrorOrNull(context.l10n) ??
          context.l10n.accountUsernameSaved,
      isError: result.isErr,
    );
  }

  // ---------------------------------------------------------------------------
  // Email / mật khẩu
  // ---------------------------------------------------------------------------

  Future<void> _editEmail(LoginMethods methods) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _TextPromptDialog(
        title: methods.hasEmail
            ? context.l10n.accountEmailChange
            : context.l10n.accountEmailAdd,
        label: context.l10n.authEmailReadOnlyLabel,
        helper: context.l10n.accountEmailDialogHint,
        initial: methods.email ?? '',
        keyboardType: TextInputType.emailAddress,
        lowercase: true,
        validator: (v) =>
            v.contains('@') ? null : context.l10n.authEmailInvalid,
      ),
    );
    if (value == null || value.isEmpty || !mounted) return;
    if (value == methods.email) return;
    final result = await ref.read(authRepositoryProvider).updateEmail(value);
    if (!mounted) return;
    if (result.isOk) ref.invalidate(loginMethodsProvider);
    _toast(
      result.localizedErrorOrNull(context.l10n) ??
          context.l10n.accountEmailSaved(value),
      isError: result.isErr,
    );
  }

  Future<void> _resendEmail(String pending) async {
    final result = await ref
        .read(authRepositoryProvider)
        .resendEmailChange(pending);
    if (!mounted) return;
    _toast(
      result.localizedErrorOrNull(context.l10n) ??
          context.l10n.accountEmailResent,
      isError: result.isErr,
    );
  }

  Future<void> _changePassword(LoginMethods methods) async {
    final input = await showDialog<({String? current, String next})>(
      context: context,
      builder: (_) => _PasswordDialog(requireCurrent: methods.hasPassword),
    );
    if (input == null || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(authRepositoryProvider)
        .changePassword(
          newPassword: input.next,
          currentPassword: input.current,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isOk) ref.invalidate(loginMethodsProvider);
    _toast(
      result.localizedErrorOrNull(context.l10n) ??
          context.l10n.accountPasswordChanged,
      isError: result.isErr,
    );
  }

  // ---------------------------------------------------------------------------
  // Liên kết tài khoản ngoài
  // ---------------------------------------------------------------------------

  Future<void> _link(SocialProvider provider) async {
    setState(() => _linking = provider);
    // Facebook: controller sẽ đồng bộ bạn bè ngay khi token về.
    ref.read(socialSyncProvider.notifier).expect(provider);
    final result = await ref
        .read(authRepositoryProvider)
        .linkProvider(provider);
    if (!mounted) return;
    if (result.isErr) {
      setState(() => _linking = null);
      final err = result.exceptionOrNull;
      if (err?.code != AppErrorCode.oauthCancelled) {
        _toast(err!.localizedMessage(context.l10n), isError: true);
      }
      return;
    }
    _toast(context.l10n.accountLinkBrowser);
  }

  Future<void> _unlink(LinkedIdentity identity, LoginMethods methods) async {
    final label = socialProviderLabel(identity.provider);
    if (!methods.canUnlink(identity)) {
      _toast(context.l10n.accountUnlinkBlocked, isError: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.accountUnlinkConfirmTitle(label)),
        content: Text(context.l10n.accountUnlinkConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.expense,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(context.l10n.accountUnlink),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(authRepositoryProvider)
        .unlinkProvider(identity);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isOk) ref.invalidate(loginMethodsProvider);
    _toast(
      result.localizedErrorOrNull(context.l10n) ??
          context.l10n.accountUnlinked(label),
      isError: result.isErr,
    );
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final userAsync = ref.watch(currentUserProvider);
    final methodsAsync = ref.watch(loginMethodsProvider);
    final user = userAsync.valueOrNull;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(context.l10n.accountTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.accountBack,
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // --- Hồ sơ ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Center(child: EditableAvatar(user: user, radius: 44)),
            ),
            Center(
              child: Text(
                context.l10n.accountAvatarTapToChange,
                style: TextStyle(color: colors.textTertiary, fontSize: 12),
              ),
            ),
            _SectionLabel(context.l10n.accountSectionProfile),
            _ValueTile(
              icon: Icons.badge_outlined,
              title: context.l10n.accountDisplayName,
              value: (user?.fullName ?? '').trim().isEmpty
                  ? null
                  : user!.fullName!.trim(),
              subtitle: context.l10n.accountDisplayNameHint,
              onTap: userAsync.isLoading ? null : () => _editName(user),
            ),
            _ValueTile(
              icon: Icons.alternate_email,
              title: context.l10n.accountUsername,
              value: (user?.username ?? '').trim().isEmpty
                  ? null
                  : '@${user!.username}',
              subtitle: context.l10n.accountUsernameHint,
              onTap: userAsync.isLoading ? null : () => _editUsername(user),
            ),

            const Divider(height: 32),
            _SectionLabel(context.l10n.accountSectionLogin),
            methodsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => AsyncErrorView(
                error: e,
                compact: true,
                onRetry: () => ref.invalidate(loginMethodsProvider),
              ),
              data: (m) => Column(
                children: [
                  _EmailTile(
                    methods: m,
                    onEdit: _busy ? null : () => _editEmail(m),
                    onResend: _busy || m.pendingEmail == null
                        ? null
                        : () => _resendEmail(m.pendingEmail!),
                  ),
                  _PasswordTile(
                    methods: m,
                    onChange: _busy ? null : () => _changePassword(m),
                  ),
                ],
              ),
            ),

            const Divider(height: 32),
            _SectionLabel(context.l10n.accountSectionLinked),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                context.l10n.accountLinkHint,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ),
            methodsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (m) => Column(
                children: [
                  // Provider đang tắt vẫn hiện nếu tài khoản đã liên kết từ
                  // trước — nếu không người dùng sẽ mất đường gỡ liên kết.
                  for (final p in SocialProvider.values)
                    if (p.isEnabled || m.identityFor(p) != null)
                      _ProviderTile(
                        provider: p,
                        identity: m.identityFor(p),
                        canUnlink:
                            m.identityFor(p) != null &&
                            m.canUnlink(m.identityFor(p)!),
                        linking: _linking == p,
                        enabled: !_busy && _linking == null,
                        onLink: () => _link(p),
                        onUnlink: () => _unlink(m.identityFor(p)!, m),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tiles
// -----------------------------------------------------------------------------

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      leading: Icon(icon, color: colors.textSecondary),
      title: Text(
        title,
        style: TextStyle(color: colors.textSecondary, fontSize: 13),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value ?? context.l10n.accountNotSet,
            style: TextStyle(
              color: value == null ? colors.textTertiary : colors.textPrimary,
              fontSize: 16,
              fontStyle: value == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: colors.textTertiary, fontSize: 12),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Icon(
        Icons.edit_outlined,
        size: 20,
        color: colors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}

class _EmailTile extends StatelessWidget {
  const _EmailTile({
    required this.methods,
    required this.onEdit,
    required this.onResend,
  });

  final LoginMethods methods;
  final VoidCallback? onEdit;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final pending = methods.pendingEmail;

    final Widget status;
    if (methods.hasEmail) {
      status = _StatusChip(
        label: methods.emailConfirmed
            ? l10n.accountEmailVerified
            : l10n.accountEmailUnverified,
        color: methods.emailConfirmed ? colors.income : colors.warning,
        icon: methods.emailConfirmed ? Icons.verified : Icons.hourglass_top,
      );
    } else {
      status = const SizedBox.shrink();
    }

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.mail_outline, color: colors.textSecondary),
          title: Text(
            l10n.accountEmail,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          subtitle: Row(
            children: [
              Flexible(
                child: Text(
                  methods.email ?? l10n.accountEmailNone,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: methods.hasEmail
                        ? colors.textPrimary
                        : colors.textTertiary,
                    fontSize: 16,
                    fontStyle: methods.hasEmail
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
              if (methods.hasEmail) ...[const SizedBox(width: 8), status],
            ],
          ),
          trailing: TextButton(
            onPressed: onEdit,
            child: Text(
              methods.hasEmail ? l10n.accountEmailChange : l10n.accountEmailAdd,
            ),
          ),
          onTap: onEdit,
        ),
        if (pending != null && pending.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: colors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.accountEmailPending(pending),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          l10n.accountEmailPendingHint,
                          style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onResend,
                    child: Text(l10n.accountEmailResend),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PasswordTile extends StatelessWidget {
  const _PasswordTile({required this.methods, required this.onChange});

  final LoginMethods methods;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return ListTile(
      leading: Icon(Icons.lock_outline, color: colors.textSecondary),
      title: Text(
        l10n.accountPassword,
        style: TextStyle(color: colors.textSecondary, fontSize: 13),
      ),
      subtitle: Text(
        methods.hasPassword ? '••••••••' : l10n.accountPasswordNone,
        style: TextStyle(
          color: methods.hasPassword ? colors.textPrimary : colors.textTertiary,
          fontSize: methods.hasPassword ? 16 : 13,
          letterSpacing: methods.hasPassword ? 2 : 0,
        ),
      ),
      // Yêu cầu: không hiện mật khẩu, chỉ một dòng chữ màu vàng bấm được.
      trailing: TextButton(
        onPressed: onChange,
        style: TextButton.styleFrom(foregroundColor: colors.primary),
        child: Text(
          methods.hasPassword
              ? l10n.accountChangePassword
              : l10n.accountSetPassword,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      onTap: onChange,
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.identity,
    required this.canUnlink,
    required this.linking,
    required this.enabled,
    required this.onLink,
    required this.onUnlink,
  });

  final SocialProvider provider;
  final LinkedIdentity? identity;
  final bool canUnlink;
  final bool linking;
  final bool enabled;
  final VoidCallback onLink;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final linked = identity != null;
    final name = identity?.displayName;
    final secondary = identity?.secondary;

    final subtitleText = !linked
        ? l10n.accountNotLinked
        : [
            if (name != null && name.isNotEmpty) name,
            if (secondary != null && secondary.isNotEmpty) secondary,
          ].join(' · ');

    return ListTile(
      leading: SocialProviderIcon(provider, size: 32),
      title: Text(
        socialProviderLabel(provider),
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitleText.isEmpty ? l10n.accountLink : subtitleText,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: linked ? colors.textSecondary : colors.textTertiary,
          fontSize: 13,
          fontStyle: linked ? FontStyle.normal : FontStyle.italic,
        ),
      ),
      trailing: linking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : linked
          ? Tooltip(
              message: canUnlink ? '' : l10n.accountUnlinkBlocked,
              child: TextButton(
                onPressed: enabled ? onUnlink : null,
                style: TextButton.styleFrom(
                  foregroundColor: canUnlink
                      ? colors.expense
                      : colors.textTertiary,
                ),
                child: Text(l10n.accountUnlink),
              ),
            )
          : OutlinedButton(
              onPressed: enabled ? onLink : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary),
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Text(l10n.accountLink),
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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

// -----------------------------------------------------------------------------
// Dialogs
// -----------------------------------------------------------------------------

/// Hộp thoại một ô nhập có validate, trả chuỗi đã trim (null nếu huỷ).
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.label,
    required this.initial,
    this.helper,
    this.validator,
    this.keyboardType,
    this.lowercase = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final String title;
  final String label;
  final String initial;
  final String? helper;
  final String? Function(String value)? validator;
  final TextInputType? keyboardType;
  final bool lowercase;
  final TextCapitalization textCapitalization;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    var value = _controller.text.trim();
    if (widget.lowercase) value = value.toLowerCase();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.surface,
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.helper,
            helperMaxLines: 3,
          ),
          validator: (v) {
            var value = (v ?? '').trim();
            if (widget.lowercase) value = value.toLowerCase();
            if (value.isEmpty) return null;
            return widget.validator?.call(value);
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
          ),
          child: Text(context.l10n.actionSave),
        ),
      ],
    );
  }
}

/// Đổi (có ô mật khẩu cũ) hoặc đặt mật khẩu lần đầu.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.requireCurrent});

  final bool requireCurrent;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      current: widget.requireCurrent ? _current.text : null,
      next: _next.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: context.colors.surface,
      title: Text(
        widget.requireCurrent
            ? l10n.accountChangePassword
            : l10n.accountSetPassword,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.requireCurrent) ...[
                TextFormField(
                  controller: _current,
                  obscureText: _obscure,
                  autofocus: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: l10n.accountCurrentPassword,
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? l10n.authPasswordRequired
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _next,
                obscureText: _obscure,
                autofocus: !widget.requireCurrent,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: l10n.accountNewPassword,
                  helperText: l10n.authPasswordMinHint,
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? l10n.authShowPassword
                        : l10n.authHidePassword,
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? l10n.authPasswordMinLength
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: l10n.accountConfirmNewPassword,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return l10n.authConfirmPasswordRequired;
                  }
                  if (v != _next.text) return l10n.authPasswordMismatch;
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
          ),
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
