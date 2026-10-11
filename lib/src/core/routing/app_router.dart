import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/accounts/presentation/screens/manage_accounts_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/recover_code_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';
import '../../features/categories/presentation/screens/manage_categories_screen.dart';
import '../../features/charts/presentation/screens/charts_screen.dart';
import '../../features/groups/presentation/screens/group_members_screen.dart';
import '../../features/groups/presentation/screens/manage_groups_screen.dart';
import '../../features/groups/presentation/screens/settle_up_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/account_screen.dart';
import '../../features/profile/presentation/screens/friend_screen.dart';
import '../../features/profile/presentation/screens/me_screen.dart';
import '../../features/records/presentation/screens/records_screen.dart';
import '../../features/recurring/presentation/screens/recurring_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/delete_account_screen.dart';
import '../../features/settings/presentation/screens/export_screen.dart';
import '../../features/settings/presentation/screens/privacy_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../features/transactions/presentation/screens/edit_transaction_screen.dart';
import '../../shell/main_shell_screen.dart';
import '../l10n/l10n.dart';

/// Các đường dẫn dùng được khi CHƯA đăng nhập.
const _publicRoutes = {
  '/login',
  '/register',
  '/forgot-password',
  '/recover-code',
  '/reset-password',
  '/privacy',
};

/// Cầu nối giữa `Stream<AuthState>` của Supabase và `refreshListenable` của
/// GoRouter.
///
/// Thiếu thứ này, `redirect` chỉ chạy khi có điều hướng — token hết hạn hay
/// đăng xuất từ thiết bị khác sẽ để người dùng kẹt trong shell rỗng.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final notifier = _AuthNotifier(auth.onAuthStateChange);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
      final location = state.uri.path;
      final isPublic = _publicRoutes.contains(location);

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && (location == '/login' || location == '/register')) {
        return '/';
      }
      return null;
    },
    errorBuilder: (context, state) =>
        _RouteErrorScreen(location: state.uri.path),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: RecordsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/charts',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ChartsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AddTransactionScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ReportsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MeScreen()),
                routes: [
                  GoRoute(
                    path: 'manage-groups',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: HeroMode(
                        enabled: false,
                        child: ManageGroupsScreen(),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'group-members',
                    pageBuilder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final groupId = extra?['groupId'] as String? ?? '';
                      return NoTransitionPage(
                        key: ValueKey('group-members-$groupId'),
                        child: HeroMode(
                          enabled: false,
                          child: GroupMembersScreen(
                            groupId: groupId,
                            groupName: extra?['groupName'] as String? ?? '',
                            isPersonal: extra?['isPersonal'] as bool? ?? true,
                          ),
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'account',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: AccountScreen()),
                  ),
                  GoRoute(
                    path: 'settings',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: SettingsScreen()),
                  ),
                  GoRoute(
                    path: 'accounts',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: ManageAccountsScreen()),
                  ),
                  GoRoute(
                    path: 'categories',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: ManageCategoriesScreen()),
                  ),
                  GoRoute(
                    path: 'budgets',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: BudgetsScreen()),
                  ),
                  GoRoute(
                    path: 'recurring',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: RecurringScreen()),
                  ),
                  GoRoute(
                    path: 'export',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: ExportScreen()),
                  ),
                  GoRoute(
                    path: 'delete-account',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: DeleteAccountScreen()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // --- Ngoài shell ---
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/recover-code',
        builder: (context, state) {
          final email = state.extra as String?;
          if (email == null || email.isEmpty) {
            return const ForgotPasswordScreen();
          }
          return RecoverCodeScreen(email: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) =>
            ResetPasswordScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(path: '/privacy', builder: (_, _) => const PrivacyScreen()),
      GoRoute(
        path: '/notifications',
        builder: (_, _) =>
            const HeroMode(enabled: false, child: NotificationsScreen()),
      ),
      GoRoute(
        path: '/friend',
        builder: (_, _) =>
            const HeroMode(enabled: false, child: FriendScreen()),
      ),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: '/settle-up',
        builder: (context, state) {
          final groupId = state.extra as String? ?? '';
          if (groupId.isEmpty) {
            return const _RouteErrorScreen(location: '/settle-up');
          }
          return SettleUpScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/edit-transaction',
        builder: (context, state) {
          final tx = state.extra as Transaction?;
          if (tx == null) {
            return const _RouteErrorScreen(location: '/edit-transaction');
          }
          return EditTransactionScreen(transaction: tx);
        },
      ),
    ],
  );
});

/// Màn hình khi đường dẫn không hợp lệ hoặc thiếu dữ liệu truyền kèm.
class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.routeErrorTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off, size: 44),
              const SizedBox(height: 16),
              Text(
                context.l10n.routeErrorBody(location),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go('/'),
                child: Text(context.l10n.routeErrorGoHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
