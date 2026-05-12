import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../providers/gallery_provider.dart';
import '../models/photo_model.dart';
import '../utils/app_theme.dart';
import 'album_detail_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<GalleryProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 100,
                backgroundColor: AppTheme.background,
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text(
                    'Albums',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                  titlePadding: EdgeInsets.only(left: 20, bottom: 12),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add, color: AppTheme.primaryBlue),
                    onPressed: () {},
                  ),
                ],
              ),
              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                )
              else ...[
                // My Albums header
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Albums',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'See All',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Albums grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.82,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= provider.albums.length) {
                          return null;
                        }
                        final album = provider.albums[index];
                        return _AlbumCard(
                          album: album,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AlbumDetailScreen(album: album),
                              ),
                            );
                          },
                        );
                      },
                      childCount: provider.albums.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // Media Types Section
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: AppTheme.divider),
                        SizedBox(height: 8),
                        Text(
                          'Media Types',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverList(
                  delegate: SliverChildListDelegate([
                    _MediaTypeRow(
                      icon: Icons.videocam_outlined,
                      label: 'Videos',
                      count: provider.allPhotos
                          .where((p) => p.type.toString().contains('video'))
                          .length,
                      onTap: () {},
                    ),
                    _MediaTypeRow(
                      icon: Icons.portrait,
                      label: 'Selfies',
                      count: 0,
                      onTap: () {},
                    ),
                    _MediaTypeRow(
                      icon: Icons.panorama_outlined,
                      label: 'Panoramas',
                      count: 0,
                      onTap: () {},
                    ),
                    _MediaTypeRow(
                      icon: Icons.screenshot_monitor_outlined,
                      label: 'Screenshots',
                      count: 0,
                      onTap: () {},
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final AlbumModel album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: album.coverPhoto != null
                  ? AssetEntityImage(
                      album.coverPhoto!.asset,
                      isOriginal: false,
                      thumbnailSize: const ThumbnailSize.square(300),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppTheme.surfaceSecondary),
                    )
                  : Container(
                      color: AppTheme.surfaceSecondary,
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: AppTheme.textSecondary,
                        size: 40,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            album.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${album.count}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaTypeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _MediaTypeRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, color: AppTheme.primaryBlue, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 60),
              child: Divider(color: AppTheme.divider, height: 1),
            ),
          ],
        ),
      ),
    );
  }
}