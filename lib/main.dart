import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/core/config/oauth_config.dart';
import 'src/core/errors/error_reporter.dart';
import 'src/core/services/secure_local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nạp cấu hình trước tiên. `.env` được đóng gói vào asset bundle; nếu vì lý do
  // nào đó thiếu, hiện màn hướng dẫn thay vì màn trắng khó hiểu.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    runApp(const _ConfigErrorApp());
    return;
  }

  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    runApp(const _ConfigErrorApp());
    return;
  }

  final sentryDsn = dotenv.env['SENTRY_DSN'];

  if (sentryDsn != null && sentryDsn.isNotEmpty) {
    // Sentry tự thiết lập zone bảo vệ + FlutterError.onError của riêng nó.
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.environment = dotenv.env['APP_ENV'] ?? 'production';
      options.tracesSampleRate = 0.2;
      options.debug = true; // TAM THOI
    }, appRunner: () {
      // TAM THOI: nem mot loi async sau 6 giay de kiem tra duong day len Sentry.
      Future<void>.delayed(const Duration(seconds: 6), () {
        throw StateError('Coinsort smoke test — loi co y, se go sau khi kiem tra');
      });
      return _bootstrap(url, anonKey, sentryEnabled: true);
    });
  } else {
    // Không có DSN: vẫn bắt lỗi async ngoài luồng bằng zone của chính ta.
    await runZonedGuarded(
      () => _bootstrap(url, anonKey, sentryEnabled: false),
      (error, stack) =>
          ErrorReporter.instance.report(error, stack, fatal: true),
    );
  }
}

Future<void> _bootstrap(
  String url,
  String anonKey, {
  required bool sentryEnabled,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (sentryEnabled) ErrorReporter.instance.markSentryEnabled();

  // Google native cần Web client ID; trống thì nút Google đi qua trình duyệt.
  OAuthConfig.configure(googleWebClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID']);

  // Edge-to-edge thống nhất trên mọi bản Android (15+ vốn đã ép buộc);
  // màu icon status bar do AnnotatedRegion trong app.dart quyết định theo theme.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Dữ liệu locale cho intl (tên thứ/tháng tiếng Việt và tiếng Anh).
  await initializeDateFormatting('vi_VN');
  await initializeDateFormatting('en_US');

  try {
    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
      // Toàn bộ bảng/RPC nằm trong schema riêng (xem Assets/SQL/README.md).
      postgrestOptions: const PostgrestClientOptions(schema: kSupabaseSchema),
      // Giữ token trong Keystore/Keychain thay vì SharedPreferences plaintext.
      authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
    );
  } catch (error, stack) {
    await ErrorReporter.instance.report(
      error,
      stack,
      hint: 'Supabase.initialize',
    );
    runApp(const _InitErrorApp());
    return;
  }

  // Khi không bật Sentry, tự nối các móc lỗi framework/async vào ErrorReporter.
  // Khi bật Sentry, chính Sentry đã nối các móc này nên không ghi đè.
  if (!sentryEnabled) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      ErrorReporter.instance.report(details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorReporter.instance.report(error, stack, fatal: true);
      return true;
    };
  }

  runApp(const ProviderScope(child: CoinsortApp()));
}

/// Hiện khi thiếu `.env` — thay vì crash với thông báo khó hiểu.
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return const _BootstrapErrorScreen(
      icon: Icons.settings_ethernet,
      title: 'Thiếu cấu hình máy chủ',
      message:
          'Tạo file .env ở thư mục gốc với SUPABASE_URL và SUPABASE_ANON_KEY, '
          'rồi chạy lại ứng dụng. Xem .env.example để biết định dạng.',
    );
  }
}

/// Hiện khi kết nối máy chủ thất bại lúc khởi động (URL sai, storage lỗi…).
class _InitErrorApp extends StatelessWidget {
  const _InitErrorApp();

  @override
  Widget build(BuildContext context) {
    return const _BootstrapErrorScreen(
      icon: Icons.cloud_off,
      title: 'Không kết nối được máy chủ',
      message:
          'Ứng dụng chưa khởi động được kết nối tới máy chủ. Kiểm tra mạng và '
          'cấu hình SUPABASE_URL, rồi mở lại ứng dụng.',
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
