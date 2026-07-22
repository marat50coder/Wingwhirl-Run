import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../data/game_data.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import 'main_menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0;
  int _dots = 0;
  Timer? _dotTimer;
  late final AnimationController _pulse;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _dotTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _dots = (_dots + 1) % 4);
    });
  }

  // Kick off real loading once we can access the asset bundle via context.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _runLoading();
    }
  }

  Future<void> _runLoading() async {
    final navigator = Navigator.of(context);
    // Build the list of real work units so the bar reflects actual loading.
    final assets = <String>[
      for (var i = 1; i <= 8; i++) 'assets/bg${i}_asset.webp',
      'assets/Horizontal_Loading_Screen.webp',
      'assets/Vertical_Loading_Screen.webp',
      'assets/Game_Name.webp',
      GameData.coinIcon,
      GameData.coinStack,
      for (final c in GameData.chickens) c.asset,
      for (final f in GameData.fish) f.asset,
      for (final e in GameData.eggs) e.asset,
      for (final l in GameData.rodTrack.levels) l.asset,
      for (final b in GameData.bobbers) b.asset,
      GameData.chickens[0].asset,
    ];

    // Total steps: state init (1) + audio warm (1) + each asset.
    final total = assets.length + 2;
    var done = 0;
    void bump() {
      done++;
      if (mounted) setState(() => _progress = done / total);
    }

    try {
      await GameState.instance.init();
    } catch (_) {}
    bump();

    for (final path in assets) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
      bump();
    }

    // Warm up / start menu music.
    try {
      await AudioService.instance.playMusic(AudioService.tension, volume: 0.0);
      await AudioService.instance.stopMusic();
    } catch (_) {}
    bump();

    // Ensure the bar visibly completes before leaving.
    if (mounted) setState(() => _progress = 1.0);
    await Future<void>.delayed(const Duration(milliseconds: 450));

    // Lock to landscape for the main game experience.
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!mounted) return;
    navigator.pushReplacement(fadeSlideRoute(const MainMenuScreen()));
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final bg = orientation == Orientation.landscape
        ? 'assets/Horizontal_Loading_Screen.webp'
        : 'assets/Vertical_Loading_Screen.webp';
    final size = MediaQuery.of(context).size;
    final barWidth = (size.width * 0.6).clamp(240.0, 560.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.skyGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(bg, fit: BoxFit.cover),
            // Subtle bottom scrim so the bar/text stay readable.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.75, end: 1.0)
                          .animate(_pulse),
                      child: Text(
                        'Loading${'.' * _dots}${' ' * (3 - _dots)}',
                        style: AppText.title(26),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: barWidth,
                      child: _SplashBar(value: _progress),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress * 100).round()}%',
                      style: AppText.heavy(16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBar extends StatelessWidget {
  const _SplashBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.coral],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.8),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
