import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import '../widgets/coin_chip.dart';
import '../widgets/menu_scaffold.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => MenuScaffold(
        title: 'Fishing Spots',
        icon: Icons.map_rounded,
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 340,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: GameData.locations.length,
          itemBuilder: (context, i) =>
              _LocationCard(location: GameData.locations[i]),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});
  final FishingLocation location;

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    final unlocked = state.unlockedLocations.contains(location.id);
    final current = state.currentLocation == location.id;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(location.background, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: unlocked ? 0.1 : 0.45),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          if (current)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.gold, width: 3),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(location.name,
                          style: AppText.title(20),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (current)
                      const _Tag(text: 'ACTIVE', color: AppColors.gold),
                  ],
                ),
                const SizedBox(height: 2),
                Text(location.subtitle,
                    style: AppText.bodyStyle(12, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const Spacer(),
                Row(
                  children: [
                    _Tag(
                      text: 'x${location.coinMultiplier} coins',
                      color: AppColors.green,
                    ),
                    const Spacer(),
                    _actionButton(context, state, unlocked, current),
                  ],
                ),
              ],
            ),
          ),
          if (!unlocked)
            const Positioned(
              top: 10,
              right: 10,
              child: Icon(Icons.lock, color: Colors.white, size: 26),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(
      BuildContext context, GameState state, bool unlocked, bool current) {
    if (current) {
      return GradientButton(
        label: 'Fishing here',
        height: 40,
        fontSize: 14,
        gradient: AppColors.greenButton,
        enabled: false,
        onTap: () {},
      );
    }
    if (unlocked) {
      return GradientButton(
        label: 'Select',
        height: 40,
        fontSize: 14,
        gradient: AppColors.blueButton,
        onTap: () {
          AudioService.instance.playSfx(AudioService.click);
          state.selectLocation(location);
        },
      );
    }
    final affordable = state.canAfford(location.unlockCost);
    return GradientButton(
      label: formatCoins(location.unlockCost),
      icon: Icons.lock_open,
      height: 40,
      fontSize: 14,
      enabled: affordable,
      gradient: AppColors.goldButton,
      onTap: () {
        if (state.unlockLocation(location)) {
          state.selectLocation(location);
        } else {
          AudioService.instance.playSfx(AudioService.negative);
        }
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: AppText.heavy(12, color: Colors.white)),
    );
  }
}
