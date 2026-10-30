import 'package:flutter/foundation.dart';
import '../models/media_item.dart';
import '../services/media_storage_service.dart';

enum MediaFilter { all, pdf, image, video, document, audio }

class MediaProvider extends ChangeNotifier {
  final MediaStorageService _service;

  List<MediaItem> _items = [];
  MediaFilter _activeFilter = MediaFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  MediaProvider(this._service) {
    _loadItems();
  }

  List<MediaItem> get allItems => _items;
  MediaFilter get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<MediaItem> get filteredItems {
    var list = _items;

    // Apply type filter
    if (_activeFilter != MediaFilter.all) {
      final targetType = _filterToType(_activeFilter);
      list = list.where((e) => e.type == targetType).toList();
    }

    // Apply search
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) {
        return e.name.toLowerCase().contains(q) ||
            (e.subject?.toLowerCase().contains(q) ?? false) ||
            (e.description?.toLowerCase().contains(q) ?? false) ||
            e.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    return list;
  }

  int countForFilter(MediaFilter filter) {
    if (filter == MediaFilter.all) return _items.length;
    final t = _filterToType(filter);
    return _items.where((e) => e.type == t).length;
  }

  MediaType _filterToType(MediaFilter f) {
    switch (f) {
      case MediaFilter.pdf:
        return MediaType.pdf;
      case MediaFilter.image:
        return MediaType.image;
      case MediaFilter.video:
        return MediaType.video;
      case MediaFilter.document:
        return MediaType.document;
      case MediaFilter.audio:
        return MediaType.audio;
      default:
        return MediaType.other;
    }
  }

  void setFilter(MediaFilter filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void _loadItems() {
    try {
      _items = _service.loadAll();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load media: $e';
      notifyListeners();
    }
  }

  Future<MediaItem?> addFile({
    required Uint8List fileBytes,
    required String fileName,
    String? subject,
    String? description,
    List<String> tags = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final item = await _service.addFile(
        fileBytes: fileBytes,
        fileName: fileName,
        subject: subject,
        description: description,
        tags: tags,
      );
      _items.insert(0, item);
      _isLoading = false;
      notifyListeners();
      return item;
    } catch (e) {
      _errorMessage = 'Upload failed: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _service.deleteItem(id);
      _items.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Delete failed: $e';
      notifyListeners();
    }
  }

  Future<void> updateItemMeta({
    required String id,
    String? subject,
    String? description,
    List<String>? tags,
  }) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final updated = _items[idx].copyWith(
      subject: subject ?? _items[idx].subject,
      description: description ?? _items[idx].description,
      tags: tags ?? _items[idx].tags,
    );
    _items[idx] = updated;
    await _service.updateItem(updated);
    notifyListeners();
  }

  Future<Uint8List?> getFileBytes(MediaItem item) {
    return _service.getFileBytes(item);
  }

  String? getFilePath(MediaItem item) {
    return _service.getFilePath(item);
  }
}
