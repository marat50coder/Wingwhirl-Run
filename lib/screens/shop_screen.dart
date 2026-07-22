import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import '../widgets/coin_chip.dart';
import '../widgets/menu_scaffold.dart';
import 'egg_reveal.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => MenuScaffold(
        title: 'Shop',
        icon: Icons.storefront_rounded,
        child: Column(
          children: [
            const SizedBox(height: 4),
            PillTabs(
              tabs: const ['Gear', 'Eggs', 'Bobbers'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 10),
            Expanded(child: _body(state)),
          ],
        ),
      ),
    );
  }

  Widget _body(GameState state) {
    switch (_tab) {
      case 0:
        return _upgrades(state);
      case 1:
        return _eggs(state);
      default:
        return _bobbers(state);
    }
  }

  // --------------------------------------------------------------- Upgrades
  Widget _upgrades(GameState state) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: GameData.upgradeTracks
          .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _UpgradeCard(track: t),
              ))
          .toList(),
    );
  }

  // ------------------------------------------------------------------- Eggs
  Widget _eggs(GameState state) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        childAspectRatio: 0.92,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: GameData.eggs.length,
      itemBuilder: (context, i) => _EggCard(egg: GameData.eggs[i]),
    );
  }

  // ---------------------------------------------------------------- Bobbers
  Widget _bobbers(GameState state) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: GameData.bobbers.length,
      itemBuilder: (context, i) => _BobberCard(skin: GameData.bobbers[i]),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.track});
  final UpgradeTrack track;

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    final level = state.levelOf(track.id);
    final maxed = level >= track.levels.length - 1;
    final current = track.levels[level];
    final next = maxed ? null : track.levels[level + 1];

    return GlassPanel(
      color: AppColors.waterDeep.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset((next ?? current).asset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.title, style: AppText.title(19)),
                Text(track.description,
                    style: AppText.bodyStyle(13, color: Colors.white)),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(track.levels.length, (i) {
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 22,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= level
                            ? AppColors.gold
                            : Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (maxed)
            const _Tag(text: 'MAX', color: AppColors.green)
          else
            GradientButton(
              label: formatCoins(next!.cost),
              icon: Icons.arrow_upward_rounded,
              height: 46,
              fontSize: 15,
              enabled: state.canAfford(next.cost),
              onTap: () {
                if (!state.buyUpgrade(track.id)) {
                  AudioService.instance.playSfx(AudioService.negative);
                }
              },
            ),
        ],
      ),
    );
  }
}

class _EggCard extends StatelessWidget {
  const _EggCard({required this.egg});
  final EggType egg;

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    final affordable = state.canAfford(egg.price);
    return GlassPanel(
      color: AppColors.waterDeep.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(child: Image.asset(egg.asset, fit: BoxFit.contain)),
          const SizedBox(height: 6),
          Text(egg.name, style: AppText.title(18)),
          const SizedBox(height: 2),
          Text(_odds(egg),
              textAlign: TextAlign.center,
              style: AppText.bodyStyle(11, color: Colors.white70)),
          const SizedBox(height: 8),
          GradientButton(
            label: formatCoins(egg.price),
            icon: Icons.egg_alt,
            height: 44,
            fontSize: 15,
            width: double.infinity,
            enabled: affordable,
            onTap: () {
              final result = state.openEgg(egg);
              if (result == null) {
                AudioService.instance.playSfx(AudioService.negative);
                return;
              }
              showEggReveal(context, result);
            },
          ),
        ],
      ),
    );
  }

  String _odds(EggType egg) {
    final total = egg.weights.values.fold(0.0, (a, c) => a + c);
    final parts = egg.weights.entries
        .map((e) => '${e.key.label} ${(e.value / total * 100).round()}%')
        .toList();
    return parts.join(' · ');
  }
}

class _BobberCard extends StatelessWidget {
  const _BobberCard({required this.skin});
  final BobberSkin skin;

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    final owned = state.ownedBobbers.contains(skin.id);
    final equipped = state.equippedBobber == skin.id;
    return PressableScale(
      onTap: () {
        if (owned) {
          AudioService.instance.playSfx(AudioService.click);
          state.equipBobber(skin.id);
        } else if (state.buyBobber(skin)) {
          // bought & equipped
        } else {
          AudioService.instance.playSfx(AudioService.negative);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.waterDeep.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: equipped ? AppColors.gold : Colors.white24,
            width: equipped ? 3 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Expanded(child: Image.asset(skin.asset, fit: BoxFit.contain)),
            const SizedBox(height: 4),
            Text(skin.name, style: AppText.heavy(13, color: Colors.white)),
            const SizedBox(height: 4),
            if (equipped)
              const _Tag(text: 'EQUIPPED', color: AppColors.gold)
            else if (owned)
              const _Tag(text: 'Tap to equip', color: AppColors.green)
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(GameData.coinIcon, width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(formatCoins(skin.price),
                      style: AppText.heavy(13, color: Colors.white)),
                ],
              ),
          ],
        ),
      ),
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
      child: Text(text, style: AppText.heavy(11, color: Colors.white)),
    );
  }
}
