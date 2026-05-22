import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/dummy_data.dart';

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
  bool _isHovered = false;
  bool _isLiked = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

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
    super.dispose();
  }

  void _toggleLike() {
    setState(() => _isLiked = !_isLiked);
    _heartController.forward().then((_) => _heartController.reverse());
  }

  @override
  Widget build(BuildContext context) {
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
            child: Stack(
              children: [
                // ── Ảnh nền ──────────────────────────────────
                Positioned.fill(
                  child: widget.photo.imageBytes != null 
                    ? Image.memory(
                        widget.photo.imageBytes!,
                        fit: BoxFit.cover,
                      )
                    : CachedNetworkImage(
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

                // ── Header: Avatar + Name + Time ──────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildHeader(),
                ),

                // ── Footer: Caption + Reactions ───────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildFooter(),
                ),

                // ── Double-tap heart animation ────────────────
                Positioned.fill(
                  child: GestureDetector(
                    onDoubleTap: _toggleLike,
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.55),
            Colors.transparent,
          ],
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
                      child: CachedNetworkImage(
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
                  widget.photo.timeAgo,
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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black26,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Caption
          if (widget.photo.caption != null)
            Expanded(
              child: Text(
                widget.photo.caption!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),

          const SizedBox(width: 12),

          // Like button
          Column(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: AnimatedBuilder(
                  animation: _heartScale,
                  builder: (_, __) => Transform.scale(
                    scale: _heartScale.value,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isLiked
                            ? AppColors.primary.withOpacity(0.9)
                            : Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.photo.reactionCount + (_isLiked ? 1 : 0)}',
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
    );
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
          Icon(Icons.broken_image_rounded,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 8),
          Text('Could not load image',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
