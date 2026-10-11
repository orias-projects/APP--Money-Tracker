// Cài backend Coinsort lên Supabase từ máy dev bằng Management API.
//
// Làm thay toàn bộ bước tay trong Assets/SQL/README.md:
//   1. Chạy Assets/SQL/INSTALL_ALL.sql (schema `coinsort` + bảng + RPC + seed).
//   2. Thêm `coinsort` vào Exposed schemas của Data API (PostgREST).
//      Endpoint cấu hình có thể bị 403 tuỳ quyền tài khoản → tự rơi về SQL:
//      alter role authenticator set pgrst.db_schemas … + notify pgrst.
//   3. Auth: Confirm email OFF · Secure email change OFF · Manual linking ON ·
//      Redirect URL coinsort://login-callback/. (Không có đường SQL — nếu 403
//      thì in hướng dẫn bấm tay và đi tiếp.)
//   4. Kiểm tra: select count(*) from coinsort.categories → 25.
//
// CẦN: Personal Access Token (supabase.com/dashboard/account/tokens, dạng sbp_…).
// Token là bí mật cấp tài khoản — KHÔNG đặt vào .env (file đó được đóng gói vào
// app). Truyền theo một trong hai cách:
//   $env:SUPABASE_ACCESS_TOKEN = "sbp_..."; dart run tool/supabase_apply.dart
//   hoặc ghi token vào file .supabase_access_token ở thư mục gốc (đã gitignore).
// Project ref lấy tự động từ SUPABASE_URL trong .env. Dùng xong nên thu hồi token.
//
// Tuỳ chọn: --skip-sql (không chạy INSTALL_ALL), --skip-config (chỉ chạy SQL),
//           --dry-run, --query "select …" (chạy SQL lẻ, in JSON).
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _api = 'https://api.supabase.com/v1';
const _schema = 'coinsort';
const _redirect = 'coinsort://login-callback/';

Future<void> main(List<String> args) async {
  final skipSql = args.contains('--skip-sql');
  final skipConfig = args.contains('--skip-config');
  final dryRun = args.contains('--dry-run');
  final queryIdx = args.indexOf('--query');

  final token = _readToken();
  if (token == null) {
    _fail(
      'Thiếu Personal Access Token. Đặt biến môi trường SUPABASE_ACCESS_TOKEN '
      'hoặc tạo file .supabase_access_token chứa token (sbp_...).',
    );
  }
  final ref = _projectRefFromEnv();
  stdout.writeln('Project ref: $ref');
  final client = _Api(token, ref);

  // Chế độ chạy SQL lẻ để kiểm tra nhanh.
  if (queryIdx >= 0) {
    if (queryIdx + 1 >= args.length) _fail('--query cần kèm câu SQL.');
    final res = await client.query(args[queryIdx + 1]);
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(res));
    return;
  }

  if (!skipSql) {
    final sql = File('Assets/SQL/INSTALL_ALL.sql').readAsStringSync();
    stdout.writeln(
      '1/4  Chạy INSTALL_ALL.sql (${(sql.length / 1024).toStringAsFixed(0)} KB)…',
    );
    if (!dryRun) {
      await client.query(sql);
      // PostgREST cache cấu trúc DB; bảng/hàm mới tạo phải bảo nó nạp lại,
      // nếu không REST trả PGRST205 "not in the schema cache".
      await client.query("notify pgrst, 'reload schema';");
      stdout.writeln('     ✓ SQL xong (+ reload schema cache).');
    }
  } else {
    stdout.writeln('1/4  (bỏ qua INSTALL_ALL.sql)');
  }

  final manual = <String>[];

  if (!skipConfig) {
    stdout.writeln('2/4  Exposed schemas: thêm "$_schema"…');
    await _exposeSchema(client, ref, dryRun: dryRun);

    stdout.writeln('3/4  Auth settings…');
    final ok = await _configureAuth(client, ref, dryRun: dryRun);
    if (!ok) {
      manual.add(
        'Authentication → Sign In / Up → provider Email: Confirm email OFF · '
        'Secure email change OFF; khối User Signups: Allow manual linking ON.',
      );
      manual.add(
        'Authentication → URL Configuration → Redirect URLs: thêm $_redirect',
      );
    }
  }

  if (!dryRun) {
    stdout.writeln('4/4  Kiểm tra…');
    final n = _scalar(
      await client.query('select count(*)::int as n from $_schema.categories;'),
    );
    stdout.writeln('     $_schema.categories = $n (kỳ vọng 25)');
    final fns = _scalar(
      await client.query(
        "select count(*)::int as n from pg_proc p join pg_namespace s "
        "on s.oid = p.pronamespace where s.nspname = '$_schema';",
      ),
    );
    stdout.writeln('     hàm trong schema $_schema = $fns');
    final tables = _scalar(
      await client.query(
        "select count(*)::int as n from pg_tables where schemaname = '$_schema';",
      ),
    );
    stdout.writeln('     bảng trong schema $_schema = $tables');
    final exposed = await _currentExposedSchemas(client);
    stdout.writeln('     pgrst.db_schemas = ${exposed ?? '(chưa đặt)'}');
  }

  stdout.writeln('');
  if (manual.isNotEmpty) {
    stdout.writeln('CÒN PHẢI BẤM TAY trên Dashboard (API từ chối quyền):');
    for (final m in manual) {
      stdout.writeln('  • $m');
    }
  }
  stdout.writeln(
    'Bật provider Google/Facebook/Twitter với client ID/secret riêng của bạn — '
    'xem docs/SOCIAL_AUTH_SETUP.md. Nhớ thu hồi Personal Access Token khi xong.',
  );
}

