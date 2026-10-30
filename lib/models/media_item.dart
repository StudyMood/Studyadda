
enum MediaType { pdf, image, video, document, audio, other }

class MediaItem {
  final String id;
  final String name;
  final MediaType type;
  final String? filePath; // Local file path (Windows/Desktop)
  final String? fileBytes; // Base64 encoded bytes (Web)
  final int sizeBytes;
  final String? subject;
  final String? description;
  final List<String> tags;
  final DateTime createdAt;
  final String? thumbnailBytes; // Base64 thumbnail for images

  MediaItem({
    required this.id,
    required this.name,
    required this.type,
    this.filePath,
    this.fileBytes,
    required this.sizeBytes,
    this.subject,
    this.description,
    this.tags = const [],
    required this.createdAt,
    this.thumbnailBytes,
  });

  static MediaType typeFromExtension(String ext) {
    final lower = ext.toLowerCase();
    if (lower == 'pdf') return MediaType.pdf;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'].contains(lower)) {
      return MediaType.image;
    }
    if (['mp4', 'mkv', 'avi', 'mov', 'webm', 'flv', 'wmv'].contains(lower)) {
      return MediaType.video;
    }
    if (['doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'csv'].contains(lower)) {
      return MediaType.document;
    }
    if (['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'].contains(lower)) {
      return MediaType.audio;
    }
    return MediaType.other;
  }

  String get typeLabel {
    switch (type) {
      case MediaType.pdf:
        return 'PDF';
      case MediaType.image:
        return 'Image';
      case MediaType.video:
        return 'Video';
      case MediaType.document:
        return 'Document';
      case MediaType.audio:
        return 'Audio';
      case MediaType.other:
        return 'File';
    }
  }

  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'filePath': filePath,
        'fileBytes': fileBytes,
        'sizeBytes': sizeBytes,
        'subject': subject,
        'description': description,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'thumbnailBytes': thumbnailBytes,
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: json['id'] as String,
        name: json['name'] as String,
        type: MediaType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MediaType.other,
        ),
        filePath: json['filePath'] as String?,
        fileBytes: json['fileBytes'] as String?,
        sizeBytes: json['sizeBytes'] as int,
        subject: json['subject'] as String?,
        description: json['description'] as String?,
        tags: List<String>.from(json['tags'] as List? ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
        thumbnailBytes: json['thumbnailBytes'] as String?,
      );

  MediaItem copyWith({
    String? id,
    String? name,
    MediaType? type,
    String? filePath,
    String? fileBytes,
    int? sizeBytes,
    String? subject,
    String? description,
    List<String>? tags,
    DateTime? createdAt,
    String? thumbnailBytes,
  }) =>
      MediaItem(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        filePath: filePath ?? this.filePath,
        fileBytes: fileBytes ?? this.fileBytes,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        subject: subject ?? this.subject,
        description: description ?? this.description,
        tags: tags ?? this.tags,
        createdAt: createdAt ?? this.createdAt,
        thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      );
}
