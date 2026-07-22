import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../data/game_data.dart';
import '../game/fishing_game.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import '../widgets/coin_chip.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final FishingGame _game;
  CatchResult? _popup;

  @override
  void initState() {
    super.initState();
    _game = FishingGame(onCatch: _onCatch, onMiss: _onMiss);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.playMusic(AudioService.tension, volume: 0.18);
    });
  }

  void _onCatch(CatchResult result) {
    if (!mounted) return;
    setState(() => _popup = result);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && _popup == result) setState(() => _popup = null);
    });
  }

  void _onMiss() {}

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    return Scaffold(
      body: SkyBackground(
        bgAsset: state.location.background,
        child: Stack(
          children: [
            GameWidget(game: _game),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _topBar(state),
                    const Spacer(),
                    _bottomControls(),
                  ],
                ),
              ),
            ),
            if (_popup != null) _CatchPopup(result: _popup!),
          ],
        ),
      ),
    );
  }

  Widget _topBar(GameState state) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Row(
        children: [
          CircleIconButton(
            icon: Icons.home_rounded,
            onTap: () {
              AudioService.instance.playSfx(AudioService.click);
              Navigator.of(context).maybePop();
            },
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.waterDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(state.location.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.heavy(15, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          StatChip(
            icon: Icons.set_meal,
            color: AppColors.rarityRare,
            label: '${state.totalFishCaught}',
          ),
          const SizedBox(width: 8),
          const CoinChip(),
        ],
      ),
    );
  }

  Widget _bottomControls() {
    return Column(
      children: [
        ValueListenableBuilder<double>(
          valueListenable: _game.biteProgress,
          builder: (context, progress, _) {
            if (progress <= 0) return const SizedBox(height: 10);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 220,
                child: GlowProgressBar(
                  value: progress,
                  height: 10,
                  animate: false,
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.coral],
                  ),
                ),
              ),
            );
          },
        ),
        ValueListenableBuilder<String>(
          valueListenable: _game.hint,
          builder: (context, hint, _) => Text(
            hint,
            style: AppText.title(20),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<GamePhase>(
          valueListenable: _game.phase,
          builder: (context, phase, _) => _actionButton(phase),
        ),
      ],
    );
  }

  Widget _actionButton(GamePhase phase) {
    switch (phase) {
      case GamePhase.idle:
        return GradientButton(
          label: 'CAST',
          icon: Icons.gps_fixed,
          width: 200,
          height: 58,
          fontSize: 24,
          gradient: AppColors.greenButton,
          onTap: _game.cast,
        );
      case GamePhase.biting:
        return GradientButton(
          label: 'HOOK!',
          icon: Icons.bolt,
          width: 200,
          height: 58,
          fontSize: 24,
          gradient: const LinearGradient(
            colors: [AppColors.coral, AppColors.goldDeep],
          ),
          onTap: () => _game.hookFromButton(),
        );
      case GamePhase.waiting:
        return GradientButton(
          label: 'Waiting...',
          width: 200,
          height: 58,
          fontSize: 20,
          gradient: AppColors.blueButton,
          enabled: false,
          onTap: () {},
        );
      default:
        return const SizedBox(height: 58);
    }
  }
}

class _CatchPopup extends StatefulWidget {
  const _CatchPopup({required this.result});
  final CatchResult result;

  @override
  State<_CatchPopup> createState() => _CatchPopupState();
}

class _CatchPopupState extends State<_CatchPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fish = widget.result.fish;
    final rarity = fish.rarity;
    return IgnorePointer(
      child: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
          child: FadeTransition(
            opacity: _c,
            child: GlassPanel(
              color: rarity.color.withValues(alpha: 0.4),
              borderColor: rarity.color,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.result.isNewSpecies)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('NEW!', style: AppText.title(18, color: AppColors.gold)),
                    ),
                  SizedBox(height: 96, child: Image.asset(fish.asset)),
                  const SizedBox(height: 6),
                  Text(fish.name, style: AppText.title(22)),
                  const SizedBox(height: 4),
                  RarityBadge(rarity: rarity, fontSize: 12),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(GameData.coinIcon, width: 24, height: 24),
                      const SizedBox(width: 6),
                      Text('+${widget.result.coins}',
                          style: AppText.title(24, color: AppColors.gold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
