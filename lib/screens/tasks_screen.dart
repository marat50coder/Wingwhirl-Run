import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import '../widgets/menu_scaffold.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => MenuScaffold(
        title: 'Daily Tasks',
        icon: Icons.checklist_rounded,
        child: Column(
          children: [
            const SizedBox(height: 6),
            Text('Resets every day · Complete tasks for bonus coins',
                style: AppText.bodyStyle(14, color: Colors.white)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: state.dailyTasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _TaskCard(task: state.dailyTasks[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});
  final DailyTask task;

  IconData get _icon {
    switch (task.type) {
      case TaskType.catchAny:
        return Icons.set_meal;
      case TaskType.catchRare:
        return Icons.auto_awesome;
      case TaskType.earnCoins:
        return Icons.monetization_on;
      case TaskType.openEgg:
        return Icons.egg_alt;
      case TaskType.catchLegendary:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    final ratio = (task.progress / task.target).clamp(0.0, 1.0);
    return GlassPanel(
      color: AppColors.waterDeep.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.goldButton,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: AppText.title(18)),
                const SizedBox(height: 6),
                GlowProgressBar(value: ratio, height: 12),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${task.progress}/${task.target}',
                        style: AppText.heavy(13, color: Colors.white)),
                    const Spacer(),
                    Image.asset(GameData.coinIcon, width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text('+${task.reward}',
                        style: AppText.heavy(13, color: AppColors.gold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _claimButton(context, state),
        ],
      ),
    );
  }

  Widget _claimButton(BuildContext context, GameState state) {
    if (task.claimed) {
      return const Icon(Icons.check_circle, color: AppColors.green, size: 34);
    }
    return GradientButton(
      label: 'Claim',
      height: 44,
      fontSize: 15,
      enabled: task.completed,
      gradient: AppColors.greenButton,
      onTap: () {
        if (!state.claimTask(task)) {
          AudioService.instance.playSfx(AudioService.negative);
        }
      },
    );
  }
}
