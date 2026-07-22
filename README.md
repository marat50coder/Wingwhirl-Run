# Wingwhirl Run

A cozy casual **fishing game** built with Flutter + Flame. You play a funny
angler-chicken who travels between lakes and seas, catches fish of increasing
rarity, earns coins, upgrades gear, unlocks new fishing spots and collects a
full roster of 30 quirky chickens hatched from surprise eggs.

* Engine: **Flutter 3.38** / Dart 3.10, gameplay powered by **Flame**
* Orientation: **Landscape** (game) · Splash supports portrait + landscape
* **Fully offline** — no INTERNET permission in the release build
* Language: **English**

---

## Running

```bash
flutter pub get
flutter run                 # debug on a connected device
flutter build apk --release # release APK
flutter build appbundle     # Play Store bundle (recommended, smaller download)
```

Regenerate launcher icons after changing `assets/Icon.png`:

```bash
dart run flutter_launcher_icons
```

---

## Asset inventory & analysis

All source art lives in `assets/` (WebP) and audio in `sounds/` (MP3). The large
`*_asset.webp` files are **collections of many individual objects on a
transparent background** — they are *not* uniform sprite sheets. They were
auto-sliced into individual PNG sprites (see "Sprite slicing" below).

| Source file | Size | Contents | Used as |
|---|---|---|---|
| `bg1..bg8_asset.webp` | 768×1376 | 8 painted lake/sea scenes (meadow, pine forest, mountain, tropical, cliffs, ocean, sunset, night) | The 8 fishing locations (cover-cropped to landscape) |
| `Horizontal_Loading_Screen.webp` | 2400×1080 | Branded splash art (landscape) | Splash background (landscape) |
| `Vertical_Loading_Screen.webp` | 1080×2400 | Branded splash art (portrait) | Splash background (portrait) |
| `chickens_asset.webp` | 1584×672 | **30** collectible chickens (3×10) | Collection + in-game angler |
| `collection_fish_asset.webp` | 1584×672 | **48** fish (6×8) | Catchable fish / Fishdex |
| `fishing_equipment_asset.webp` | 1584×672 | 3 rods, 8 reels, lines, hooks, 7 floats, 5 baits, tackle boxes, nets… | Upgrades & bobber skins |
| `egg_asset.webp` | 1584×672 | **10** eggs of ascending rarity | Shop eggs |
| `coins_asset.webp` | 1584×672 | Spinning-coin frames + coin piles | Coin icon / HUD |
| `collectible_rewards_asset.webp` | 1584×672 | Chests, crates, baskets, gems | Reward icons |
| `water_effects_and_objects_asset.webp` | 1584×672 | Splashes, ripples, bubbles, lily pads, jumping fish | Reference for the procedural water FX |
| `nature/shoreline/wooden_objects_asset.webp` | 1584×672 | Plants, rocks, docks, fences, bridges | Scenery (the dock under the chicken is `wooden_00`) |
| `Icon.png` | 512×512 | App icon scene | Launcher icon (+ generated adaptive foreground) |
| `sounds/*.mp3` | — | 15 SFX (cast, bite, catch, coins, egg, level-up, legendary…) | Sound effects & ambience |

### Sprite slicing (important)

Because the sheets are irregular collections (varying object sizes and spacing),
a grid slice would not work. Instead, `tools/export_slices.py` detects each
object via **alpha connected-component labeling** (with a small dilation to merge
disconnected parts) and exports tight, row-major-ordered PNGs into
`assets/sprites/<category>/`. Detection was verified to be exact for the two
gameplay-critical sheets — **30/30 chickens** and **48/48 fish**.

Helper scripts (not shipped in the app):
* `tools/export_slices.py` – slices all sheets → `assets/sprites/`
* `tools/analyze_slices.py` – draws detection overlays for QA
* `tools/palette.py` – extracts dominant colors

Re-run slicing with: `python tools/export_slices.py`

---

## Design system

The palette was extracted directly from the art (dominant sky-blue water, fresh
green shorelines, warm gold coins), giving a bright, cozy aquatic theme with
gold reward accents. Defined in `lib/theme/app_theme.dart`.

| Role | Color |
|---|---|
| Primary (sky) | `#29ABE2` |
| Primary deep (water) | `#0F6FB8` |
| Secondary (green) | `#7CB342` |
| Accent (gold) | `#FFC23C` |
| Warn / energy (coral) | `#F6663B` |
| Ink (text) | `#0E3A54` |

Rarity ramp: Common `#8FA3B0` → Uncommon `#44BE7A` → Rare `#2E9BE6` →
Epic `#A65CE0` → Legendary `#FFB300`.

Typography (bundled locally for offline use, in `assets/fonts/`):
* **Fredoka** — display / headings
* **Nunito** — body text

UI kit in `lib/theme/app_widgets.dart`: gradient buttons with press-scale + glow,
frosted glass panels, glowing progress bars, rarity badges, stat chips.
Screen transitions are Fade + Slide (`Curves.easeInOut`, ~420 ms).

---

## Gameplay

Cast → wait for the bite → tap within the timing window (widened by the reel) →
reel in → earn coins scaled by fish rarity × location multiplier × rod power.

* **8 locations** with rising coin multipliers and rarer-fish odds
* **Upgrades**: Rod (coin value), Reel (timing window), Bait (bite speed & rarity)
* **Eggs** (4 tiers) hatch collectible chickens by weighted rarity
* **Bobber skins** (7) — cosmetic, change the in-game float
* **Daily tasks** (deterministic per day) grant bonus coins
* **Collection**: 30 chickens + 48-fish Fishdex with silhouettes for undiscovered
* Progress saved locally via `shared_preferences` (JSON blob)

---

## Project structure

```
lib/
  main.dart                 # entry: orientation, immersive mode
  app.dart                  # MaterialApp, theme, page transitions, backgrounds
  theme/                    # colors, text styles, reusable widgets
  data/                     # models + all static content (fish/chickens/eggs/…)
  state/game_state.dart     # ChangeNotifier: progress, economy, save/load, RNG
  services/                 # save (prefs) + audio (audioplayers)
  game/fishing_game.dart    # Flame game: chicken, bobber, line, particles, FSM
  screens/                  # splash, menu, game, shop, collection, locations,
                            # tasks, settings, egg reveal, webview
  widgets/                  # coin chip, menu scaffold, tabs
tools/                      # asset slicing / analysis scripts (dev only)
```

---

## Google Play readiness

* No `INTERNET` permission in the release manifest (verified in the merged
  manifest). The webview (`lib/screens/webview_screen.dart`) renders **local
  HTML strings** only, so Privacy Policy & Support work offline.
* All I/O (save, audio, image loads) is wrapped in try/catch — no crashes.
* Adaptive Android launcher icon generated from `assets/Icon.png` with a
  scaled foreground so nothing is clipped by device masks.
* English UI; placeholder Privacy Policy and Support pages are included —
  **replace the Support URL** in `webview_screen.dart` before publishing.
