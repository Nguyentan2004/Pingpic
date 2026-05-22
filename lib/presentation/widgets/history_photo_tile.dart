import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/dummy_data.dart';
import '../../../app.dart';
import '../providers/history_provider.dart';

/// Grid tile cho một ảnh lịch sử.
/// Khi hover: xuất hiện overlay mờ + ngày giờ + caption + stats.
/// Khi click: mở detail dialog.
class HistoryPhotoTile extends StatefulWidget {
  final DummyHistoryPhoto photo;
  final int index;

  const HistoryPhotoTile({
    super.key,
    required this.photo,
    required this.index,
  });

  @override
  State<HistoryPhotoTile> createState() => _HistoryPhotoTileState();
}

class _HistoryPhotoTileState extends State<HistoryPhotoTile>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _ctrl;
  late Animation<double> _overlayOpacity;
  late Animation<double> _contentSlide;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _overlayOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onHover(bool hovered) {
    setState(() => _isHovered = hovered);
    hovered ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showDetailDialog(context),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.3),
                      blurRadius: _isHovered ? 24 : 10,
                      offset: const Offset(0, 4),
                      spreadRadius: _isHovered ? 1 : 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ── Ảnh nền ─────────────────────────────────
                      _buildImage(),

                      // ── Hover overlay ────────────────────────────
                      FadeTransition(
                        opacity: _overlayOpacity,
                        child: _buildOverlay(),
                      ),

                      // ── Reaction badge (luôn hiện) ───────────────
                      if (widget.photo.reactionCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _buildReactionBadge(),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.photo.imageBytes != null) {
      return Image.memory(
        widget.photo.imageBytes!,
        fit: BoxFit.cover,
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.photo.imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: 350,
      placeholder: (context, url) => Container(
        color: AppColors.darkCard,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.darkCard,
        child: Icon(
          Icons.broken_image_rounded,
          color: AppColors.textMuted,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slide-up animation cho content
            Transform.translate(
              offset: Offset(0, _contentSlide.value),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Date & time ──────────────────────────
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.photo.sentAt,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // ── Caption ──────────────────────────────
                  if (widget.photo.caption != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      widget.photo.caption!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // ── Stats row ─────────────────────────────
                  Row(
                    children: [
                      _StatPill(
                        icon: Icons.group_rounded,
                        label: '${widget.photo.recipientCount}',
                      ),
                      const SizedBox(width: 6),
                      if (widget.photo.reactionCount > 0)
                        _StatPill(
                          icon: Icons.favorite_rounded,
                          label: '${widget.photo.reactionCount}',
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionBadge() {
    return AnimatedOpacity(
      opacity: _isHovered ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: AppColors.primary,
              size: 11,
            ),
            const SizedBox(width: 3),
            Text(
              '${widget.photo.reactionCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => _PhotoDetailDialog(photo: widget.photo),
    );
  }
}

// ── Stat pill label ───────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo detail dialog ───────────────────────────────────────────────────────
class _PhotoDetailDialog extends StatefulWidget {
  final DummyHistoryPhoto photo;

  const _PhotoDetailDialog({required this.photo});

  @override
  State<_PhotoDetailDialog> createState() => _PhotoDetailDialogState();
}

class _PhotoDetailDialogState extends State<_PhotoDetailDialog> {
  bool _isDeleting = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Xóa ảnh', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn có chắc chắn muốn xóa khoảnh khắc này không?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Đóng confirm dialog
              
              setState(() {
                _isDeleting = true;
              });

              try {
                await context.read<HistoryProvider>().deleteMoment(widget.photo.id);
                if (mounted) {
                  Navigator.pop(context); // Đóng Detail Dialog
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa ảnh'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isDeleting = false;
                  });
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
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
              color: Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image (Left) ─────────────────────────────────────────
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(28)),
                  child: photo.imageBytes != null
                      ? Image.memory(
                          photo.imageBytes!,
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: photo.imageUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 800,
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
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: AppColors.textMuted,
                              size: 48,
                            ),
                          ),
                        ),
                ),
              ),

              // ── Details (Right) ───────────────────────────────────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top-aligned Date row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
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
                                  const Text(
                                    'Sent on',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    widget.photo.sentAt,
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
                          if (_isDeleting)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () => _confirmDelete(context),
                              tooltip: 'Xóa ảnh',
                            ),
                        ],
                      ),

                      if (widget.photo.caption != null) ...[
                        const SizedBox(height: 18),
                        Text(
                          widget.photo.caption!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 15,
                          ),
                        ),
                      ],

                      // Spacer đẩy Stats và Nút Close xuống bottom
                      const Spacer(),

                      // Bottom-aligned Stats row
                      Row(
                        children: [
                          _DetailStat(
                            icon: Icons.group_rounded,
                            value: '${widget.photo.recipientCount}',
                            label: 'friends',
                          ),
                          const SizedBox(width: 16),
                          _DetailStat(
                            icon: Icons.favorite_rounded,
                            value: '${widget.photo.reactionCount}',
                            label: 'reactions',
                            iconColor: AppColors.primary,
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
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _DetailStat({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              TextSpan(
                text: ' $label',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
