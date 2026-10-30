import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../utils/app_colors.dart';

class MediaLibraryScreen extends StatelessWidget {
  const MediaLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MediaLibraryBody();
  }
}

class _MediaLibraryBody extends StatefulWidget {
  const _MediaLibraryBody();

  @override
  State<_MediaLibraryBody> createState() => _MediaLibraryBodyState();
}

class _MediaLibraryBodyState extends State<_MediaLibraryBody>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Upload file ──────────────────────────────────────────────────────────
  Future<void> _pickAndUpload(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp',
        'mp4', 'mkv', 'avi', 'mov', 'webm',
        'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'csv',
        'mp3', 'm4a', 'aac', 'wav', 'ogg',
      ],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    if (!context.mounted) return;
    setState(() => _isUploading = true);

    final media = context.read<MediaProvider>();
    int successCount = 0;

    for (final file in result.files) {
      Uint8List? bytes;

      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) continue;

      // Show upload dialog for metadata
      if (!context.mounted) break;
      final meta = await _showUploadMetaDialog(
        context,
        fileName: file.name,
        fileSize: bytes.length,
      );
      if (meta == null) continue; // user cancelled

      await media.addFile(
        fileBytes: bytes,
        fileName: file.name,
        subject: meta['subject'],
        description: meta['description'],
        tags: meta['tags'] ?? [],
      );
      successCount++;
    }

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (successCount > 0 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successCount == 1
                ? '✅ 1 file uploaded successfully!'
                : '✅ $successCount files uploaded!',
          ),
          backgroundColor: const Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _showUploadMetaDialog(
    BuildContext context, {
    required String fileName,
    required int fileSize,
  }) async {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final type = MediaItem.typeFromExtension(
      fileName.contains('.') ? fileName.split('.').last : '',
    );

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              _MediaTypeIcon(type: type, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Media Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Size: ${_formatSize(fileSize)} · ${type.name.toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectCtrl,
                decoration: InputDecoration(
                  labelText: 'Subject / Category (optional)',
                  hintText: 'e.g., DATA STRUCTURES, PYTHON',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description of this file...',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Skip'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.upload_rounded, size: 16),
              label: const Text('Upload'),
              onPressed: () {
                Navigator.pop(ctx, {
                  'subject': subjectCtrl.text.trim().isEmpty
                      ? null
                      : subjectCtrl.text.trim(),
                  'description': descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  'tags': <String>[],
                });
              },
            ),
          ],
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ─── Open / view file ─────────────────────────────────────────────────────
  Future<void> _openFile(BuildContext context, MediaItem item) async {
    final media = context.read<MediaProvider>();

    if (!kIsWeb) {
      final path = media.getFilePath(item);
      if (path != null) {
        final result = await OpenFile.open(path);
        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot open: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Web: show bytes in viewer
    final bytes = await media.getFileBytes(item);
    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    _showWebFileViewer(context, item, bytes);
  }

  void _showWebFileViewer(
    BuildContext context,
    MediaItem item,
    Uint8List bytes,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 700,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  _MediaTypeIcon(type: item.type, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: item.type == MediaType.image
                    ? Center(child: Image.memory(bytes, fit: BoxFit.contain))
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _MediaTypeIcon(type: item.type, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.formattedSize,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'File stored locally. Open with system app.',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MediaItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete File?'),
          ],
        ),
        content: Text(
          'Permanently delete "${item.name}"?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MediaProvider>().deleteItem(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('File deleted'),
                  backgroundColor: Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = context.watch<MediaProvider>();

    final filtered = media.filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.perm_media_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Media Library',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          // Upload button
          _isUploading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.upload_file_rounded),
                  tooltip: 'Upload Files',
                  onPressed: () => _pickAndUpload(context),
                ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => media.setSearchQuery(v),
              decoration: InputDecoration(
                hintText: 'Search files, subjects, descriptions...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          media.clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E2535) : const Color(0xFFF0F2F8),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Filter chips
          _FilterChipsRow(media: media),

          // Stats bar
          if (media.allItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} ${filtered.length == 1 ? 'file' : 'files'}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (media.allItems.isNotEmpty)
                    Text(
                      _formatSize(
                          media.allItems.fold(0, (s, e) => s + e.sizeBytes)),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: media.allItems.isEmpty
                ? _EmptyMediaState(onUpload: () => _pickAndUpload(context))
                : filtered.isEmpty
                    ? _NoResultsState()
                    : _MediaGrid(
                        items: filtered,
                        onOpen: (item) => _openFile(context, item),
                        onDelete: (item) => _confirmDelete(context, item),
                      ),
          ),
        ],
      ),

      // FAB: Upload
      floatingActionButton: media.allItems.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: _isUploading ? null : () => _pickAndUpload(context),
            ),
    );
  }
}

