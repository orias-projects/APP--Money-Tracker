import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../constants/app_palette.dart';
import '../errors/error_reporter.dart';
import '../l10n/l10n.dart';
import 'app_settings.dart';

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

/// Thiết bị có vân tay / Face ID dùng được không.
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    final auth = ref.read(localAuthProvider);
    if (!await auth.isDeviceSupported()) return false;
    return auth.canCheckBiometrics;
  } catch (_) {
    // Web và desktop không có API sinh trắc học.
    return false;
  }
});

/// Chắn màn hình cho tới khi người dùng xác thực.
///
/// Bọc quanh toàn bộ app. Khi tắt khoá trong Cài đặt, widget này trong suốt.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _authenticating = false;
  DateTime? _backgroundedAt;

  /// Rời app dưới 30 giây (chuyển sang app khác chọn ảnh, xem thông báo) thì
  /// không bắt xác thực lại — nếu không, chọn ảnh hoá đơn xong là bị khoá.
  static const _graceperiod = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!ref.read(settingsProvider).biometricLock) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt = DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      if (since != null && DateTime.now().difference(since) > _graceperiod) {
        setState(() => _unlocked = false);
      }
      _backgroundedAt = null;
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    try {
      final ok = await ref
          .read(localAuthProvider)
          .authenticate(
            localizedReason: context.l10n.appLockReason,
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: false,
            ),
          );
      if (!mounted) return;
      setState(() {
        _authenticating = false;
        // ok == false nghĩa là người dùng huỷ hoặc xác thực sai → GIỮ khoá,
        // cho bấm thử lại. Không được tự mở.
        _unlocked = ok;
      });
    } on PlatformException catch (e, stack) {
      if (!mounted) return;
      // Chỉ mở khoá khi thiết bị THỰC SỰ không thể xác thực (không có phần cứng
      // sinh trắc học, chưa đăng ký, chưa đặt mã khoá màn hình, hoặc nền tảng
      // không hỗ trợ) — nếu không sẽ nhốt người dùng vĩnh viễn ngoài dữ liệu của
      // chính họ. Mọi lỗi khác (bị khoá tạm do thử sai nhiều lần, lỗi cấu hình
      // như thiếu FragmentActivity) GIỮ màn khoá và cho thử lại; đồng thời báo
      // Sentry để không âm thầm bỏ qua lỗi cấu hình.
      final deviceCannotAuthenticate =
          e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet ||
          e.code == auth_error.otherOperatingSystem;
      if (!deviceCannotAuthenticate) {
        ErrorReporter.instance.report(
          e,
          stack,
          hint: 'app_lock.authenticate:${e.code}',
        );
      }
      setState(() {
        _authenticating = false;
        _unlocked = deviceCannotAuthenticate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // .select: gate này bọc TOÀN BỘ app — đổi theme/tiền tệ không được phép
    // rebuild nó.
    final locked = ref.watch(settingsProvider.select((s) => s.biometricLock));

    if (!locked || _unlocked) return widget.child;

    return _LockScreen(
      authenticating: _authenticating,
      onUnlock: _authenticate,
    );
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen({required this.authenticating, required this.onUnlock});

  final bool authenticating;
  final VoidCallback onUnlock;

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  @override
  void initState() {
    super.initState();
    // Hỏi vân tay ngay, không bắt người dùng bấm thêm một nút.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onUnlock());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: context.colors.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 56, color: context.colors.primary),
              const SizedBox(height: 20),
              Text(
                context.l10n.appLockLocked,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              if (widget.authenticating)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                FilledButton.icon(
                  onPressed: widget.onUnlock,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(context.l10n.appLockUnlock),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
