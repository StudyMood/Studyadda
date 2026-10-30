import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/study_progress_provider.dart';
import '../utils/app_colors.dart';
import 'pdf_notes_screen.dart';
import 'unit_detail_screen.dart';

class SubjectDetailScreen extends StatelessWidget {
  final CourseSubject subject;
  final int subjectIndex;

  const SubjectDetailScreen({
    super.key,
    required this.subject,
    required this.subjectIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hue = AppColors.getSubjectColor(subjectIndex);
    final progress = context.watch<StudyProgressProvider>();

    final subjectProgress = progress.getSubjectProgress(subject);
    final completedCount = progress.getSubjectCompletedCount(subject);
    final totalVideos = subject.totalVideos;

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            tooltip: 'Subject PDF Notes',
            onPressed: () {
              PdfNotesSheet.show(
                context,
                subjectName: subject.name,
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header summary banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      hue.withValues(alpha: isDark ? 0.25 : 0.12),
                      hue.withValues(alpha: isDark ? 0.08 : 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: hue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                '${subject.units.length} Units · $totalVideos Total Lectures',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completedCount of $totalVideos finished',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          '${(subjectProgress * 100).toInt()}% Done',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: hue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalVideos > 0 ? subjectProgress : 0,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          subjectProgress == 1.0 ? AppColors.success : hue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                'UNITS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ),

          // Units list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, ui) {
                  final unit = subject.units[ui];
                  int unitDone = 0;
                  for (final v in unit.videos) {
                    if (progress.isCompleted(v.key)) unitDone++;
                  }
                  final bool allDone = unit.videos.isNotEmpty && unitDone == unit.videos.length;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: allDone
                            ? AppColors.success.withValues(alpha: 0.4)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: const Color(0xFF14213A).withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => UnitDetailScreen(
                                subject: subject,
                                unit: unit,
                                unitIndex: ui,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: allDone
                                      ? AppColors.success.withValues(alpha: 0.15)
                                      : hue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: allDone
                                      ? const Icon(Icons.check_rounded, color: AppColors.success, size: 20)
                                      : Text(
                                          '${ui + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: hue,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      unit.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${unit.videos.length} videos · $unitDone completed',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: subject.units.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}
