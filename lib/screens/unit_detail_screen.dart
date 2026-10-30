import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../models/unit.dart';
import '../providers/study_progress_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/video_tile.dart';
import 'pdf_notes_screen.dart';
import 'video_player_screen.dart';

class UnitDetailScreen extends StatelessWidget {
  final CourseSubject subject;
  final CourseUnit unit;
  final int unitIndex;

  const UnitDetailScreen({
    super.key,
    required this.subject,
    required this.unit,
    required this.unitIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = context.watch<StudyProgressProvider>();

    int unitCompleted = 0;
    for (final v in unit.videos) {
      if (progress.isCompleted(v.key)) {
        unitCompleted++;
      }
    }
    final double unitPct = unit.videos.isNotEmpty
        ? (unitCompleted / unit.videos.length).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              unit.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subject.name,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            tooltip: 'Unit PDF Notes',
            onPressed: () {
              PdfNotesSheet.show(
                context,
                subjectName: subject.name,
                unitName: unit.name,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Unit progress strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$unitCompleted of ${unit.videos.length} videos finished',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            '${(unitPct * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: unitPct,
                          minHeight: 5,
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            unitPct == 1.0 ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Video list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: unit.videos.length,
              itemBuilder: (ctx, index) {
                final video = unit.videos[index];
                return VideoTile(
                  video: video,
                  subtitle: video.lectureNumber != null ? 'Lecture ${video.lectureNumber}' : null,
                  onPlay: () {
                    VideoPlayerModal.show(
                      context,
                      video: video,
                      subjectName: subject.name,
                      unitName: unit.name,
                    );
                  },
                  onPdfNotes: () {
                    PdfNotesSheet.show(
                      context,
                      subjectName: subject.name,
                      unitName: unit.name,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
