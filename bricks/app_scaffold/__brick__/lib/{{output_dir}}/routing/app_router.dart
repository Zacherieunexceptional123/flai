import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// Route name constants for the app scaffold.
///
/// Use these with [GoRouter.goNamed] for type-safe navigation:
/// ```dart
/// context.goNamed(AppRoutes.chatList);
/// context.goNamed(AppRoutes.chatDetail, pathParameters: {'id': chatId});
/// ```
abstract final class AppRoutes {
  /// Login screen.
  static const login = 'login';

  /// Registration screen.
  static const register = 'register';

  /// Forgot password screen.
  static const forgotPassword = 'forgot-password';

  /// Conversation list (main screen).
  static const chatList = 'chat-list';

  /// Chat detail screen. Requires `id` path parameter.
  static const chatDetail = 'chat-detail';

  /// Settings screen.
  static const settings = 'settings';

  /// Profile screen.
  static const profile = 'profile';
}

/// Route path constants.
abstract final class AppPaths {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const chatList = '/chats';
  static const chatDetail = '/chats/:id';
  static const settings = '/settings';
  static const profile = '/profile';
}

/// Creates the [GoRouter] for the app scaffold.
///
/// Listens to [AuthProvider.authStateChanges] to redirect between auth
/// screens and the main app. When the user is [Unauthenticated], all
/// non-auth routes redirect to login. When [Authenticated], auth routes
/// redirect to the chat list.
///
/// The [pageBuilder] callbacks are intentionally left for the consumer to
/// fill in — this function only provides the routing skeleton and auth
/// redirect logic.
///
/// ```dart
/// final router = createAppRouter(
///   authProvider: myAuthProvider,
///   loginBuilder: (context, state) => FlaiLoginScreen(...),
///   chatListBuilder: (context, state) => FlaiChatListScreen(...),
///   // ...
/// );
/// ```
GoRouter createAppRouter({
  required AuthProvider authProvider,
  required Widget Function(BuildContext, GoRouterState) loginBuilder,
  required Widget Function(BuildContext, GoRouterState) registerBuilder,
  required Widget Function(BuildContext, GoRouterState) forgotPasswordBuilder,
  required Widget Function(BuildContext, GoRouterState) chatListBuilder,
  required Widget Function(BuildContext, GoRouterState) chatDetailBuilder,
  required Widget Function(BuildContext, GoRouterState) settingsBuilder,
  required Widget Function(BuildContext, GoRouterState) profileBuilder,
  String initialLocation = AppPaths.chatList,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: _AuthStateNotifier(authProvider),
    redirect: (context, state) {
      final authState = authProvider.currentState;
      final isAuthRoute = state.matchedLocation == AppPaths.login ||
          state.matchedLocation == AppPaths.register ||
          state.matchedLocation == AppPaths.forgotPassword;

      // Still loading — don't redirect yet.
      if (authState is AuthLoading) return null;

      // Not authenticated and not on an auth route — go to login.
      if (authState is Unauthenticated && !isAuthRoute) {
        return AppPaths.login;
      }

      // Authenticated but on an auth route — go to chat list.
      if (authState is Authenticated && isAuthRoute) {
        return AppPaths.chatList;
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: AppPaths.login,
        name: AppRoutes.login,
        builder: loginBuilder,
      ),
      GoRoute(
        path: AppPaths.register,
        name: AppRoutes.register,
        builder: registerBuilder,
      ),
      GoRoute(
        path: AppPaths.forgotPassword,
        name: AppRoutes.forgotPassword,
        builder: forgotPasswordBuilder,
      ),

      // Main app routes
      GoRoute(
        path: AppPaths.chatList,
        name: AppRoutes.chatList,
        builder: chatListBuilder,
      ),
      GoRoute(
        path: AppPaths.chatDetail,
        name: AppRoutes.chatDetail,
        builder: chatDetailBuilder,
      ),
      GoRoute(
        path: AppPaths.settings,
        name: AppRoutes.settings,
        builder: settingsBuilder,
      ),
      GoRoute(
        path: AppPaths.profile,
        name: AppRoutes.profile,
        builder: profileBuilder,
      ),
    ],
  );
}

/// Bridges [AuthProvider.authStateChanges] into a [ChangeNotifier] so
/// [GoRouter] can listen for auth state changes and trigger redirects.
class _AuthStateNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  _AuthStateNotifier(AuthProvider authProvider) {
    _subscription = authProvider.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
