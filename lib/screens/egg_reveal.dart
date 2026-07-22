import 'dart:math';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

Future<void> showEggReveal(BuildContext context, EggResult result) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => _EggRevealDialog(result: result),
  );
}

class _EggRevealDialog extends StatefulWidget {
  const _EggRevealDialog({required this.result});
  final EggResult result;

  @override
  State<_EggRevealDialog> createState() => _EggRevealDialogState();
}

class _EggRevealDialogState extends State<_EggRevealDialog>
    with TickerProviderStateMixin {
  late final AnimationController _shake;
  late final AnimationController _reveal;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _play();
  }

  Future<void> _play() async {
    AudioService.instance.playSfx(AudioService.eggOpen);
    await _shake.forward();
    if (!mounted) return;
    setState(() => _revealed = true);
    final rarity = widget.result.chicken.rarity;
    if (rarity.index >= Rarity.epic.index) {
      AudioService.instance.playSfx(AudioService.legendary);
    } else {
      AudioService.instance.playSfx(AudioService.newChicken);
    }
    await _reveal.forward();
  }

  @override
  void dispose() {
    _shake.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chicken = widget.result.chicken;
    final rarity = chicken.rarity;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassPanel(
          color: rarity.color.withValues(alpha: 0.35),
          borderColor: rarity.color,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_revealed ? 'New Chicken!' : 'Opening...',
                  style: AppText.title(24)),
              const SizedBox(height: 14),
              SizedBox(
                height: 170,
                width: 170,
                child: _revealed ? _chickenReveal(chicken, rarity) : _egg(),
              ),
              const SizedBox(height: 12),
              if (_revealed) ...[
                Text(chicken.name, style: AppText.title(22)),
                const SizedBox(height: 6),
                RarityBadge(rarity: rarity, fontSize: 13),
                const SizedBox(height: 4),
                Text(
                  widget.result.isNew ? 'Added to your coop!' : 'Duplicate',
                  style: AppText.bodyStyle(14, color: Colors.white),
                ),
                const SizedBox(height: 14),
                GradientButton(
                  label: 'Awesome!',
                  width: 180,
                  onTap: () {
                    AudioService.instance.playSfx(AudioService.click);
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _egg() {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final angle = sin(t * pi * 8) * 0.18 * (1 - t * 0.3);
        return Transform.rotate(angle: angle, child: child);
      },
      child: Image.asset(widget.result.egg.asset, fit: BoxFit.contain),
    );
  }

  Widget _chickenReveal(ChickenSpecies chicken, Rarity rarity) {
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, child) {
        final v = Curves.elasticOut.transform(_reveal.value.clamp(0.0, 1.0));
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: (_reveal.value).clamp(0.0, 1.0),
              child: _RaysGlow(color: rarity.color),
            ),
            Transform.scale(scale: v, child: child),
          ],
        );
      },
      child: Image.asset(chicken.asset, fit: BoxFit.contain),
    );
  }
}

class _RaysGlow extends StatelessWidget {
  const _RaysGlow({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}
