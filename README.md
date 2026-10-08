# ✨ Sparkle Nail Spa

A cute, **fully offline** nail-spa game for kids **ages 3–8**.
No accounts, no ads, no in-app purchases, no external links, no text to read —
just big friendly buttons, sparkles and happy sounds.

> The full design constitution lives in **[docs/sparkle-nail-spa-gdd.md](docs/sparkle-nail-spa-gdd.md)** (v1.7).
> Every implementation decision is measured against it.

---

## Current status

| Phase | Scope | State |
|---|---|---|
| **Phase 1 — Architecture** | models, storage, state management, routing, theme, helpers | ✅ done |
| **Phase 1 — Screens** | splash, home, characters, spa, studio, reveal, gallery, rewards, settings | ✅ done |
| **Phase 2.1 — Art & theme** | replaceable art layer, room backdrops, tablet layout, 7 real art assets | ✅ **done** |
| **Phase 2.2 — Audio** | `lib/core/audio/` engine + 11 real MP3 files (410 KB) | ✅ **done** |
| **Phase 2.3 — Motion** | shared motion engine, 9 screen entrances, full reveal choreography | ✅ **done** |
| **Phase 2.4 — Achievements** | pure engine, 14 badges, star wall screen, save durability fix | ✅ **done** |
| **Phase 2.5 — Gift rooms** | 4 pastel rooms, 12 one-time surprise boxes, 8 gift-only studio items, pure gift engine | ✅ **done** |
| **Phase 2.6 — Final QA** | full code review, 12 fixes (incl. the grown-ups gate), safety test suite, docs | 🔎 review + fixes ✅ · `flutter` tests ⏳ — see [docs/final-qa-report.md](docs/final-qa-report.md) |
| Phase 3 — Release | device testing, store screenshots, privacy policy, age rating | 🕐 |

### Achievements & star wall (Phase 2.4)

Three layers, exactly as specified:

| Layer | File | Testable without Flutter UI? |
|---|---|---|
| **Engine** (pure maths) | `lib/core/achievements/achievement_engine.dart` | ✅ yes — no widgets, no storage, no timers |
| **Facts** (a snapshot) | `lib/core/achievements/game_facts.dart` | ✅ yes |
| **Progress repository** | `data/models/progress_state.dart` + `local_storage_service.dart` | ✅ yes (json round trips) |
| **Star wall UI** | `lib/features/achievements/achievements_screen.dart` | widget layer |

* **14 badges** across spa steps, colour/sticker/ring/pattern variety, all six
  friends, daily streak and surprise boxes. Fun, never punishing.
* **Pay once:** `claimAchievements` filters ids already recorded, and the engine
  filters before that — a badge can never pay twice.
* **Nothing is ever lost:** stars and badges only grow; only the gated
  grown-ups reset clears them. No timers, no penalties, no ads, fully offline.
* Most metrics are *derived from the album* (every design stores its full
  recipe), so the game does not have to track things in the background.
* Reachable from **Gifts → Stars**; the nine original screens keep working
  unchanged.

### Gift rooms (Phase 2.5)

Four pastel rooms, twelve boxes, and a rule that makes the whole thing safe:

| | |
|---|---|
| **Rooms** | blush · mint · sky · sunny — opened at **star milestones** (0 / 12 / 30 / 60) |
| **Stars** | milestones only. **Never spent**, so nothing a child earned can ever be taken back |
| **Boxes** | 3 per room, each with a **fixed** prize (coins, keys, stars, or a new studio item). No loot boxes, no randomness to reason about |
| **Once and only once** | the box id and its prize are written in a *single* state transition; a second tap finds the id recorded and does nothing |
| **Badges** | the third box in each room asks for 1 / 2 / 3 / 4 badges — that is the bridge between the star wall and the gifts |
| **New studio items** | 4 gift-only polish colours + 4 charm rings (41,472 designs now) — they show a little gift where a price would be, and are **never for sale** |
| **Motion** | reuse of `BoxWiggle` / `PopIn` / `GlowHalo`, all of which already obey *reduce motion* |
| **No pressure** | no timers, no streaks that break, no "come back tomorrow", no ads, fully offline |

Engine: `lib/core/gift_rooms/gift_room_engine.dart` (pure — no widgets, no
storage, no clock), values in `lib/core/gift_rooms/gift_room.dart`, screen in
`lib/features/gift_rooms/`. Reached from **Gifts → Rooms** and from the star wall.

### Save durability (hardening after review)

The review was right: reading `ref.read(...)` before an `await` protects the
*widget*, not the *notifier*. So the save path no longer touches Riverpod at all:

