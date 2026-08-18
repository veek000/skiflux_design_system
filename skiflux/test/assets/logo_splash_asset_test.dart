/// The splash composition, checked against what the renderer can actually draw.
///
/// The exported file arrived with the white→purple background change carried by
/// an After Effects **layer effect** (`ADBE Fill`) on a solid. lottie-flutter
/// implements exactly two layer effects — blur and drop shadow — and drops the
/// rest with a warning, so the background stayed white for the whole run and the
/// white logo and wordmark that fade in at frame 60 were invisible on it. The
/// asset now expresses that colour as an ordinary animated shape fill, which
/// every Lottie player supports.
///
/// It also arrived with its one track matte pair in the wrong order, which
/// painted the wordmark's purple wipe rectangle over the artwork instead of
/// using it to reveal the wordmark. See the matte tests below.
///
/// A fresh export from After Effects will reintroduce both. That is what these
/// tests are for: they fail with the renderer's own warning text, so the fix is
/// to flatten the effect into the shape and re-order the matte pair (or re-run
/// the conversion) rather than to ship a white screen again.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

const _asset = 'assets/animations/logo_splash.json';

/// The brand purple the background lands on, as Lottie stores colour: unit
/// components rather than 0–255. `#5610AB`.
const _purple = [0.337254911661, 0.06274510175, 0.670588254929, 1.0];

Future<LottieComposition> _load() =>
    LottieComposition.fromBytes(File(_asset).readAsBytesSync());

Map<String, dynamic> _json() =>
    jsonDecode(File(_asset).readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('the composition loads with nothing the renderer had to skip', () async {
    final composition = await _load();

    expect(
      composition.warnings,
      isEmpty,
      reason: 'lottie-flutter silently drops what it cannot draw; a warning '
          'here is a part of the animation that will not appear on a device',
    );
  });

  test('no layer carries an effect', () {
    // Narrower than the warning check, and it names the culprit: `ef` is the
    // layer-effects array, and everything the design needs can be expressed
    // without one.
    final layers = (_json()['layers'] as List).cast<Map<String, dynamic>>();
    final offenders = layers
        .where((layer) => layer.containsKey('ef'))
        .map((layer) => layer['nm'])
        .toList();

    expect(offenders, isEmpty);
  });

  test('the background still animates from white to brand purple', () {
    // The one thing the effect was doing. Without it the splash is a white
    // rectangle for five seconds — the exact symptom this asset shipped with.
    final layers = (_json()['layers'] as List).cast<Map<String, dynamic>>();
    final background = layers.firstWhere((layer) => layer['nm'] == 'White Solid 1');
    final group = (background['shapes'] as List).first as Map<String, dynamic>;
    final fill = (group['it'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((item) => item['ty'] == 'fl');
    final colour = fill['c'] as Map<String, dynamic>;

    expect(colour['a'], 1, reason: 'the fill colour must be animated');
    final keyframes = (colour['k'] as List).cast<Map<String, dynamic>>();
    expect((keyframes.first['s'] as List).cast<num>(), [1, 1, 1, 1]);
    expect(
      (keyframes.last['s'] as List).cast<num>().map((c) => c.toDouble()),
      _purple,
    );
  });

  test('every track matte sits directly above the layer it mattes', () {
    // The second thing this file arrived wrong. Lottie pairs a matte with its
    // subject *positionally* — `CompositionLayer` walks the array from the
    // bottom up and hands each `tt` layer the layer immediately above it — and
    // there is no `tp` (matte-parent) support in lottie-flutter 3.5.1 to say
    // otherwise. The export had the pair the other way round, so the wordmark
    // took the white logo as its matte and the purple wipe rectangle, which is
    // `td` and must never be painted, was drawn as an ordinary layer: a purple
    // box across the logo and wordmark from frame 69 to the end of the run.
    final layers = (_json()['layers'] as List).cast<Map<String, dynamic>>();

    for (var i = 0; i < layers.length; i++) {
      if (layers[i]['td'] == 1) {
        expect(
          i + 1 < layers.length ? layers[i + 1]['tt'] : null,
          isNotNull,
          reason:
              '"${layers[i]['nm']}" is matte artwork with nothing below it to '
              'matte, so the renderer will paint it',
        );
      }
      if (layers[i]['tt'] != null) {
        expect(
          i > 0 ? layers[i - 1]['td'] : null,
          1,
          reason:
              '"${layers[i]['nm']}" would take the wrong layer as its matte',
        );
      }
    }
  });

  test('the wipe rectangle is matte artwork, not something to draw', () {
    // Names the offender directly: a 633×157 rect filled with the same brand
    // purple as the background, which is why the bug read as "another purple
    // box" rather than as a stray shape.
    final layers = (_json()['layers'] as List).cast<Map<String, dynamic>>();
    final mask = layers.firstWhere((layer) => layer['nm'] == 'Mask');
    final group = (mask['shapes'] as List).first as Map<String, dynamic>;
    final fill = (group['it'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((item) => item['ty'] == 'fl');

    expect(mask['td'], 1);
    expect(
      (fill['c']['k'] as List).cast<num>().map((c) => c.toDouble()).toList(),
      _purple.map((c) => closeTo(c, 0.001)),
      reason: 'if this ever stops being the brand purple the symptom changes '
          'but the defect does not',
    );
  });

  test('it covers the full frame, so nothing shows through behind it', () {
    // `BoxFit.cover` crops the composition to the screen; a background that
    // does not fill the composition would leak the Scaffold at the edges.
    final doc = _json();
    final layers = (doc['layers'] as List).cast<Map<String, dynamic>>();
    final background = layers.firstWhere((layer) => layer['nm'] == 'White Solid 1');
    final group = (background['shapes'] as List).first as Map<String, dynamic>;
    final rect = (group['it'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((item) => item['ty'] == 'rc');

    expect((rect['s']['k'] as List).cast<num>(), [doc['w'], doc['h']]);
    expect(background['ip'], doc['ip']);
    expect(background['op'], greaterThanOrEqualTo(doc['op'] as num));
  });
}
