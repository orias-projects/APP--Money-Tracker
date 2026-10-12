import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
}

/// Nguồn [SupabaseClient] để các repository nhận qua constructor thay vì gọi
/// [SupabaseService.client] tĩnh — nhờ đó unit-test có thể override provider này
/// để tiêm một client giả.
///
/// Mặc định vẫn trả về [Supabase.instance.client] như cũ nên hành vi runtime
/// không đổi.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
