import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import '../widgets/menu_scaffold.dart';

/// A 7-day login reward calendar. One reward can be claimed per calendar day;
/// claiming advances the streak to the next (bigger) day.
class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({super.key});

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _claim(GameState state) {
    final amount = state.claimDailyReward();
    if (amount <= 0) {
      AudioService.instance.playSfx(AudioService.negative);
      return;
    }
    _showRewardBurst(amount);
  }

  void _showRewardBurst(int amount) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => _RewardBurstDialog(amount: amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final available = state.dailyRewardAvailable;
        final claimIndex = state.dailyRewardIndex;
        return MenuScaffold(
          title: 'Daily Reward',
          icon: Icons.card_giftcard_rounded,
          child: Column(
            children: [
              const SizedBox(height: 4),
              Text(
                available
                    ? 'Your gift is ready — come back every day for more!'
                    : 'Reward claimed. Come back tomorrow for the next one!',
                textAlign: TextAlign.center,
                style: AppText.bodyStyle(14, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(GameData.dailyRewards.length,
                            (i) {
                          final claimed = i < claimIndex;
                          final current = i == claimIndex && available;
                          return _DayCard(
                            day: i + 1,
                            amount: GameData.dailyRewards[i],
                            claimed: claimed,
                            current: current,
                            big: i == GameData.dailyRewards.length - 1,
                            pulse: _pulse,
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: available
                    ? 'Claim +${state.dailyRewardAmount}'
                    : 'Come Back Tomorrow',
                icon: available ? Icons.redeem_rounded : Icons.schedule_rounded,
                height: 58,
                fontSize: 22,
                width: 300,
                enabled: available,
                gradient: AppColors.greenButton,
                onTap: () => _claim(state),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.amount,
    required this.claimed,
    required this.current,
    required this.big,
    required this.pulse,
  });

  final int day;
  final int amount;
  final bool claimed;
  final bool current;
  final bool big;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final gradient = big
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gold, AppColors.coral])
        : AppColors.blueButton;

    Widget card = Container(
      width: 108,
      height: 118,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: claimed
            ? LinearGradient(colors: [
                AppColors.waterDark.withValues(alpha: 0.7),
                AppColors.waterDark.withValues(alpha: 0.5),
              ])
            : gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: current
              ? Colors.white
              : Colors.white.withValues(alpha: 0.4),
          width: current ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (current ? AppColors.gold : Colors.black)
                .withValues(alpha: current ? 0.6 : 0.25),
            blurRadius: current ? 18 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('DAY $day',
              style: AppText.heavy(13, color: Colors.white.withValues(alpha: 0.9))),
          const SizedBox(height: 6),
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(GameData.coinIcon, width: 38),
              if (claimed)
                const Icon(Icons.check_circle,
                    color: AppColors.green, size: 26),
            ],
          ),
          const SizedBox(height: 6),
          Text('+$amount',
              style: AppText.title(15, color: AppColors.gold)),
        ],
      ),
    );

    if (current) {
      card = AnimatedBuilder(
        animation: pulse,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.04 * sin(pulse.value * pi),
          child: child,
        ),
        child: card,
      );
    }
    return Opacity(opacity: claimed ? 0.75 : 1, child: card);
  }
}

class _RewardBurstDialog extends StatefulWidget {
  const _RewardBurstDialog({required this.amount});
  final int amount;

  @override
  State<_RewardBurstDialog> createState() => _RewardBurstDialogState();
}

class _RewardBurstDialogState extends State<_RewardBurstDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    AudioService.instance.playSfx(AudioService.mission);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
        child: GlassPanel(
          color: AppColors.waterDeep.withValues(alpha: 0.55),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reward Claimed!', style: AppText.title(24)),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(GameData.coinIcon, width: 44),
                  const SizedBox(width: 10),
                  Text('+${widget.amount}',
                      style: AppText.title(34, color: AppColors.gold)),
                ],
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Awesome!',
                width: 180,
                gradient: AppColors.greenButton,
                onTap: () {
                  AudioService.instance.playSfx(AudioService.click);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
