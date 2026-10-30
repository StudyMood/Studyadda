import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/pdf_resource.dart';
import '../models/video_lecture.dart';
import '../providers/catalog_provider.dart';
import '../utils/app_colors.dart';
import 'video_player_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddSubjectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subject Name',
            hintText: 'e.g., OPERATING SYSTEMS (OS)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                context.read<CatalogProvider>().addSubject(text);
                Navigator.pop(ctx);
                _showToast(context, 'Subject added successfully!');
              }
            },
            child: const Text('Add Subject'),
          ),
        ],
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, int index, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Subject Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                context.read<CatalogProvider>().updateSubject(index, text);
                Navigator.pop(ctx);
                _showToast(context, 'Subject updated!');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubject(BuildContext context, int index, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text('Are you sure you want to delete "$name" and all its units and lectures?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.favorite, foregroundColor: Colors.white),
            onPressed: () {
              context.read<CatalogProvider>().deleteSubject(index);
              Navigator.pop(ctx);
              _showToast(context, 'Subject deleted.');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddUnitDialog(BuildContext context, int subjectIndex, String subjectName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Unit to $subjectName'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Unit / Topic Name',
            hintText: 'e.g., Unit 1: Introduction & Architecture',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                context.read<CatalogProvider>().addUnit(subjectIndex, text);
                Navigator.pop(ctx);
                _showToast(context, 'Unit added!');
              }
            },
            child: const Text('Add Unit'),
          ),
        ],
      ),
    );
  }

  void _showEditUnitDialog(BuildContext context, int subjectIndex, int unitIndex, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Unit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Unit Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                context.read<CatalogProvider>().updateUnit(subjectIndex, unitIndex, text);
                Navigator.pop(ctx);
                _showToast(context, 'Unit updated!');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUnit(BuildContext context, int subjectIndex, int unitIndex, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit?'),
        content: Text('Are you sure you want to delete "$name" and its lectures?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.favorite, foregroundColor: Colors.white),
            onPressed: () {
              context.read<CatalogProvider>().deleteUnit(subjectIndex, unitIndex);
              Navigator.pop(ctx);
              _showToast(context, 'Unit deleted.');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showVideoDialog(
    BuildContext context, {
    required int subjectIndex,
    required int unitIndex,
    int? videoIndex,
    VideoLecture? existing,
  }) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final numberController = TextEditingController(text: existing?.lectureNumber?.toString() ?? '');
    final urlController = TextEditingController(text: existing?.resolvedUrl ?? '');
    final tagsController = TextEditingController(text: existing?.tags ?? '');

    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Video Lecture' : 'Add New Video Lecture'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Lecture Title *',
                  hintText: 'e.g., L-1 Introduction to Concept',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Lecture Number',
                  hintText: 'e.g., 1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL *',
                  hintText: 'YouTube link, MP4 URL, or .m3u8 stream',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (Optional)',
                  hintText: 'e.g., basics, algorithms, notes',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final url = urlController.text.trim();
              if (title.isEmpty || url.isEmpty) {
                _showToast(context, 'Please enter title and video URL.');
                return;
              }
              final lecNum = int.tryParse(numberController.text.trim());
              final key = isEdit ? existing.key : 'lec_${DateTime.now().millisecondsSinceEpoch}';

              final lecture = VideoLecture(
                key: key,
                title: title,
                lectureNumber: lecNum,
                tags: tagsController.text.trim(),
                resolvedUrl: url,
              );

              final provider = context.read<CatalogProvider>();
              if (isEdit) {
                provider.updateVideo(subjectIndex, unitIndex, videoIndex!, lecture);
                _showToast(context, 'Lecture updated!');
              } else {
                provider.addVideo(subjectIndex, unitIndex, lecture);
                _showToast(context, 'Lecture added successfully!');
              }
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Save Changes' : 'Add Lecture'),
          ),
        ],
      ),
    );
  }

  void _showAddPdfDialog(BuildContext context, {PdfResource? existing, int? existingIndex}) {
    final catalog = context.read<CatalogProvider>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final urlController = TextEditingController(text: existing?.url ?? '');
    final sizeController = TextEditingController(text: existing?.fileSize ?? '2.5 MB');
    final unitController = TextEditingController(text: existing?.unitName ?? '');

    String selectedSubject = existing?.subjectName ??
        (catalog.subjects.isNotEmpty ? catalog.subjects.first.name : 'DATA STRUCTURES (DS)');

    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit PDF Material' : 'Upload / Add PDF Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Material Title *',
                    hintText: 'e.g., Unit 1 Formulas & Questions',
                  ),
                ),
                const SizedBox(height: 12),
                if (catalog.subjects.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: catalog.subjects.any((s) => s.name == selectedSubject)
                        ? selectedSubject
                        : catalog.subjects.first.name,
                    decoration: const InputDecoration(labelText: 'Subject *'),
                    items: catalog.subjects.map((s) {
                      return DropdownMenuItem(value: s.name, child: Text(s.name, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedSubject = val);
                      }
                    },
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit / Topic (Optional)',
                    hintText: 'e.g., Unit 1: Introduction',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'PDF / Document Link *',
                    hintText: 'https://... (Direct link, Drive link or Telegram link)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sizeController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated File Size',
                    hintText: 'e.g., 3.4 MB',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final url = urlController.text.trim();
                if (title.isEmpty || url.isEmpty) {
                  _showToast(context, 'Please enter title and URL.');
                  return;
                }

                final resource = PdfResource(
                  id: isEdit ? existing.id : 'pdf_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  subjectName: selectedSubject,
                  unitName: unitController.text.trim().isEmpty ? null : unitController.text.trim(),
                  url: url,
                  fileSize: sizeController.text.trim().isEmpty ? null : sizeController.text.trim(),
                );

                if (isEdit) {
                  catalog.updatePdfResource(existingIndex!, resource);
                  _showToast(context, 'PDF material updated!');
                } else {
                  catalog.addPdfResource(resource);
                  _showToast(context, 'PDF material added!');
                }
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Save' : 'Upload'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Admin PIN'),
        content: TextField(
          controller: pinController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New 4-Digit PIN',
            hintText: 'e.g., 5678',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newPin = pinController.text.trim();
              if (newPin.isNotEmpty) {
                context.read<CatalogProvider>().updateAdminPin(newPin);
                Navigator.pop(ctx);
                _showToast(context, 'Admin PIN updated successfully!');
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  void _showChangeAccessPasswordDialog(BuildContext context) {
    final catalog = context.read<CatalogProvider>();
    final controller = TextEditingController(text: catalog.accessPassword);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Student Access Passcode'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Access Passcode (Short password)',
            hintText: 'e.g., 1234',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newPw = controller.text.trim();
              if (newPw.isNotEmpty) {
                catalog.updateAccessPassword(newPw);
                Navigator.pop(ctx);
                _showToast(context, 'Student access passcode updated!');
              }
            },
            child: const Text('Save Passcode'),
          ),
        ],
      ),
    );
  }

  void _showEditTelegramDialog(BuildContext context, String currentLink) {
    final controller = TextEditingController(text: currentLink);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Community / Telegram Link'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Telegram or Community URL'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final link = controller.text.trim();
              if (link.isNotEmpty) {
                context.read<CatalogProvider>().updateTelegramLink(link);
                Navigator.pop(ctx);
                _showToast(context, 'Telegram link updated!');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final catalog = context.read<CatalogProvider>();
    final jsonStr = catalog.exportCatalogJson();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Course Catalog (JSON)'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Copy this JSON to backup, share, or embed into assets/encrypted_catalog.json:'),
              const SizedBox(height: 10),
              Container(
                height: 240,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              _showToast(context, 'Catalog JSON copied to clipboard!');
            },
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Course Catalog (JSON)'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste catalog JSON below to replace and update courses immediately:'),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '{\n  "subjects": [...]\n}',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Import Now'),
            onPressed: () async {
              final jsonStr = controller.text.trim();
              if (jsonStr.isEmpty) return;
              final success = await context.read<CatalogProvider>().importCatalogJson(jsonStr);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                if (success) {
                  _showToast(context, 'Catalog imported successfully!');
                } else {
                  _showToast(context, 'Invalid JSON format. Please verify.');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catalog = context.watch<CatalogProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Admin Management Studio', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.auto_stories_rounded), text: 'Courses & Units'),
            Tab(icon: Icon(Icons.picture_as_pdf_rounded), text: 'PDF Materials'),
            Tab(icon: Icon(Icons.settings_suggest_rounded), text: 'Backup & Settings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Export Catalog JSON',
            onPressed: () => _showExportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Import Catalog JSON',
            onPressed: () => _showImportDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Subjects, Units & Lectures
          _buildCoursesTab(context, catalog, isDark),

          // Tab 2: PDF Resources & Materials
          _buildPdfsTab(context, catalog, isDark),

          // Tab 3: Backup & Settings
          _buildSettingsTab(context, catalog, isDark),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Subject', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _showAddSubjectDialog(context),
            )
          : _tabController.index == 1
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Add PDF', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () => _showAddPdfDialog(context),
                )
              : null,
    );
  }

  Widget _buildCoursesTab(BuildContext context, CatalogProvider catalog, bool isDark) {
    if (catalog.subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('No courses added yet.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Click "+ Add Subject" below to create your first course.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add New Subject'),
              onPressed: () => _showAddSubjectDialog(context),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: catalog.subjects.length,
      itemBuilder: (context, sIdx) {
        final subject = catalog.subjects[sIdx];
        final hue = AppColors.getSubjectColor(sIdx);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          elevation: 0,
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: hue, borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    '${sIdx + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              title: Text(
                subject.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              subtitle: Text(
                '${subject.units.length} Units · ${subject.totalVideos} Lectures',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit Subject',
                    onPressed: () => _showEditSubjectDialog(context, sIdx, subject.name),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.favorite),
                    tooltip: 'Delete Subject',
                    onPressed: () => _confirmDeleteSubject(context, sIdx, subject.name),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'UNITS (${subject.units.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: () => _showAddUnitDialog(context, sIdx, subject.name),
                      ),
                    ],
                  ),
                ),
                if (subject.units.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No units in this subject yet. Tap "Add Unit" above.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...subject.units.asMap().entries.map((uEntry) {
                    final uIdx = uEntry.key;
                    final unit = uEntry.value;

                    return Container(
                      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: ExpansionTile(
                        leading: const Icon(Icons.folder_outlined, size: 22, color: AppColors.primary),
                        title: Text(unit.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text('${unit.videos.length} Lectures', style: const TextStyle(fontSize: 11.5)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.primary),
                              tooltip: 'Add Video Lecture',
                              onPressed: () => _showVideoDialog(context, subjectIndex: sIdx, unitIndex: uIdx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit Unit',
                              onPressed: () => _showEditUnitDialog(context, sIdx, uIdx, unit.name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.favorite),
                              tooltip: 'Delete Unit',
                              onPressed: () => _confirmDeleteUnit(context, sIdx, uIdx, unit.name),
                            ),
                          ],
                        ),
                        children: [
                          if (unit.videos.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No videos added yet. Click (+) above to add a lecture.'),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              itemCount: unit.videos.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (ctx, vIdx) {
                                final vid = unit.videos[vIdx];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    child: Text(
                                      '${vid.lectureNumber ?? vIdx + 1}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  title: Text(vid.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  subtitle: vid.resolvedUrl != null
                                      ? Text(
                                          vid.resolvedUrl!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11),
                                        )
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.play_circle_outline_rounded, size: 20, color: AppColors.primary),
                                        tooltip: 'Test Play Video',
                                        onPressed: () => VideoPlayerModal.show(
                                          context,
                                          video: vid,
                                          subjectName: subject.name,
                                          unitName: unit.name,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        tooltip: 'Edit Video',
                                        onPressed: () => _showVideoDialog(
                                          context,
                                          subjectIndex: sIdx,
                                          unitIndex: uIdx,
                                          videoIndex: vIdx,
                                          existing: vid,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.favorite),
                                        tooltip: 'Delete Video',
                                        onPressed: () {
                                          catalog.deleteVideo(sIdx, uIdx, vIdx);
                                          _showToast(context, 'Video lecture removed.');
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPdfsTab(BuildContext context, CatalogProvider catalog, bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Community / Telegram Group Link Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.secondary.withValues(alpha: 0.08)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.send_rounded, color: AppColors.primary, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Official Community / Telegram Link', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      catalog.telegramLink ?? 'https://t.me/StudyHubOfficialNotes',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                tooltip: 'Edit Telegram Link',
                onPressed: () => _showEditTelegramDialog(context, catalog.telegramLink ?? 'https://t.me/StudyHubOfficialNotes'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'UPLOADED PDF MATERIALS (${catalog.pdfResources.length})',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add PDF Material', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              onPressed: () => _showAddPdfDialog(context),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (catalog.pdfResources.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No PDF materials uploaded yet. Tap "Add PDF Material" above.')),
          )
        else
          ...catalog.pdfResources.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              elevation: 0,
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.favorite.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.favorite, size: 22),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text(
                  '${item.subjectName}${item.unitName != null ? " · ${item.unitName}" : ""}${item.fileSize != null ? " · ${item.fileSize}" : ""}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit PDF',
                      onPressed: () => _showAddPdfDialog(context, existing: item, existingIndex: idx),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.favorite),
                      tooltip: 'Delete PDF',
                      onPressed: () {
                        catalog.deletePdfResource(item.id);
                        _showToast(context, 'PDF material removed.');
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSettingsTab(BuildContext context, CatalogProvider catalog, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Security card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          elevation: 0,
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Admin Security & PIN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Protect your Admin Management Studio with a custom 4-digit PIN (Default is 1234).',
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  icon: const Icon(Icons.pin_rounded, size: 18),
                  label: const Text('Change Admin PIN'),
                  onPressed: () => _showChangePinDialog(context),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Student Access Passcode Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          elevation: 0,
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key_rounded, color: AppColors.secondary),
                    const SizedBox(width: 10),
                    const Text('Student Access Passcode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.watch<CatalogProvider>().accessPassword,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.secondary, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'The short passcode required by students to unlock the study hub (Default is 1234). It is shown on the unlock screen for students.',
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                  icon: const Icon(Icons.password_rounded, size: 18),
                  label: const Text('Change Student Passcode'),
                  onPressed: () => _showChangeAccessPasswordDialog(context),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Backup and Sync Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          elevation: 0,
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.backup_outlined, color: AppColors.success),
                    SizedBox(width: 10),
                    Text('Backup & JSON Sync', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Export your custom courses to a clean JSON file, or restore / import an existing catalog from backup.',
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Export JSON'),
                        onPressed: () => _showExportDialog(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.upload_rounded, size: 18),
                        label: const Text('Import JSON'),
                        onPressed: () => _showImportDialog(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Reset Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.favorite.withValues(alpha: 0.3)),
          ),
          elevation: 0,
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.favorite),
                    SizedBox(width: 10),
                    Text('Reset Catalog', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.favorite)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Clear all custom modifications and restore original default sample syllabus courses.',
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.favorite, side: const BorderSide(color: AppColors.favorite)),
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Reset to Default Courses'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset Catalog?'),
                        content: const Text('This will delete all custom subjects and revert to sample data.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.favorite, foregroundColor: Colors.white),
                            onPressed: () {
                              catalog.resetToSampleCatalog();
                              Navigator.pop(ctx);
                              _showToast(context, 'Reset to sample courses.');
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