// ─── Filter Chips Row ──────────────────────────────────────────────────────────
class _FilterChipsRow extends StatelessWidget {
  final MediaProvider media;
  const _FilterChipsRow({required this.media});

  @override
  Widget build(BuildContext context) {
    final filters = [
      (MediaFilter.all, Icons.grid_view_rounded, 'All'),
      (MediaFilter.pdf, Icons.picture_as_pdf_rounded, 'PDFs'),
      (MediaFilter.image, Icons.image_rounded, 'Images'),
      (MediaFilter.video, Icons.videocam_rounded, 'Videos'),
      (MediaFilter.document, Icons.description_rounded, 'Docs'),
      (MediaFilter.audio, Icons.audiotrack_rounded, 'Audio'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: filters.length,
        separatorBuilder: (_, _s) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (filter, icon, label) = filters[i];
          final count = media.countForFilter(filter);
          final isActive = media.activeFilter == filter;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ChoiceChip(
              avatar: Icon(icon,
                  size: 16,
                  color: isActive ? Colors.white : AppColors.primary),
              label: Text(
                count > 0 ? '$label ($count)' : label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : null,
                ),
              ),
              selected: isActive,
              selectedColor: AppColors.primary,
              onSelected: (_) => media.setFilter(filter),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        },
      ),
    );
  }
}

// ─── Media Grid ───────────────────────────────────────────────────────────────
class _MediaGrid extends StatelessWidget {
  final List<MediaItem> items;
  final void Function(MediaItem) onOpen;
  final void Function(MediaItem) onDelete;

  const _MediaGrid({
    required this.items,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      int crossAxisCount = 2;
      if (constraints.maxWidth < 500) {
        crossAxisCount = 1;
      } else if (constraints.maxWidth < 800) {
        crossAxisCount = 2;
      } else if (constraints.maxWidth < 1200) {
        crossAxisCount = 3;
      } else {
        crossAxisCount = 4;
      }

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: crossAxisCount == 1 ? 3.5 : 1.3,
        ),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _MediaCard(
          item: items[i],
          onOpen: () => onOpen(items[i]),
          onDelete: () => onDelete(items[i]),
        ),
      );
    });
  }
}

// ─── Media Card ───────────────────────────────────────────────────────────────
class _MediaCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _MediaCard({
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A2236) : Colors.white;
    final (color, icon) = _typeStyle(item.type);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Type icon badge
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const Spacer(),
                    // Delete button
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onDelete,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: isDark
                              ? Colors.red[300]
                              : Colors.red[400],
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // File name
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : const Color(0xFF1A2236),
                  ),
                ),
                const SizedBox(height: 4),
                // Subject tag
                if (item.subject != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.subject!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                // Size & date
                Row(
                  children: [
                    Text(
                      item.formattedSize,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey[500]
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('·',
                        style: TextStyle(color: Colors.grey[500])),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatDate(item.createdAt),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, IconData) _typeStyle(MediaType type) {
    switch (type) {
      case MediaType.pdf:
        return (Colors.red, Icons.picture_as_pdf_rounded);
      case MediaType.image:
        return (Colors.teal, Icons.image_rounded);
      case MediaType.video:
        return (Colors.purple, Icons.videocam_rounded);
      case MediaType.document:
        return (Colors.blue, Icons.description_rounded);
      case MediaType.audio:
        return (Colors.orange, Icons.audiotrack_rounded);
      case MediaType.other:
        return (Colors.grey, Icons.insert_drive_file_rounded);
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Media Type Icon ──────────────────────────────────────────────────────────
class _MediaTypeIcon extends StatelessWidget {
  final MediaType type;
  final double size;

  const _MediaTypeIcon({required this.type, required this.size});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style();
    return Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.8),
    );
  }

  (Color, IconData) _style() {
    switch (type) {
      case MediaType.pdf:
        return (Colors.red, Icons.picture_as_pdf_rounded);
      case MediaType.image:
        return (Colors.teal, Icons.image_rounded);
      case MediaType.video:
        return (Colors.purple, Icons.videocam_rounded);
      case MediaType.document:
        return (Colors.blue, Icons.description_rounded);
      case MediaType.audio:
        return (Colors.orange, Icons.audiotrack_rounded);
      case MediaType.other:
        return (Colors.grey, Icons.insert_drive_file_rounded);
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyMediaState extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyMediaState({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Media Library is Empty',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Upload PDFs, images, videos, documents, and audio files.\nThey will be stored permanently on your device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.upload_rounded),
              label: const Text(
                'Upload Files',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              onPressed: onUpload,
            ),
            const SizedBox(height: 12),
            Text(
              'Supports: PDF, JPG, PNG, MP4, MKV, DOCX, PPTX, MP3 & more',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── No Results State ─────────────────────────────────────────────────────────
class _NoResultsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 54,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No files found',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Try changing the filter or search query.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}


