import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';

enum GamePhase { idle, casting, waiting, biting, reeling }

/// The Flame fishing game. The location background is drawn by Flutter behind a
/// transparent game canvas; Flame renders the chicken, dock, bobber, fishing
/// line and all particle effects on top.
class FishingGame extends FlameGame with TapCallbacks {
  FishingGame({
    required this.onCatch,
    required this.onMiss,
  });

  final void Function(CatchResult result) onCatch;
  final VoidCallback onMiss;

  final GameState state = GameState.instance;
  final Random _rng = Random();

  final ValueNotifier<GamePhase> phase = ValueNotifier(GamePhase.idle);
  final ValueNotifier<String> hint = ValueNotifier('Tap to cast!');
  final ValueNotifier<double> biteProgress = ValueNotifier(0);

  late final SpriteComponent _chicken;
  SpriteComponent? _dock;
  BobberComponent? _bobber;

  FishSpecies? _pendingFish;
  int _token = 0;

  Vector2 _rodTip = Vector2.zero();
  Vector2 _castPoint = Vector2.zero();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    images.prefix = '';

    final dockSprite = await _safeSprite(spritePath('wooden', 0));
    if (dockSprite != null) {
      _dock = SpriteComponent(sprite: dockSprite, anchor: Anchor.bottomCenter);
      add(_dock!);
    }

    _chicken = SpriteComponent(anchor: Anchor.bottomCenter);
    final chickenSprite = await _safeSprite(_currentChickenAsset());
    if (chickenSprite != null) _chicken.sprite = chickenSprite;
    add(_chicken);

