import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/friend_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Add Friends', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<FriendProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // ── Search Bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) => provider.searchUsers(val),
                  decoration: InputDecoration(
                    hintText: 'Search by username...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.darkCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
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
                        _buildSectionHeader('Search Results'),
                        ...provider.searchResults.map((user) => _UserListTile(
                          user: user,
                          onAction: () => provider.sendRequest(user.id),
                          actionLabel: user.isFriend 
                            ? 'Friend' 
                            : (user.isRequested ? 'Requested' : 'Add'),
                          isPending: user.isRequested,
                          isFriend: user.isFriend,
                        )),
                        const Divider(color: Colors.white10, height: 32),
                      ],

                      // ── Pending Requests ───────────────────────────────────
                      if (provider.pendingRequests.isNotEmpty) ...[
                        _buildSectionHeader('Friend Requests'),
                        ...provider.pendingRequests.map((req) => _RequestListTile(
                          request: req,
                          onAccept: () => provider.acceptRequest(req.id),
                        )),
                        const SizedBox(height: 24),
                      ],

                      // ── Friends List ───────────────────────────────────────
                      _buildSectionHeader('My Friends (${provider.friends.length})'),
                      if (provider.isLoading)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ))
                      else if (provider.friends.isEmpty)
                        _buildEmptyState('No friends yet. Start adding some!')
                      else
                        ...provider.friends.map((friend) => _UserListTile(
                          user: friend,
                          isFriend: true,
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
        style: TextStyle(
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
          Text(message, style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final dynamic user; // UserModel
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool isPending;
  final bool isFriend;

  const _UserListTile({
    required this.user,
    this.onAction,
    this.actionLabel,
    this.isPending = false,
    this.isFriend = false,
  });

  String _formatLastActive(DateTime? lastActive) {
    if (lastActive == null) return 'Offline';
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inSeconds < 60) {
      return 'Active just now';
    } else if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours}h ago';
    } else {
      final days = difference.inDays;
      if (days == 1) {
        return 'Active yesterday';
      }
      return 'Active $days days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
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
                  ? Text(user.fullName[0], style: const TextStyle(color: AppColors.primary)) 
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
                        color: AppColors.darkSurface,
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '@${user.username}',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    if (isFriend) ...[
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.isOnline ? 'Online' : _formatLastActive(user.lastActive),
                        style: TextStyle(
                          color: user.isOnline ? AppColors.success : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: user.isOnline ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (actionLabel != null)
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

  const _RequestListTile({required this.request, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  'wants to be friends',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAccept,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}
