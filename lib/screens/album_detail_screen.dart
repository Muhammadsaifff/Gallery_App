import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/photo_model.dart';
import '../providers/gallery_provider.dart';
import '../widgets/photo_thumbnail.dart';
import '../utils/app_theme.dart';
import 'photo_viewer_screen.dart';

class AlbumDetailScreen extends StatelessWidget {
  final AlbumModel album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 80,
                backgroundColor: AppTheme.background,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.chevron_left,
                      color: AppTheme.primaryBlue,
                      size: 32,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${album.count} items',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  titlePadding:
                      const EdgeInsets.only(left: 60, bottom: 12),
                ),
                actions: [
                  TextButton(
                    onPressed: () => provider.toggleSelectionMode(),
                    child: Text(
                      provider.isSelectionMode ? 'Cancel' : 'Select',
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 1.5,
                  crossAxisSpacing: 1.5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final photo = album.photos[index];
                    return PhotoThumbnail(
                      photo: photo,
                      isSelected: provider.isPhotoSelected(photo),
                      isSelectionMode: provider.isSelectionMode,
                      onTap: () {
                        if (provider.isSelectionMode) {
                          provider.togglePhotoSelection(photo);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PhotoViewerScreen(
                                photos: album.photos,
                                initialIndex: index,
                              ),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        if (!provider.isSelectionMode) {
                          provider.toggleSelectionMode();
                          provider.togglePhotoSelection(photo);
                        }
                      },
                    );
                  },
                  childCount: album.photos.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }
}