// -----------------------------------------------------------------------------
// Bước 2 — Exposed schemas
// -----------------------------------------------------------------------------

Future<void> _exposeSchema(
  _Api client,
  String ref, {
  required bool dryRun,
}) async {
  // Đường chính: Management API.
  final rest = await client.tryGet('/projects/$ref/postgrest');
  if (rest != null) {
    final current = rest['db_schema'] as String? ?? 'public, graphql_public';
    final schemas = _splitList(current);
    if (!schemas.contains(_schema)) schemas.add(_schema);
    final next = schemas.join(', ');
    stdout.writeln('     [API] $current  →  $next');
    if (!dryRun && next != current) {
      await client.patch('/projects/$ref/postgrest', {'db_schema': next});
    }
    stdout.writeln('     ✓ Data API cập nhật qua Management API.');
    return;
  }

  // Dự phòng: PostgREST trên Supabase đọc cấu hình từ role `authenticator`
  // (pgrst.db_schemas). Đặt qua SQL rồi bảo PostgREST nạp lại.
  stdout.writeln(
    '     API cấu hình bị từ chối (403) → đặt qua SQL trên role authenticator.',
  );
  final current = await _currentExposedSchemas(client);
  final schemas = _splitList(current ?? 'public, graphql_public');
  if (!schemas.contains(_schema)) schemas.add(_schema);
  final next = schemas.join(', ');
  stdout.writeln('     [SQL] ${current ?? '(mặc định)'}  →  $next');
  if (!dryRun) {
    await client.query(
      "alter role authenticator set pgrst.db_schemas = '${next.replaceAll("'", "''")}';",
    );
    await client.query("notify pgrst, 'reload config';");
    await client.query("notify pgrst, 'reload schema';");
    stdout.writeln(
      '     ✓ pgrst.db_schemas đã đặt + notify pgrst (config + schema).',
    );
    stdout.writeln(
      '     Lưu ý: vào Dashboard → Project Settings → Data API → Exposed '
      'schemas kiểm tra thấy "$_schema" (nếu chưa thì thêm tay một lần để '
      'platform không ghi đè khi project restart).',
    );
  }
}

Future<String?> _currentExposedSchemas(_Api client) async {
  final rows = await client.query(
    "select coalesce((select split_part(c, '=', 2) from unnest(rolconfig) c "
    "where c like 'pgrst.db_schemas=%'), '') as v "
    "from pg_roles where rolname = 'authenticator';",
  );
  final v = _scalar(rows)?.toString().trim() ?? '';
  return v.isEmpty ? null : v;
}

