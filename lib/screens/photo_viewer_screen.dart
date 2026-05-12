import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../models/photo_model.dart';
import '../utils/app_theme.dart';
import '../widgets/video_player.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<PhotoModel> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;
  late AnimationController _uiAnimController;
  late Animation<double> _uiAnimation;

  PhotoModel get _current => widget.photos[_currentIndex];
  bool get _isVideo => _current.type == AssetType.video;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _uiAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _uiAnimation = CurvedAnimation(
      parent: _uiAnimController,
      curve: Curves.easeInOut,
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _uiAnimController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
    _showUI ? _uiAnimController.forward() : _uiAnimController.reverse();
  }

  Future<void> _shareMedia() async {
    final file = await _current.asset.file;
    if (file != null) await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _deleteMedia() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DeleteConfirmSheet(
        isVideo: _isVideo,
        onDelete: () async {
          await PhotoManager.editor.deleteWithIds([_current.asset.id]);
          if (mounted) {
            Navigator.pop(ctx);
            Navigator.pop(context, true);
          }
        },
      ),
    );
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InfoSheet(photo: _current),
    );
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '';
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Media pages ─────────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              if (photo.type == AssetType.video) {
                return VideoPlayerWidget(
                  key: ValueKey(photo.id),
                  photo: photo,
                  showUI: _showUI,
                  onTap: _toggleUI,
                );
              }
              return GestureDetector(
                onTap: _toggleUI,
                child: _FastPhotoPage(photo: photo),
              );
            },
          ),

          // ── Top bar ─────────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: FadeTransition(
              opacity: _uiAnimation,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.chevron_left,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _current.createDateTime != null
                                    ? DateFormat('EEEE, MMMM d, yyyy')
                                        .format(_current.createDateTime!)
                                    : '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _current.createDateTime != null
                                    ? DateFormat('h:mm a')
                                        .format(_current.createDateTime!)
                                    : '',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (_isVideo)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.videocam_outlined,
                                    color: Colors.white, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(_current.duration),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        const Icon(Icons.more_horiz,
                            color: Colors.white, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Counter ─────────────────────────────────────────────────────
          if (_showUI)
            Positioned(
              top: 0, left: 0, right: 0,
              child: FadeTransition(
                opacity: _uiAnimation,
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 58),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.photos.length}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Bottom actions ───────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: FadeTransition(
              opacity: _uiAnimation,
              child: Container(
                decoration: _isVideo
                    ? null
                    : BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.65),
                            Colors.transparent
                          ],
                        ),
                      ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 32,
                      right: 32,
                      top: 8,
                      bottom: _isVideo ? 170 : 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BottomAction(
                            icon: Icons.ios_share,
                            label: 'Share',
                            onTap: _shareMedia),
                        _BottomAction(
                            icon: Icons.favorite_border,
                            label: 'Favourite',
                            onTap: () {}),
                        _BottomAction(
                            icon: Icons.info_outline,
                            label: 'Info',
                            onTap: _showInfoSheet),
                        _BottomAction(
                            icon: Icons.delete_outline,
                            label: 'Delete',
                            onTap: _deleteMedia,
                            color: AppTheme.destructive),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fast photo page: thumbnail first → full res swap ─────────────────────────

class _FastPhotoPage extends StatelessWidget {
  final PhotoModel photo;
  const _FastPhotoPage({required this.photo});

  @override
  Widget build(BuildContext context) {
    // Show thumbnail immediately, then swap to full-res once loaded
    return PhotoView(
      imageProvider: AssetEntityImageProvider(
        photo.asset,
        isOriginal: true, // loads full res
        thumbnailSize: const ThumbnailSize.square(800),
      ),
      // While full-res loads, show a blurry thumbnail placeholder instantly
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      heroAttributes: PhotoViewHeroAttributes(tag: photo.id),
      loadingBuilder: (context, event) => Stack(
        fit: StackFit.expand,
        children: [
          // Blurry thumbnail as placeholder — loads from cache instantly
          Image(
            image: AssetEntityImageProvider(
              photo.asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(300),
            ),
            fit: BoxFit.contain,
          ),
          if (event != null &&
              event.expectedTotalBytes != null &&
              event.expectedTotalBytes! > 0)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    value: event.cumulativeBytesLoaded /
                        event.expectedTotalBytes!,
                    backgroundColor: Colors.white24,
                    color: Colors.white60,
                    minHeight: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_outlined,
            color: Colors.white38, size: 64),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      );
}

class _DeleteConfirmSheet extends StatelessWidget {
  final VoidCallback onDelete;
  final bool isVideo;
  const _DeleteConfirmSheet({required this.onDelete, this.isVideo = false});

  @override
  Widget build(BuildContext context) {
    final label = isVideo ? 'Video' : 'Photo';
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Icon(isVideo ? Icons.videocam_outlined : Icons.photo_outlined,
              color: AppTheme.destructive, size: 48),
          const SizedBox(height: 12),
          Text('Delete $label',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('This $label will be deleted from your library.',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Divider(color: AppTheme.divider, height: 1),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Delete $label',
                  style: const TextStyle(
                      color: AppTheme.destructive,
                      fontSize: 17,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ),
          ),
          Divider(color: AppTheme.divider, height: 1),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.w400),
                  textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final PhotoModel photo;
  const _InfoSheet({required this.photo});

  String _dur(Duration? d) {
    if (d == null) return 'Unknown';
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = photo.type == AssetType.video;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isVideo ? 'Video Info' : 'Photo Info',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            title: 'Date',
            value: photo.createDateTime != null
                ? DateFormat('MMMM d, yyyy • h:mm a')
                    .format(photo.createDateTime!)
                : 'Unknown',
          ),
          _InfoRow(
            icon: Icons.photo_size_select_actual_outlined,
            title: 'Dimensions',
            value: '${photo.width} × ${photo.height}',
          ),
          if (isVideo)
            _InfoRow(
                icon: Icons.timer_outlined,
                title: 'Duration',
                value: _dur(photo.duration)),
          _InfoRow(
            icon: isVideo ? Icons.videocam_outlined : Icons.image_outlined,
            title: 'Type',
            value: isVideo ? 'Video' : 'Photo',
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done',
                  style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoRow(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 22),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
      );
}