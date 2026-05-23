import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pingpic/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import 'friend_avatar.dart'; // For AppSidebar
import 'camera_panel.dart'; // For CameraPanel

class MainLayoutShell extends StatefulWidget {
  final GoRouterState state;
  final Widget child;

  const MainLayoutShell({
    super.key,
    required this.state,
    required this.child,
  });

  @override
  State<MainLayoutShell> createState() => _MainLayoutShellState();
}

class _MainLayoutShellState extends State<MainLayoutShell> {
  // Responsive breakpoints
  static const double _kTabletBreakpoint = 600;
  static const double _kDesktopBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final currentPath = widget.state.uri.path;
    final isHome = currentPath == '/home';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width >= _kDesktopBreakpoint) {
            return _buildDesktopLayout(currentPath, isHome);
          } else if (width >= _kTabletBreakpoint) {
            return _buildTabletLayout(currentPath, isHome);
          } else {
            return _buildMobileLayout(currentPath, isHome);
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // DESKTOP LAYOUT: Left AppSidebar | Center dynamic child | Right CameraPanel (on /home)
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(String currentPath, bool isHome) {
    return Row(
      children: [
        AppSidebar(currentPath: currentPath),
        Expanded(
          child: widget.child,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // TABLET LAYOUT: Top bar | Center dynamic child | Bottom Nav
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildTabletLayout(String currentPath, bool isHome) {
    return Column(
      children: [
        if (isHome) _buildTopBar(),
        Expanded(
          child: widget.child,
        ),
        _buildBottomNavBar(currentPath),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // MOBILE LAYOUT: Full dynamic child, FAB for camera (on /home), Bottom Nav
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(String currentPath, bool isHome) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: isHome
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: _buildTopBar(),
            )
          : null,
      body: SafeArea(child: widget.child),
      bottomNavigationBar: _buildBottomNavBar(currentPath),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // SHARABLE HEADER & BOTTOM NAV
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : AppColors.textDark;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // App Logo + Name
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color: textCol,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // History Button
          IconButton(
            icon: Icon(Icons.history_rounded, color: textCol),
            tooltip: AppLocalizations.of(context)!.navHistory,
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(String currentPath) {
    final l10n = AppLocalizations.of(context)!;
    final navItems = [
      _BottomNavItem(icon: Icons.home_rounded, label: l10n.navHome, path: '/home'),
      _BottomNavItem(icon: Icons.group_rounded, label: l10n.navFriends, path: '/friends'),
      _BottomNavItem(icon: Icons.camera_alt_rounded, label: l10n.navCamera, path: '/camera'),
      _BottomNavItem(icon: Icons.notifications_rounded, label: l10n.navNotifications, path: '/notifications'),
      _BottomNavItem(icon: Icons.person_rounded, label: l10n.navProfile, path: '/profile'),
    ];

    int selectedIndex = 0;
    if (currentPath == '/home') selectedIndex = 0;
    else if (currentPath == '/friends') selectedIndex = 1;
    else if (currentPath == '/camera') selectedIndex = 2;
    else if (currentPath == '/notifications') selectedIndex = 3;
    else if (currentPath == '/profile' || currentPath == '/settings') selectedIndex = 4;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (i) {
            final item = navItems[i];
            final isSelected = selectedIndex == i;

            if (i == 3) {
              return Consumer<NotificationProvider>(
                builder: (context, notifProvider, child) {
                  final unreadCount = notifProvider.unreadCount;
                  return _buildBottomNavButton(item, isSelected, badgeCount: unreadCount);
                },
              );
            }

            return _buildBottomNavButton(item, isSelected);
          }),
        ),
      ),
    );
  }

  Widget _buildBottomNavButton(_BottomNavItem item, bool isSelected, {int badgeCount = 0}) {
    return GestureDetector(
      onTap: () {
        if (item.path == '/profile') {
          final auth = context.read<AuthProvider>();
          context.go('/profile?userId=${auth.userId}');
        } else {
          context.go(item.path);
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraFAB() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showCameraModal,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
      ),
    );
  }

  void _showCameraModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: const Column(
            children: [
              SizedBox(height: 8),
              _BottomSheetHandle(),
              SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CameraPanel(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;
  final String path;
  const _BottomNavItem({required this.icon, required this.label, required this.path});
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
