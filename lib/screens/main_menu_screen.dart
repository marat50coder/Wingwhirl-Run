import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/game_data.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import '../widgets/coin_chip.dart';
import 'achievements_screen.dart';
import 'collection_screen.dart';
import 'daily_reward_screen.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'locations_screen.dart';
import 'mini_game_screen.dart';
import 'settings_sheet.dart';
import 'shop_screen.dart';
import 'tasks_screen.dart';

/// The main menu: a full-bleed living diorama with a minimal glass HUD, a
/// glowing hero PLAY button and a slim icon dock for secondary navigation.
/// Every other screen is reached from the dock; the background art is never
/// covered by more than a thin strip of UI.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bob; // logo idle bob
  late final AnimationController _drift; // ambient particles
  late final AnimationController _zoom; // slow Ken Burns background zoom
  late final AnimationController _pulse; // play button glow pulse
  late final AnimationController _twinkle; // logo sparkles
  late final AnimationController _entrance; // one-shot intro fade/slide

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _drift =
        AnimationController(vsync: this, duration: const Duration(seconds: 11))
          ..repeat();
    _zoom = AnimationController(
        vsync: this, duration: const Duration(seconds: 18))
      ..repeat(reverse: true);
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _twinkle =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.playMusic(AudioService.tension, volume: 0.25);
    });
  }

  @override
  void dispose() {
    _bob.dispose();
    _drift.dispose();
    _zoom.dispose();
    _pulse.dispose();
    _twinkle.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _go(Widget page) {
    AudioService.instance.playSfx(AudioService.click);
    Navigator.of(context).push(fadeSlideRoute(page));
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _kenBurnsBackground(state),
              const _AtmosphereOverlay(),
              _Fireflies(controller: _drift),
              _FloatingDecor(controller: _drift),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, c) => _layout(state, c),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kenBurnsBackground(GameState state) {
    return AnimatedBuilder(
      animation: _zoom,
      builder: (context, child) {
        final scale = 1.0 + 0.07 * Curves.easeInOut.transform(_zoom.value);
        return Transform.scale(scale: scale, child: child);
      },
      child: Image.asset(state.location.background, fit: BoxFit.cover),
    );
  }

  // --------------------------------------------------------------- Layout
  Widget _layout(GameState state, BoxConstraints c) {
    const topBarH = 46.0;
    const dockPad = 12.0;
    final dockH = (c.maxHeight * 0.16).clamp(64.0, 82.0);
    final playD = (c.maxHeight * 0.32).clamp(78.0, 116.0);
    final footerBlockH = dockH + playD * 0.42 + dockPad;
    final logoBudget =
        (c.maxHeight - topBarH - footerBlockH - 44).clamp(56.0, 260.0);

    return Stack(
      children: [
        Positioned(
          top: topBarH + 14,
          left: 0,
          right: 0,
          height: logoBudget,
          child: Center(child: _logo(logoBudget, c.maxWidth)),
        ),
        Positioned(left: 12, top: 6, child: _hudLeft(state)),
        Positioned(right: 12, top: 6, child: _hudRight(state)),
        Positioned(
          left: 0,
          right: 0,
          bottom: dockPad,
          child: _dock(state, dockH, c.maxWidth, playD),
        ),
        Positioned(
          bottom: dockPad + dockH - playD * 0.56,
          left: 0,
          right: 0,
          child: Center(child: _playButton(playD)),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- HUD
  Widget _hudLeft(GameState state) {
    return _EntranceFade(
      controller: _entrance,
      delay: 0.0,
      offset: const Offset(-24, 0),
      child: GlassPanel(
        radius: 30,
        padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
        color: AppColors.waterDark.withValues(alpha: 0.4),
        borderColor: Colors.white.withValues(alpha: 0.35),
        child: PressableScale(
          onTap: () => _go(const CollectionScreen()),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(GameData.coinIcon, width: 30, height: 30),
              const SizedBox(width: 6),
              Text(formatCoins(state.coins), style: AppText.heavy(17)),
              const SizedBox(width: 10),
              Container(
                width: 1.4,
                height: 22,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.pets, color: AppColors.rarityEpic, size: 18),
              const SizedBox(width: 4),
              Text('${state.collectionOwned}/${state.collectionTotal}',
                  style: AppText.heavy(15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hudRight(GameState state) {
    return _EntranceFade(
      controller: _entrance,
      delay: 0.05,
      offset: const Offset(24, 0),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.help_outline_rounded,
            size: 40,
            onTap: () => _go(const HowToPlayScreen()),
          ),
          const SizedBox(width: 8),
          CircleIconButton(
            icon: state.musicOn ? Icons.music_note_rounded : Icons.music_off_rounded,
            size: 40,
            onTap: () {
              AudioService.instance.playSfx(AudioService.click);
              state.toggleMusic();
            },
          ),
          const SizedBox(width: 8),
          CircleIconButton(
            icon: Icons.settings_rounded,
            size: 40,
            onTap: () {
              AudioService.instance.playSfx(AudioService.click);
              showSettingsSheet(context);
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Logo
  Widget _logo(double budget, double maxWidth) {
    final logoW = min(maxWidth * 0.42, budget * 1.7);
    return _EntranceFade(
      controller: _entrance,
      delay: 0.1,
      offset: const Offset(0, -18),
      child: SizedBox(
        height: budget,
        width: logoW + 120,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Soft radial glow so the logo pops off any background.
            Container(
              width: logoW * 1.55,
              height: budget * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            _TwinkleField(controller: _twinkle, width: logoW + 120, height: budget),
            AnimatedBuilder(
              animation: _bob,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -5 * sin(_bob.value * pi)),
                child: Transform.rotate(
                    angle: 0.012 * sin(_bob.value * pi), child: child),
              ),
              child: Image.asset('assets/Game_Name.webp',
                  width: logoW, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Dock
  Widget _dock(GameState state, double height, double maxWidth, double playD) {
    final left = <_DockItem>[
      _DockItem(
        icon: Icons.card_giftcard_rounded,
        label: 'Daily',
        color: AppColors.gold,
        dot: state.dailyRewardAvailable,
        onTap: () => _go(const DailyRewardScreen()),
      ),
      _DockItem(
        icon: Icons.sports_esports_rounded,
        label: 'Arcade',
        color: AppColors.coral,
        onTap: () => _go(const MiniGameScreen()),
      ),
      _DockItem(
        icon: Icons.storefront_rounded,
        label: 'Shop',
        color: AppColors.goldDeep,
        onTap: () => _go(const ShopScreen()),
      ),
    ];
    final right = <_DockItem>[
      _DockItem(
        icon: Icons.map_rounded,
        label: 'Places',
        color: AppColors.waterDeep,
        onTap: () => _go(const LocationsScreen()),
      ),
      _DockItem(
        icon: Icons.checklist_rounded,
        label: 'Tasks',
        color: AppColors.green,
        badge: _pendingTasks(state),
        onTap: () => _go(const TasksScreen()),
      ),
      _DockItem(
        icon: Icons.emoji_events_rounded,
        label: 'Awards',
        color: AppColors.rarityEpic,
        badge: state.achievementsUnclaimed,
        onTap: () => _go(const AchievementsScreen()),
      ),
    ];

    final dockWidth = min(maxWidth - 24, 760.0);
    // Keep clear of the floating PLAY button that sits above the dock's
    // midpoint — no icon should ever land underneath it.
    final centerGap = playD * 0.86;

    return Center(
      child: _EntranceFade(
        controller: _entrance,
        delay: 0.15,
        offset: const Offset(0, 30),
        child: SizedBox(
          width: dockWidth,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.waterDark.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(height / 2),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28), width: 1.4),
                  boxShadow: const [
                    BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    for (final it in left)
                      Expanded(child: _DockButton(item: it, size: height)),
                    SizedBox(width: centerGap),
                    for (final it in right)
                      Expanded(child: _DockButton(item: it, size: height)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _pendingTasks(GameState state) =>
      state.dailyTasks.where((t) => t.completed && !t.claimed).length;

  // ------------------------------------------------------------- PLAY FAB
  Widget _playButton(double d) {
    return _EntranceFade(
      controller: _entrance,
      delay: 0.2,
      offset: const Offset(0, 24),
      child: PressableScale(
        pressedScale: 0.92,
        onTap: () => _go(const GameScreen()),
        child: SizedBox(
          width: d + 30,
          height: d + 30,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final t = _pulse.value;
                  return Opacity(
                    opacity: (1 - t) * 0.55,
                    child: Transform.scale(
                      scale: 0.86 + 0.34 * t,
                      child: Container(
                        width: d,
                        height: d,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                              BorderSide(color: AppColors.gold, width: 3)),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.greenButton,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9), width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.75),
                      blurRadius: 26,
                      spreadRadius: 2,
                    ),
                    const BoxShadow(
                        color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: d * 0.42),
                    Text('PLAY',
                        style: AppText.title(d * 0.16, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================ Entrance fx

/// Fades + slides a child in once, staggered by [delay] (0..1 of the shared
/// controller's duration). Purely decorative, disposed-safe since it just
/// listens to a controller owned by the parent.
class _EntranceFade extends StatelessWidget {
  const _EntranceFade({
    required this.controller,
    required this.child,
    this.delay = 0.0,
    this.offset = Offset.zero,
  });

  final Animation<double> controller;
  final Widget child;
  final double delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(delay.clamp(0.0, 0.85), (delay + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, c) {
        final t = anim.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(offset.dx * (1 - t), offset.dy * (1 - t)),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

/// A handful of small stars that twinkle around the logo.
class _TwinkleField extends StatelessWidget {
  const _TwinkleField({
    required this.controller,
    required this.width,
    required this.height,
  });

  final Animation<double> controller;
  final double width;
  final double height;

  static const _pts = [
    Offset(0.06, 0.20), Offset(0.94, 0.15), Offset(0.14, 0.80),
    Offset(0.88, 0.78), Offset(0.02, 0.55), Offset(0.97, 0.50),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Stack(
              children: List.generate(_pts.length, (i) {
                final phase = i * 0.9;
                final v = (sin(controller.value * 2 * pi * 1.3 + phase) + 1) / 2;
                final opacity = (v > 0.55) ? (v - 0.55) / 0.45 : 0.0;
                return Positioned(
                  left: _pts[i].dx * width,
                  top: _pts[i].dy * height,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Icon(Icons.auto_awesome,
                        color: Colors.white, size: 12 + (i % 3) * 4),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================ Dock button

class _DockItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool dot;
  final int badge;
  const _DockItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.dot = false,
    this.badge = 0,
  });
}

class _DockButton extends StatelessWidget {
  const _DockButton({required this.item, required this.size});
  final _DockItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final circle = size * 0.56;
    return PressableScale(
      onTap: item.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: circle,
                height: circle,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      item.color.withValues(alpha: 0.95),
                      Color.lerp(item.color, Colors.black, 0.25)!,
                    ],
                  ),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55), width: 1.6),
                  boxShadow: [
                    BoxShadow(
                        color: item.color.withValues(alpha: 0.5), blurRadius: 10),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: circle * 0.56),
              ),
              if (item.badge > 0)
                Positioned(right: -4, top: -4, child: _badge('${item.badge}')),
              if (item.dot && item.badge == 0)
                Positioned(right: -2, top: -2, child: _badge('')),
            ],
          ),
          SizedBox(height: size * 0.05),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.heavy((size * 0.15).clamp(9.0, 12.0)),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    final deco = BoxDecoration(
      color: AppColors.coral,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white, width: 1.4),
      boxShadow: [
        BoxShadow(color: AppColors.coral.withValues(alpha: 0.7), blurRadius: 6),
      ],
    );
    if (text.isEmpty) {
      return Container(width: 12, height: 12, decoration: deco);
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: deco,
      child: Text(text,
          style: AppText.heavy(10).copyWith(height: 1),
          textAlign: TextAlign.center),
    );
  }
}

// ============================================================ Ambience

/// Cool vignette + subtle top/bottom darkening so UI text always reads
/// clearly over any location background.
class _AtmosphereOverlay extends StatelessWidget {
  const _AtmosphereOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x59000000),
            Color(0x14000000),
            Color(0x0A000000),
            Color(0x66000000),
          ],
          stops: [0.0, 0.22, 0.6, 1.0],
        ),
      ),
    );
  }
}

/// Small glowing motes drifting slowly upward — cheap, premium ambience.
class _Fireflies extends StatelessWidget {
  const _Fireflies({required this.controller});
  final AnimationController controller;

  static const _flies = [
    Offset(0.10, 0.85), Offset(0.22, 0.40), Offset(0.35, 0.70),
    Offset(0.62, 0.30), Offset(0.75, 0.65), Offset(0.85, 0.20),
    Offset(0.48, 0.85), Offset(0.92, 0.50),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, c) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Stack(
              children: List.generate(_flies.length, (i) {
                final phase = i * 0.37;
                final t = (controller.value + phase) % 1.0;
                final y = _flies[i].dy - t * 0.5;
                final x = _flies[i].dx + sin(t * 2 * pi + i) * 0.02;
                final fade = sin(t * pi); // fades in, peaks, fades out
                final size = 3.0 + (i % 3);
                return Positioned(
                  left: c.maxWidth * x,
                  top: c.maxHeight * (y % 1.0),
                  child: Opacity(
                    opacity: (fade * 0.55).clamp(0.0, 0.55),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.8),
                              blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      }),
    );
  }
}

/// A couple of drifting coins/eggs tucked in the far corners (ambience only,
/// never overlapping the HUD or dock).
class _FloatingDecor extends StatelessWidget {
  const _FloatingDecor({required this.controller});
  final AnimationController controller;

  static final _items = <_DecorItem>[
    _DecorItem(asset: GameData.coinIcon, dx: 0.92, dy: 0.22, size: 24, phase: 0.4),
    _DecorItem(asset: 'assets/sprites/eggs/eggs_09.png', dx: 0.06, dy: 0.30, size: 30, phase: 0.7),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, c) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Stack(
              children: _items.map((it) {
                final t = (controller.value + it.phase) % 1.0;
                final float = sin(t * 2 * pi) * 10;
                return Positioned(
                  left: c.maxWidth * it.dx,
                  top: c.maxHeight * it.dy + float,
                  child: Opacity(
                    opacity: 0.55,
                    child: Transform.rotate(
                      angle: sin(t * 2 * pi) * 0.2,
                      child:
                          Image.asset(it.asset, width: it.size, height: it.size),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      }),
    );
  }
}

class _DecorItem {
  final String asset;
  final double dx;
  final double dy;
  final double size;
  final double phase;
  const _DecorItem({
    required this.asset,
    required this.dx,
    required this.dy,
    required this.size,
    required this.phase,
  });
}
