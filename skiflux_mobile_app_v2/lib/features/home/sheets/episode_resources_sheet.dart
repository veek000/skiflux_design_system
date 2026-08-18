/// Figma: Episode Resources from More Menu (`1256:27145`).
///
/// The files and links the creator attached to this episode, from
/// `Episode.resources`. This used to be four hardcoded rows —
/// `design_tokens.fig`, `component_kit.zip`, `episode_notes.pdf`,
/// `color_styles.xlsx` — shown on every episode in the app, downloadable by
/// nobody: the button toasted "Downloading…" and did nothing else.
///
/// A file downloads through the browser/OS handler and a link opens; both go
/// through [openExternalUrl] rather than being fetched into the app, because
/// these are arbitrary documents (Figma files, spreadsheets, ZIPs) that the app
/// has no viewer for.
library;

import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/sheets/skiflux_sheet.dart';
import '../../../shared/toast/skiflux_toast.dart';
import '../../../shared/utils/external_link.dart';
import '../data/episode_resource.dart';

Future<void> showEpisodeResourcesSheet(
  BuildContext context,
  List<EpisodeResource> resources,
) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => _EpisodeResourcesSheet(resources: resources),
  );
}

class _EpisodeResourcesSheet extends StatelessWidget {
  const _EpisodeResourcesSheet({required this.resources});

  final List<EpisodeResource> resources;

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: 'Episode Resources',
      count: resources.isEmpty ? null : resources.length,
      child: resources.isEmpty
          // The More Menu hides the entry point when there is nothing here, so
          // this is only reachable if the list emptied in between.
          ? const Padding(
              padding: EdgeInsets.all(SkifluxSpacing.space2xl),
              child: SkifluxEmptyState(
                icon: Icon(
                  RemixIcons.folder_open_line,
                  size: SkifluxEmptyState.iconSize,
                  color: SkifluxColors.contentBrand,
                ),
                title: 'No resources',
                message:
                    "This episode doesn't have any files or links attached.",
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              // Sheet drags down only when the list is at its top.
              controller: ModalScrollController.of(context),
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              itemCount: resources.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: SkifluxSpacing.spaceS),
              itemBuilder: (context, i) => _ResourceRow(resources[i]),
            ),
    );
  }
}

class _ResourceRow extends StatefulWidget {
  const _ResourceRow(this.resource);

  final EpisodeResource resource;

  @override
  State<_ResourceRow> createState() => _ResourceRowState();
}

class _ResourceRowState extends State<_ResourceRow> {
  var _downloading = false;

  Future<void> _open() async {
    final urlString = widget.resource.url ?? '';
    final url = Uri.tryParse(urlString);
    if (url == null || !url.hasScheme) {
      SkifluxToast.error(context, "That resource can't be opened");
      return;
    }

    if (widget.resource.isLink) {
      await openExternalUrl(context, url);
      return;
    }

    if (_downloading) return;
    setState(() => _downloading = true);
    
    SkifluxToast.info(context, 'Downloading resource...');

    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      
      var filename = url.pathSegments.isNotEmpty ? url.pathSegments.last : 'download';
      if (!filename.contains('.')) {
        filename = '$filename.pdf'; // simple fallback
      }
      
      final savePath = '${tempDir.path}/$filename';

      await dio.download(urlString, savePath);

      if (!mounted) return;
      await Share.shareXFiles([XFile(savePath)], text: widget.resource.displayName);
    } catch (e) {
      if (!mounted) return;
      SkifluxToast.error(context, "We couldn't download that file.");
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SkifluxColors.backgroundHover,
      borderRadius: SkifluxRadii.borderX,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
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
                child: _downloading
                    ? const SizedBox(
                        width: SkifluxUnit.u20,
                        height: SkifluxUnit.u20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SkifluxColors.contentBrand,
                        ),
                      )
                    : Icon(
                        widget.resource.icon,
                        size: SkifluxUnit.u20,
                        color: SkifluxColors.contentBrand,
                      ),
              ),
              const SizedBox(width: SkifluxSpacing.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.resource.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SkifluxTypography.headingH10Bold.copyWith(
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                    Text(
                      widget.resource.metaLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SkifluxTypography.bodyP11Regular.copyWith(
                        color: SkifluxColors.contentTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // The glyph says which of the two things the tap will do.
              Icon(
                widget.resource.isLink
                    ? RemixIcons.external_link_line
                    : RemixIcons.download_2_line,
                color: SkifluxColors.contentBrand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