    await _addBobber();
    _layout();
    _idleBob();
  }

  String _currentChickenAsset() {
    // The angler = the best owned chicken.
    return _bestOwnedChicken(state.ownedChickens).asset;
  }

  Future<void> _addBobber() async {
    final sprite = await _safeSprite(state.currentBobber.asset);
    _bobber = BobberComponent(sprite: sprite)
      ..anchor = Anchor.center
      ..scale = Vector2.all(0.0);
    add(_bobber!);
  }

  Future<Sprite?> _safeSprite(String path) async {
    try {
      return Sprite(await images.load(path));
    } catch (_) {
      return null;
    }
  }

  void _layout() {
    if (!isMounted) return;
    final w = size.x, h = size.y;

    _dock?.position = Vector2(w * 0.17, h * 1.02);
    _dock?.size = Vector2(w * 0.34, w * 0.34 * 0.5);

    final chickenH = h * 0.42;
    _chicken.size = _fit(_chicken.sprite, chickenH);
    _chicken.position = Vector2(w * 0.17, h * 0.96);

    // Anchor the line to the rod tip drawn in the chicken sprite (upper-left).
    final cw = _chicken.size.x;
    final ch = _chicken.size.y;
    final leftEdge = _chicken.position.x - cw / 2;
    final topEdge = _chicken.position.y - ch;
    _rodTip = Vector2(leftEdge + cw * 0.08, topEdge + ch * 0.06);
    _castPoint = Vector2(w * 0.66, h * 0.64);

    if (_bobber != null && phase.value == GamePhase.idle) {
      _bobber!.position = _castPoint.clone();
    }
  }

  Vector2 _fit(Sprite? sprite, double targetHeight) {
    if (sprite == null) return Vector2.all(targetHeight);
    final ratio = sprite.srcSize.x / sprite.srcSize.y;
    return Vector2(targetHeight * ratio, targetHeight);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layout();
  }

  /// Called by the screen when the equipped chicken/bobber changes.
  Future<void> refreshCosmetics() async {
    final chickenSprite = await _safeSprite(_currentChickenAsset());
    if (chickenSprite != null) _chicken.sprite = chickenSprite;
    final bob = await _safeSprite(state.currentBobber.asset);
    if (bob != null) _bobber?.sprite = bob;
    _layout();
  }

  // ------------------------------------------------------------- Interaction
  /// Public hooks used by the HUD action button.
  void cast() {
    if (phase.value == GamePhase.idle) _cast();
  }

  void hookFromButton() {
    if (phase.value == GamePhase.biting) _hook(true);
  }

  @override
  void onTapDown(TapDownEvent event) {
    switch (phase.value) {
      case GamePhase.idle:
        _cast();
        break;
      case GamePhase.biting:
        _hook(true);
        break;
      case GamePhase.waiting:
        // Reeled in too early: gentle miss.
        _tooEarly();
        break;
      default:
        break;
    }
  }

  void _cast() {
    phase.value = GamePhase.casting;
    hint.value = 'Casting...';
    AudioService.instance.playSfx(AudioService.cast);
    final token = ++_token;

    final b = _bobber!;
    b.position = _rodTip.clone();
    b.scale = Vector2.all(0.0);
    b.add(ScaleEffect.to(
      Vector2.all(_bobberScale()),
      EffectController(duration: 0.45, curve: Curves.easeOut),
    ));
    b.add(MoveEffect.to(
      _castPoint.clone(),
      EffectController(duration: 0.55, curve: Curves.easeOutCubic),
      onComplete: () {
        if (token != _token) return;
        AudioService.instance.playSfx(AudioService.floatLand);
        _ripple(_castPoint);
        _startWaiting(token);
      },
    ));
  }

  double _bobberScale() {
    final s = _bobber?.sprite;
    if (s == null) return 0.5;
    // Target on-screen bobber height ~ 8% of screen height.
    return (size.y * 0.09) / s.srcSize.y;
  }

  void _startWaiting(int token) {
    phase.value = GamePhase.waiting;
    hint.value = 'Waiting for a bite...';
    _bobber?.startIdleBob();

    final base = 1.4 + _rng.nextDouble() * 3.0;
    final wait = base * state.biteSpeedFactor;
    Future.delayed(Duration(milliseconds: (wait * 1000).round()), () {
      if (token != _token || !isMounted) return;
      if (phase.value == GamePhase.waiting) _bite(token);
    });
  }

  void _bite(int token) {
    phase.value = GamePhase.biting;
    _pendingFish = state.rollFish();
    hint.value = 'BITE! Tap now!';
    AudioService.instance.playSfx(AudioService.bite);

    _bobber?.stopIdleBob();
    _bobber?.dip();
    _splash(_castPoint, big: _pendingFish!.rarity.index >= Rarity.rare.index);

    // Timing window (wider with better reels).
    final window = state.catchWindow;
    biteProgress.value = 1.0;
    final start = DateTime.now();
    void tick() {
      if (token != _token || !isMounted) return;
      if (phase.value != GamePhase.biting) return;
      final elapsed = DateTime.now().difference(start).inMilliseconds / 1000.0;
      final remaining = (1 - elapsed / window).clamp(0.0, 1.0);
      biteProgress.value = remaining;
      if (remaining <= 0) {
        _hook(false); // missed the window
      } else {
        Future.delayed(const Duration(milliseconds: 30), tick);
      }
    }

    tick();
  }

  void _hook(bool inTime) {
    if (phase.value != GamePhase.biting) return;
    final token = ++_token;
    biteProgress.value = 0;

    if (!inTime || _pendingFish == null) {
      _fail();
      return;
    }

    phase.value = GamePhase.reeling;
    hint.value = 'Reeling in...';
    final fish = _pendingFish!;
    _pendingFish = null;

    _splash(_castPoint, big: fish.rarity.index >= Rarity.rare.index);
    _bobber?.stopIdleBob();

    // Bobber flies back to the rod.
    _bobber?.add(MoveEffect.to(
      _rodTip.clone(),
      EffectController(duration: 0.4, curve: Curves.easeIn),
    ));
    _bobber?.add(ScaleEffect.to(
      Vector2.all(0.0),
      EffectController(duration: 0.4),
    ));

    _spawnJumpingFish(fish);

    Future.delayed(const Duration(milliseconds: 550), () {
      if (token != _token || !isMounted) return;
      _finishCatch(fish);
    });
  }

  void _finishCatch(FishSpecies fish) {
    final rarity = fish.rarity;
    if (rarity == Rarity.legendary) {
      AudioService.instance.playSfx(AudioService.legendary);
    } else if (rarity.index >= Rarity.rare.index) {
      AudioService.instance.playSfx(AudioService.rareFish);
    } else {
      AudioService.instance.playSfx(AudioService.catchOk);
    }
    final result = state.registerCatch(fish);
    onCatch(result);
    _resetToIdle();
  }

  void _fail() {
    final token = ++_token;
    phase.value = GamePhase.reeling;
    hint.value = 'It got away...';
    _pendingFish = null;
    AudioService.instance.playSfx(AudioService.negative);
    _bobber?.stopIdleBob();
    _bobber?.add(MoveEffect.to(
      _rodTip.clone(),
      EffectController(duration: 0.4, curve: Curves.easeIn),
    ));
    _bobber?.add(ScaleEffect.to(Vector2.all(0.0), EffectController(duration: 0.4)));
    onMiss();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (token != _token || !isMounted) return;
      _resetToIdle();
    });
  }

  void _tooEarly() {
    // Cancel the current cast without penalty.
    ++_token;
    phase.value = GamePhase.reeling;
    hint.value = 'Reeled in early';
    _pendingFish = null;
    _bobber?.stopIdleBob();
    _bobber?.add(ScaleEffect.to(Vector2.all(0.0), EffectController(duration: 0.3)));
    Future.delayed(const Duration(milliseconds: 400), _resetToIdle);
  }

  void _resetToIdle() {
    if (!isMounted) return;
    phase.value = GamePhase.idle;
    hint.value = 'Tap to cast!';
    biteProgress.value = 0;
    _bobber?.position = _castPoint.clone();
    _bobber?.scale = Vector2.all(0.0);
    _idleBob();
  }

  void _idleBob() {
    _chicken.add(
      MoveByEffect(
        Vector2(0, -6),
        EffectController(
          duration: 1.4,
          reverseDuration: 1.4,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  // -------------------------------------------------------------- Effects
  void _ripple(Vector2 pos) {
    add(RippleComponent(position: pos.clone()));
  }

  void _splash(Vector2 pos, {bool big = false}) {
    final count = big ? 26 : 14;
    add(
      ParticleSystemComponent(
        position: pos.clone(),
        particle: Particle.generate(
          count: count,
          lifespan: 0.7,
          generator: (i) {
            final angle = -pi / 2 + (_rng.nextDouble() - 0.5) * pi * 0.9;
            final speed = 60 + _rng.nextDouble() * (big ? 180 : 110);
            final v = Vector2(cos(angle), sin(angle)) * speed;
            return AcceleratedParticle(
              acceleration: Vector2(0, 320),
              speed: v,
              child: CircleParticle(
                radius: 2.0 + _rng.nextDouble() * 2.5,
                paint: Paint()
                  ..color = (big ? AppColors.skyLight : Colors.white)
                      .withValues(alpha: 0.9),
              ),
            );
          },
        ),
      ),
    );
    _ripple(pos);
  }

  void _spawnJumpingFish(FishSpecies fish) {
    _safeSprite(fish.asset).then((sprite) {
      if (sprite == null || !isMounted) return;
      final comp = SpriteComponent(
        sprite: sprite,
        anchor: Anchor.center,
        position: _castPoint.clone(),
        size: _fit(sprite, size.y * 0.16),
      );
      add(comp);
      comp.add(MoveEffect.by(
        Vector2(-size.x * 0.06, -size.y * 0.28),
        EffectController(duration: 0.45, curve: Curves.decelerate),
        onComplete: () {
          comp.add(MoveEffect.by(
            Vector2(-size.x * 0.10, size.y * 0.32),
            EffectController(duration: 0.4, curve: Curves.easeIn),
          ));
        },
      ));
      comp.add(RotateEffect.by(-0.6, EffectController(duration: 0.85)));
      comp.add(OpacityEffect.to(0.0, EffectController(duration: 0.85, startDelay: 0.2),
          onComplete: comp.removeFromParent));
    });
  }

  // Draw the fishing line from the rod tip to the bobber.
  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final b = _bobber;
    if (b == null) return;
    if (phase.value == GamePhase.idle) return;
    if (b.scale.x <= 0.01) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final start = Offset(_rodTip.x, _rodTip.y);
    final end = Offset(b.position.x, b.position.y - b.size.y * 0.4 * b.scale.y);
    // Arc the line up and over the chicken so it clearly leaves the rod tip,
    // then dips down to the bobber on the water.
    final mid = Offset((start.dx + end.dx) / 2, start.dy - 18);
    final path = ui.Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
  }
}

/// The floating bobber with an idle bobbing motion and a bite dip.
class BobberComponent extends SpriteComponent {
  BobberComponent({super.sprite});

  MoveEffect? _idle;

  void startIdleBob() {
    stopIdleBob();
    _idle = MoveByEffect(
      Vector2(0, 5),
      EffectController(
        duration: 0.8,
        reverseDuration: 0.8,
        infinite: true,
        curve: Curves.easeInOut,
      ),
    );
    add(_idle!);
  }

  void stopIdleBob() {
    _idle?.removeFromParent();
    _idle = null;
  }

  void dip() {
    add(MoveByEffect(
      Vector2(0, 16),
      EffectController(duration: 0.12, reverseDuration: 0.12, curve: Curves.easeIn),
    ));
  }
}

/// Expanding ring drawn on the water surface.
class RippleComponent extends PositionComponent {
  RippleComponent({required Vector2 position})
      : super(position: position, anchor: Anchor.center);

  double _t = 0;
  static const _life = 0.9;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    final progress = (_t / _life).clamp(0.0, 1.0);
    final radius = 6 + progress * 46;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: (1 - progress) * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * (1 - progress);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius),
      paint,
    );
  }
}

/// Picks the "best" owned chicken sprite to use as the angler.
ChickenSpecies _bestOwnedChicken(Set<int> owned) {
  final list = GameData.chickens.where((c) => owned.contains(c.id)).toList()
    ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
  return list.isNotEmpty ? list.first : GameData.chickens.first;
}
