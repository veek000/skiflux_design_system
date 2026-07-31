/// The learner's selected SkillWorld — the gradient pill on My Profile and,
/// per the Figma copy, what the feed / tasks / gigs are filtered by.
///
/// Signed in, the selection is real: it hydrates from `GET /me/profile`
/// (`skillworld`) and persists via the existing profile repository's
/// `PATCH /me/update`; the public `GET /skillworlds` catalogue drives which
/// worlds the Change SkillWorld sheet offers. Signed out it stays a local
/// demo selection.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import '../../../shared/network/token_store.dart';
import 'profile_repository.dart';
import 'profile_store.dart';

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

  /// The wire value (`UserSkillworldEnum`) — enum names match the spec's
  /// lowercase vocabulary exactly for all ten worlds authored here.
  String get backendValue => name;

  /// Resolves the world a sign-up selection refers to. The auth flow stores its
  /// choice as a plain [String] (that state predates this enum), so the two are
  /// reconciled by [label] when sign-up hands off to the profile store.
  static SkillWorld? fromLabel(String? label) {
    for (final world in values) {
      if (world.label == label) return world;
    }
    return null;
  }

  /// Resolves a backend `skillworld` value ("design", "ai", …) to its enum,
  /// or null for values with no authored art/copy here (the spec also has
  /// `code` and `writing` — see [skillWorldOptionsProvider]).
  static SkillWorld? fromBackendValue(String? value) {
    if (value == null) return null;
    final needle = value.trim().toLowerCase();
    for (final world in values) {
      if (world.name == needle) return world;
    }
    return null;
  }
}

/// `GET /skillworlds` — the public catalogue of selectable worlds.
///
/// The spec declares no response schema ("Skillworlds retrieved."), so
/// [parseSkillWorlds] accepts a bare array, a `{data: [...]}` envelope, and
/// entries that are plain strings or `{value|slug|name|key|label}` maps.
class SkillWorldsRepository extends ApiRepository {
  const SkillWorldsRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  Future<List<String>> list() => guard(() async {
    final response = await dio.get<dynamic>('/skillworlds');
    return parseSkillWorlds(response.data);
  });

  static List<String> parseSkillWorlds(Object? body) {
    Object? raw = body;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      raw = map['data'] ?? map['skillworlds'] ?? map['results'] ?? raw;
      if (raw is Map) {
        final inner = Map<String, dynamic>.from(raw);
        raw = inner['skillworlds'] ?? inner['results'] ?? raw;
      }
    }
    if (raw is! List) return const [];
    final values = <String>[];
    for (final entry in raw) {
      String? value;
      if (entry is String) {
        value = entry;
      } else if (entry is Map) {
        for (final key in const ['value', 'slug', 'name', 'key', 'label']) {
          final candidate = entry[key];
          if (candidate is String && candidate.trim().isNotEmpty) {
            value = candidate;
            break;
          }
        }
      }
      final normalized = value?.trim().toLowerCase();
      if (normalized != null &&
          normalized.isNotEmpty &&
          !values.contains(normalized)) {
        values.add(normalized);
      }
    }
    return values;
  }
}

final skillWorldsRepositoryProvider = Provider<SkillWorldsRepository>(
  (ref) => SkillWorldsRepository(ref.watch(apiClientProvider)),
);

/// The worlds the Change SkillWorld sheet offers — the enum (art/labels)
/// filtered to what the backend currently lists.
///
/// Backend values with no enum representation are dropped: the spec's
/// vocabulary also contains `code` and `writing`, which have no authored
/// card art/copy here (a known mismatch — the enum stays the render source).
/// A failed or unusable fetch falls back to the full enum so the sheet is
/// never empty; this is the app's own catalogue, not fabricated user data.
final skillWorldOptionsProvider = FutureProvider<List<SkillWorld>>((
  ref,
) async {
  try {
    final names = await ref.read(skillWorldsRepositoryProvider).list();
    final available = [
      for (final world in SkillWorld.values)
        if (names.contains(world.backendValue)) world,
    ];
    return available.isEmpty ? SkillWorld.values : available;
  } catch (_) {
    return SkillWorld.values;
  }
});

/// Riverpod choice: [NotifierProvider] — a single mutable selection.
///
/// [build] watches [meProfileProvider], so the pill hydrates from the
/// signed-in profile's `skillworld` and re-syncs whenever the profile
/// refreshes; [selectAndPersist] writes the choice back through the existing
/// profile repository (`PATCH /me/update` supports `skillworld`).
class SkillWorldNotifier extends Notifier<SkillWorld> {
  @override
  SkillWorld build() {
    final profile = ref.watch(meProfileProvider).value;
    if (profile != null) {
      for (final value in profile.skillworld) {
        final world = SkillWorld.fromBackendValue(value);
        if (world != null) return world;
      }
    }
    return SkillWorld.design;
  }

  /// Local-only selection — used by onboarding before a profile exists.
  void select(SkillWorld world) => state = world;

  /// Optimistic select + persist: the pill flips immediately, the PATCH runs
  /// behind it, and a failure rolls the pill back and rethrows so the caller
  /// surfaces the error. Signed out this is just [select] (demo session).
  Future<void> selectAndPersist(SkillWorld world) async {
    final previous = state;
    if (previous == world) return;
    state = world;
    bool session;
    try {
      session = await ref.read(tokenStoreProvider).hasSession();
    } catch (_) {
      session = false;
    }
    if (!session) return;
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(skillworld: [world.backendValue]);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final skillWorldProvider = NotifierProvider<SkillWorldNotifier, SkillWorld>(
  SkillWorldNotifier.new,
);
