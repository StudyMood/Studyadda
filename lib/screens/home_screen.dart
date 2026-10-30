import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/study_stats_header.dart';
import '../widgets/subject_card.dart';
import '../widgets/video_tile.dart';
import 'admin_panel_screen.dart';
import 'favorites_screen.dart';
import 'media_library_screen.dart';
import 'pdf_notes_screen.dart';
import 'subject_detail_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catalog = context.watch<CatalogProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final isSearching = catalog.searchQuery.trim().isNotEmpty;
    final searchResults = catalog.searchResults;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Study Hub',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          // Media Library Button
          IconButton(
            icon: const Icon(Icons.perm_media_rounded),
            tooltip: 'Media Library',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MediaLibraryScreen(),
                ),
              );
            },
          ),

          // Admin Studio Button
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded),
            tooltip: 'Admin Management Studio',
            onPressed: () => _showAdminLoginDialog(context),
          ),

          // Theme Toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFFFD166) : AppColors.lightTextPrimary,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => themeProvider.toggleTheme(context),
          ),

          // Lock / Exit Session button
          IconButton(
            icon: const Icon(Icons.lock_outline_rounded),
            tooltip: 'Lock Study Hub',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Lock Study Hub?'),
                  content: const Text(
                    'This will clear decrypted keys from memory. You will need your password to unlock again.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.favorite,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        catalog.lock();
                      },
                      child: const Text('Lock Now'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SearchBarWidget(
                query: catalog.searchQuery,
                onChanged: (val) => catalog.setSearchQuery(val),
                onClear: () => catalog.clearSearch(),
              ),
            ),

            // Main Body Area
            Expanded(
              child: isSearching
                  ? _buildSearchResults(context, searchResults, catalog.searchQuery)
                  : _buildMainContent(context, catalog),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    List<IndexedLecture> results,
    String query,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 54,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No videos found for "$query"',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Try searching by subject name, unit, or lecture number (e.g. "Unit 2" or "L-1").',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Text(
            '${results.length} ${results.length == 1 ? 'RESULT' : 'RESULTS'}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: results.length,
            itemBuilder: (ctx, index) {
              final item = results[index];
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
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, CatalogProvider catalog) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // Stats Overview Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: StudyStatsHeader(
              onFavoritesTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                );
              },
            ),
          ),
        ),

        // Section Title: Subjects
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SUBJECTS (${catalog.subjects.length})',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primary),
                  label: const Text(
                    'All Notes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  onPressed: () {
                    PdfNotesSheet.show(context);
                  },
                ),
              ],
            ),
          ),
        ),

        // Responsive Grid of Subjects
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverLayoutBuilder(
            builder: (ctx, constraints) {
              final width = constraints.crossAxisExtent;
              int crossAxisCount = 2;
              if (width < 500) {
                crossAxisCount = 1;
              } else if (width < 750) {
                crossAxisCount = 2;
              } else if (width < 1100) {
                crossAxisCount = 3;
              } else {
                crossAxisCount = 4;
              }

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final subject = catalog.subjects[index];
                    return SubjectCard(
                      subject: subject,
                      index: index,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubjectDetailScreen(
                              subject: subject,
                              subjectIndex: index,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: catalog.subjects.length,
                ),
              );
            },
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Admin Studio Login', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Admin PIN to manage subjects, units, videos, and study materials.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              obscureText: false,
              autofocus: true,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Admin PIN / Passcode (1234)',
                hintText: 'Default PIN is 1234',
                prefixIcon: const Icon(Icons.password_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) {
                _verifyAndOpenAdmin(context, ctx, pinController.text);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _verifyAndOpenAdmin(context, ctx, pinController.text);
            },
            child: const Text('Access Admin'),
          ),
        ],
      ),
    );
  }

  void _verifyAndOpenAdmin(BuildContext parentContext, BuildContext dialogContext, String pin) {
    final catalog = parentContext.read<CatalogProvider>();
    final isAuthorized = catalog.verifyAdminPin(pin);
    if (!dialogContext.mounted) return;
    Navigator.pop(dialogContext);

    if (isAuthorized) {
      if (!parentContext.mounted) return;
      catalog.ensureAdminReady();
      Navigator.push(
        parentContext,
        MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
      );
    } else {
      if (!parentContext.mounted) return;
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
          content: Text('Invalid Admin PIN! Default PIN is 1234.'),
          backgroundColor: AppColors.favorite,
        ),
      );
    }
  }
}
