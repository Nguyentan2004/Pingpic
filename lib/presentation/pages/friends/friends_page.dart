import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pingpic/l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/app_colors.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<FriendProvider>().fetchFriendsData()
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showUnfriendDialog(BuildContext context, UserModel friend, FriendProvider provider, bool isDark, AppLocalizations l10n) {
    final dialogBg = isDark ? AppColors.darkSurface : Colors.white;
    final textCol = isDark ? Colors.white : AppColors.textDark;
    final subtextCol = isDark ? Colors.white70 : AppColors.textLight;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(l10n.friendsUnfriendConfirmTitle, style: TextStyle(color: textCol, fontWeight: FontWeight.bold)),
        content: Text(l10n.friendsUnfriendConfirmDesc(friend.fullName), style: TextStyle(color: subtextCol)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.settingsCancel, style: TextStyle(color: subtextCol)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.removeFriend(friend.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                      ? l10n.friendsUnfriendSuccess(friend.fullName) 
                      : l10n.friendsUnfriendFailed),
                    backgroundColor: success ? AppColors.success : Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(l10n.friendsUnfriendConfirmTitle, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCodeSection(BuildContext context, bool isDark, AppLocalizations l10n) {
    final authProvider = context.watch<AuthProvider>();
    final shareCode = authProvider.shareCode ?? '------';
    final textCol = isDark ? Colors.white : AppColors.textDark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primaryDark.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.inviteYourCode,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  shareCode,
                  style: TextStyle(
                    color: textCol,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.friendsInviteDesc,
                  style: TextStyle(
                    color: isDark ? AppColors.textMuted : AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(l10n.friendsInviteCopied),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(l10n.friendsCopy),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
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
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final hintCol = isDark ? AppColors.textMuted : AppColors.textLight;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.friendsTitle,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: context.canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: Consumer<FriendProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildInviteCodeSection(context, isDark, l10n),
              // ── Search Bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: textColor),
                  onChanged: (val) => provider.searchUsers(val),
                  decoration: InputDecoration(
                    hintText: l10n.friendsSearchPlaceholder,
                    hintStyle: TextStyle(color: hintCol),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty 
                      ? IconButton(
                          icon: Icon(Icons.clear, color: hintCol, size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            provider.searchUsers('');
                          },
                        )
                      : null,
                  ),
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.fetchFriendsData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // ── Search Results ─────────────────────────────────────
                      if (provider.searchResults.isNotEmpty) ...[
                        _buildSectionHeader(l10n.friendsSearchResults),
                        ...provider.searchResults.map((user) => _UserListTile(
                          user: user,
                          isDark: isDark,
                          l10n: l10n,
                          onAction: () => provider.sendRequest(user.id),
                          actionLabel: user.isFriend 
                            ? l10n.navFriends
                            : (user.isRequested ? l10n.friendRequested : l10n.addFriendButton),
                          isPending: user.isRequested,
                          isFriend: user.isFriend,
                        )),
                        Divider(color: isDark ? Colors.white10 : AppColors.black10, height: 32),
                      ],

                      // ── Pending Requests ───────────────────────────────────
                      if (provider.pendingRequests.isNotEmpty) ...[
                        _buildSectionHeader(l10n.friendsFriendRequests),
                        ...provider.pendingRequests.map((req) => _RequestListTile(
                          request: req,
                          isDark: isDark,
                          l10n: l10n,
                          onAccept: () => provider.acceptRequest(req.id),
                          onReject: () => provider.rejectRequest(req.id),
                        )),
                        const SizedBox(height: 24),
                      ],

                      // ── Friends List ───────────────────────────────────────
                      _buildSectionHeader(l10n.friendsMyFriends(provider.friends.length)),
                      if (provider.isLoading)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ))
                      else if (provider.friends.isEmpty)
                        _buildEmptyState(l10n.friendsNoFriendsDesc)
                      else
                        ...provider.friends.map((friend) => _UserListTile(
                          user: friend,
                          isFriend: true,
                          isDark: isDark,
                          l10n: l10n,
                          onUnfriend: () => _showUnfriendDialog(context, friend, provider, isDark, l10n),
                        )),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool isPending;
  final bool isFriend;
  final VoidCallback? onUnfriend;
  final bool isDark;
  final AppLocalizations l10n;

  const _UserListTile({
    required this.user,
    required this.isDark,
    required this.l10n,
    this.onAction,
    this.actionLabel,
    this.isPending = false,
    this.isFriend = false,
    this.onUnfriend,
  });

  String _formatLastActive(DateTime? lastActive, AppLocalizations l10n) {
    if (lastActive == null) return l10n.friendsOffline;
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inSeconds < 60) {
      return l10n.friendsLastActiveJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.friendsLastActiveMinutes(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.friendsLastActiveHours(difference.inHours);
    } else {
      final days = difference.inDays;
      if (days == 1) {
        return l10n.friendsLastActiveYesterday;
      }
      return l10n.friendsLastActiveDays(days);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final textCol = isDark ? Colors.white : AppColors.textDark;
    final subtextCol = isDark ? AppColors.textMuted : AppColors.textLight;
    final borderCol = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.2),
                backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) 
                  ? NetworkImage(user.avatarUrl!) 
                  : null,
                child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                  ? Text(user.fullName.isNotEmpty ? user.fullName[0] : '?', style: const TextStyle(color: AppColors.primary)) 
                  : null,
              ),
              if (isFriend && user.isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cardBg,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(color: textCol, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '@${user.username}',
                      style: TextStyle(color: subtextCol, fontSize: 13),
                    ),
                    if (isFriend) ...[
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(color: subtextCol, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.isOnline ? l10n.friendsOnlineStatus : _formatLastActive(user.lastActive, l10n),
                          style: TextStyle(
                            color: user.isOnline ? AppColors.success : subtextCol,
                            fontSize: 12,
                            fontWeight: user.isOnline ? FontWeight.w500 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isFriend && onUnfriend != null)
            IconButton(
              icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent, size: 20),
              tooltip: l10n.friendsUnfriendConfirmTitle,
              onPressed: onUnfriend,
            )
          else if (actionLabel != null)
            ElevatedButton(
              onPressed: (isPending || isFriend) ? null : onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFriend ? Colors.transparent : AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _RequestListTile extends StatelessWidget {
  final FriendRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isDark;
  final AppLocalizations l10n;

  const _RequestListTile({
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final textCol = isDark ? Colors.white : AppColors.textDark;
    final subtextCol = isDark ? AppColors.textMuted : AppColors.textLight;
    final cardBg = isDark ? AppColors.primary.withOpacity(0.05) : AppColors.primary.withOpacity(0.03);
    final borderCol = isDark ? AppColors.primary.withOpacity(0.1) : AppColors.primary.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: (request.requesterAvatar.isNotEmpty)
                ? NetworkImage(request.requesterAvatar)
                : null,
            child: (request.requesterAvatar.isEmpty)
                ? Text(
                    request.requesterName.isNotEmpty ? request.requesterName[0] : '?',
                    style: const TextStyle(color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.requesterName,
                  style: TextStyle(color: textCol, fontWeight: FontWeight.bold),
                ),
                Text(
                  l10n.friendsWantsToBeFriends,
                  style: TextStyle(color: subtextCol, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: onAccept,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(l10n.friendsAccept),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : AppColors.textLight,
                  side: BorderSide(color: isDark ? Colors.white24 : AppColors.black24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(l10n.friendsReject),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
