import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pingpic/l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/web_safe_image/web_safe_image.dart';
import '../../providers/notification_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/notification_model.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  String _formatTimeAgo(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.isNegative) return l10n.notificationsJustNow;
    if (diff.inSeconds < 60) return l10n.notificationsJustNow;
    if (diff.inMinutes < 60) return l10n.notificationsMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.notificationsHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.notificationsDaysAgo(diff.inDays);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
  String _getLocalizedTitle(NotificationModel notification, AppLocalizations l10n) {
    switch (notification.type) {
      case 'friend_request':
        return l10n.notificationFriendRequestTitle;
      case 'friend_accepted':
        return l10n.notificationFriendAcceptedTitle;
      case 'moment_posted':
        return l10n.notificationMomentPostedTitle;
      case 'like':
        return l10n.notificationLikedMomentTitle;
      case 'comment':
        return l10n.notificationCommentedMomentTitle;
      case 'reply':
        return l10n.notificationRepliedCommentTitle;
      default:
        return '';
    }
  }

  String _getLocalizedBody(NotificationModel notification, AppLocalizations l10n) {
    switch (notification.type) {
      case 'friend_request':
        return l10n.notificationFriendRequestBody(notification.senderName);
      case 'friend_accepted':
        return l10n.notificationFriendAcceptedBody(notification.senderName);
      case 'moment_posted':
        return l10n.notificationMomentPostedBody(notification.senderName);
      case 'like':
        return l10n.notificationLikedMoment(notification.senderName);
      case 'comment':
        return l10n.notificationCommentedMoment(notification.senderName);
      case 'reply':
        return l10n.notificationRepliedComment(notification.senderName);
      default:
        return '';
    }
  }

  void _showMomentPreview(BuildContext context, NotificationModel notification, bool isDark, AppLocalizations l10n) {
    if (notification.imageUrl == null || notification.imageUrl!.isEmpty) return;

    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final textCol = isDark ? Colors.white : AppColors.textDark;
    final subtextCol = isDark ? Colors.white70 : AppColors.textLight;
    final borderCol = isDark ? Colors.white10 : AppColors.black10;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: cardBg,
              border: Border.all(color: borderCol),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          backgroundImage: notification.senderAvatar.isNotEmpty
                              ? NetworkImage(notification.senderAvatar)
                              : null,
                          child: notification.senderAvatar.isEmpty
                              ? Text(
                                  notification.senderName.isNotEmpty ? notification.senderName[0] : '?',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 12),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            notification.senderName,
                            style: TextStyle(
                              color: textCol,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: textCol, size: 20),
                          onPressed: () => Navigator.pop(dialogContext),
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                        )
                      ],
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: WebSafeImage(
                      imageUrl: notification.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(Icons.broken_image, size: 48, color: textCol.withOpacity(0.3)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _getLocalizedBody(notification, l10n),
                      style: TextStyle(color: subtextCol, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subtextColor = isDark ? AppColors.textMuted : AppColors.textLight;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.notificationsTitle,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              final hasUnread = provider.unreadCount > 0;
              return TextButton.icon(
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text(l10n.notificationsReadAll),
                style: TextButton.styleFrom(
                  foregroundColor: hasUnread ? AppColors.primary : subtextColor,
                ),
                onPressed: hasUnread
                    ? () async {
                        await provider.markAllAsRead();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.notificationsMarkedRead),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    : null,
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: subtextColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.notificationsNoNotifications,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.notificationsWeWillNotify,
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: provider.notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = provider.notifications[index];
              return _NotificationTile(
                notification: item,
                title: _getLocalizedTitle(item, l10n),
                body: _getLocalizedBody(item, l10n),
                timeAgo: _formatTimeAgo(item.createdAt, l10n),
                isDark: isDark,
                onTap: () {
                  if (!item.isRead) {
                    provider.markAsRead(item.id);
                  }
                  if (item.type == 'moment_posted' ||
                      item.type == 'like' ||
                      item.type == 'comment' ||
                      item.type == 'reply') {
                    if (item.postId != null && item.postId!.isNotEmpty) {
                      final authProvider = context.read<AuthProvider>();
                      final String ownerId = item.postOwnerId ?? (item.type == 'moment_posted' ? item.senderId : authProvider.userId ?? '');
                      final String ownerName = (ownerId == authProvider.userId)
                          ? (authProvider.fullName ?? '')
                          : item.senderName;
                      final String ownerAvatar = (ownerId == authProvider.userId)
                          ? (authProvider.avatarUrl ?? '')
                          : item.senderAvatar;

                      context.push(
                        '/profile/moments'
                        '?userId=$ownerId'
                        '&senderName=${Uri.encodeComponent(ownerName)}'
                        '&senderAvatar=${Uri.encodeComponent(ownerAvatar)}'
                        '&momentId=${item.postId}',
                      );
                    }
                  } else if (item.type == 'friend_request' || item.type == 'friend_accepted') {
                    context.push('/profile?userId=${item.senderId}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final String title;
  final String body;
  final String timeAgo;
  final VoidCallback onTap;
  final bool isDark;

  const _NotificationTile({
    required this.notification,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textCol = isDark ? Colors.white : AppColors.textDark;
    final subtextCol = isDark ? AppColors.textMuted : AppColors.textLight;
    final tileBg = notification.isRead 
        ? (isDark ? AppColors.darkSurface : Colors.white)
        : AppColors.primary.withOpacity(isDark ? 0.06 : 0.04);
    final borderCol = notification.isRead 
        ? (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04))
        : AppColors.primary.withOpacity(0.2);

    IconData getIcon() {
      switch (notification.type) {
        case 'friend_request':
          return Icons.person_add_rounded;
        case 'friend_accepted':
          return Icons.check_circle_rounded;
        case 'moment_posted':
          return Icons.photo_library_rounded;
        case 'like':
          return Icons.favorite_rounded;
        case 'comment':
          return Icons.chat_bubble_rounded;
        case 'reply':
          return Icons.reply_rounded;
        default:
          return Icons.notifications_rounded;
      }
    }

    Color getBadgeBgColor() {
      switch (notification.type) {
        case 'like':
          return Colors.redAccent;
        case 'comment':
          return Colors.blueAccent;
        case 'reply':
          return Colors.purpleAccent;
        case 'friend_request':
          return Colors.orangeAccent;
        case 'friend_accepted':
          return Colors.green;
        case 'moment_posted':
          return AppColors.primary;
        default:
          return Colors.grey;
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          children: [
            // Sender Avatar with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? AppColors.darkCard : Colors.grey[200],
                  backgroundImage: notification.senderAvatar.isNotEmpty && 
                          !notification.senderAvatar.contains('pravatar.cc')
                      ? NetworkImage(notification.senderAvatar)
                      : null,
                  child: notification.senderAvatar.isEmpty || 
                          notification.senderAvatar.contains('pravatar.cc')
                      ? Text(
                          notification.senderName.isNotEmpty ? notification.senderName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppColors.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: getBadgeBgColor(),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      getIcon(),
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            
            // Notification Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textCol,
                      fontSize: 13,
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(
                      color: subtextCol,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: subtextCol.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),

            // Thumbnail preview
            if (notification.imageUrl != null && 
                notification.imageUrl!.isNotEmpty)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.white10 : AppColors.black10),
                ),
                clipBehavior: Clip.antiAlias,
                child: WebSafeImage(
                  imageUrl: notification.imageUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 100,
                  memCacheHeight: 100,
                ),
              ),

            // Unread Dot Indicator
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
