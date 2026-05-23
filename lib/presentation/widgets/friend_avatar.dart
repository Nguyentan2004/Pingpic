import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'web_safe_image/web_safe_image.dart';
import '../../core/constants/app_colors.dart';
import '../providers/friend_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'package:pingpic/l10n/app_localizations.dart';

/// Left navigation sidebar — Desktop only
class AppSidebar extends StatelessWidget {
  final String currentPath;

  const AppSidebar({
    super.key,
    required this.currentPath,
  });



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final navItems = [
      _NavItem(icon: Icons.home_rounded, label: l10n.navHome, path: '/home'),
      _NavItem(icon: Icons.group_rounded, label: l10n.navFriends, path: '/friends'),
      _NavItem(icon: Icons.notifications_rounded, label: l10n.navNotifications, path: '/notifications'),
      _NavItem(icon: Icons.settings_rounded, label: l10n.navSettings, path: '/settings'),
    ];

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // App Logo
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.photo_camera_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Nav items
          ...List.generate(navItems.length, (i) {
            final item = navItems[i];
            final isSelected = currentPath == item.path;
            
            if (item.path == '/notifications') {
              return Consumer<NotificationProvider>(
                builder: (context, notifProvider, child) {
                  final unreadCount = notifProvider.unreadCount;
                  return _SidebarNavButton(
                    icon: item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    onTap: () => context.go(item.path),
                    badgeCount: unreadCount,
                  );
                },
              );
            }

            return _SidebarNavButton(
              icon: item.icon,
              label: item.label,
              isSelected: isSelected,
              onTap: () => context.go(item.path),
            );
          }),

          const Spacer(),

          // User avatar at bottom (navigates to Profile)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Consumer<AuthProvider>(
              builder: (context, auth, child) {
                final avatar = auth.avatarUrl;
                final isProfileSelected = currentPath == '/profile';
                return GestureDetector(
                  onTap: () => context.go('/profile?userId=${auth.userId}'),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isProfileSelected 
                              ? AppColors.primary 
                              : AppColors.primary.withOpacity(0.3),
                          width: 2.5,
                        ),
                        boxShadow: isProfileSelected ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 8,
                          )
                        ] : null,
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.darkCard,
                        child: avatar != null && avatar.isNotEmpty && !avatar.contains('pravatar.cc')
                            ? ClipOval(
                                child: WebSafeImage(
                                  imageUrl: avatar,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 80,
                                  memCacheHeight: 80,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.darkCard,
                                    padding: const EdgeInsets.all(6),
                                    child: const CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.person, size: 20, color: Colors.white70),
                                ),
                              )
                            : const Icon(Icons.person, size: 20, color: Colors.white70),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}

class _SidebarNavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _SidebarNavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<_SidebarNavButton> createState() => _SidebarNavButtonState();
}

class _SidebarNavButtonState extends State<_SidebarNavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : _isHovered
                      ? Colors.white.withOpacity(0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: widget.isSelected
                  ? Border.all(
                      color: AppColors.primary.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  widget.icon,
                  color: widget.isSelected
                      ? AppColors.primary
                      : _isHovered
                          ? Colors.white.withOpacity(0.8)
                          : AppColors.textMuted,
                  size: 24,
                ),
                if (widget.badgeCount > 0)
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
                          '${widget.badgeCount}',
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
          ),
        ),
      ),
    );
  }
}

/// Online friends strip (horizontal) at top of the feed
class FriendStripWidget extends StatelessWidget {
  const FriendStripWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, provider, child) {
        final friends = provider.friends;
        return SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: friends.length + 1, // +1 for "Add friend"
            padding: const EdgeInsets.symmetric(vertical: 8),
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == 0) return _AddFriendButton();
              final friend = friends[index - 1];
              return _FriendAvatar(
                userId: friend.id,
                name: friend.fullName,
                avatarUrl: friend.avatarUrl ?? 'https://i.pravatar.cc/150?u=${friend.username}',
                isOnline: friend.isOnline,
              );
            },
          ),
        );
      },
    );
  }
}

class _AddFriendButton extends StatefulWidget {
  @override
  State<_AddFriendButton> createState() => _AddFriendButtonState();
}

class _AddFriendButtonState extends State<_AddFriendButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push('/friends'),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isHovered
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.darkCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isHovered ? AppColors.primary : Colors.white.withOpacity(0.12),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.person_add_rounded,
                color: _isHovered ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.add,
              style: TextStyle(
                color: _isHovered ? AppColors.primary : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendAvatar extends StatefulWidget {
  final String userId;
  final String name;
  final String avatarUrl;
  final bool isOnline;

  const _FriendAvatar({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
  });

  @override
  State<_FriendAvatar> createState() => _FriendAvatarState();
}

class _FriendAvatarState extends State<_FriendAvatar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final shortName = widget.name.split(' ').first;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push('/profile?userId=${widget.userId}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -3.0 : 0.0),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.isOnline
                          ? const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: widget.isOnline
                          ? null
                          : Colors.white.withOpacity(0.1),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.darkCard,
                      child: widget.avatarUrl.isNotEmpty && !widget.avatarUrl.contains('pravatar.cc')
                          ? ClipOval(
                              child: WebSafeImage(
                                imageUrl: widget.avatarUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 100,
                                memCacheHeight: 100,
                                placeholder: (context, url) => Container(
                                  color: AppColors.darkCard,
                                  padding: const EdgeInsets.all(8),
                                  child: const CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.person, size: 24, color: Colors.white70),
                              ),
                            )
                          : const Icon(Icons.person, size: 24, color: Colors.white70),
                    ),
                  ),
                  if (widget.isOnline)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.darkBackground, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                shortName,
                style: TextStyle(
                  color: _isHovered ? Colors.white : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
