import 'package:flutter/material.dart';

import '../app.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

/// A friendly illustrated tutorial shown from the main menu. Explains the core
/// fishing loop across a few swipeable cards.
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  static const List<_HowStep> _steps = [
    _HowStep(
      icon: Icons.sports_esports_rounded,
      color: AppColors.green,
      title: 'Cast Your Line',
      body:
          'Tap PLAY, then tap the water to cast your rod. Your chicken angler '
          'will send the bobber flying out onto the pond.',
    ),
    _HowStep(
      icon: Icons.notifications_active_rounded,
      color: AppColors.sky,
      title: 'Wait for the Bite',
      body:
          'Keep an eye on the bobber. When it dips under the water and you hear '
          'the splash — a fish is on the hook!',
    ),
    _HowStep(
      icon: Icons.touch_app_rounded,
      color: AppColors.coral,
      title: 'Hook It in Time',
      body:
          'Tap the moment the fish bites to reel it in. Upgrading your reel '
          'widens the timing window, so catches get easier.',
    ),
    _HowStep(
      icon: Icons.monetization_on_rounded,
      color: AppColors.gold,
      title: 'Earn Coins',
      body:
          'The rarer the fish, the fatter the reward. Chase Common, Uncommon, '
          'Rare, Epic and Legendary catches for more coins.',
    ),
    _HowStep(
      icon: Icons.upgrade_rounded,
      color: AppColors.rarityEpic,
      title: 'Upgrade & Explore',
      body:
          'Spend coins on better rods, bait and brand-new locations. Each pond '
          'hides bigger, more valuable fish.',
    ),
    _HowStep(
      icon: Icons.egg_alt_rounded,
      color: AppColors.rarityLegendary,
      title: 'Collect Chickens',
      body:
          'Hatch surprise eggs to unlock a whole flock of collectible chicken '
          'anglers — complete tasks and awards for bonus rewards!',
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    AudioService.instance.playSfx(AudioService.click);
    if (_page >= _steps.length - 1) {
      Navigator.of(context).maybePop();
    } else {
      _pc.nextPage(
          duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _steps.length - 1;
    return Scaffold(
      body: SkyBackground(
        bgAsset: null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.skyGradient),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: Row(
                      children: [
                        CircleIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () {
                            AudioService.instance.playSfx(AudioService.click);
                            Navigator.of(context).maybePop();
                          },
                        ),
                        const SizedBox(width: 12),
                        Text('How to Play', style: AppText.title(26)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pc,
                      itemCount: _steps.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) => _StepCard(step: _steps[i]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _dots(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: GradientButton(
                      label: last ? "Let's Fish!" : 'Next',
                      icon: last
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      height: 54,
                      width: 240,
                      gradient: last
                          ? AppColors.greenButton
                          : AppColors.blueButton,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps.length, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 9,
          height: 9,
          decoration: BoxDecoration(
            color: active ? AppColors.gold : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});
  final _HowStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlassPanel(
            color: AppColors.waterDeep.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  key: ValueKey(step.title),
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, s, child) =>
                      Transform.scale(scale: s, child: child),
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          step.color,
                          Color.lerp(step.color, Colors.black, 0.28)!,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.7), width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: step.color.withValues(alpha: 0.6),
                            blurRadius: 18),
                      ],
                    ),
                    child: Icon(step.icon, color: Colors.white, size: 46),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(step.title, style: AppText.title(24)),
                      const SizedBox(height: 10),
                      Text(step.body,
                          style: AppText.bodyStyle(15, color: Colors.white)
                              .copyWith(height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HowStep {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _HowStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}