```
lib/data/repositories/design_saver.dart
  capture()  ->  atomic PNG write (tmp + rename)  ->  durable name map
```

* No `ref`, no `Notifier`, no `BuildContext` inside the save path.
* The album merges that durable map when progress loads
  (`ProgressState.withDesignImages`), so a write that lands **after** the child
  left the celebration still shows up in the album.
* A disposed notifier can no longer surface as an unhandled error — the in-memory
  mirror is wrapped in `try/catch`, and storage is the source of truth.
* The file name is **derived** from the design id (`design_<id>.png`), so even a
  lost index is recoverable: the album lists what is really on disk and fills
  the missing picture back in (`withAvailableDesigns`).
* `.tmp_*` leftovers of a killed app are swept on the next album visit, and a
  stale temp for the same design is dropped before every write.
* Retrying is idempotent (same id → same file), and a double tap on **Done**
  can no longer twin a design — `completeRound` recognises the same round.
* Full reasoning: [docs/save-durability.md](docs/save-durability.md).

### Final QA (Phase 2.6)

The whole codebase was re-read with one rule: **no claim of a passing test that
was never run.** What the review actually changed:

| Finding | Fix |
|---|---|
| Home had **no mute button** (it builds its own top bar) | one shared `lib/widgets/quick_mute_button.dart`, used by `KidScreen` **and** Home |
| A screen passing `onBack` (the gift room) lost the Home corner | Home is now **always** top-left; the optional "one level up" arrow sits beside it |
| Home counters could overflow on a narrow phone | `Flexible` + `FittedBox(scaleDown)` |
| **7 looping animations kept spinning while invisible** under *reduce motion* | shared `syncLoopTicker()` stops/starts every loop with the setting (buttons and the mascot included) |
| Images decoded at full size for tiny widgets (488 KB logo → 120 px) | `SafeAssetImage` now passes `cacheWidth`/`cacheHeight` from the display size |
| Unused packages `lottie` + `flutter_svg`, a dead `sparkleAnim` asset, an empty asset dir | removed (with the stale README lines) |
| 2 unused imports + 15 files with unordered imports | removed / sorted (`directives_ordering`) |
| The destructive dialog was **written** (up to 12 words) and a single static hold could be an accident | gate is now **textless** (icon-only cancel) and irreversibles ask for **two displaced holds** |

A new `test/safety_test.dart` locks the promises that need no device: no
ads/purchases/tracking/network packages, no URL or `HttpClient` anywhere in
`lib/`, every audio path has a file, every declared asset directory exists,
every screen keeps the shared Home+Mute skeleton, and destructive actions stay
behind the parent gate.

**Status: not release-ready.** 8 test files / 114 cases are written and the
static review is clean, but `flutter pub get · analyze · test · run` have never
been executed anywhere — see [docs/final-qa-report.md](docs/final-qa-report.md)
and [docs/verification.md](docs/verification.md).

Release verification is three commands on a machine with Flutter:

```bash
flutter doctor -v && bash tools/verify.sh   # 1. machine + project
flutter run                                 # 2. the 30-point device checklist
bash tools/verify.sh --apk                  # 3. the release APK
```

### Motion (Phase 2.3)

```
lib/core/animations/
  motion_tokens.dart       every duration/curve in one place (locked by tests)
  motion_policy.dart       "calm motion" = app toggle OR the system setting
  screen_transitions.dart  softPage(): the single transition every route uses
  entrances.dart           ScreenEntrance, EntranceItem (staggered), PopIn
  celebration.dart         GlowHalo, StarPop, SavedBadge, BoxWiggle
```

* Durations follow the brief and are **asserted by tests**: transitions 340 ms,
  entrances 420/560 ms, selection 180 ms, reveal 2600 ms, ambient loops 2.4-3 s.
