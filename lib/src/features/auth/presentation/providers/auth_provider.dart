import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/auth_repository.dart';
import '../../domain/app_user.dart';
import '../../domain/login_methods.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  return ref.read(authRepositoryProvider).getProfile();
});

/// Cach dang nhap hien co (mat khau, email, tai khoan lien ket) — nguon du lieu
/// cho man Tai khoan. autoDispose vi chi man do dung.
final loginMethodsProvider = FutureProvider.autoDispose<LoginMethods>((ref) {
  return ref.read(authRepositoryProvider).getLoginMethods();
});
