import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import '../widgets/menu_scaffold.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final done = GameData.achievements
            .where((a) => state.isAchievementComplete(a))
            .length;
        return MenuScaffold(
          title: 'Achievements',
          icon: Icons.emoji_events_rounded,
          child: Column(
            children: [
              const SizedBox(height: 6),
              Text('$done / ${GameData.achievements.length} unlocked',
                  style: AppText.heavy(15, color: Colors.white)),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    childAspectRatio: 3.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: GameData.achievements.length,
                  itemBuilder: (context, i) =>
                      _AchievementCard(achievement: GameData.achievements[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    final value = state.achievementMetric(achievement.metric);
    final complete = state.isAchievementComplete(achievement);
    final claimed = state.isAchievementClaimed(achievement);
    final ratio = (value / achievement.goal).clamp(0.0, 1.0);

    return GlassPanel(
      color: (complete ? AppColors.gold : AppColors.waterDeep)
          .withValues(alpha: complete && !claimed ? 0.5 : 0.4),
      borderColor: complete ? AppColors.gold : Colors.white24,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: complete ? AppColors.goldButton : AppColors.blueButton,
              borderRadius: BorderRadius.circular(14),
              boxShadow: complete
                  ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.6), blurRadius: 10)]
                  : null,
            ),
            child: Icon(achievement.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: AppText.title(17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(achievement.description,
                    style: AppText.bodyStyle(12, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                GlowProgressBar(value: ratio, height: 10),
                const SizedBox(height: 3),
                Text('${value.clamp(0, achievement.goal)}/${achievement.goal}',
                    style: AppText.heavy(11, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _reward(state, complete, claimed),
        ],
      ),
    );
  }

  Widget _reward(GameState state, bool complete, bool claimed) {
    if (claimed) {
      return const SizedBox(
        width: 66,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.green, size: 30),
            SizedBox(height: 2),
          ],
        ),
      );
    }
    if (complete) {
      return SizedBox(
        width: 74,
        child: GradientButton(
          label: '+${achievement.reward}',
          height: 46,
          fontSize: 13,
          gradient: AppColors.greenButton,
          onTap: () {
            if (!state.claimAchievement(achievement)) {
              AudioService.instance.playSfx(AudioService.negative);
            }
          },
        ),
      );
    }
    return SizedBox(
      width: 66,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(GameData.coinIcon, width: 20, height: 20),
          Text('+${achievement.reward}',
              style: AppText.heavy(12, color: AppColors.gold)),
        ],
      ),
    );
  }
}
