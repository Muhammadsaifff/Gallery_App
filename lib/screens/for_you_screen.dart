import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../providers/gallery_provider.dart';
import '../models/photo_model.dart';
import '../utils/app_theme.dart';
import 'photo_viewer_screen.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen>
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
                    'For You',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                  titlePadding: EdgeInsets.only(left: 20, bottom: 12),
                ),
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
                // Memories section
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Memories',
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

                // Horizontal memories scroll
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: _MemoriesCarousel(provider: provider),
                  ),
                ),

                // Favourites section
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Favourites',
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

                // Recent highlights grid
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Recent Highlights',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                if (provider.allPhotos.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final highlights = provider.allPhotos
                              .take(12)
                              .toList();
                          if (index >= highlights.length) return null;
                          final photo = highlights[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PhotoViewerScreen(
                                    photos: highlights,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: index == 0
                                  ? const BorderRadius.only(
                                      topLeft: Radius.circular(8))
                                  : index == 2
                                      ? const BorderRadius.only(
                                          topRight: Radius.circular(8))
                                      : BorderRadius.zero,
                              child: AssetEntityImage(
                                photo.asset,
                                isOriginal: false,
                                thumbnailSize: const ThumbnailSize.square(200),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: AppTheme.surfaceSecondary),
                              ),
                            ),
                          );
                        },
                        childCount:
                            provider.allPhotos.take(12).length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MemoriesCarousel extends StatelessWidget {
  final GalleryProvider provider;

  const _MemoriesCarousel({required this.provider});

  List<Map<String, dynamic>> _getMemories() {
    final memories = <Map<String, dynamic>>[];
    final photosByMonth = provider.photosByMonth;

    for (final entry in photosByMonth.entries.take(6)) {
      final parts = entry.key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      memories.add({
        'title': DateFormat('MMMM yyyy').format(date),
        'count': entry.value.length,
        'photos': entry.value,
        'cover': entry.value.first,
      });
    }
    return memories;
  }

  @override
  Widget build(BuildContext context) {
    final memories = _getMemories();
    if (memories.isEmpty) {
      return const Center(
        child: Text(
          'No memories yet',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final memory = memories[index];
        final photos = memory['photos'] as List<PhotoModel>;
        final cover = memory['cover'] as PhotoModel;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhotoViewerScreen(
                  photos: photos,
                  initialIndex: 0,
                ),
              ),
            );
          },
          child: Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AssetEntityImage(
                    cover.asset,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize(300, 400),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppTheme.surfaceSecondary),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memory['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${memory['count']} photos',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}