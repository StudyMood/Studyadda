import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_lecture.dart';
import '../providers/study_progress_provider.dart';
import '../utils/app_colors.dart';

class VideoTile extends StatelessWidget {
  final VideoLecture video;
  final String? subtitle;
  final VoidCallback onPlay;
  final VoidCallback onPdfNotes;

  const VideoTile({
    super.key,
    required this.video,
    this.subtitle,
    required this.onPlay,
    required this.onPdfNotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progressProvider = context.watch<StudyProgressProvider>();

    final isFav = progressProvider.isFavorite(video.key);
    final isDone = progressProvider.isCompleted(video.key);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? AppColors.success.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF14213A).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPlay,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Play Icon Button
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.success
                        : (isDark ? AppColors.primaryDark : AppColors.primary),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDone ? AppColors.success : AppColors.primary).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Completion Toggle Button
                    IconButton(
                      icon: Icon(
                        isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isDone
                            ? AppColors.success
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        size: 22,
                      ),
                      tooltip: isDone ? 'Mark as incomplete' : 'Mark as completed',
                      onPressed: () {
                        progressProvider.toggleCompleted(video.key);
                      },
                    ),

                    // Favorite Button
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav
                            ? AppColors.favorite
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        size: 22,
                      ),
                      tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                      onPressed: () {
                        progressProvider.toggleFavorite(video.key);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFav ? 'Removed from favorites' : 'Added to favorites',
                            ),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    // PDF Notes Button
                    IconButton(
                      icon: const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      tooltip: 'PDF notes & resources',
                      onPressed: onPdfNotes,
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
}