* Calm motion is honoured from **two** sources: the in-game toggle *and*
  `MediaQuery.disableAnimations` (Android "Remove animations", iOS "Reduce
  Motion"). When calmed, entrances collapse, distances become zero and all
  looping decorations stop — which is also what protects the battery.
* Off-screen routes cost nothing: Flutter mutes their tickers via `TickerMode`.
* **Reveal is choreographed, the save is not.** The PNG capture starts on the
  very first frame (before any animation), the screenshot wraps only the design
  card, and the repository/notifier are read *before* the first `await`, so the
  write still lands if the child leaves mid-celebration. Nothing is ever
  disabled while things animate. If a capture is ever lost, the album repairs
  that design from its recipe (a capped, staggered repair pass in the album).
* Details, timings and **the tests that were NOT run** are in
  [docs/motion-report.md](docs/motion-report.md).

### Audio (Phase 2.2)

```
lib/core/audio/
  audio_cues.dart     cue table: path + gain + throttle per sound
  audio_engine.dart   pre-loaded players, single music stream, burst limiter
  sound_helper.dart   thin facade the screens talk to
assets/audio/sfx/     10 effects      assets/audio/music/  one loop
```

* **Real files, original:** every sound is generated from scratch by
  `tools/generate_audio.py` (`python3 tools/generate_audio.py` regenerates the
  whole set). Peaks are all ≤ −8 dBFS and the files contain ~0% energy above
  8 kHz — nothing piercing, nothing startling.
* **One music stream, always:** `startMusic()` is idempotent, so moving between
  screens can never stack two loops. Music pauses when the app is backgrounded.
* **Anti-spam:** per-cue throttling for drag sounds plus a burst limiter
  (max 3 sounds / 140 ms) so little hands drumming the screen stay pleasant.
* **Never breaks:** a missing or undecodable file is caught and the cue simply
  stays silent; the game keeps playing.
* Measurements, design rules and **the tests that were NOT run** are recorded
  honestly in [docs/audio-report.md](docs/audio-report.md).

### Art layer (Phase 2.1)

```
lib/art/
  art_direction.dart    design tokens + the character/room sheets
  asset_slots.dart      the only place that knows art file paths
  art_or_fallback.dart  show the file if it exists, draw it if not
```

* Drop a correctly named PNG into `assets/images/...` and it appears —
  **no code change**.
* Delete the whole `assets/` folder and the game still looks intentional
  (faces, hand, nails, patterns and sparkles are all painted procedurally).
* **Shipped art:** `logo.png` + the six character portraits, one consistent
  style, already cropped to squares and optimised (7.9 MB → 3.1 MB).
* Rooms, tools, stickers, rings and frames are pending — ready-made prompts
  live in [docs/art-prompts.md](docs/art-prompts.md), and the rules in
  [docs/art-bible.md](docs/art-bible.md).
* Tablets are supported: content stays inside a comfortable width and grids
  gain a column (`lib/core/utils/responsive.dart`).

**Everything runs with zero art files.** Faces, the spa hand, nails, patterns,
stickers and rings are drawn procedurally (CustomPainter), so the game is
playable and pretty today — dropping real PNGs later only *upgrades* it.
Missing sounds simply stay silent; nothing ever crashes.

### The nine screens

| Screen | What happens | Kid-safety detail |
|---|---|---|
| Splash | logo, chime, auto-advance | no taps required |
| Home | Play / Album / Gifts + counters | settings behind the grown-ups gate |
| Characters | 6 friends, each with its own mood | tap = pick, no confirm dialogs |
| Spa | 5 rub-to-win steps with live feedback | one gesture, impossible to fail |
| Studio | shape → color → pattern → sticker → ring | locked items invite, never frustrate |
| Reveal | confetti, applause, 3 stars, auto-saved design | the PNG is stored even if never tapped |
| Album | every design, newest first | delete requires a grown-up hold |
| Rewards | daily gift + surprise box (1 key) | streak stars, no timers, no pressure |
| Settings | sound, music, vibration, calm motion, reset | reset needs the star hold again |

---

## Requirements

- **Flutter 3.27+ / Dart 3.6+** (`flutter --version`)
  Earlier versions will fail `pub get` — the code uses `Color.withValues()`,
  `CardThemeData` and `DialogThemeData`.
- An Android device/emulator or an iOS device/simulator.

---

## Run it

The repo contains the Dart/Flutter **source**; the platform folders
(`android/`, `ios/`) are generated locally.

```bash
# 1. Generate the platform folders in a temp project (so nothing in lib/ is touched)
flutter create --platforms=android,ios --org com.yourname \
  --project-name sparkle_nail_spa ../sns_platforms

# 2. Move them into this repo and drop the temp project
mv ../sns_platforms/android ../sns_platforms/ios .
rm -rf ../sns_platforms

# 3. Dependencies + run
flutter pub get
flutter run
```

> If you prefer `flutter create .` directly in the repo, that works too —
> but it regenerates `lib/main.dart`, so restore it afterwards with
> `git checkout -- lib`.

### Tests

```bash
flutter test          # pure logic: models, save parsing + merging, motion rules,
                      # achievements engine and flow (rewards-once, persistence,
                      # cumulative targets, reset), save durability (retry,
                      # atomicity, temp files), gift rooms (catalog + once-only)
```

> ⚠️ **Nothing has been analysed or run yet** — the working environment has no
> Flutter SDK, so `flutter analyze`, `flutter test` and `flutter run` are still
> pending on a real machine. What *was* verified here: every relative import
> resolves, no deprecated APIs are used, delimiters balance, every audio cue
> path matches a file on disk (11/11), all MP3s carry a valid frame header, the
> music loop seam is continuous, and no sound has harsh high-frequency energy.
> See [docs/audio-report.md](docs/audio-report.md) §5 for the explicit list.

---

## Assets

Drop your art/audio into `assets/` using the **exact names** listed in
[`lib/core/constants/assets.dart`](lib/core/constants/assets.dart):

```
assets/images/ui/logo.png        # ✅ shipped
assets/images/rooms/{home,spa,...}.png          # optional room backdrops
assets/audio/sfx/*.mp3                          # ✅ shipped (10 cues)
assets/audio/music/spa_loop.mp3                 # ✅ shipped (18.85 s loop)
assets/images/characters/{kitty,bunny,panda,unicorn,fairy,kid}.png
assets/images/tools/{sponge,soap,towel,cream,brush,water}.png
assets/images/stickers/{star,heart,...,butterfly}.png
assets/images/{hand_dirty,hand_clean}.png
assets/fonts/Fredoka-*.ttf        # then uncomment the fonts block in pubspec.yaml
```

Notes:

- **Sound paths have no `assets/` prefix** (`AssetSource('audio/sfx/tap.mp3')`
  resolves inside `assets/` automatically). This was a bug in the original draft.
- There is **no animation file slot**: every sparkle, badge and confetti burst is
  drawn in code (`lib/core/animations/`), so nothing extra is downloaded or parsed.
- Missing assets **never crash the game** — audio stays silent, images fall back
  to a friendly placeholder.
- **Fonts are bundled, not downloaded.** `google_fonts` was removed on purpose:
  a runtime font fetch would break the "works offline" promise.

---

## Architecture

```
lib/
  main.dart                    # bootstrap: storage -> audio pool -> ProviderScope
  app.dart                     # root widget: theme, router, audio/haptics wiring

  core/
    constants/                 # assets.dart, game_constants.dart (every tunable number)
    router/                    # app_routes.dart (paths) + app_router.dart (soft transitions)
    theme/                     # app_colors.dart (pastel palette), app_theme.dart
    utils/                     # sound_helper, feedback_helper, parent_gate

  data/
    models/                    # character, nail catalog, gallery item, round/progress/settings
    repositories/              # local_storage_service (device only) + gallery_repository (PNGs)

  features/
    game/                      # round / progress / settings controllers + providers
    splash|home|characters|spa|studio|reveal|gallery|rewards|settings/

test/
  models_test.dart             # pure-logic tests for models & save-data parsing
```

### State design (three separate stores)

| Store | Holds | Persisted? |
|---|---|---|
| `roundControllerProvider` | character, spa step + rub progress, studio step + picks | only the character id |
| `progressControllerProvider` | stars, coins, keys, unlocks, the album | ✅ |
| `settingsControllerProvider` | sound, music, haptics, reduce motion | ✅ |

Why it matters:

- Dragging a sponge updates **memory only** → no disk writes during a drag
  (the original design wrote JSON on *every* pan update).
- "Reset progress" clears progress **and keeps** the child's sound settings.
- All writes go through a queue, and all reads are crash-tolerant: corrupted or
  outdated save data degrades to safe defaults instead of losing the album.

---

## What this phase fixed (vs. the original draft)

| # | Original draft | Now |
|---|---|---|
| 1 | `withValues()` with an SDK constraint older than the API | `sdk >=3.6.0`, `flutter >=3.27.0` |
| 2 | `CardTheme` / `DialogTheme` (deprecated) | `CardThemeData` / `DialogThemeData` |
| 3 | Sound constants included `assets/` → `assets/assets/...` | paths relative to `assets/` |
| 4 | One `AudioPlayer` per sound | pool of 4 + throttled drag sounds |
| 5 | Save on every drag update | in-memory round, queued disk writes |
| 6 | Settings wiped by reset | settings stored separately |
| 7 | `google_fonts` at runtime (needs internet) | optional bundled Fredoka font |
| 8 | 5 screens; no reveal/gallery flow in state | 9 routes, reveal → auto-save → album |
| 9 | `int` indices in save data | stable string ids + tolerant parsing |
| 10 | No kid-safety extras | parent gate + haptics/motion settings |

---

## Next step

**Phase 1 — Screens**, in this order:
theme widgets (`CuteBackground`, `BigButton`, `SafeAssetImage`, `SparkleEffect`)
→ Splash & Home → Character select → Spa room → Nail studio → Reveal + capture →
Gallery → Rewards → Settings.
