import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../providers/gallery_provider.dart';
import '../models/photo_model.dart';
import '../utils/app_theme.dart';
import 'photo_viewer_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  List<PhotoModel> _searchResults = [];
  bool _isSearching = false;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, List<PhotoModel> allPhotos) {
    setState(() {
      _query = query;
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = allPhotos.where((photo) {
          final date = photo.createDateTime;
          if (date == null) return false;
          final dateStr = DateFormat('MMMM yyyy EEEE d').format(date).toLowerCase();
          return dateStr.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

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
                backgroundColor: AppTheme.background,
                expandedHeight: 100,
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                  titlePadding: EdgeInsets.only(left: 20, bottom: 12),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (q) =>
                          _onSearchChanged(q, provider.allPhotos),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by date, month...',
                        hintStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 17,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.textSecondary,
                        ),
                        suffixIcon: _isSearching
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _onSearchChanged('', provider.allPhotos);
                                },
                                child: const Icon(
                                  Icons.cancel,
                                  color: AppTheme.textSecondary,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
              if (_isSearching) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      '${_searchResults.length} results for "$_query"',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
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
                      final photo = _searchResults[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PhotoViewerScreen(
                                photos: _searchResults,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: AssetEntityImage(
                          photo.asset,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize.square(200),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.surfaceSecondary,
                          ),
                        ),
                      );
                    },
                    childCount: _searchResults.length,
                  ),
                ),
              ] else ...[
                // Suggested categories
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'Suggested',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    _SuggestedCategory(
                      icon: Icons.people_outline,
                      title: 'People',
                      color: Colors.orange,
                      onTap: () {},
                    ),
                    _SuggestedCategory(
                      icon: Icons.place_outlined,
                      title: 'Places',
                      color: Colors.green,
                      onTap: () {},
                    ),
                    _SuggestedCategory(
                      icon: Icons.category_outlined,
                      title: 'Categories',
                      color: Colors.blue,
                      onTap: () {},
                    ),
                    _SuggestedCategory(
                      icon: Icons.calendar_month_outlined,
                      title: 'This Month',
                      color: Colors.purple,
                      onTap: () {
                        final now = DateTime.now();
                        _searchController.text =
                            DateFormat('MMMM').format(now);
                        _onSearchChanged(
                          DateFormat('MMMM').format(now),
                          provider.allPhotos,
                        );
                      },
                    ),
                  ]),
                ),

                // Recent years
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text(
                      'Recent Years',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final years = provider.photosByYear.keys.toList()
                        ..sort((a, b) => b.compareTo(a));
                      if (index >= years.length) return null;
                      final year = years[index];
                      final count =
                          provider.photosByYear[year]?.length ?? 0;
                      return _SuggestedCategory(
                        icon: Icons.calendar_today_outlined,
                        title: year,
                        subtitle: '$count photos',
                        color: Colors.teal,
                        onTap: () {
                          _searchController.text = year;
                          _onSearchChanged(year, provider.allPhotos);
                        },
                      );
                    },
                    childCount: provider.photosByYear.length,
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

class _SuggestedCategory extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SuggestedCategory({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 74),
              child: Divider(color: AppTheme.divider, height: 1),
            ),
          ],
        ),
      ),
    );
  }
}