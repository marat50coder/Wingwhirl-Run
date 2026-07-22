import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// Helper to build a sliced sprite asset path.
String spritePath(String folder, int index) =>
    'assets/sprites/$folder/${folder}_${index.toString().padLeft(2, '0')}.png';

/// The stat an achievement tracks. Kept free of any state dependency so the
/// achievement catalog can live in [models]/[GameData] without import cycles.
enum AchMetric {
  totalFish,
  totalCoins,
  chickensOwned,
  locationsUnlocked,
  fishDiscovered,
  eggsOpened,
  legendaryCaught,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchMetric metric;
  final int goal;
  final int reward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.metric,
    required this.goal,
    required this.reward,
  });
}

class FishSpecies {
  final int id; // == sprite index in the fish sheet
  final String name;
  final Rarity rarity;
  final int baseValue;

  const FishSpecies(this.id, this.name, this.rarity, this.baseValue);

  String get asset => spritePath('fish', id);
}

class ChickenSpecies {
  final int id; // == sprite index in the chickens sheet
  final String name;
  final Rarity rarity;

  const ChickenSpecies(this.id, this.name, this.rarity);

  String get asset => spritePath('chickens', id);
}

class EggType {
  final String id;
  final String name;
  final int spriteIndex;
  final int price;
  final Map<Rarity, double> weights;

  const EggType({
    required this.id,
    required this.name,
    required this.spriteIndex,
    required this.price,
    required this.weights,
  });

  String get asset => spritePath('eggs', spriteIndex);
}

class FishingLocation {
  final int id;
  final int bgIndex; // 1..8 -> bgN_asset.webp
  final String name;
  final String subtitle;
  final int unlockCost;
  final double coinMultiplier;

  /// Bias 0..1 shifting the catch roll toward rarer fish.
  final double rarityBias;

  const FishingLocation({
    required this.id,
    required this.bgIndex,
    required this.name,
    required this.subtitle,
    required this.unlockCost,
    required this.coinMultiplier,
    required this.rarityBias,
  });

  String get background => 'assets/bg${bgIndex}_asset.webp';
}

class UpgradeLevel {
  final String name;
  final int cost;
  final int spriteIndex; // index in the equipment sheet
  final double value; // meaning depends on the track

  const UpgradeLevel({
    required this.name,
    required this.cost,
    required this.spriteIndex,
    required this.value,
  });

  String get asset => spritePath('equipment', spriteIndex);
}

class UpgradeTrack {
  final String id;
  final String title;
  final String description;
  final List<UpgradeLevel> levels;

  const UpgradeTrack({
    required this.id,
    required this.title,
    required this.description,
    required this.levels,
  });
}

class BobberSkin {
  final String id;
  final String name;
  final int spriteIndex;
  final int price;

  const BobberSkin({
    required this.id,
    required this.name,
    required this.spriteIndex,
    required this.price,
  });

  String get asset => spritePath('equipment', spriteIndex);
}

enum TaskType { catchAny, catchRare, earnCoins, openEgg, catchLegendary }

class DailyTask {
  final TaskType type;
  final int target;
  final int reward;
  int progress;
  bool claimed;

  DailyTask({
    required this.type,
    required this.target,
    required this.reward,
    this.progress = 0,
    this.claimed = false,
  });

  bool get completed => progress >= target;

  String get title {
    switch (type) {
      case TaskType.catchAny:
        return 'Catch $target fish';
      case TaskType.catchRare:
        return 'Catch $target rare+ fish';
      case TaskType.earnCoins:
        return 'Earn $target coins';
      case TaskType.openEgg:
        return 'Open $target ${target == 1 ? 'egg' : 'eggs'}';
      case TaskType.catchLegendary:
        return 'Catch a legendary fish';
    }
  }

  Map<String, dynamic> toJson() => {
        't': type.index,
        'g': target,
        'r': reward,
        'p': progress,
        'c': claimed,
      };

  factory DailyTask.fromJson(Map<String, dynamic> j) => DailyTask(
        type: TaskType.values[j['t'] as int],
        target: j['g'] as int,
        reward: j['r'] as int,
        progress: j['p'] as int,
        claimed: j['c'] as bool,
      );
}
