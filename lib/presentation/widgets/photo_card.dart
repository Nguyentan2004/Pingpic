import 'package:flutter/material.dart';
import 'dart:ui';
import 'web_safe_image/web_safe_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/dummy_data.dart';
import '../../core/utils/time_formatter.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../providers/feed_provider.dart';
import '../../app.dart';
import '../../data/repositories/photo_repository.dart';
import '../../data/models/comment_model.dart';
import 'package:pingpic/l10n/app_localizations.dart';


/// Widget hiển thị một item trong feed ảnh
class PhotoCard extends StatefulWidget {
  final DummyPhoto photo;
  final int index;

  const PhotoCard({
    super.key,
    required this.photo,
    required this.index,
  });

  @override
  State<PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<PhotoCard>
    with SingleTickerProviderStateMixin {
  final PhotoRepository _photoRepo = PhotoRepository();
  bool _isHovered = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  bool _isReplyExpanded = false;
  String? _selectedFriendId;
  final FocusNode _replyFocusNode = FocusNode();
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    _replyFocusNode.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _toggleLike(bool isLiked) {
    _heartController.forward().then((_) => _heartController.reverse());
    final currentUserId = context.read<AuthProvider>().userId;
    if (currentUserId != null) {
      context.read<FeedProvider>().toggleLike(widget.photo.id, isLiked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().userId;
    final isLiked = widget.photo.likes.contains(currentUserId);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.primary.withOpacity(0.3)
                    : Colors.black.withOpacity(0.25),
                blurRadius: _isHovered ? 32 : 20,
                offset: const Offset(0, 8),
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              color: AppColors.darkCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header: Avatar + Name + Time ──────────────
                  _buildHeader(),

                  // ── Image Area (Expanded to fill remaining height) ──
                  Expanded(
                    child: Stack(
                      children: [
                        // ── Ảnh nền ──────────────────────────────────
                        Positioned.fill(
                          child: widget.photo.imageBytes != null 
                            ? Image.memory(
                                widget.photo.imageBytes!,
                                fit: BoxFit.cover,
                              )
                            : WebSafeImage(
                                imageUrl: widget.photo.imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 600,
                                placeholder: (context, url) => _buildImageSkeleton(),
                                errorWidget: (context, url, error) => _buildImageError(),
                              ),
                        ),

                        // ── Gradient overlay ──────────────────────────
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.15),
                                  Colors.black.withOpacity(0.7),
                                ],
                                stops: const [0.0, 0.45, 0.65, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // ── Double-tap heart animation ────────────────
                        Positioned.fill(
                          child: GestureDetector(
                            onDoubleTap: () => _toggleLike(isLiked),
                            child: const ColoredBox(color: Colors.transparent),
                          ),
                        ),

                        // ── Quick Reply Overlay ───────────────────────
                        _buildQuickReplyOverlay(currentUserId),

                        // ── Footer: Caption + Reactions ───────────────
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _buildFooter(isLiked),
                        ),
                      ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.darkCard,
              child: widget.photo.senderAvatar.isNotEmpty && !widget.photo.senderAvatar.contains('pravatar.cc')
                  ? ClipOval(
                      child: WebSafeImage(
                        imageUrl: widget.photo.senderAvatar,
                        fit: BoxFit.cover,
                        memCacheWidth: 100,
                        memCacheHeight: 100,
                        placeholder: (context, url) => Container(
                          color: AppColors.darkCard,
                          padding: const EdgeInsets.all(6),
                          child: const CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.person, size: 22, color: Colors.white70),
                      ),
                    )
                  : const Icon(Icons.person, size: 22, color: Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          // Name + Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.photo.senderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.photo.createdAt != null
                      ? formatMomentTime(widget.photo.createdAt!, l10n: AppLocalizations.of(context))
                      : widget.photo.timeAgo,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // More options button
          _buildMoreOptions(context),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isLiked) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expanded switcher for caption/like vs quick input bar
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    axisAlignment: -1.0,
                    child: child,
                  ),
                );
              },
              child: _isReplyExpanded
                  ? _buildInputBar(context)
                  : Row(
                      key: const ValueKey('normal_footer_row'),
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Caption
                        Expanded(
                          child: widget.photo.caption != null && widget.photo.caption!.isNotEmpty
                              ? Text(
                                  widget.photo.caption!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 12),
                        // Like button
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _toggleLike(isLiked),
                              child: AnimatedBuilder(
                                animation: _heartScale,
                                builder: (_, __) => Transform.scale(
                                  scale: _heartScale.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isLiked
                                          ? AppColors.primary.withOpacity(0.9)
                                          : Colors.black38,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.photo.reactionCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(width: 16),

          // Comment toggle button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isReplyExpanded = !_isReplyExpanded;
                    if (_isReplyExpanded) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _replyFocusNode.requestFocus();
                      });
                    } else {
                      _replyFocusNode.unfocus();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isReplyExpanded ? AppColors.primary : Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isReplyExpanded ? Icons.close_rounded : Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              if (!_isReplyExpanded) ...[
                const SizedBox(height: 4),
                StreamBuilder<List<CommentModel>>(
                  stream: _photoRepo.getCommentsStream(widget.photo.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return ClipRRect(
      key: const ValueKey('input_bar'),
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          padding: const EdgeInsets.only(left: 16, right: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  focusNode: _replyFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.commentsPrivateHint,
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendQuickReply(context),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
                onPressed: () => _sendQuickReply(context),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReplyOverlay(String? currentUserId) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: _isReplyExpanded ? 80 : -220,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _isReplyExpanded ? 1.0 : 0.0,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: _buildChatPanelContent(currentUserId),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanelContent(String? currentUserId) {
    if (currentUserId == null) return const SizedBox.shrink();

    final isOwner = currentUserId == widget.photo.userId;

    return StreamBuilder<List<CommentModel>>(
      stream: _photoRepo.getCommentsStream(widget.photo.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          );
        }

        final comments = snapshot.data ?? [];

        if (isOwner) {
          // Group by friend
          final Map<String, List<CommentModel>> threads = {};
          for (var c in comments) {
            final otherUserId = c.senderId == currentUserId ? c.receiverId : c.senderId;
            if (otherUserId.isNotEmpty) {
              threads.putIfAbsent(otherUserId, () => []).add(c);
            }
          }

          if (threads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)!.commentsNoComments,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            );
          }

          // Set default selected friend if none selected
          if (_selectedFriendId == null || !threads.containsKey(_selectedFriendId)) {
            String? newestFriendId;
            DateTime? newestTime;
            threads.forEach((friendId, friendComments) {
              final lastCommentTime = friendComments.last.createdAt;
              if (newestTime == null || lastCommentTime.isAfter(newestTime!)) {
                newestTime = lastCommentTime;
                newestFriendId = friendId;
              }
            });
            _selectedFriendId = newestFriendId;
          }

          final activeComments = _selectedFriendId != null ? threads[_selectedFriendId] ?? [] : <CommentModel>[];
          final sortedActiveComments = List<CommentModel>.from(activeComments)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Column(
            children: [
              // Friends selection list
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: threads.length,
                  itemBuilder: (context, idx) {
                    final friendId = threads.keys.elementAt(idx);
                    final friendComments = threads[friendId]!;
                    
                    // Resolve friend details
                    String friendName = 'Friend';
                    String friendAvatar = '';
                    for (var c in friendComments) {
                      if (c.senderId == friendId) {
                        friendName = c.senderName;
                        friendAvatar = c.senderAvatar;
                        break;
                      }
                    }

                    final isSelected = friendId == _selectedFriendId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFriendId = friendId;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.darkSurface,
                          backgroundImage: friendAvatar.isNotEmpty && !friendAvatar.contains('pravatar.cc')
                              ? NetworkImage(friendAvatar)
                              : null,
                          child: friendAvatar.isEmpty || friendAvatar.contains('pravatar.cc')
                              ? Text(friendName.isNotEmpty ? friendName[0] : 'F', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Message bubbles
              Expanded(
                child: _buildMessagesList(sortedActiveComments, currentUserId),
              ),
            ],
          );
        } else {
          // Friend view
          final sortedComments = List<CommentModel>.from(comments)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return _buildMessagesList(sortedComments, currentUserId);
        }
      },
    );
  }

  Widget _buildMessagesList(List<CommentModel> messages, String currentUserId) {
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            AppLocalizations.of(context)!.commentsNoCommentsDesc,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMe = msg.senderId == currentUserId;

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary.withOpacity(0.85) : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isMe ? 12 : 3),
                bottomRight: Radius.circular(isMe ? 3 : 12),
              ),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.text,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMomentTime(msg.createdAt, l10n: AppLocalizations.of(context)),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.white54,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendQuickReply(BuildContext context) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = context.read<AuthProvider>().userId;
    if (currentUserId == null) return;

    final isOwner = currentUserId == widget.photo.userId;
    final receiverId = isOwner ? _selectedFriendId : widget.photo.userId;

    final l10n = AppLocalizations.of(context)!;
    if (receiverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.commentReceiverNotFound),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _replyController.clear();
    try {
      await _photoRepo.addComment(widget.photo.id, receiverId, text);
      setState(() {
        _isReplyExpanded = false;
        _replyFocusNode.unfocus();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.commentSendFailed(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildImageSkeleton() {
    return Container(
      color: AppColors.darkCard,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary.withOpacity(0.5),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: AppColors.darkCard,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_rounded,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.errLoadImage,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMoreOptions(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.darkSurface.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          elevation: 8,
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: AppLocalizations.of(context)!.tooltipOptions,
        onSelected: (value) => _handleMenuAction(context, value),
        itemBuilder: (BuildContext context) {
          final l10n = AppLocalizations.of(context)!;
          final currentUserId = context.read<AuthProvider>().userId;
          final isOwnMoment = widget.photo.userId == currentUserId;
          if (isOwnMoment) {
            return [
              PopupMenuItem<String>(
                value: 'details',
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      l10n.menuDetails,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      l10n.menuDelete,
                      style: const TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ];
          } else {
            return [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      l10n.menuProfile,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ];
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(10),
          child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    if (action == 'details') {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.8),
        builder: (_) => _FeedPhotoDetailDialog(photo: widget.photo),
      );
    } else if (action == 'delete') {
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(l10n.deleteMomentTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            l10n.deleteMomentConfirm,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.settingsCancel, style: const TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx); // Close confirmation dialog
                
                scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Text(l10n.deleteMomentLoading),
                      ],
                    ),
                    backgroundColor: AppColors.darkCard,
                    duration: const Duration(days: 1),
                  ),
                );

                try {
                  await context.read<HistoryProvider>().deleteMoment(widget.photo.id);
                  scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text(l10n.deleteMomentSuccess),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text(l10n.deleteMomentFailed(e.toString())),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(l10n.delete, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (action == 'profile') {
      if (widget.photo.userId != null) {
        context.push('/profile?userId=${widget.photo.userId}');
      }
    }
  }
}

class _FeedPhotoDetailDialog extends StatefulWidget {
  final DummyPhoto photo;

  const _FeedPhotoDetailDialog({required this.photo});

  @override
  State<_FeedPhotoDetailDialog> createState() => _FeedPhotoDetailDialogState();
}

class _FeedPhotoDetailDialogState extends State<_FeedPhotoDetailDialog> {
  bool _isDeleting = false;

  void _confirmDelete(BuildContext context) {
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.deleteMomentTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          l10n.deleteMomentConfirm,
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.settingsCancel, style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation dialog
              
              setState(() {
                _isDeleting = true;
              });

              try {
                await context.read<HistoryProvider>().deleteMoment(widget.photo.id);
                if (mounted) {
                  navigator.pop(); // Close Detail Dialog
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text(l10n.deleteMomentSuccess),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isDeleting = false;
                  });
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text(l10n.deleteMomentFailed(e.toString())),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch FeedProvider to get the latest updated photo dynamically
    final feedPhotos = context.watch<FeedProvider>().photos;
    final photo = feedPhotos.firstWhere(
      (p) => p.id == widget.photo.id,
      orElse: () => widget.photo,
    );
    final currentUserId = context.read<AuthProvider>().userId;
    final isOwnMoment = photo.userId == currentUserId;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 500),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useVerticalLayout = constraints.maxWidth < 600;

              final imageWidget = ClipRRect(
                borderRadius: useVerticalLayout
                    ? const BorderRadius.vertical(top: Radius.circular(28))
                    : const BorderRadius.horizontal(left: Radius.circular(28)),
                child: photo.imageBytes != null
                    ? Image.memory(
                        photo.imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : WebSafeImage(
                        imageUrl: photo.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: AppColors.darkCard,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.darkCard,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.textMuted,
                            size: 48,
                          ),
                        ),
                      ),
              );

              final detailsWidget = Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date & Delete action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.detailSentOn,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  photo.createdAt != null
                                      ? formatMomentTime(photo.createdAt!, l10n: AppLocalizations.of(context))
                                      : photo.timeAgo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (isOwnMoment)
                          _isDeleting
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                  onPressed: () => _confirmDelete(context),
                                  tooltip: AppLocalizations.of(context)!.deleteMomentTooltip,
                                ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Sender info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.darkCard,
                          backgroundImage: photo.senderAvatar.isNotEmpty && !photo.senderAvatar.contains('pravatar.cc')
                              ? NetworkImage(photo.senderAvatar)
                              : null,
                          child: photo.senderAvatar.isEmpty || photo.senderAvatar.contains('pravatar.cc')
                              ? const Icon(Icons.person, size: 16, color: Colors.white70)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          photo.senderName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    if (photo.caption != null && photo.caption!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        photo.caption!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 15,
                        ),
                      ),
                    ],

                    if (useVerticalLayout)
                      const SizedBox(height: 32)
                    else
                      const Spacer(),

                    // Reaction count
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.detailReactionsCount(photo.reactionCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.15),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(AppLocalizations.of(context)!.detailClose),
                      ),
                    ),
                  ],
                ),
              );

              if (useVerticalLayout) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: imageWidget,
                      ),
                      detailsWidget,
                    ],
                  ),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: imageWidget,
                  ),
                  Expanded(
                    flex: 4,
                    child: detailsWidget,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
