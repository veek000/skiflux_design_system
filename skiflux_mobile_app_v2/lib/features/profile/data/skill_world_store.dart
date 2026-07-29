/// The learner's selected SkillWorld — the gradient pill on My Profile and,
/// per the Figma copy, what the feed / tasks / gigs are filtered by. Static
/// in-memory demo state only, mirroring the other feature stores.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

/// Figma: **Choose your Skillworld** (`2897:12161`) — the ten worlds offered at
/// sign-up, reused verbatim by the "Change SkillWorld" sheet on Profile
/// (`1256:24173`). One list, two surfaces: the sign-up grid and the profile
/// sheet both iterate [SkillWorld.values], so the order here is the order the
/// user sees in both places.
///
/// Copy note — two Figma authoring slips are deliberately **not** reproduced:
/// the Crypto card repeats Health's caption ("Fitness, Biohacking, Performance
/// Routines"), and the AI card's title is authored as `"AI "` with a trailing
/// space.
enum SkillWorld {
  design(
    label: 'Design',
    icon: RemixIcons.brush_fill,
    skills: 'UI/UX, Graphic Design, Motion',
  ),
  engineering(
    label: 'Engineering',
    icon: RemixIcons.braces_fill,
    skills: 'Frontend, Backend, Mobile Dev',
  ),
  marketing(
    label: 'Marketing',
    icon: RemixIcons.megaphone_fill,
    skills: 'Growth, SEO, Content Creation',
  ),
  product(
    label: 'Product',
    icon: RemixIcons.lightbulb_flash_fill,
    skills: 'Product Management, Agile, Strategy',
  ),
  business(
    label: 'Business',
    icon: RemixIcons.briefcase_4_fill,
    skills: 'Sales, Negotiation, E-commerce',
  ),
  lifestyle(
    label: 'Lifestyle',
    icon: RemixIcons.compass_3_fill,
    skills: 'Personal Branding, Networking, Mindset',
  ),
  health(
    label: 'Health',
    icon: RemixIcons.heart_pulse_fill,
    skills: 'Fitness, Biohacking, Performance Routines',
  ),
  entrepreneur(
    label: 'Entrepreneur',
    icon: RemixIcons.store_2_fill,
    skills: 'Tailoring, Barbing, Culinary Arts, Local Services',
  ),
  crypto(
    label: 'Crypto',
    icon: RemixIcons.bit_coin_fill,
    skills: 'Trading, Web3, DeFi Fundamentals',
  ),

  /// Figma draws a bespoke "ai" vector here rather than a named Remix glyph —
  /// the only world without one. `sparkling-2-fill` is the closest match in the
  /// library and keeps the grid on a single icon source; swap it for an
  /// exported SVG if the custom mark is ever published as an asset.
  ai(
    label: 'AI',
    icon: RemixIcons.sparkling_2_fill,
    skills: 'AI Prompting, No-Code Tools, Automation, Data',
  );

  const SkillWorld({
    required this.label,
    required this.icon,
    required this.skills,
  });

  final String label;
  final IconData icon;

  /// Card sub-label listing what the world covers.
  final String skills;

  /// Label on the My Profile pill — Figma shows "Design World" (`1256:24041`).
  String get pillLabel => '$label World';

  /// Resolves the world a sign-up selection refers to. The auth flow stores its
  /// choice as a plain [String] (that state predates this enum), so the two are
  /// reconciled by [label] when sign-up hands off to the profile store.
  static SkillWorld? fromLabel(String? label) {
    for (final world in values) {
      if (world.label == label) return world;
    }
    return null;
  }
}

/// Riverpod choice: [NotifierProvider] — a single mutable selection with no
/// async source yet.
// TODO(backend, blocking): persist the selected SkillWorld on the authenticated user profile instead of session-only state — expects: {world: String} on GET/PATCH profile
class SkillWorldNotifier extends Notifier<SkillWorld> {
  @override
  SkillWorld build() => SkillWorld.design;

  void select(SkillWorld world) => state = world;
}

final skillWorldProvider = NotifierProvider<SkillWorldNotifier, SkillWorld>(
  SkillWorldNotifier.new,
);
