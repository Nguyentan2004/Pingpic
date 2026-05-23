import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/dummy_data.dart';
import '../../core/utils/time_formatter.dart';
import '../../data/models/comment_model.dart';
import '../../data/repositories/photo_repository.dart';
import 'package:pingpic/l10n/app_localizations.dart';

class CommentsBottomSheet extends StatefulWidget {
  final DummyPhoto photo;

  const CommentsBottomSheet({super.key, required this.photo});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final PhotoRepository _photoRepo = PhotoRepository();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _activeFriendId;
  String? _activeFriendName;
  String? _activeFriendAvatar;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isOwner => _currentUserId == widget.photo.userId;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final l10n = AppLocalizations.of(context);
    return formatMomentTime(dateTime, l10n: l10n);
  }

  void _sendComment(String targetFriendId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    try {
      await _photoRepo.addComment(widget.photo.id, targetFriendId, text);
      // Wait a moment for layout build and scroll to bottom (index 0 for reverse list)
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.commentsSendFailed(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          // Header
          _buildHeader(),
          const Divider(color: Colors.white10, height: 1),

          // Body Content
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // If owner is in a specific friend's thread
    if (_isOwner && _activeFriendId != null) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () {
                setState(() {
                  _activeFriendId = null;
                  _activeFriendName = null;
                  _activeFriendAvatar = null;
                });
              },
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.darkSurface,
              backgroundImage: _activeFriendAvatar != null && _activeFriendAvatar!.isNotEmpty
                  ? NetworkImage(_activeFriendAvatar!)
                  : null,
              child: _activeFriendAvatar == null || _activeFriendAvatar!.isEmpty
                  ? Text(_activeFriendName?[0] ?? 'F', style: const TextStyle(color: Colors.white, fontSize: 12))
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              _activeFriendName ?? 'Friend',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Default header
    return Container(
      height: 56,
      alignment: Alignment.center,
      child: Text(
        _isOwner 
            ? AppLocalizations.of(context)!.commentsTitle 
            : AppLocalizations.of(context)!.commentsPrivateWith(widget.photo.senderName),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<CommentModel>>(
      stream: _photoRepo.getCommentsStream(widget.photo.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final comments = snapshot.data ?? [];

        // Scenario 1: Moment Owner seeing the Thread List
        if (_isOwner && _activeFriendId == null) {
          return _buildThreadList(comments);
        }

        // Scenario 2: Chat Conversation (Friend view, or Owner inside a thread)
        final targetFriendId = _isOwner ? _activeFriendId! : widget.photo.userId!;
        return _buildChatThread(comments, targetFriendId);
      },
    );
  }

  Widget _buildThreadList(List<CommentModel> comments) {
    // Group comments by otherUserId
    final Map<String, List<CommentModel>> threads = {};
    for (var comment in comments) {
      final otherUserId = comment.senderId == _currentUserId ? comment.receiverId : comment.senderId;
      if (otherUserId.isNotEmpty) {
        threads.putIfAbsent(otherUserId, () => []).add(comment);
      }
    }

    if (threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.commentsNoComments,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.commentsNoCommentsDesc,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: threads.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
      itemBuilder: (context, index) {
        final friendId = threads.keys.elementAt(index);
        final threadComments = threads[friendId]!;
        final lastComment = threadComments.last;

        // Resolve friend's name and avatar from comments sent by them
        String friendName = 'Friend';
        String friendAvatar = '';
        for (var c in threadComments) {
          if (c.senderId == friendId) {
            friendName = c.senderName;
            friendAvatar = c.senderAvatar;
            break;
          }
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.darkSurface,
            backgroundImage: friendAvatar.isNotEmpty ? NetworkImage(friendAvatar) : null,
            child: friendAvatar.isEmpty
                ? Text(friendName[0], style: const TextStyle(color: Colors.white))
                : null,
          ),
          title: Text(
            friendName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              lastComment.text,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(lastComment.createdAt),
                style: TextStyle(color: AppColors.textMuted.withOpacity(0.6), fontSize: 11),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
            ],
          ),
          onTap: () {
            setState(() {
              _activeFriendId = friendId;
              _activeFriendName = friendName;
              _activeFriendAvatar = friendAvatar;
            });
          },
        );
      },
    );
  }

  Widget _buildChatThread(List<CommentModel> comments, String targetFriendId) {
    // Filter comments for this conversation only
    final chatComments = comments.where((c) => 
      c.senderId == targetFriendId || c.receiverId == targetFriendId
    ).toList();

    // Sort descending for ListView.builder with reverse: true
    chatComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        // Message list
        Expanded(
          child: chatComments.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.commentsStartPrivate,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: chatComments.length,
                  itemBuilder: (context, index) {
                    final item = chatComments[index];
                    final isMe = item.senderId == _currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : AppColors.darkSurface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          border: isMe
                              ? null
                              : Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.text,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(item.createdAt),
                              style: TextStyle(
                                color: isMe ? Colors.white60 : AppColors.textMuted.withOpacity(0.6),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Input field
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkBackground,
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.commentsPrivateHint,
                        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendComment(targetFriendId),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendComment(targetFriendId),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
