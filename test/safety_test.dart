import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Phase 2.6 — packaging & child-safety checks that need **no device**.
///
/// They read the repository itself (`pubspec.yaml`, `lib/`, `assets/`), so they
/// run in the very same `flutter test` pass as the pure-logic tests and guard
/// the promises we make to parents: no ads, no purchases, no tracking, no
/// external links, and every asset the code names really exists.
void main() {
  String read(String path) => File(path).readAsStringSync();

  List<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList();

  /// Comments talk about things (https, "share") — only code counts.
  String withoutComments(String source) {
    final String noBlock =
        source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    return noBlock
        .split('\n')
        .map((String line) => line.split('//').first)
        .join('\n');
  }

  group('what must NOT ship', () {
    test('pubspec declares no ads, purchases, tracking or network packages', () {
      final String yaml = read('pubspec.yaml').toLowerCase();
      const List<String> banned = <String>[
        'google_mobile_ads',
        'admob',
        'in_app_purchase',
        'purchases_flutter',
        'firebase',
        'analytics',
        'mixpanel',
        'amplitude',
        'crashlytics',
        'sentry',
        'url_launcher',
        'webview',
        'share_plus',
        'http:',
        'dio:',
        'supabase',
        'graphql',
        'facebook',
        'appsflyer',
        'adjust_',
      ];
      for (final String needle in banned) {
        expect(yaml.contains(needle), isFalse,
            reason: '"$needle" must never ship in a kids game');
      }
    });

    test('lib/ opens no link and makes no network request', () {
      final RegExp forbidden = RegExp(
        r'(https?://|package:http/|package:dio/|url_launcher|HttpClient)',
      );
      final List<String> offenders = <String>[];
      for (final File file in dartFiles('lib')) {
        if (forbidden.hasMatch(withoutComments(file.readAsStringSync()))) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty);
    });

    test('no stray prints (release logs stay quiet)', () {
      final List<String> offenders = <String>[];
      for (final File file in dartFiles('lib')) {
        if (RegExp(r'(^|[^t])print\(').hasMatch(withoutComments(file.readAsStringSync()))) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty);
    });
  });

  group('assets the code names really exist', () {
    test('every audio path has a file on disk', () {
      const String assets = 'lib/core/constants/assets.dart';
      final Iterable<RegExpMatch> matches = RegExp(
        r"static const String \w+ = '([^']+\.mp3)'",
      ).allMatches(read(assets));

      expect(matches.length, 11,
          reason: '11 cues are expected (10 sfx + 1 music loop)');

      for (final RegExpMatch match in matches) {
        final String path = match.group(1)!;
        expect(
          File('assets/$path').existsSync() || File(path).existsSync(),
          isTrue,
          reason: 'missing audio file: $path',
        );
      }
    });

    test('every asset directory declared in pubspec exists', () {
      final Iterable<RegExpMatch> dirs = RegExp(
        r'^\s*-\s+(assets/[^\s]+/)\s*$',
        multiLine: true,
      ).allMatches(read('pubspec.yaml'));

      expect(dirs, isNotEmpty);
      for (final RegExpMatch match in dirs) {
        final String dir = match.group(1)!;
        expect(Directory(dir).existsSync(), isTrue,
            reason: 'pubspec declares a directory that is not there: $dir');
      }
    });
  });

  group('the grown-ups gate stays strong where it matters', () {
    test('the gate has nothing to read (GDD: textless)', () {
      final String gate = read('lib/core/utils/parent_gate.dart');
      expect(gate.contains('Text('), isFalse,
          reason: 'the gate and its dialog must stay textless');
      expect(gate.contains('ParentGate('), isTrue,
          reason: 'the hold-to-unlock widget is the whole point');
    });

    test('erasing data asks for two displaced holds', () {
      const String doubleHold =
          'showParentGateDialog(context, doubleHold: true)';
      expect(read('lib/features/settings/settings_screen.dart')
          .contains(doubleHold), isTrue,
          reason: 'resetting everything is irreversible');
      expect(read('lib/features/gallery/gallery_screen.dart')
          .contains(doubleHold), isTrue,
          reason: 'deleting a design is irreversible too');
    });

    test('every destructive call site sits behind the gate', () {
      const Map<String, List<String>> destructive = <String, List<String>>{
        'lib/features/settings/settings_screen.dart': <String>[
          'resetProgress()',
          'deleteAllDesignImages()',
        ],
        'lib/features/gallery/gallery_screen.dart': <String>[
          'deleteDesignImage(',
          'removeDesign(',
        ],
      };

      destructive.forEach((String path, List<String> calls) {
        final String code = read(path);
        expect(code.contains('showParentGateDialog'), isTrue,
            reason: '$path erases data and must ask the gate first');
        for (final String call in calls) {
          expect(code.contains(call), isTrue,
              reason: '$call is expected to live in $path');
        }
      });
    });

    test('no visible string is longer than four words', () {
      final RegExp literal = RegExp(r"Text\(\s*'((?:[^'\\]|\\.)*)'");
      final List<String> offenders = <String>[];

      for (final File file in dartFiles('lib')) {
        final String code = withoutComments(file.readAsStringSync());
        for (final RegExpMatch match in literal.allMatches(code)) {
          final String visible = match
              .group(1)!
              .replaceAll(RegExp(r'\$\{[^}]*\}'), '')
              .trim();
          final int words = visible
              .split(RegExp(r'\s+'))
              .where((String word) => RegExp('[A-Za-z]').hasMatch(word))
              .length;
          if (words > 4) {
            offenders.add('${file.path}: "$visible" ($words words)');
          }
        }
      }

      expect(offenders, isEmpty,
          reason: 'GDD: in-app text is decorative and at most 4 words');
    });
  });

  group('the child-safety rules stay wired in', () {
    test('every screen keeps the shared home + mute skeleton', () {
      const Map<String, String> screens = <String, String>{
        // (Home builds its own top bar — it is checked separately below.)
        'characters': 'character_select_screen',
        'spa': 'spa_screen',
        'studio': 'nail_studio_screen',
        'reveal': 'reveal_screen',
        'gallery': 'gallery_screen',
        'rewards': 'rewards_screen',
        'settings': 'settings_screen',
        'achievements': 'achievements_screen',
        'gift_rooms': 'gift_rooms_screen',
      };

      for (final MapEntry<String, String> entry in screens.entries) {
        final File file = File('lib/features/${entry.key}/${entry.value}.dart');
        expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
        final String code = file.readAsStringSync();
        expect(code.contains('KidScreen('), isTrue,
            reason: '${entry.value} must use the shared skeleton');
      }

      // Home builds its own top bar, so it is checked for both corners.
      final String home = read('lib/features/home/home_screen.dart');
      expect(home.contains('QuickMuteButton'), isTrue,
          reason: 'Home must keep the mute button in the top-right corner');
      expect(home.contains('ParentGate('), isTrue,
          reason: 'Home settings must sit behind the grown-ups gate');
    });

    test('the shared skeleton always offers Home top-left', () {
      final String skeleton = read('lib/widgets/kid_screen.dart');
      expect(skeleton.contains('Icons.home_rounded'), isTrue,
          reason: 'the home corner must exist');
      expect(skeleton.contains('goHome(context)'), isTrue,
          reason: 'the home button must really go home');

      // A screen with its own "one level up" action still keeps Home.
      final String room = read('lib/features/gift_rooms/gift_room_screen.dart');
      expect(room.contains('KidScreen('), isTrue);
      expect(room.contains('onBack:'), isTrue);
    });

    test('destructive actions sit behind the parent gate', () {
      expect(
        read('lib/features/settings/settings_screen.dart')
            .contains('showParentGateDialog'),
        isTrue,
      );
      expect(
        read('lib/features/gallery/gallery_screen.dart')
            .contains('showParentGateDialog'),
        isTrue,
      );
    });

    test('every route used by a screen exists and is registered', () {
      final String routes = read('lib/core/router/app_routes.dart');
      final String router = read('lib/core/router/app_router.dart');

      const List<String> names = <String>[
        'splash', 'home', 'characters', 'spa', 'studio', 'reveal',
        'gallery', 'rewards', 'stars', 'gifts', 'settings',
      ];

      for (final String name in names) {
        expect(routes.contains('$name = '), isTrue,
            reason: 'AppRoutes.$name is missing');
        expect(router.contains('AppRoutes.$name'), isTrue,
            reason: 'route $name is not registered in the router');
      }
    });
  });
}
