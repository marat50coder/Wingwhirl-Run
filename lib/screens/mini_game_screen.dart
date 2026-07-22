import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/game_data.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

/// "Quick Catch" — a 20 second reflex mini-game. Fish pop up around the pond;
/// tap them before they vanish to earn bonus coins. Rarer fish are worth more.
class MiniGameScreen extends StatefulWidget {
  const MiniGameScreen({super.key});

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

enum _Phase { intro, playing, results }

class _MiniGameScreenState extends State<MiniGameScreen> {
  static const int _roundSeconds = 20;

  final Random _rng = Random();
  final List<_Target> _targets = [];

  _Phase _phase = _Phase.intro;
  int _countdown = 3;
  double _timeLeft = _roundSeconds.toDouble();
  int _coins = 0;
  int _caught = 0;
  int _combo = 0;
  int _seq = 0;

  Timer? _spawnTimer;
  Timer? _tickTimer;
  Timer? _introTimer;

  @override
  void initState() {
    super.initState();
    _startIntro();
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _tickTimer?.cancel();
    _introTimer?.cancel();
    super.dispose();
  }

  void _startIntro() {
    setState(() {
      _phase = _Phase.intro;
      _countdown = 3;
      _targets.clear();
      _coins = 0;
      _caught = 0;
      _combo = 0;
      _timeLeft = _roundSeconds.toDouble();
    });
    _introTimer?.cancel();
    _introTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_countdown <= 1) {
        t.cancel();
        _startRound();
      } else {
        setState(() => _countdown--);
        AudioService.instance.playSfx(AudioService.click);
      }
    });
  }

  void _startRound() {
    setState(() => _phase = _Phase.playing);
    _spawnTimer =
        Timer.periodic(const Duration(milliseconds: 620), (_) => _spawn());
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _timeLeft -= 0.1);
      if (_timeLeft <= 0) _endRound();
    });
    _spawn();
  }

  void _endRound() {
    _spawnTimer?.cancel();
    _tickTimer?.cancel();
    if (_coins > 0) GameState.instance.grantCoins(_coins);
    AudioService.instance.playSfx(AudioService.mission);
    setState(() {
      _phase = _Phase.results;
      _targets.clear();
    });
  }

  FishSpecies _weightedFish() {
    const weights = {
      Rarity.common: 55.0,
      Rarity.uncommon: 25.0,
      Rarity.rare: 13.0,
      Rarity.epic: 5.0,
      Rarity.legendary: 2.0,
    };
    final total = weights.values.fold(0.0, (a, b) => a + b);
    var roll = _rng.nextDouble() * total;
    var rarity = Rarity.common;
    for (final e in weights.entries) {
      roll -= e.value;
      if (roll <= 0) {
        rarity = e.key;
        break;
      }
    }
    final pool = GameData.fishOfRarity(rarity);
    return pool[_rng.nextInt(pool.length)];
  }

  void _spawn() {
    if (!mounted || _phase != _Phase.playing) return;
    final fish = _weightedFish();
    final id = _seq++;
    setState(() {
      _targets.add(_Target(
        id: id,
        fish: fish,
        dx: 0.06 + _rng.nextDouble() * 0.82,
        dy: 0.24 + _rng.nextDouble() * 0.62,
      ));
    });
  }

  void _expire(int id) {
    if (!mounted) return;
    setState(() {
      _targets.removeWhere((t) => t.id == id);
      _combo = 0; // missed fish breaks the combo
    });
  }

  void _catch(_Target target) {
    if (!mounted) return;
    final value = (4 * target.fish.rarity.valueMultiplier).round();
    setState(() {
      _targets.removeWhere((t) => t.id == target.id);
      _combo++;
      _caught++;
      _coins += value * (1 + _combo ~/ 5); // small combo bonus
    });
    AudioService.instance.playSfx(
      target.fish.rarity.index >= Rarity.epic.index
          ? AudioService.rareFish
          : AudioService.coin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        bgAsset: GameState.instance.location.background,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _fishLayer()),
              _topBar(),
              if (_phase == _Phase.intro) _introOverlay(),
              if (_phase == _Phase.results) _resultsOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fishLayer() {
    return LayoutBuilder(builder: (context, c) {
      return Stack(
        children: [
          for (final t in _targets)
            Builder(builder: (context) {
              final size =
                  t.fish.rarity.index >= Rarity.epic.index ? 78.0 : 66.0;
              return Positioned(
                left: t.dx * (c.maxWidth - size),
                top: t.dy * (c.maxHeight - size),
                child: _FishTarget(
                  key: ValueKey(t.id),
                  fish: t.fish,
                  size: size,
                  onCatch: () => _catch(t),
                  onExpire: () => _expire(t.id),
                ),
              );
            }),
        ],
      );
    });
  }

  Widget _topBar() {
    final ratio = (_timeLeft / _roundSeconds).clamp(0.0, 1.0);
    return Positioned(
      left: 12,
      right: 12,
      top: 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleIconButton(
            icon: Icons.arrow_back_rounded,
            size: 42,
            onTap: () {
              AudioService.instance.playSfx(AudioService.click);
              Navigator.of(context).maybePop();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text('${_timeLeft.ceil()}s',
                        style: AppText.heavy(15, color: Colors.white)),
                    const Spacer(),
                    if (_combo >= 2)
                      Text('Combo x${1 + _combo ~/ 5}  🔥',
                          style: AppText.heavy(15, color: AppColors.gold)),
                  ],
                ),
                const SizedBox(height: 4),
                GlowProgressBar(
                  value: ratio,
                  height: 10,
                  gradient: const LinearGradient(
                      colors: [AppColors.green, AppColors.gold]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatChip(iconAsset: GameData.coinIcon, label: '$_coins'),
        ],
      ),
    );
  }

  Widget _introOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quick Catch', style: AppText.title(34)),
              const SizedBox(height: 8),
              Text('Tap the fish before they escape!',
                  style: AppText.bodyStyle(16, color: Colors.white)),
              const SizedBox(height: 22),
              TweenAnimationBuilder<double>(
                key: ValueKey(_countdown),
                tween: Tween(begin: 1.6, end: 1),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, s, child) =>
                    Transform.scale(scale: s, child: child),
                child: Text('$_countdown',
                    style: AppText.title(72, color: AppColors.gold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultsOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: GlassPanel(
            color: AppColors.waterDeep.withValues(alpha: 0.55),
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Time\'s Up!', style: AppText.title(30)),
                const SizedBox(height: 14),
                Text('Fish caught: $_caught',
                    style: AppText.heavy(18, color: Colors.white)),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(GameData.coinIcon, width: 40),
                    const SizedBox(width: 8),
                    Text('+$_coins',
                        style: AppText.title(32, color: AppColors.gold)),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GradientButton(
                      label: 'Home',
                      icon: Icons.home_rounded,
                      width: 140,
                      gradient: AppColors.blueButton,
                      onTap: () {
                        AudioService.instance.playSfx(AudioService.click);
                        Navigator.of(context).maybePop();
                      },
                    ),
                    const SizedBox(width: 12),
                    GradientButton(
                      label: 'Again',
                      icon: Icons.refresh_rounded,
                      width: 140,
                      gradient: AppColors.greenButton,
                      onTap: () {
                        AudioService.instance.playSfx(AudioService.click);
                        _startIntro();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Target {
  final int id;
  final FishSpecies fish;
  final double dx; // 0..1 of width
  final double dy; // 0..1 of height
  _Target(
      {required this.id,
      required this.fish,
      required this.dx,
      required this.dy});
}

/// A single tappable fish that pops in, waits, then escapes if not caught.
class _FishTarget extends StatefulWidget {
  const _FishTarget({
    super.key,
    required this.fish,
    required this.size,
    required this.onCatch,
    required this.onExpire,
  });

  final FishSpecies fish;
  final double size;
  final VoidCallback onCatch;
  final VoidCallback onExpire;

  @override
  State<_FishTarget> createState() => _FishTargetState();
}

class _FishTargetState extends State<_FishTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1350))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && !_done) {
          _done = true;
          widget.onExpire();
        }
      })
      ..forward();
    // Pop in quickly, hold, then shrink away.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 25),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
    ]).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tap() {
    if (_done) return;
    _done = true;
    widget.onCatch();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.fish.rarity.color;
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _tap,
        child: Container(
          width: widget.size,
          height: widget.size,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.35),
            border: Border.all(color: color, width: 2.5),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 14),
            ],
          ),
          child: Image.asset(widget.fish.asset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
