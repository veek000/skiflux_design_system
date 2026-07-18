import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/sheets/skiflux_sheet.dart';

// Figma: Episode Resources from More Menu (`1256:27145`).

Future<void> showEpisodeResourcesSheet(BuildContext context) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => const _EpisodeResourcesSheet(),
  );
}

class _EpisodeResourcesSheet extends StatelessWidget {
  const _EpisodeResourcesSheet();

  static const _files = <(String, String, IconData)>[
    ('design_tokens.fig', 'FIG · 4.2 MB', RemixIcons.file_3_fill),
    ('component_kit.zip', 'ZIP · 12 MB', RemixIcons.file_zip_fill),
    ('episode_notes.pdf', 'PDF · 890 KB', RemixIcons.file_pdf_fill),
    ('color_styles.xlsx', 'XLS · 210 KB', RemixIcons.file_excel_fill),
  ];

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: 'Episode Resources',
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        itemCount: _files.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: SkifluxSpacing.spaceS),
        itemBuilder: (context, i) {
          final (name, meta, icon) = _files[i];
          return Container(
            padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
            decoration: BoxDecoration(
              color: SkifluxColors.backgroundHover,
              borderRadius: SkifluxRadii.borderX,
            ),
            child: Row(
              children: [
                Container(
                  width: SkifluxUnit.u48,
                  height: SkifluxUnit.u48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: SkifluxColors.backgroundPrimaryBrand,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: SkifluxColors.contentBrand,
                  ),
                ),
                const SizedBox(width: SkifluxSpacing.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: SkifluxTypography.headingH10Bold.copyWith(
                          color: SkifluxColors.contentPrimary,
                        ),
                      ),
                      Text(
                        meta,
                        style: SkifluxTypography.bodyP11Regular.copyWith(
                          color: SkifluxColors.contentTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading $name…'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(
                    RemixIcons.download_2_line,
                    color: SkifluxColors.contentBrand,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
