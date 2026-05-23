import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/web_safe_image/web_safe_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/history_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/dummy_data.dart';
import '../../../core/utils/time_formatter.dart';
import 'package:pingpic/l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loadingOtherUser = false;
  String? _otherFullName;
  String? _otherUsername;
  String? _otherAvatarUrl;
  String? _otherBio;
  int _otherFriendsCount = 0;
  List<DummyHistoryPhoto> _otherMoments = [];

  String? _relationshipId;
  String? _relationshipStatus;
  String? _relationshipRequesterId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final currentUserId = context.read<AuthProvider>().userId;
      if (widget.userId != null && widget.userId != currentUserId) {
        _loadOtherUserData();
      } else {
        context.read<HistoryProvider>().fetchHistoryPhotos();
        context.read<FriendProvider>().fetchFriendsData();
      }
    });
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      final currentUserId = context.read<AuthProvider>().userId;
      if (widget.userId != null && widget.userId != currentUserId) {
        _loadOtherUserData();
      } else {
        // Reset other user details to display own profile
        setState(() {
          _otherFullName = null;
          _otherUsername = null;
          _otherAvatarUrl = null;
          _otherBio = null;
          _otherFriendsCount = 0;
          _otherMoments = [];
          _relationshipId = null;
          _relationshipStatus = null;
          _relationshipRequesterId = null;
        });
        context.read<HistoryProvider>().fetchHistoryPhotos();
        context.read<FriendProvider>().fetchFriendsData();
      }
    }
  }

  Future<void> _loadOtherUserData() async {
    setState(() {
      _loadingOtherUser = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _otherFullName = data['fullName'];
        _otherUsername = data['username'];
        _otherAvatarUrl = data['avatarUrl'];
        _otherBio = data['bio'];
      }

      // Fetch relationship status
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null && widget.userId != null) {
        try {
          final relQuery = await FirebaseFirestore.instance.collection('friendships')
              .where(Filter.or(
                Filter.and(Filter('requesterId', isEqualTo: currentUserId), Filter('receiverId', isEqualTo: widget.userId)),
                Filter.and(Filter('requesterId', isEqualTo: widget.userId), Filter('receiverId', isEqualTo: currentUserId))
              ))
              .get();
          if (relQuery.docs.isNotEmpty) {
            final relData = relQuery.docs.first.data();
            _relationshipId = relQuery.docs.first.id;
            _relationshipStatus = relData['status'];
            _relationshipRequesterId = relData['requesterId'];
          } else {
            _relationshipId = null;
            _relationshipStatus = null;
            _relationshipRequesterId = null;
          }
        } catch (relError) {
          debugPrint('PROFILE_DEBUG: Error loading relationship status: $relError');
          _relationshipId = null;
          _relationshipStatus = null;
          _relationshipRequesterId = null;
        }
      }

      // Fetch friends count
      try {
        final reqQuery = await FirebaseFirestore.instance.collection('friendships')
            .where('status', isEqualTo: 'accepted')
            .where('requesterId', isEqualTo: widget.userId)
            .get();
        final recQuery = await FirebaseFirestore.instance.collection('friendships')
            .where('status', isEqualTo: 'accepted')
            .where('receiverId', isEqualTo: widget.userId)
            .get();
        _otherFriendsCount = reqQuery.docs.length + recQuery.docs.length;
      } catch (friendshipError) {
        debugPrint('PROFILE_DEBUG: Error loading other user friendship count: $friendshipError');
        _otherFriendsCount = 0;
      }
    } catch (e) {
      debugPrint('PROFILE_DEBUG: Error loading other user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingOtherUser = false;
        });
      }
    }
  }

  Widget _buildFriendshipActionButton(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (widget.userId == null || widget.userId == currentUserId) {
      return const SizedBox.shrink();
    }

    final friendsProvider = context.watch<FriendProvider>();

    if (_relationshipStatus == 'accepted') {
      return OutlinedButton.icon(
        icon: const Icon(Icons.person_remove_rounded, size: 16),
        label: Text(AppLocalizations.of(context)!.unfriendButton),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onPressed: () async {
          final success = await friendsProvider.removeFriend(widget.userId!);
          if (success) {
            _loadOtherUserData(); // reload status
          }
        },
      );
    } else if (_relationshipStatus == 'pending') {
      if (_relationshipRequesterId == currentUserId) {
        return ElevatedButton.icon(
          icon: const Icon(Icons.hourglass_empty_rounded, size: 16),
          label: Text(AppLocalizations.of(context)!.friendRequested),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white12,
            foregroundColor: Colors.white70,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: null, // disabled
        );
      } else {
        return ElevatedButton.icon(
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: Text(AppLocalizations.of(context)!.friendAcceptRequest),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: () async {
            if (_relationshipId != null) {
              final success = await friendsProvider.acceptRequest(_relationshipId!);
              if (success) {
                _loadOtherUserData(); // reload status
              }
            }
          },
        );
      }
    } else {
      return ElevatedButton.icon(
        icon: const Icon(Icons.person_add_rounded, size: 16),
        label: Text(AppLocalizations.of(context)!.addFriendButton),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onPressed: () async {
          final success = await friendsProvider.sendRequest(widget.userId!);
          if (success) {
            _loadOtherUserData(); // reload status
          }
        },
      );
    }
  }

  Widget _buildPrivateProfileUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: AppColors.primary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.profilePrivateDesc,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.profilePrivateSub,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().userId;
    final isOtherUser = widget.userId != null && widget.userId != currentUserId;

    if (isOtherUser) {
      if (_loadingOtherUser) {
        return const Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final avatarUrl = _otherAvatarUrl;
      final fullName = _otherFullName ?? '';
      final username = _otherUsername ?? '';
      final bio = _otherBio ?? '';
      final friendsCount = _otherFriendsCount;
      final momentsCount = _otherMoments.length;

      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text('@$username', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header Card ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // User Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: AppColors.darkCard,
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(fullName.isNotEmpty ? fullName[0] : '?', style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 24),
                      
                      // User Stats
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(AppLocalizations.of(context)!.profileMomentsCount, '$momentsCount'),
                            _buildStatItem(AppLocalizations.of(context)!.profileFriendsCount, '$friendsCount'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // User Info Details
                  Text(
                    fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: TextStyle(color: AppColors.primary.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      bio,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildFriendshipActionButton(context),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1, thickness: 1),

            // ── Moments Grid Section Header ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.grid_on_rounded, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.profileMomentsGrid,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),

            // ── Moments Grid / Private State ────────────────────────
            Expanded(
              child: _relationshipStatus != 'accepted'
                  ? _buildPrivateProfileUI()
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('moments')
                          .where('userId', isEqualTo: widget.userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                        }
                        
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        final list = docs.map((doc) {
                          final data = doc.data();
                          final Timestamp? timestamp = data['createdAt'];
                          final DateTime sentDate = timestamp?.toDate() ?? DateTime.now();
                          final l10n = AppLocalizations.of(context);

                          return DummyHistoryPhoto(
                            id: doc.id,
                            imageUrl: data['imageUrl'] ?? '',
                            sentAt: formatMomentTime(sentDate, l10n: l10n),
                            sentDate: sentDate,
                            caption: data['caption'],
                            recipientCount: 0,
                            reactionCount: data['reactionCount'] ?? 0,
                          );
                        }).toList();

                        list.sort((a, b) => b.sentDate.compareTo(a.sentDate));

                        // Store in _otherMoments so statistics row displays correct count
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _otherMoments.length != list.length) {
                            setState(() {
                              _otherMoments = list;
                            });
                          }
                        });

                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final moment = list[index];
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.darkCard,
                                border: Border.all(color: Colors.white.withOpacity(0.04)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: WebSafeImage(
                                      imageUrl: moment.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: AppColors.darkCard),
                                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white30),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => context.push(
                                          '/profile/moments'
                                          '?userId=${widget.userId}'
                                          '&senderName=${Uri.encodeComponent(_otherFullName ?? "")}'
                                          '&senderAvatar=${Uri.encodeComponent(_otherAvatarUrl ?? "")}'
                                          '&initialIndex=$index'
                                          '&momentId=${moment.id}',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.profileTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            tooltip: AppLocalizations.of(context)!.settingsTitle,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Consumer3<AuthProvider, FriendProvider, HistoryProvider>(
        builder: (context, auth, friends, history, child) {
          final avatarUrl = auth.avatarUrl;
          final fullName = auth.fullName ?? '';
          final username = auth.username ?? '';
          final bio = auth.bio ?? '';
          final friendsCount = friends.friends.length;
          final momentsCount = history.history.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Header Card ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // User Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.5),
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: AppColors.darkCard,
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(fullName.isNotEmpty ? fullName[0] : '?', style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 24),
                        
                        // User Stats
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(AppLocalizations.of(context)!.profileMomentsCount, '$momentsCount'),
                              _buildStatItem(AppLocalizations.of(context)!.profileFriendsCount, '$friendsCount'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // User Info Details
                    Text(
                      fullName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$username',
                      style: TextStyle(color: AppColors.primary.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        bio,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(color: Colors.white10, height: 1, thickness: 1),

              // ── Moments Grid Section Header ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.grid_on_rounded, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.profileMomentsGrid,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),

              // ── Moments Grid ────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await history.fetchHistoryPhotos();
                    await friends.fetchFriendsData();
                  },
                  child: history.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : history.history.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemCount: history.history.length,
                              itemBuilder: (context, index) {
                                final moment = history.history[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.darkCard,
                                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: WebSafeImage(
                                          imageUrl: moment.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(color: AppColors.darkCard),
                                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white30),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => context.push(
                                              '/profile/moments'
                                              '?userId=${auth.userId}'
                                              '&senderName=${Uri.encodeComponent(fullName)}'
                                              '&senderAvatar=${Uri.encodeComponent(avatarUrl ?? "")}'
                                              '&initialIndex=$index'
                                              '&momentId=${moment.id}',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.profileNoMoments,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.profileNoMomentsDesc,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
