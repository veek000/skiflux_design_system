import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../data/legal_documents.dart';

/// Figma: **Terms of Use Screen** (`1277:32411`) and **Privacy Policy Screen**
/// (`1277:32341`).
///
/// Both frames are the same screen with different copy — a centred nav title
/// with a back chevron, then one long scroll: the "Last Updated" line, an
/// unnumbered intro paragraph, and numbered sections of prose and bullet
/// lists. So this is one widget driven by a [LegalDocument]; the copy itself
/// lives in `data/legal_documents.dart`.
///
/// Section headings are `Heading/H10 bold` at 16, body is `Body/p9 regular` at
/// 14 in `content/tertiary`, and both documents close on a semibold
/// `content/secondary` contact address.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document, required this.onBack});

  final LegalDocument document;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: document.title,
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: onBack,
        ),
        // Balances the back chevron so the title stays optically centred
        // (`I1277:32413;62:1699` is centred on the frame, not on the space
        // left of the icon).
        trailing: const SizedBox(width: SkifluxSpacing.spaceXl),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          children: [
            // `1277:32420` — bold, primary, unlike the tertiary body below it.
            Text(
              document.lastUpdated,
              style: SkifluxTypography.uiButtonMedium.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              document.intro,
              style: SkifluxTypography.bodyP9Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            for (final section in document.sections) ...[
              // Sections sit Space/S apart; heading to body is Space/XS.
              const SizedBox(height: SkifluxSpacing.spaceS),
              Text(
                section.heading,
                style: SkifluxTypography.headingH10Bold.copyWith(
                  color: SkifluxColors.contentPrimary,
                ),
              ),
              const SizedBox(height: SkifluxSpacing.spaceXs),
              for (final block in section.blocks) _LegalBlockView(block: block),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegalBlockView extends StatelessWidget {
  const _LegalBlockView({required this.block});

  final LegalBlock block;

  @override
  Widget build(BuildContext context) {
    final body = SkifluxTypography.bodyP9Regular.copyWith(
      color: SkifluxColors.contentTertiary,
    );
    return switch (block) {
      LegalParagraph(:final text, :final trailingBold) => Padding(
        // Figma's paragraph-spacing/0 is 8, applied below a paragraph that is
        // followed by more copy in the same section.
        padding: const EdgeInsets.only(bottom: SkifluxSpacing.spaceS),
        child: Text.rich(
          TextSpan(
            style: body,
            children: [
              TextSpan(text: text),
              if (trailingBold != null)
                TextSpan(
                  text: trailingBold,
                  style: SkifluxTypography.bodyP9Semibold.copyWith(
                    color: SkifluxColors.contentSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
      LegalBullets(:final items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final item in items) _LegalBulletView(item: item)],
      ),
    };
  }
}

/// A single `list-disc` row. Flutter has no list markup, so the marker is a
/// literal bullet in a fixed-width gutter — that keeps wrapped lines aligned
/// under the text rather than under the dot.
class _LegalBulletView extends StatelessWidget {
  const _LegalBulletView({required this.item});

  final LegalBullet item;

  /// Figma's `ms-[21px]` marker indent, rounded to the nearest token.
  static const _indent = SkifluxSpacing.spaceXl;

  @override
  Widget build(BuildContext context) {
    final body = SkifluxTypography.bodyP9Regular.copyWith(
      color: SkifluxColors.contentTertiary,
    );
    return Padding(
      padding: EdgeInsets.only(
        left: item.nested ? _indent : 0,
        bottom: SkifluxSpacing.spaceXs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _indent,
            child: Text('•', style: body, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: body,
                children: [
                  if (item.lead != null)
                    TextSpan(
                      text: '${item.lead} ',
                      style: SkifluxTypography.bodyP9Semibold.copyWith(
                        color: SkifluxColors.contentTertiary,
                      ),
                    ),
                  TextSpan(text: item.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
