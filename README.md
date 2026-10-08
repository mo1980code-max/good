# ✨ Sparkle Nail Spa

A cute, **fully offline** nail-spa game for kids **ages 3–8**.
No accounts, no ads, no in-app purchases, no external links, no text to read —
just big friendly buttons, sparkles and happy sounds.

> The full design constitution lives in **[docs/sparkle-nail-spa-gdd.md](docs/sparkle-nail-spa-gdd.md)** (v1.1).
> Every implementation decision is measured against it.

---

## Current status

| Phase | Scope | State |
|---|---|---|
| **Phase 1 — Architecture** | models, storage, state management, routing, theme, helpers | ✅ **done (this revision)** |
| Phase 1 — Screens | splash, home, characters, spa, studio, reveal, gallery, rewards, settings | 🕐 next |
| Phase 2 — Polish | sounds, sparkles, confetti, daily gift, surprise box, star wall | 🕐 |
| Phase 3 — Release | device testing, assets, store screenshots, privacy policy, age rating | 🕐 |

Screens currently exist as **placeholders** (so the app compiles and the router
works end-to-end). They are intentionally empty — built in the screens phase.

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
flutter test
```

---

## Assets

Drop your art/audio into `assets/` using the **exact names** listed in
[`lib/core/constants/assets.dart`](lib/core/constants/assets.dart):

```
assets/images/ui/logo.png
assets/images/characters/{kitty,bunny,panda,unicorn,fairy,kid}.png
assets/images/tools/{sponge,soap,towel,cream,brush,water}.png
assets/images/stickers/{star,heart,...,butterfly}.png
assets/images/{hand_dirty,hand_clean}.png
assets/sounds/{tap,success,sparkle,bubble,pop,water,brush,victory,applause,music_loop}.mp3
assets/animations/sparkle.json
assets/fonts/Fredoka-*.ttf        # then uncomment the fonts block in pubspec.yaml
```

Notes:

- **Sound paths have no `assets/` prefix** (`AssetSource('sounds/tap.mp3')`
  resolves inside `assets/` automatically). This was a bug in the original draft.
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
