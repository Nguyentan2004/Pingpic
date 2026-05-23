import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/web_safe_image/web_safe_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/dummy_data.dart';
import '../../providers/history_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/history_photo_tile.dart';
import '../../widgets/history_skeleton_tile.dart';
import 'package:pingpic/l10n/app_localizations.dart';
import '../../../core/utils/time_formatter.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  // View mode: grid (true) hoặc list (false)
  bool _isGridView = true;

  // Số cột hiện tại (có thể thay đổi bằng slider)
  int _crossAxisCount = 3;

  // Filter đang chọn
  int _selectedFilter = 0;
  static const _filters = ['All', 'This Week', 'This Month'];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
        
    Future.microtask(() => context.read<HistoryProvider>().fetchHistoryPhotos());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  List<DummyHistoryPhoto> get _filteredPhotos {
    final now = DateTime.now();
    final allHistory = context.watch<HistoryProvider>().history;
    return switch (_selectedFilter) {
      1 => allHistory.where((p) {
          return now.difference(p.sentDate).inDays <= 7;
        }).toList(),
      2 => allHistory.where((p) {
          return now.difference(p.sentDate).inDays <= 30;
        }).toList(),
      _ => allHistory,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Tự động điều chỉnh cross-axis theo màn hình
            final autoColumns = constraints.maxWidth > 1200
                ? 4
                : constraints.maxWidth > 800
                    ? 3
                    : constraints.maxWidth > 500
                        ? 2
                        : 2;
            final columns = _isGridView ? (_crossAxisCount > 0 ? _crossAxisCount : autoColumns) : 1;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Sticky App Bar ───────────────────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HistoryAppBarDelegate(
                    isGridView: _isGridView,
                    crossAxisCount: _crossAxisCount,
                    selectedFilter: _selectedFilter,
                    totalCount: _filteredPhotos.length,
                    onBack: () => context.go('/home'),
                    onToggleView: () =>
                        setState(() => _isGridView = !_isGridView),
                    onFilterChanged: (i) {
                      setState(() => _selectedFilter = i);
                      _fadeCtrl.forward(from: 0);
                    },
                    onColumnsChanged: (v) =>
                        setState(() => _crossAxisCount = v),
                  ),
                ),

                // ── Stats bar ─────────────────────────────────────────────
                SliverToBoxAdapter(child: _buildStatsBar()),

                // ── Grid or List ─────────────────────────────────────────
                if (context.watch<HistoryProvider>().isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const HistorySkeletonTile(),
                        childCount: 9,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                    ),
                  )
                else if (_isGridView)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final photo = _filteredPhotos[index];
                          return HistoryPhotoTile(
                            photo: photo,
                            index: index,
                          );
                        },
                        childCount: _filteredPhotos.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final photo = _filteredPhotos[index];
                          return _HistoryListTile(
                            photo: photo,
                            index: index,
                          );
                        },
                        childCount: _filteredPhotos.length,
                      ),
                    ),
                  ),

                // ── Empty state ───────────────────────────────────────────
                if (_filteredPhotos.isEmpty)
                  const SliverFillRemaining(
                    child: _EmptyState(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    final photos = _filteredPhotos;
    final totalReactions =
        photos.fold<int>(0, (sum, p) => sum + p.reactionCount);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCard(
            icon: Icons.photo_rounded,
            value: '${photos.length}',
            label: 'Photos',
            color: AppColors.primary,
          ),
          _Divider(),
          _StatCard(
            icon: Icons.favorite_rounded,
            value: '$totalReactions',
            label: 'Reactions',
            color: const Color(0xFFFF6B8A),
          ),
          _Divider(),
          _StatCard(
            icon: Icons.group_rounded,
            value: '5',
            label: 'Friends',
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

// ── Sticky SliverPersistentHeader ─────────────────────────────────────────────
class _HistoryAppBarDelegate extends SliverPersistentHeaderDelegate {
  final bool isGridView;
  final int crossAxisCount;
  final int selectedFilter;
  final int totalCount;
  final VoidCallback onBack;
  final VoidCallback onToggleView;
  final ValueChanged<int> onFilterChanged;
  final ValueChanged<int> onColumnsChanged;

  const _HistoryAppBarDelegate({
    required this.isGridView,
    required this.crossAxisCount,
    required this.selectedFilter,
    required this.totalCount,
    required this.onBack,
    required this.onToggleView,
    required this.onFilterChanged,
    required this.onColumnsChanged,
  });

  @override
  double get minExtent => 112;
  @override
  double get maxExtent => 112;

  @override
  bool shouldRebuild(_HistoryAppBarDelegate old) =>
      old.isGridView != isGridView ||
      old.selectedFilter != selectedFilter ||
      old.crossAxisCount != crossAxisCount ||
      old.totalCount != totalCount;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.darkBackground,
      child: Column(
        children: [
          // ── Top row: back + title + actions ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
            child: Row(
              children: [
                // Back button
                _BackButton(onTap: onBack),
                const SizedBox(width: 8),

                // Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Moments',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '$totalCount photos sent',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Column count (only in grid view)
                if (isGridView) ...[
                  _ColumnToggle(
                    count: crossAxisCount,
                    onChange: onColumnsChanged,
                  ),
                  const SizedBox(width: 8),
                ],

                // Grid / List toggle
                _ViewToggleButton(
                  isGrid: isGridView,
                  onToggle: onToggleView,
                ),
              ],
            ),
          ),

          // ── Filter chips ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 10),
            child: SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _HistoryPageState._filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final selected = selectedFilter == i;
                  return GestureDetector(
                    onTap: () => onFilterChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryLight
                                ],
                              )
                            : null,
                        color: selected
                            ? null
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _HistoryPageState._filters[i],
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── List view tile (alternative view) ────────────────────────────────────────
class _HistoryListTile extends StatefulWidget {
  final DummyHistoryPhoto photo;
  final int index;

  const _HistoryListTile({required this.photo, required this.index});

  @override
  State<_HistoryListTile> createState() => _HistoryListTileState();
}

class _HistoryListTileState extends State<_HistoryListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.darkSurface
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: WebSafeImage(
                  imageUrl: widget.photo.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 160,
                  memCacheHeight: 160,
                  placeholder: (context, url) => Container(
                    color: AppColors.darkCard,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.darkCard,
                    child: Icon(Icons.broken_image_rounded,
                        color: AppColors.textMuted),
                  ),
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatMomentTime(widget.photo.sentDate, l10n: AppLocalizations.of(context)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.photo.caption != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.photo.caption!,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.group_rounded,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.photo.recipientCount} friends',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.favorite_rounded,
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.photo.reactionCount}',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: _hovered
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small helper widgets ───────────────────────────────────────────────────────
class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _hovered ? AppColors.primary : Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  color: _hovered ? AppColors.primary : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewToggleButton extends StatefulWidget {
  final bool isGrid;
  final VoidCallback onToggle;
  const _ViewToggleButton({required this.isGrid, required this.onToggle});

  @override
  State<_ViewToggleButton> createState() => _ViewToggleButtonState();
}

class _ViewToggleButtonState extends State<_ViewToggleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.isGrid ? 'Switch to list view' : 'Switch to grid view',
        child: GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.isGrid
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
              color: _hovered ? Colors.white : AppColors.textMuted,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnToggle extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChange;

  const _ColumnToggle({required this.count, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [2, 3, 4].map((c) {
          final selected = count == c;
          return GestureDetector(
            onTap: () => onChange(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$c',
                  style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              color: AppColors.textMuted,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No photos yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Photos you send will appear here.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