// -----------------------------------------------------------------------------
// Bước 3 — Auth
// -----------------------------------------------------------------------------

Future<bool> _configureAuth(
  _Api client,
  String ref, {
  required bool dryRun,
}) async {
  final auth = await client.tryGet('/projects/$ref/config/auth');
  if (auth == null) {
    stdout.writeln(
      '     API cấu hình Auth bị từ chối (403) — không có đường SQL, phải bấm tay.',
    );
    return false;
  }
  final allow = _splitList(auth['uri_allow_list'] as String? ?? '');
  if (!allow.contains(_redirect)) allow.add(_redirect);
  final patch = <String, dynamic>{
    // Confirm email OFF (đăng ký username-only dùng email tổng hợp).
    'mailer_autoconfirm': true,
    // Chỉ email MỚI nhận link xác minh khi đổi email.
    'mailer_secure_email_change_enabled': false,
    // Nút "Liên kết" Google/Facebook/X trong màn Tài khoản.
    'security_manual_linking_enabled': true,
    'uri_allow_list': allow.join(','),
  };
  for (final e in patch.entries) {
    stdout.writeln('     ${e.key}: ${auth[e.key]}  →  ${e.value}');
  }
  if (!dryRun) {
    await client.patch('/projects/$ref/config/auth', patch);
    stdout.writeln('     ✓ Auth cập nhật.');
  }
  return true;
}

// -----------------------------------------------------------------------------

List<String> _splitList(String s) =>
    s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

dynamic _scalar(dynamic rows) {
  if (rows is List && rows.isNotEmpty && rows.first is Map) {
    final m = rows.first as Map;
    return m.values.isEmpty ? null : m.values.first;
  }
  return rows;
}

String? _readToken() {
  final env = Platform.environment['SUPABASE_ACCESS_TOKEN']?.trim();
  if (env != null && env.isNotEmpty) return env;
  final f = File('.supabase_access_token');
  if (f.existsSync()) {
    final t = f.readAsStringSync().trim();
    if (t.isNotEmpty) return t;
  }
  return null;
}

String _projectRefFromEnv() {
  final env = File('.env');
  if (!env.existsSync()) _fail('Không thấy .env ở thư mục gốc.');
  for (final line in env.readAsLinesSync()) {
    final t = line.trim();
    if (t.startsWith('SUPABASE_URL=')) {
      final url = t.substring('SUPABASE_URL='.length).trim();
      final host = Uri.tryParse(url)?.host ?? '';
      final ref = host.split('.').first;
      if (ref.isEmpty) _fail('SUPABASE_URL không hợp lệ: $url');
      return ref;
    }
  }
  _fail('Không thấy SUPABASE_URL trong .env.');
}

Never _fail(String msg) {
  stderr.writeln('LỖI: $msg');
  exit(1);
}

class _Api {
  _Api(this._token, this.ref);

  final String _token;
  final String ref;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  Future<dynamic> query(String sql) async {
    final res = await http.post(
      Uri.parse('$_api/projects/$ref/database/query'),
      headers: _headers,
      body: jsonEncode({'query': sql}),
    );
    _check(res, 'database/query');
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  /// GET trả null khi bị 403 (thiếu quyền endpoint) để caller chọn đường khác.
  Future<Map<String, dynamic>?> tryGet(String path) async {
    final res = await http.get(Uri.parse('$_api$path'), headers: _headers);
    if (res.statusCode == 403 || res.statusCode == 401) return null;
    _check(res, path);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$_api$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _check(res, path);
  }

  void _check(http.Response res, String what) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    _fail(
      '$what → HTTP ${res.statusCode}\n${res.body}\n'
      '(401/403: token sai hoặc không có quyền trên project; '
      '400 từ database/query: lỗi SQL — đọc thông điệp ở trên.)',
    );
  }
}
