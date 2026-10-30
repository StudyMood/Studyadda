import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';

/// Cross-platform media storage service.
/// - Windows/Desktop: Copies files to app documents directory, stores path.
/// - Web: Stores file bytes as base64 in SharedPreferences.
class MediaStorageService {
  static const String _kMediaList = 'studyhub_media_items';
  static const String _kMediaBytesPrefix = 'studyhub_media_bytes_';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) throw StateError('MediaStorageService not initialized');
    return _prefs!;
  }

  // ─── Load all media items ───────────────────────────────────────────────
  List<MediaItem> loadAll() {
    final rawList = prefs.getStringList(_kMediaList) ?? [];
    final items = <MediaItem>[];
    for (final raw in rawList) {
      try {
        items.add(MediaItem.fromJson(json.decode(raw) as Map<String, dynamic>));
      } catch (e) {
        debugPrint('MediaStorageService: failed to parse item: $e');
      }
    }
    // Sort newest first
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  // ─── Save full list ─────────────────────────────────────────────────────
  Future<void> _saveAll(List<MediaItem> items) async {
    final rawList = items.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_kMediaList, rawList);
  }

  // ─── Add a new file ─────────────────────────────────────────────────────
  /// [fileBytes]: raw bytes of the file
  /// [fileName]: original filename
  /// [subject]: optional subject tag
  /// [description]: optional description
  Future<MediaItem> addFile({
    required Uint8List fileBytes,
    required String fileName,
    String? subject,
    String? description,
    List<String> tags = const [],
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : '';
    final type = MediaItem.typeFromExtension(ext);
    final id = 'media_${DateTime.now().millisecondsSinceEpoch}';

    String? storedPath;
    String? storedBytes;

    if (kIsWeb) {
      // Web: store bytes as base64 in prefs with separate key (for large items)
      final b64 = base64Encode(fileBytes);
      await prefs.setString('$_kMediaBytesPrefix$id', b64);
      storedBytes = id; // reference key
    } else {
      // Desktop/Mobile: copy file to app documents directory
      storedPath = await _copyToAppDir(fileBytes, id, fileName);
    }

    final item = MediaItem(
      id: id,
      name: fileName,
      type: type,
      filePath: storedPath,
      fileBytes: storedBytes,
      sizeBytes: fileBytes.length,
      subject: subject,
      description: description,
      tags: tags,
      createdAt: DateTime.now(),
    );

    final all = loadAll();
    all.insert(0, item);
    await _saveAll(all);
    return item;
  }

  // ─── Delete a media item ────────────────────────────────────────────────
  Future<void> deleteItem(String id) async {
    final all = loadAll();
    final item = all.firstWhere((e) => e.id == id, orElse: () => throw Exception('Not found'));

    // Remove actual file (desktop)
    if (!kIsWeb && item.filePath != null) {
      try {
        final f = File(item.filePath!);
        if (await f.exists()) await f.delete();
      } catch (e) {
        debugPrint('Failed to delete file: $e');
      }
    }

    // Remove bytes (web)
    if (kIsWeb && item.fileBytes != null) {
      await prefs.remove('$_kMediaBytesPrefix${item.fileBytes}');
    }

    all.removeWhere((e) => e.id == id);
    await _saveAll(all);
  }

  // ─── Update metadata ────────────────────────────────────────────────────
  Future<void> updateItem(MediaItem updated) async {
    final all = loadAll();
    final idx = all.indexWhere((e) => e.id == updated.id);
    if (idx == -1) return;
    all[idx] = updated;
    await _saveAll(all);
  }

  // ─── Get file bytes for display ─────────────────────────────────────────
  Future<Uint8List?> getFileBytes(MediaItem item) async {
    if (kIsWeb) {
      if (item.fileBytes == null) return null;
      final b64 = prefs.getString('$_kMediaBytesPrefix${item.fileBytes}');
      if (b64 == null) return null;
      return base64Decode(b64);
    } else {
      if (item.filePath == null) return null;
      final f = File(item.filePath!);
      if (!await f.exists()) return null;
      return f.readAsBytes();
    }
  }

  // ─── Copy file to app documents dir (Desktop) ───────────────────────────
  Future<String> _copyToAppDir(
    Uint8List bytes,
    String id,
    String originalName,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/StudyHub/media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    final ext = originalName.contains('.') ? '.${originalName.split('.').last}' : '';
    final filePath = '${mediaDir.path}/$id$ext';
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  // ─── Get file path (Desktop) ────────────────────────────────────────────
  String? getFilePath(MediaItem item) {
    if (kIsWeb) return null;
    return item.filePath;
  }

  // ─── Clear all media ────────────────────────────────────────────────────
  Future<void> clearAll() async {
    final all = loadAll();
    for (final item in all) {
      if (!kIsWeb && item.filePath != null) {
        try {
          final f = File(item.filePath!);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      if (kIsWeb && item.fileBytes != null) {
        await prefs.remove('$_kMediaBytesPrefix${item.fileBytes}');
      }
    }
    await prefs.remove(_kMediaList);
  }
}
