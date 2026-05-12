import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../models/photo_model.dart';
import '../utils/app_theme.dart';

class PhotoThumbnail extends StatefulWidget {
  final PhotoModel photo;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double size;

  const PhotoThumbnail({
    super.key,
    required this.photo,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    this.size = 120,
  });

  @override
  State<PhotoThumbnail> createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends State<PhotoThumbnail>
    with SingleTickerProviderStateMixin {
  late AnimationController _selectionController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(PhotoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _selectionController.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _selectionController.reverse();
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thumbSize = (widget.size * 2).toInt();

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: widget.isSelected ? _scaleAnimation.value : 1.0,
          child: child,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Thumbnail via AssetEntityImage (cached, fast) ──
            AssetEntityImage(
              widget.photo.asset,
              isOriginal: false,
              thumbnailSize: ThumbnailSize.square(thumbSize),
              thumbnailFormat: ThumbnailFormat.jpeg,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, chunk) {
                if (chunk == null) return child;
                return Container(color: AppTheme.surfaceSecondary);
              },
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.surfaceSecondary,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppTheme.textSecondary, size: 28),
              ),
            ),

            // ── Video badge ──
            if (widget.photo.type == AssetType.video)
              Positioned(
                bottom: 5,
                left: 5,
                right: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 18,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                    Text(
                      _formatDuration(widget.photo.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),

            // ── Selection overlay ──
            if (widget.isSelectionMode) ...[
              if (widget.isSelected)
                Container(color: Colors.black.withOpacity(0.15)),
              Positioned(
                top: 5,
                left: 5,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected
                        ? AppTheme.primaryBlue
                        : Colors.transparent,
                    border: Border.all(
                      color: widget.isSelected
                          ? AppTheme.primaryBlue
                          : Colors.white,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 3)
                    ],
                  ),
                  child: widget.isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '0:00';
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}