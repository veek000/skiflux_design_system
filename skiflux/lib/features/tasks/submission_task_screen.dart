import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/error_handling/error_handler.dart';
import '../../shared/sheets/success_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import 'data/episode_tasks_repository.dart';
import 'data/tasks_store.dart';
import 'task_shared_widgets.dart';

// Figma: Task flow 12–09 — submission detail (`1256:14112`, upload
// `1256:14245`, file row `1256:14313`).

class SubmissionTaskScreen extends ConsumerStatefulWidget {
  const SubmissionTaskScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<SubmissionTaskScreen> createState() =>
      _SubmissionTaskScreenState();
}

class _SubmissionTaskScreenState extends ConsumerState<SubmissionTaskScreen> {
  int _method = 0; // 0 = Link URL, 1 = File Upload
  final _linkController = TextEditingController();
  final _noteController = TextEditingController();
  UploadedFileInfo? _file;
  bool _submitting = false;

  /// Default extension set for tasks that declare no `accepted_proof_types`
  /// (Figma lists a subset; product supports the broader set below).
  static const _defaultAllowed = <String>[
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'pdf',
    'zip',
    'rar',
    '7z',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'csv',
    'ppt',
    'pptx',
    'mp3',
    'wav',
    'm4a',
    'mp4',
    'mov',
    'webm',
    'txt',
  ];

  /// Proof "types" the creator can declare (`["link","image","video","file"]`
  /// per the spec) → concrete picker extensions. Raw extension tokens pass
  /// through so a creator writing `["pdf"]` also works.
  static const _proofTypeExtensions = <String, List<String>>{
    'image': ['png', 'jpg', 'jpeg', 'gif', 'webp'],
    'screenshot': ['png', 'jpg', 'jpeg', 'gif', 'webp'],
    'photo': ['png', 'jpg', 'jpeg', 'gif', 'webp'],
    'video': ['mp4', 'mov', 'webm'],
    'audio': ['mp3', 'wav', 'm4a'],
    'voice': ['mp3', 'wav', 'm4a'],
    'file': [
      'pdf', 'zip', 'rar', '7z', 'doc', 'docx',
      'xls', 'xlsx', 'csv', 'ppt', 'pptx', 'txt',
    ],
    'document': ['pdf', 'doc', 'docx', 'txt'],
    'archive': ['zip', 'rar', '7z'],
  };

  /// The task's allowlist: creator-declared proof types when present,
  /// otherwise the product default.
  List<String> get _allowed {
    final types =
        ref.read(tasksProvider).byId(widget.taskId)?.acceptedProofTypes ??
        const [];
    if (types.isEmpty) return _defaultAllowed;
    final out = <String>{};
    for (final raw in types) {
      final type = raw.trim().toLowerCase();
      if (type.isEmpty || type == 'link' || type == 'url' || type == 'text') {
        continue; // link/text proofs have no file extension.
      }
      final mapped = _proofTypeExtensions[type];
      if (mapped != null) {
        out.addAll(mapped);
      } else if (_defaultAllowed.contains(type)) {
        out.add(type);
      }
    }
    return out.isEmpty ? _defaultAllowed : out.toList(growable: false);
  }

  /// "PNG, JPG, PDF … · Max 10MB" from the live allowlist. When the creator
  /// narrowed the formats we show exactly those; the default set keeps the
  /// Figma's representative subset to avoid a wall of extensions.
  String get _dropzoneCaption {
    final allowed = _allowed;
    final shown = identical(allowed, _defaultAllowed)
        ? const ['png', 'jpg', 'pdf', 'zip', 'doc', 'xls', 'ppt', 'mp3', 'mp4']
        : (allowed.length > 9 ? allowed.sublist(0, 9) : allowed);
    return '${shown.map((e) => e.toUpperCase()).join(', ')} · Max 10MB';
  }

