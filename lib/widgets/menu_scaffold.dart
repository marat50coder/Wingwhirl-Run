import 'package:flutter/material.dart';

import '../app.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import 'coin_chip.dart';

/// Consistent full-screen menu layout: sky/location background, a header with a
/// back button, title, live coin balance, and a content area.
class MenuScaffold extends StatelessWidget {
  const MenuScaffold({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.actions = const [],
    this.showCoins = true,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final List<Widget> actions;
  final bool showCoins;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        bgAsset: GameState.instance.location.background,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
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
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 26),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(title,
                          style: AppText.title(26),
                          overflow: TextOverflow.ellipsis),
                    ),
                    ...actions,
                    if (showCoins) ...[
                      const SizedBox(width: 8),
                      const CoinChip(),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple pill tab bar used inside menu screens.
class PillTabs extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.waterDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (i) {
          final selected = i == index;
          return PressableScale(
            onTap: () {
              AudioService.instance.playSfx(AudioService.click);
              onChanged(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.goldButton : null,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Text(
                tabs[i],
                style: AppText.heavy(16,
                    color: selected ? Colors.white : Colors.white70),
              ),
            ),
          );
        }),
      ),
    );
  }
}
