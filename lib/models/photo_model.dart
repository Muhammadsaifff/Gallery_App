import 'package:photo_manager/photo_manager.dart';

class PhotoModel {
  final AssetEntity asset;
  bool isSelected;

  PhotoModel({
    required this.asset,
    this.isSelected = false,
  });

  String get id => asset.id;
  DateTime? get createDateTime => asset.createDateTime;
  AssetType get type => asset.type;
  int get width => asset.width;
  int get height => asset.height;
  Duration? get duration =>
      asset.type == AssetType.video ? Duration(seconds: asset.duration) : null;
}

class AlbumModel {
  final AssetPathEntity path;
  final List<PhotoModel> photos;
  final PhotoModel? coverPhoto;
  final String name;
  final int count;

  AlbumModel({
    required this.path,
    required this.photos,
    this.coverPhoto,
    required this.name,
    required this.count,
  });
}