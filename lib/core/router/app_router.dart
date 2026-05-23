import 'package:go_router/go_router.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/camera/camera_page.dart';
import '../../presentation/pages/friends/friends_page.dart';
import '../../presentation/pages/history/history_page.dart';
import '../../presentation/pages/notifications/notifications_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/profile/moment_viewer_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/widgets/main_layout_shell.dart';
import '../../presentation/providers/auth_provider.dart';

class AppRouter {
  static GoRouter? _router;

  static GoRouter getRouter(AuthProvider authProvider) {
    _router ??= GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final status = authProvider.status;
        final matchedLocation = state.matchedLocation;

        // 1. Auth Loading State (Firebase restoring session)
        if (status == AuthStatus.unknown) {
          if (matchedLocation == '/splash') return null;
          return '/splash';
        }

        final isAuthRoute = matchedLocation == '/login' || matchedLocation == '/register';

        // 2. Unauthenticated state -> redirect to /login
        if (status == AuthStatus.unauthenticated) {
          if (isAuthRoute) return null;
          return '/login';
        }

        // 3. Authenticated state -> redirect to /home if on login/register/splash
        if (status == AuthStatus.authenticated) {
          if (isAuthRoute || matchedLocation == '/splash') {
            return '/home';
          }
          return null;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/camera',
          name: 'camera',
          builder: (context, state) => const CameraPage(),
        ),
        GoRoute(
          path: '/history',
          name: 'history',
          builder: (context, state) => const HistoryPage(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return MainLayoutShell(state: state, child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
            GoRoute(
              path: '/friends',
              name: 'friends',
              builder: (context, state) => const FriendsPage(),
            ),
            GoRoute(
              path: '/notifications',
              name: 'notifications',
              builder: (context, state) => const NotificationsPage(),
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) {
                final userId = state.uri.queryParameters['userId'];
                return ProfilePage(userId: userId);
              },
              routes: [
                GoRoute(
                  path: 'moments',
                  name: 'profile_moments',
                  builder: (context, state) {
                    final userId = state.uri.queryParameters['userId'] ?? '';
                    final senderName = state.uri.queryParameters['senderName'] ?? '';
                    final senderAvatar = state.uri.queryParameters['senderAvatar'] ?? '';
                    final initialIndexStr = state.uri.queryParameters['initialIndex'] ?? '0';
                    final initialIndex = int.tryParse(initialIndexStr) ?? 0;
                    final initialMomentId = state.uri.queryParameters['momentId'];
                    return MomentViewerPage(
                      userId: userId,
                      senderName: senderName,
                      senderAvatar: senderAvatar,
                      initialIndex: initialIndex,
                      initialMomentId: initialMomentId,
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    );
    return _router!;
  }
}
