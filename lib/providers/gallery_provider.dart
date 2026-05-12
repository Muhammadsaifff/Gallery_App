import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_model.dart';

class GalleryProvider extends ChangeNotifier {
  List<PhotoModel> _allPhotos = [];
  List<AlbumModel> _albums = [];
  List<PhotoModel> _selectedPhotos = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _isSelectionMode = false;
  String _errorMessage = '';
  int _currentPhotoIndex = 0;

  List<PhotoModel> get allPhotos => _allPhotos;
  List<AlbumModel> get albums => _albums;
  List<PhotoModel> get selectedPhotos => _selectedPhotos;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  bool get isSelectionMode => _isSelectionMode;
  String get errorMessage => _errorMessage;
  int get currentPhotoIndex => _currentPhotoIndex;
  int get selectedCount => _selectedPhotos.length;

  // Grouped photos by date
  Map<String, List<PhotoModel>> get photosByDate {
    final Map<String, List<PhotoModel>> grouped = {};
    for (final photo in _allPhotos) {
      final date = photo.createDateTime;
      if (date != null) {
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []).add(photo);
      }
    }
    return grouped;
  }

  Map<String, List<PhotoModel>> get photosByMonth {
    final Map<String, List<PhotoModel>> grouped = {};
    for (final photo in _allPhotos) {
      final date = photo.createDateTime;
      if (date != null) {
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []).add(photo);
      }
    }
    return grouped;
  }

  Map<String, List<PhotoModel>> get photosByYear {
    final Map<String, List<PhotoModel>> grouped = {};
    for (final photo in _allPhotos) {
      final date = photo.createDateTime;
      if (date != null) {
        final key = '${date.year}';
        grouped.putIfAbsent(key, () => []).add(photo);
      }
    }
    return grouped;
  }

  Future<void> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    _hasPermission = ps.isAuth || ps.hasAccess;
    if (_hasPermission) {
      await loadPhotos();
    } else {
      _errorMessage = 'Permission denied. Please allow access to your photos.';
    }
    notifyListeners();
  }

  Future<void> loadPhotos() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Load all photos
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        onlyAll: false,
        type: RequestType.common,
      );

      if (paths.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Load all assets from "Recent" or first album
      final allAssetsPath = paths.firstWhere(
        (p) => p.isAll,
        orElse: () => paths.first,
      );

      final int count = await allAssetsPath.assetCountAsync;
      final List<AssetEntity> assets = await allAssetsPath.getAssetListRange(
        start: 0,
        end: count,
      );

      _allPhotos = assets.map((a) => PhotoModel(asset: a)).toList();

      // Load albums
      await _loadAlbums(paths);
    } catch (e) {
      _errorMessage = 'Error loading photos: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAlbums(List<AssetPathEntity> paths) async {
    final List<AlbumModel> albums = [];

    for (final path in paths) {
      final int count = await path.assetCountAsync;
      if (count == 0) continue;

      final List<AssetEntity> assets = await path.getAssetListRange(
        start: 0,
        end: count > 200 ? 200 : count,
      );

      final photos = assets.map((a) => PhotoModel(asset: a)).toList();
      final coverPhoto = photos.isNotEmpty ? photos.first : null;

      albums.add(AlbumModel(
        path: path,
        photos: photos,
        coverPhoto: coverPhoto,
        name: path.name,
        count: count,
      ));
    }

    _albums = albums;
  }

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      clearSelection();
    }
    notifyListeners();
  }

  void togglePhotoSelection(PhotoModel photo) {
    photo.isSelected = !photo.isSelected;
    if (photo.isSelected) {
      _selectedPhotos.add(photo);
    } else {
      _selectedPhotos.removeWhere((p) => p.id == photo.id);
    }
    notifyListeners();
  }

  void clearSelection() {
    for (final photo in _selectedPhotos) {
      photo.isSelected = false;
    }
    _selectedPhotos.clear();
    notifyListeners();
  }

  void selectAll() {
    for (final photo in _allPhotos) {
      if (!photo.isSelected) {
        photo.isSelected = true;
        _selectedPhotos.add(photo);
      }
    }
    notifyListeners();
  }

  void setCurrentPhotoIndex(int index) {
    _currentPhotoIndex = index;
    notifyListeners();
  }

  bool isPhotoSelected(PhotoModel photo) {
    return _selectedPhotos.any((p) => p.id == photo.id);
  }

  Future<void> deleteSelectedPhotos() async {
    final ids = _selectedPhotos.map((p) => p.id).toList();
    await PhotoManager.editor.deleteWithIds(ids);
    _allPhotos.removeWhere((p) => ids.contains(p.id));
    clearSelection();
    _isSelectionMode = false;
    await loadPhotos();
    notifyListeners();
  }
}