import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/feed_provider.dart';
import '../../widgets/photo_card.dart';
import '../../widgets/camera_panel.dart';
import '../../widgets/friend_avatar.dart';
import '../../widgets/photo_skeleton_card.dart';
import '../../providers/friend_provider.dart';
// import '../../../core/network/signalr_service.dart'; // Đã xóa

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNavIndex = 0;
  final PageController _pageController = PageController();
  final FocusNode _feedFocusNode = FocusNode();

  // Responsive breakpoints
  static const double _kTabletBreakpoint = 900;
  static const double _kDesktopBreakpoint = 1200;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final feedProvider = context.read<FeedProvider>();
      feedProvider.fetchNewPhotos();
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
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width >= _kDesktopBreakpoint) {
            return _buildDesktopLayout();
          } else if (width >= _kTabletBreakpoint) {
            return _buildTabletLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // DESKTOP LAYOUT: Sidebar | Feed (center) | Camera Panel (right)
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: Icon-only sidebar
        AppSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (i) => setState(() => _selectedNavIndex = i),
        ),

        // Center: Feed column
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildTopBar(),
              _buildFriendStrip(),
              Expanded(child: _buildFeedList()),
            ],
          ),
        ),

        // Right: Camera panel
        Container(
          width: 340,
          padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
          child: const CameraPanel(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // TABLET LAYOUT: Feed (left, 60%) | Camera Panel (right, 40%)
  // No sidebar — top app bar instead
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildTopBar(showMenuIcon: true),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildFriendStrip(),
                    Expanded(child: _buildFeedList()),
                  ],
                ),
              ),
              Container(
                width: 300,
                padding: const EdgeInsets.fromLTRB(0, 12, 16, 16),
                child: const CameraPanel(),
              ),
            ],
          ),
        ),
        _buildBottomNavBar(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // MOBILE LAYOUT: Full feed, FAB for camera, bottom nav
  // Camera Panel opens as modal bottom sheet
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _buildTopBar(showMenuIcon: false),
      ),
      body: Column(
        children: [
          _buildFriendStrip(),
          Expanded(child: _buildFeedList()),
        ],
      ),
      floatingActionButton: _buildCameraFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildTopBar({bool showMenuIcon = false}) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          if (showMenuIcon)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () {},
            ),

          // App name + logo
          Row(
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
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          const Spacer(),

          // History button
          _IconBtn(
            icon: Icons.photo_library_rounded,
            onTap: () => context.push('/history'),
            tooltip: 'My History',
          ),
          const SizedBox(width: 4),
          // Search button
          _IconBtn(
            icon: Icons.search_rounded,
            onTap: () {},
            tooltip: 'Search friends',
          ),
          const SizedBox(width: 4),
          // Notification button with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              _IconBtn(
                icon: Icons.notifications_outlined,
                onTap: () {},
                tooltip: 'Notifications',
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendStrip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Friends Online',
                style: TextStyle(
                  color: Colors.white,
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
                      '${friendProvider.friends.length} friends',
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

  Widget _buildFeedList() {
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
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.darkCard,
            onRefresh: feedProvider.fetchNewPhotos,
          child: feedProvider.isLoading
              ? PageView.builder(
                  controller: PageController(),
                  scrollDirection: Axis.vertical,
                  itemCount: 3,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: PhotoSkeletonCard(),
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PhotoCard(
                        photo: photos[index],
                        index: index,
                      ),
                    );
                  },
                ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    const navItems = [
      (Icons.home_rounded, 'Home'),
      (Icons.group_rounded, 'Friends'),
      (Icons.notifications_rounded, 'Alerts'),
      (Icons.person_rounded, 'Profile'),
    ];

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (i) {
          final item = navItems[i];
          final isSelected = _selectedNavIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedNavIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.$1,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.primary : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
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

// ─── Small helper widgets ────────────────────────────────────────────────────

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered ? Colors.white.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.icon,
              color: _hovered ? Colors.white : AppColors.textMuted,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
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
