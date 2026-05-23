import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'package:pingpic/l10n/app_localizations.dart';
import '../../providers/feed_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/photo_card.dart';
import '../../widgets/friend_avatar.dart';
import '../../widgets/photo_skeleton_card.dart';
import '../../providers/friend_provider.dart';
import '../../providers/auth_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  final FocusNode _feedFocusNode = FocusNode();
  bool _isPageAnimating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<FeedProvider>().fetchNewPhotos();
      context.read<FriendProvider>().fetchFriendsData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _feedFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Consumer2<FriendProvider, AuthProvider>(
      builder: (context, friendProvider, authProvider, child) {
        if (friendProvider.isLoading) {
          return Scaffold(
            backgroundColor: scaffoldBg,
            body: Column(
              children: [
                _buildFriendStripSkeleton(isDark, l10n),
                Expanded(child: _buildFeedListSkeleton()),
              ],
            ),
          );
        }

        if (friendProvider.friends.isEmpty) {
          return Scaffold(
            backgroundColor: scaffoldBg,
            body: _buildInviteState(authProvider, isDark, l10n),
          );
        }

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: Column(
            children: [
              _buildFriendStrip(isDark, l10n),
              Expanded(child: _buildFeedList(isDark, l10n)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendStrip(bool isDark, AppLocalizations l10n) {
    final textColor = isDark ? Colors.white : AppColors.textDark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.friendsOnline,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Consumer<FriendProvider>(
                builder: (context, friendProvider, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.friendsCount(friendProvider.friends.length),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const FriendStripWidget(),
        ],
      ),
    );
  }

  Widget _buildFeedList(bool isDark, AppLocalizations l10n) {
    final isResponsive = MediaQuery.of(context).size.width >= 900;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    return Consumer<FeedProvider>(
      builder: (context, feedProvider, child) {
        final photos = feedProvider.photos;
        
        return Focus(
          focusNode: _feedFocusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                final dy = pointerSignal.scrollDelta.dy;
                if (dy != 0 && !_isPageAnimating) {
                  final targetPage = dy > 0 
                      ? (_pageController.page ?? 0).round() + 1 
                      : (_pageController.page ?? 0).round() - 1;
                  
                  if (targetPage >= 0 && targetPage < photos.length) {
                    _isPageAnimating = true;
                    _pageController.animateToPage(
                      targetPage,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    ).then((_) {
                      _isPageAnimating = false;
                    });
                  }
                }
              }
            },
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: cardBg,
              onRefresh: feedProvider.fetchNewPhotos,
              child: feedProvider.isLoading
                  ? PageView.builder(
                      controller: PageController(),
                      scrollDirection: Axis.vertical,
                      physics: kIsWeb 
                          ? const NeverScrollableScrollPhysics() 
                          : const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        final card = const PhotoSkeletonCard();
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: isResponsive
                              ? Center(child: AspectRatio(aspectRatio: 3 / 4, child: card))
                              : card,
                        );
                      },
                    )
                  : photos.isEmpty
                      ? _buildEmptyState(isDark, l10n)
                      : PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          physics: kIsWeb 
                              ? const NeverScrollableScrollPhysics() 
                              : const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: photos.length,
                          itemBuilder: (context, index) {
                            final card = PhotoCard(
                              photo: photos[index],
                              index: index,
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: isResponsive
                                  ? Center(child: AspectRatio(aspectRatio: 3 / 4, child: card))
                                  : card,
                            );
                          },
                        ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subtextColor = isDark ? AppColors.textMuted : AppColors.textLight;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: subtextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.profileNoMoments,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profileNoMomentsDesc,
            style: TextStyle(
              color: subtextColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendStripSkeleton(bool isDark, AppLocalizations l10n) {
    final textColor = isDark ? Colors.white : AppColors.textDark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.friendsOnline,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              padding: const EdgeInsets.symmetric(vertical: 8),
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 32,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedListSkeleton() {
    final isResponsive = MediaQuery.of(context).size.width >= 900;
    return PageView.builder(
      controller: PageController(),
      scrollDirection: Axis.vertical,
      physics: kIsWeb ? const NeverScrollableScrollPhysics() : null,
      itemCount: 3,
      itemBuilder: (context, index) {
        final card = const PhotoSkeletonCard();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: isResponsive
              ? Center(child: AspectRatio(aspectRatio: 3 / 4, child: card))
              : card,
        );
      },
    );
  }

  Widget _buildInviteState(AuthProvider authProvider, bool isDark, AppLocalizations l10n) {
    final inviteCode = authProvider.shareCode ?? '------';
    final domain = kIsWeb ? Uri.base.origin : 'https://pingpic.web.app';
    final inviteLink = '$domain/invite?code=$inviteCode';

    final cardBg = isDark ? AppColors.darkSurface.withOpacity(0.6) : Colors.white;
    final textCol = isDark ? Colors.white : AppColors.textDark;
    final subtextCol = isDark ? AppColors.textMuted : AppColors.textLight;
    final inputBg = isDark ? AppColors.darkCard : Colors.grey[50]!;
    final borderCol = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderCol, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l10n.inviteTitle,
                style: TextStyle(
                  color: textCol,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.inviteDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subtextCol,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: isDark ? Colors.white10 : AppColors.black10),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.inviteYourCode,
                    style: TextStyle(
                      color: subtextCol,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            inviteCode.split('').join(' '),
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                            tooltip: 'Copy Code',
                            onPressed: () => _copyToClipboard(
                              context,
                              inviteCode,
                              l10n.inviteCodeCopied,
                              isDark,
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.inviteShareLink,
                    style: TextStyle(
                      color: subtextCol,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            inviteLink,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textCol.withOpacity(0.7),
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: const Icon(Icons.share_rounded, color: AppColors.primary, size: 20),
                            tooltip: 'Copy Link',
                            onPressed: () => _copyToClipboard(
                              context,
                              inviteLink,
                              l10n.inviteLinkCopied,
                              isDark,
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/friends');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: AppColors.primary.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_add_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          l10n.addFriendButton,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message, bool isDark) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
