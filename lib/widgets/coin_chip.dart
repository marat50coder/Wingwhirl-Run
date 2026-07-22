import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

/// HUD chip that shows the live coin balance with the coin sprite.
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameState.instance,
      builder: (context, _) => StatChip(
        iconAsset: GameData.coinIcon,
        color: AppColors.gold,
        label: _format(GameState.instance.coins),
        onTap: onTap,
      ),
    );
  }

  static String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

/// Formats coin amounts consistently across the app.
String formatCoins(int n) => CoinChip._format(n);
