import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import '../widgets/menu_scaffold.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return MenuScaffold(
          title: 'Collection',
          icon: Icons.menu_book_rounded,
          child: Column(
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  PillTabs(
                    tabs: const ['Chickens', 'Fishdex'],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  const Spacer(),
                  _progressPill(),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _tab == 0 ? _chickenGrid(state) : _fishGrid(state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _progressPill() {
    final state = GameState.instance;
    final owned = _tab == 0 ? state.collectionOwned : state.fishDexOwned;
    final total = _tab == 0 ? state.collectionTotal : state.fishDexTotal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.waterDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text('$owned / $total collected',
          style: AppText.heavy(15, color: Colors.white)),
    );
  }

  Widget _chickenGrid(GameState state) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.82,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: GameData.chickens.length,
      itemBuilder: (context, i) {
        final c = GameData.chickens[i];
        final owned = state.ownedChickens.contains(c.id);
        return _CollectionCard(
          asset: c.asset,
          name: c.name,
          rarity: c.rarity,
          owned: owned,
          onTap: owned
              ? () => _showDetail(context, c.name, c.asset, c.rarity, null)
              : null,
        );
      },
    );
  }

  Widget _fishGrid(GameState state) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: GameData.fish.length,
      itemBuilder: (context, i) {
        final f = GameData.fish[i];
        final owned = state.caughtFish.contains(f.id);
        final count = state.fishCounts[f.id] ?? 0;
        return _CollectionCard(
          asset: f.asset,
          name: f.name,
          rarity: f.rarity,
          owned: owned,
          badge: owned && count > 0 ? 'x$count' : null,
          onTap: owned
              ? () => _showDetail(context, f.name, f.asset, f.rarity, f.baseValue)
              : null,
        );
      },
    );
  }

  void _showDetail(BuildContext context, String name, String asset,
      Rarity rarity, int? value) {
    AudioService.instance.playSfx(AudioService.click);
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: GlassPanel(
            color: rarity.color.withValues(alpha: 0.35),
            borderColor: rarity.color,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 140, child: Image.asset(asset)),
                const SizedBox(height: 10),
                Text(name, style: AppText.title(24)),
                const SizedBox(height: 6),
                RarityBadge(rarity: rarity, fontSize: 13),
                if (value != null) ...[
                  const SizedBox(height: 8),
                  Text('Base value: $value coins',
                      style: AppText.heavy(15, color: Colors.white)),
                ],
                const SizedBox(height: 16),
                GradientButton(
                  label: 'Close',
                  fontSize: 16,
                  width: 160,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.asset,
    required this.name,
    required this.rarity,
    required this.owned,
    this.onTap,
    this.badge,
  });

  final String asset;
  final String name;
  final Rarity rarity;
  final bool owned;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: owned,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: owned
                ? [
                    rarity.color.withValues(alpha: 0.55),
                    AppColors.waterDeep.withValues(alpha: 0.55),
                  ]
                : [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.45),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: owned ? rarity.color : Colors.white24,
            width: 2,
          ),
          boxShadow: owned
              ? [BoxShadow(color: rarity.color.withValues(alpha: 0.4), blurRadius: 8)]
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: owned
                        ? Image.asset(asset, fit: BoxFit.contain)
                        : _Silhouette(asset: asset),
                  ),
                  if (badge != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(badge!,
                            style: AppText.heavy(12, color: AppColors.ink)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              owned ? name : '???',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.heavy(12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the sprite as a dark silhouette for undiscovered entries.
class _Silhouette extends StatelessWidget {
  const _Silhouette({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0xCC0A2A3D), BlendMode.srcATop),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}
