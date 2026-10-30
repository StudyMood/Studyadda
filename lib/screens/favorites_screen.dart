import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/study_progress_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/video_tile.dart';
import 'pdf_notes_screen.dart';
import 'video_player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = context.watch<StudyProgressProvider>();
    final catalog = context.watch<CatalogProvider>();

    final favLectures = catalog.flatLectures
        .where((item) => progress.isFavorite(item.video.key))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: AppColors.favorite, size: 22),
            const SizedBox(width: 8),
            Text('Favorites (${favLectures.length})'),
          ],
        ),
      ),
      body: favLectures.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.favorite.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 48,
                        color: AppColors.favorite,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No favorites yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap the heart icon on any video lecture to quickly save and access it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favLectures.length,
              itemBuilder: (ctx, index) {
                final item = favLectures[index];
                return VideoTile(
                  video: item.video,
                  subtitle: '${item.subjectName} · ${item.unitName}',
                  onPlay: () {
                    VideoPlayerModal.show(
                      context,
                      video: item.video,
                      subjectName: item.subjectName,
                      unitName: item.unitName,
                    );
                  },
                  onPdfNotes: () {
                    PdfNotesSheet.show(
                      context,
                      subjectName: item.subjectName,
                      unitName: item.unitName,
                    );
                  },
                );
              },
            ),
    );
  }
}
