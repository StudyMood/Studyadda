import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/video_lecture.dart';
import '../providers/catalog_provider.dart';
import '../providers/study_progress_provider.dart';
import '../services/media_resolver_service.dart';
import '../utils/app_colors.dart';
import 'pdf_notes_screen.dart';

class VideoPlayerModal extends StatefulWidget {
  final VideoLecture video;
  final String subjectName;
  final String unitName;

  const VideoPlayerModal({
    super.key,
    required this.video,
    required this.subjectName,
    required this.unitName,
  });

  static Future<void> show(
    BuildContext context, {
    required VideoLecture video,
    required String subjectName,
    required String unitName,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: VideoPlayerModal(
          video: video,
          subjectName: subjectName,
          unitName: unitName,
        ),
      ),
    );
  }

  @override
  State<VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  bool _isLoading = true;
  String? _resolvedUrl;
  String? _error;
  double _selectedSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _resolveUrl();
  }

  Future<void> _resolveUrl() async {
    final catalog = context.read<CatalogProvider>();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = await catalog.resolveVideoUrl(widget.video);
      if (mounted) {
        setState(() {
          _resolvedUrl = url;
          _isLoading = false;
          if (url == null || url.isEmpty) {
            _error = 'Unable to resolve video URL. Please check password or connection.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Decryption error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchVideo() async {
    if (_resolvedUrl == null || _resolvedUrl!.isEmpty) return;
    final uri = Uri.parse(_resolvedUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch video')),
        );
      }
    }
  }

  Future<void> _launchVlc() async {
    if (_resolvedUrl == null || _resolvedUrl!.isEmpty) return;
    final vlcUri = Uri.parse('vlc://${_resolvedUrl!}');
    if (await canLaunchUrl(vlcUri)) {
      await launchUrl(vlcUri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to direct URL
      await _launchVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = context.watch<StudyProgressProvider>();
    final isDone = progress.isCompleted(widget.video.key);
    final isFav = progress.isFavorite(widget.video.key);

    final isYt = _resolvedUrl != null && MediaResolverService.isYouTube(_resolvedUrl!);
    final isHls = _resolvedUrl != null && MediaResolverService.isHlsStream(_resolvedUrl!);

    return Container(
      constraints: const BoxConstraints(maxWidth: 640),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.subjectName} · ${widget.unitName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Player preview / Status banner
          Container(
            width: double.infinity,
            height: 180,
            color: Colors.black,
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text(
                          'Unlocking video stream...',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.favorite, size: 36),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _resolveUrl,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background gradient / subtle design
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF141E30), Color(0xFF243B55)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _launchVideo,
                                  borderRadius: BorderRadius.circular(40),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.5),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isYt
                                    ? 'YouTube Lecture'
                                    : (isHls ? 'HLS Adaptive Stream' : 'Online Video Lecture'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
          ),

          // Speed selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(
              children: [
                Text(
                  'Playback Speed:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  children: [0.75, 1.0, 1.25, 1.5, 2.0].map((spd) {
                    final selected = _selectedSpeed == spd;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedSpeed = spd);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${spd}x',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.open_in_browser_rounded, size: 20),
                        label: const Text('Play / Open Video', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: _resolvedUrl != null ? _launchVideo : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          side: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy Link', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: _resolvedUrl != null
                            ? () {
                                Clipboard.setData(ClipboardData(text: _resolvedUrl!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Video link copied to clipboard!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          side: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.ondemand_video_rounded, size: 18),
                        label: const Text('Open in VLC', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: _resolvedUrl != null ? _launchVlc : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDone ? AppColors.success : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          side: BorderSide(
                            color: isDone ? AppColors.success : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 18),
                        label: Text(
                          isDone ? 'Completed' : 'Mark Done',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          progress.toggleCompleted(widget.video.key);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // PDF notes & Favorite toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primary),
                      label: const Text(
                        'PDF Notes for this Unit',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        PdfNotesSheet.show(
                          context,
                          subjectName: widget.subjectName,
                          unitName: widget.unitName,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? AppColors.favorite : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                      onPressed: () {
                        progress.toggleFavorite(widget.video.key);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
