import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../providers/gallery_provider.dart';
import '../models/photo_model.dart';
import '../widgets/photo_thumbnail.dart';
import '../utils/app_theme.dart';
import 'photo_viewer_screen.dart';

enum LibraryViewMode { days, months, years, allPhotos }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with AutomaticKeepAliveClientMixin {
  LibraryViewMode _viewMode = LibraryViewMode.days;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<GalleryProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Large title app bar
              SliverAppBar(
                pinned: true,
                expandedHeight: 100,
                backgroundColor: AppTheme.background,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
                ),
                actions: [
                  if (provider.isSelectionMode)
                    TextButton(
                      onPressed: () => provider.toggleSelectionMode(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 17,
                        ),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () => provider.toggleSelectionMode(),
                      child: const Text(
                        'Select',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 17,
                        ),
                      ),
                    ),
                ],
              ),

              // Zoom buttons bar
              SliverToBoxAdapter(
                child: _ViewModeSelector(
                  currentMode: _viewMode,
                  onModeChanged: (mode) {
                    setState(() => _viewMode = mode);
                  },
                ),
              ),

              // Photo content
              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                )
              else if (provider.allPhotos.isEmpty)
                const SliverFillRemaining(
                  child: _EmptyState(),
                )
              else ...[
                if (_viewMode == LibraryViewMode.days)
                  _DaysView(photos: provider.allPhotos)
                else if (_viewMode == LibraryViewMode.months)
                  _MonthsView(photosByMonth: provider.photosByMonth)
                else if (_viewMode == LibraryViewMode.years)
                  _YearsView(photosByYear: provider.photosByYear)
                else
                  _AllPhotosView(photos: provider.allPhotos),
              ],
            ],
          ),

          // Selection toolbar
          bottomSheet: provider.isSelectionMode
              ? _SelectionToolbar(provider: provider)
              : null,
        );
      },
    );
  }
}

class _ViewModeSelector extends StatelessWidget {
  final LibraryViewMode currentMode;
  final ValueChanged<LibraryViewMode> onModeChanged;

  const _ViewModeSelector({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _ModeTab(
              label: 'Years',
              isSelected: currentMode == LibraryViewMode.years,
              onTap: () => onModeChanged(LibraryViewMode.years),
            ),
            _ModeTab(
              label: 'Months',
              isSelected: currentMode == LibraryViewMode.months,
              onTap: () => onModeChanged(LibraryViewMode.months),
            ),
            _ModeTab(
              label: 'Days',
              isSelected: currentMode == LibraryViewMode.days,
              onTap: () => onModeChanged(LibraryViewMode.days),
            ),
            _ModeTab(
              label: 'All Photos',
              isSelected: currentMode == LibraryViewMode.allPhotos,
              onTap: () => onModeChanged(LibraryViewMode.allPhotos),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DaysView extends StatelessWidget {
  final List<PhotoModel> photos;

  const _DaysView({required this.photos});

  Map<String, List<PhotoModel>> get _byDate {
    final Map<String, List<PhotoModel>> grouped = {};
    for (final photo in photos) {
      final date = photo.createDateTime;
      if (date != null) {
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []).add(photo);
      }
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final byDate = _byDate;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = byDate.entries.elementAt(index);
          final dateKey = entry.key;
          final datePhotos = entry.value;
          final date = DateTime.parse(dateKey);

          String dateLabel;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final photoDate = DateTime(date.year, date.month, date.day);
          final diff = today.difference(photoDate).inDays;

          if (diff == 0) {
            dateLabel = 'Today';
          } else if (diff == 1) {
            dateLabel = 'Yesterday';
          } else {
            dateLabel = DateFormat('EEEE, MMMM d').format(date);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _PhotoGrid(photos: datePhotos, allPhotos: photos),
            ],
          );
        },
        childCount: byDate.length,
      ),
    );
  }
}

class _MonthsView extends StatelessWidget {
  final Map<String, List<PhotoModel>> photosByMonth;

  const _MonthsView({required this.photosByMonth});

  @override
  Widget build(BuildContext context) {
    final sorted = Map.fromEntries(
      photosByMonth.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key)),
    );

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = sorted.entries.elementAt(index);
          final parts = entry.key.split('-');
          final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
          final photos = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(left: 16, top: 20, bottom: 8),
                child: Text(
                  DateFormat('MMMM yyyy').format(date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _PhotoGrid(photos: photos, allPhotos: photos, crossAxisCount: 3),
            ],
          );
        },
        childCount: sorted.length,
      ),
    );
  }
}

class _YearsView extends StatelessWidget {
  final Map<String, List<PhotoModel>> photosByYear;

  const _YearsView({required this.photosByYear});

  @override
  Widget build(BuildContext context) {
    final sorted = Map.fromEntries(
      photosByYear.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key)),
    );

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = sorted.entries.elementAt(index);
          final year = entry.key;
          final photos = entry.value;

          return GestureDetector(
            onTap: () {},
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photos.isNotEmpty)
                  AssetEntityImage(
                    photos.first.asset,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(400),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppTheme.surfaceSecondary),
                  )
                else
                  Container(color: AppTheme.surfaceSecondary),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        year,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${photos.length} photos',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        childCount: sorted.length,
      ),
    );
  }
}

class _AllPhotosView extends StatelessWidget {
  final List<PhotoModel> photos;

  const _AllPhotosView({required this.photos});

  @override
  Widget build(BuildContext context) {
    return _PhotoGrid(photos: photos, allPhotos: photos, crossAxisCount: 4);
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<PhotoModel> photos;
  final List<PhotoModel> allPhotos;
  final int crossAxisCount;

  const _PhotoGrid({
    required this.photos,
    required this.allPhotos,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GalleryProvider>();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return PhotoThumbnail(
          photo: photo,
          isSelected: provider.isPhotoSelected(photo),
          isSelectionMode: provider.isSelectionMode,
          onTap: () {
            if (provider.isSelectionMode) {
              provider.togglePhotoSelection(photo);
            } else {
              final globalIndex = allPhotos.indexWhere((p) => p.id == photo.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoViewerScreen(
                    photos: allPhotos,
                    initialIndex: globalIndex >= 0 ? globalIndex : index,
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
    );
  }
}

class _SelectionToolbar extends StatelessWidget {
  final GalleryProvider provider;

  const _SelectionToolbar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            provider.selectedCount > 0
                ? '${provider.selectedCount} Selected'
                : 'Select Items',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              if (provider.selectedCount > 0) ...[
                GestureDetector(
                  onTap: () {},
                  child: const Icon(
                    Icons.ios_share,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.surface,
                        title: const Text(
                          'Delete Photos?',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          'Delete ${provider.selectedCount} photo(s)?',
                          style:
                              const TextStyle(color: AppTheme.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              provider.deleteSelectedPhotos();
                            },
                            child: const Text(
                              'Delete',
                              style:
                                  TextStyle(color: AppTheme.destructive),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.destructive,
                    size: 24,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              color: AppTheme.textSecondary, size: 64),
          SizedBox(height: 16),
          Text(
            'No Photos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Photos and videos you take\nwill appear here.',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}