  @override
  void dispose() {
    _linkController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_submitting) return false;
    if (_method == 0) return _linkController.text.trim().isNotEmpty;
    return _file != null;
  }

  Future<void> _pickFile() async {
    // file_picker 12 flipped `pickFiles` to multi-select by default and added
    // `pickFile` for the single-file case. A submission takes exactly one
    // file, so use `pickFile` — otherwise the picker would let the user choose
    // several and we would silently keep only the first.
    PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: _allowed,
      );
    } on PlatformException {
      // SAF picker refused to open (no document provider / OS denial).
      if (!mounted) return;
      SkifluxToast.error(context, "Couldn't open the file picker. Try again.");
      return;
    }
    if (picked == null) return; // User cancelled the OS picker — not an error.
    // Re-bind after the null check: promotion of a nullable local does not
    // carry into a closure body, and the `_file` assignment below happens
    // inside `setState`.
    final file = picked;
    // The dropzone copy promises "Max 10MB" — hold the line client-side.
    if (file.size > 10 * 1024 * 1024) {
      if (!mounted) return;
      SkifluxToast.error(context, 'That file is over the 10MB limit.');
      return;
    }
    final ext = (file.extension ?? 'file').toLowerCase();
    final sizeMb = file.size / (1024 * 1024);
    final sizeLabel = sizeMb >= 0.1
        ? '${sizeMb.toStringAsFixed(sizeMb >= 10 ? 0 : 1)} MB'
        : '${(file.size / 1024).toStringAsFixed(0)} KB';
    setState(() {
      _file = UploadedFileInfo(
        name: file.name,
        extensionLabel: ext.toUpperCase(),
        sizeLabel: sizeLabel,
        path: file.path,
      );
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    try {
      // Link method: require a usable http(s) URL before sending.
      // Invalid input surfaces as a task-submission failure (modal) via
      // the centralized error layer.
      String? link;
      if (_method == 0) {
        link = _linkController.text.trim();
          if (!link.toLowerCase().startsWith('http://') && !link.toLowerCase().startsWith('https://')) {
            link = 'https://$link';
          }
          final uri = Uri.tryParse(link);
        final valid =
            uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty;
        if (!valid) {
          throw const SkifluxFailure(SkifluxErrorKind.taskSubmission);
        }
      }

      final task = ref.read(tasksProvider).byId(widget.taskId);
      if (task == null) {
        throw const SkifluxFailure(SkifluxErrorKind.taskSubmission);
      }

      // Live tasks upload for real via `POST /episodes/task/submit`; the
      // success sheet appears only after the server's 2xx. Demo (signed-out)
      // seeds keep the local-only flow.
      if (task.fromBackend) {
        final episodeId = task.episodeId;
        if (episodeId == null) {
          throw const SkifluxFailure(SkifluxErrorKind.taskSubmission);
        }
        final note = _noteController.text.trim();
        setState(() => _submitting = true);
        try {
          final repo = ref.read(episodeTasksRepositoryProvider);
          if (_method == 0) {
            await repo.submitProjectLink(
              episodeId: episodeId,
              url: link!,
              note: note.isEmpty ? null : note,
            );
          } else {
            final file = _file!;
            final path = file.path;
            if (path == null || path.isEmpty) {
              // Picker returned no readable path — nothing to upload.
              throw const SkifluxFailure(SkifluxErrorKind.taskSubmission);
            }
            await repo.submitProjectFile(
              episodeId: episodeId,
              filePath: path,
              fileName: file.name,
              note: note.isEmpty ? null : note,
            );
          }
        } finally {
          if (mounted) setState(() => _submitting = false);
        }
      }

      ref.read(tasksProvider.notifier).markInReview(widget.taskId);
      if (!mounted) return;
      // Confirmation rides the app-wide overlay pattern (blur + scrim +
      // headerless card) rather than a centred Material Dialog — same shell
      // every other success state in the app uses.
      await showSuccessSheet(
        context,
        title: 'Task Submitted!',
        message:
            'Your work is in review. You\'ll be notified when it\'s '
            'approved — usually within 24 hours.',
        buttonLabel: 'Back to Tasks',
      );
      // Any dismissal — button, close circle, scrim tap, swipe-down — returns
      // to the task list, which is what the old barrier-locked dialog did on
      // its single action.
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e, st) {
      if (!mounted) return;
      // Centralized classify → toast/modal + crash-report hook. The picked
      // file / link stays in place so the user can retry without redoing it.
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch so the detail screen rebuilds if task status mutates while open.
    final task = ref.watch(tasksProvider).byId(widget.taskId);
    if (task == null) {
      return Scaffold(
        appBar: SkifluxTopNavBar(
          label: 'Task Details',
          labelStyle: SkifluxTypography.headingH8Bold,
          leading: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(RemixIcons.arrow_left_s_line),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text('Task not found')),
      );
    }

    // Sticky CTA is a Column sibling (not an overlay) — only need side-equal
    // Space/L under the last field so scroll end matches L/R gutters.
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Task Details',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              children: [
                Text(
                  task.title,
                  style: SkifluxTypography.headingH7Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                if (task.hasAnyReward) ...[
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  TaskRewardPill(task: task),
                ],
                const SizedBox(height: SkifluxSpacing.spaceL),
                TaskEpisodeRow(
                  title: task.episodeTitle,
                  subtitle: task.episodeSubtitle,
                  onTap: () => openTaskEpisode(context, ref, task),
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                _BriefCard(
                  intro: task.briefIntro ?? '',
                  bullets: task.briefBullets,
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                Text(
                  'Submission Method',
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentSecondary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceS),
                SkifluxSegmentedControl(
                  labels: const ['Link URL', 'File Upload'],
                  selectedIndex: _method,
                  onChanged: (i) => setState(() => _method = i),
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                if (_method == 0)
                  SkifluxInputField(
                    controller: _linkController,
                    hintText: 'Paste your link here',
                    leadingIcon: const Icon(RemixIcons.link),
                    onChanged: (_) => setState(() {}),
                    fieldKey: const ValueKey('link_input'),
                  )
                else ...[
                  _DashedUploadZone(onTap: _pickFile, caption: _dropzoneCaption),
                  if (_file != null) ...[
                    const SizedBox(height: SkifluxSpacing.spaceS),
                    _UploadedFileRow(
                      file: _file!,
                      onRemove: () => setState(() => _file = null),
                    ),
                  ],
                ],
                const SizedBox(height: SkifluxSpacing.spaceL),
                Text(
                  'Add a note (Optional)',
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentSecondary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceS),
                _NoteField(controller: _noteController),
              ],
            ),
          ),
          // Sticky submit — matches Figma sticky CTA rail.
          Material(
            color: SkifluxColors.backgroundPrimary,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                ),
                child: SkifluxButton(
                  // Promise coins only when the task actually declares them.
                  label: task.hasCoinReward
                      ? 'Submit Task & Earn ${task.coinsLabel} coins'
                      : 'Submit Task',
                  expanded: true,
                  loading: _submitting,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pieces ───────────────────────────────────────────────────────────

class _BriefCard extends StatelessWidget {
  const _BriefCard({required this.intro, required this.bullets});

  final String intro;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundPrimary,
        borderRadius: SkifluxRadii.borderL,
        border: Border.all(
          color: SkifluxColors.contentSecondaryInverse,
          width: SkifluxBorderWidth.xs,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The Brief',
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
          if (intro.isNotEmpty) ...[
            const SizedBox(height: SkifluxSpacing.spaceXs),
            Text(
              intro,
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
          ],
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: SkifluxSpacing.spaceS),
            for (final b in bullets) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    RemixIcons.check_double_fill,
                    size: 16,
                    color: SkifluxColors.contentPositive,
                  ),
                  const SizedBox(width: SkifluxSpacing.spaceS),
                  Expanded(
                    child: Text(
                      b,
                      style: SkifluxTypography.bodyP10Regular.copyWith(
                        color: SkifluxColors.contentTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SkifluxSpacing.spaceS),
            ],
          ],
        ],
      ),
    );
  }
}

/// Figma `1256:14245` — dashed dropzone with upload-cloud icon.
class _DashedUploadZone extends StatelessWidget {
  const _DashedUploadZone({required this.onTap, required this.caption});

  final VoidCallback onTap;

  /// Accepted-format line, derived from the task's real allowlist.
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: SkifluxRadii.borderL,
        child: CustomPaint(
          painter: _DashedRRectPainter(
            color: SkifluxColors.contentDisabled,
            radius: SkifluxRadii.l,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SkifluxSpacing.spaceL,
                vertical: SkifluxSpacing.spaceXl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    RemixIcons.upload_cloud_2_line,
                    size: SkifluxIcons.sizeM,
                    color: SkifluxColors.contentSecondary,
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  Text(
                    'Tap to upload screenshot or file',
                    textAlign: TextAlign.center,
                    style: SkifluxTypography.uiInputContent.copyWith(
                      color: SkifluxColors.contentSecondary,
                    ),
                  ),
                  Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: SkifluxTypography.bodyP11Regular.copyWith(
                      color: SkifluxColors.contentDisabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = SkifluxBorderWidth.xs;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 6.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

/// Figma `1256:14327` — pending-task-style file chip with type icon.
class _UploadedFileRow extends StatelessWidget {
  const _UploadedFileRow({required this.file, required this.onRemove});

  final UploadedFileInfo file;
  final VoidCallback onRemove;

  static IconData iconFor(String ext) {
    switch (ext.toLowerCase()) {
      case 'zip':
      case 'rar':
      case '7z':
        return RemixIcons.file_zip_fill;
      case 'pdf':
        return RemixIcons.file_pdf_fill;
      case 'doc':
      case 'docx':
        return RemixIcons.file_word_fill;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return RemixIcons.file_excel_fill;
      case 'ppt':
      case 'pptx':
        return RemixIcons.file_ppt_fill;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return RemixIcons.file_music_fill;
      case 'mp4':
      case 'mov':
      case 'webm':
        return RemixIcons.file_video_fill;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return RemixIcons.file_image_fill;
      case 'txt':
        return RemixIcons.file_text_fill;
      default:
        return RemixIcons.file_3_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundHover,
        borderRadius: SkifluxRadii.borderX,
      ),
      child: Row(
        children: [
          // Brand-100 circle + type glyph (Figma avatar slot ≈ 48 outer).
          Padding(
            padding: const EdgeInsets.all(SkifluxSpacing.spaceS),
            child: Container(
              width: SkifluxUnit.u48,
              height: SkifluxUnit.u48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: SkifluxColors.backgroundPrimaryBrand,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconFor(file.extensionLabel),
                size: 20,
                color: SkifluxColors.contentBrand,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                Text(
                  '${file.extensionLabel} • ${file.sizeLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.bodyP11Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ),
          // 48×48 trash hit target (Figma Main Avatar).
          SizedBox(
            width: SkifluxUnit.u48,
            height: SkifluxUnit.u48,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onRemove,
              icon: const Icon(
                RemixIcons.delete_bin_fill,
                size: 16,
                color: SkifluxColors.contentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: SkifluxTypography.bodyP10Regular.copyWith(
        color: SkifluxColors.contentPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Add a note about your approach (optional)',
        hintStyle: SkifluxTypography.bodyP10Regular.copyWith(
          color: SkifluxColors.contentTertiary,
        ),
        filled: true,
        fillColor: SkifluxColors.backgroundPrimary,
        contentPadding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        border: OutlineInputBorder(
          borderRadius: SkifluxRadii.borderL,
          borderSide: const BorderSide(
            color: SkifluxColors.borderTertiary,
            width: SkifluxBorderWidth.xs,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SkifluxRadii.borderL,
          borderSide: const BorderSide(
            color: SkifluxColors.borderTertiary,
            width: SkifluxBorderWidth.xs,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SkifluxRadii.borderL,
          borderSide: const BorderSide(
            color: SkifluxColors.borderFocus,
            width: SkifluxBorderWidth.m,
          ),
        ),
      ),
    );
  }
}
