import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'models.dart';

/// All static game content for Wingwhirl Run.
class GameData {
  GameData._();

  // ---------------------------------------------------------------- Fish (48)
  static const List<String> _fishNames = [
    // Common (0-15)
    'Largemouth Bass', 'Goldfish', 'Silver Mackerel', 'Green Perch',
    'Whiskered Catfish', 'Rainbow Trout', 'Sunfish', 'Blue Tang',
    'Clownfish', 'Royal Blue Tang', 'Crimson Betta', 'Razor Piranha',
    'Blue Marlin', 'Northern Pike', 'Copper Snapper', 'Koi Carp',
    // Uncommon (16-27)
    'Pink Snapper', 'Violet Wrasse', 'Emerald Bass', 'Zebra Fish',
    'Golden Tang', 'Coral Grouper', 'Spiny Lionfish', 'Bluefin Tuna',
    'Steel Barracuda', 'Rosy Parrotfish', 'Neon Damsel', 'Golden Arowana',
    // Rare (28-37)
    'Ancient Sturgeon', 'Mahi Mahi', 'Ruby Rockfish', 'Clown Triggerfish',
    'Spotted Flounder', 'Emperor Angelfish', 'Shadow Moray', 'Sunset Discus',
    'Orca', 'Great White Shark',
    // Epic (38-43)
    'Reef Shark', 'Whale Shark', 'Crystal Icefish', 'Molten Lavafish',
    'Abyss Anglerfish', 'Golden Bonefish',
    // Legendary (44-47)
    'Rainbow Serpent', 'Spectral Koi', 'Void Dragonfish', 'King Midas Fish',
  ];

  static Rarity _fishRarity(int i) {
    if (i <= 15) return Rarity.common;
    if (i <= 27) return Rarity.uncommon;
    if (i <= 37) return Rarity.rare;
    if (i <= 43) return Rarity.epic;
    return Rarity.legendary;
  }

  static final List<FishSpecies> fish = List.generate(_fishNames.length, (i) {
    final rarity = _fishRarity(i);
    // Smoothly increasing base value with a per-tier floor.
    const tierBase = {
      Rarity.common: 12,
      Rarity.uncommon: 45,
      Rarity.rare: 130,
      Rarity.epic: 380,
      Rarity.legendary: 1100,
    };
    const tierStep = {
      Rarity.common: 3,
      Rarity.uncommon: 9,
      Rarity.rare: 28,
      Rarity.epic: 90,
      Rarity.legendary: 300,
    };
    final tierStart = fishIndexOfFirst(rarity);
    final within = i - tierStart;
    final value = tierBase[rarity]! + within * tierStep[rarity]!;
    return FishSpecies(i, _fishNames[i], rarity, value);
  });

  static int fishIndexOfFirst(Rarity r) {
    switch (r) {
      case Rarity.common:
        return 0;
      case Rarity.uncommon:
        return 16;
      case Rarity.rare:
        return 28;
      case Rarity.epic:
        return 38;
      case Rarity.legendary:
        return 44;
    }
  }

  static List<FishSpecies> fishOfRarity(Rarity r) =>
      fish.where((f) => f.rarity == r).toList();

  // ------------------------------------------------------------ Chickens (30)
  static const List<String> _chickenNames = [
    'Redcap Angler', 'Buttercup', 'Meadow Scout', 'Speckle', 'Cozy Cluck',
    'Sailor Sam', 'Woodsy', 'Blossom', 'Sunny Shades', 'Aloha Lily',
    'Captain Blackbeak', 'Pearl Corsair', 'Redscarf Rogue', 'Admiral Featherton',
    'Professor Peck', 'Ranger Fern', 'Trailblazer', 'Dusty Digger',
    'Goggles Rusty', 'Ace Aviator', 'Rainy Rae', 'Hoodie Hank', 'Violet Knit',
    'Trapper Tom', 'Frosty Beanie', 'Sergeant Sprout', 'Boss Cluck', 'Petal',
    'Scuba Steve', 'Deepdive Diva',
  ];

  static Rarity _chickenRarity(int i) {
    if (i <= 9) return Rarity.common;
    if (i <= 17) return Rarity.uncommon;
    if (i <= 24) return Rarity.rare;
    if (i <= 28) return Rarity.epic;
    return Rarity.legendary;
  }

  static final List<ChickenSpecies> chickens = List.generate(
    _chickenNames.length,
    (i) => ChickenSpecies(i, _chickenNames[i], _chickenRarity(i)),
  );

  static List<ChickenSpecies> chickensOfRarity(Rarity r) =>
      chickens.where((c) => c.rarity == r).toList();

  // ---------------------------------------------------------------- Eggs
  static const List<EggType> eggs = [
    EggType(
      id: 'wooden',
      name: 'Meadow Egg',
      spriteIndex: 0,
      price: 600,
      weights: {
        Rarity.common: 70,
        Rarity.uncommon: 25,
        Rarity.rare: 5,
      },
    ),
    EggType(
      id: 'forest',
      name: 'Forest Egg',
      spriteIndex: 1,
      price: 2200,
      weights: {
        Rarity.common: 35,
        Rarity.uncommon: 45,
        Rarity.rare: 17,
        Rarity.epic: 3,
      },
    ),
    EggType(
      id: 'mystic',
      name: 'Mystic Egg',
      spriteIndex: 7,
      price: 7500,
      weights: {
        Rarity.uncommon: 30,
        Rarity.rare: 45,
        Rarity.epic: 22,
        Rarity.legendary: 3,
      },
    ),
    EggType(
      id: 'golden',
      name: 'Golden Egg',
      spriteIndex: 9,
      price: 20000,
      weights: {
        Rarity.rare: 30,
        Rarity.epic: 50,
        Rarity.legendary: 20,
      },
    ),
  ];

  // ------------------------------------------------------------- Locations (8)
  static const List<FishingLocation> locations = [
    FishingLocation(
      id: 0,
      bgIndex: 1,
      name: 'Sunny Meadow Lake',
      subtitle: 'A calm lake among green hills.',
      unlockCost: 0,
      coinMultiplier: 1.0,
      rarityBias: 0.0,
    ),
    FishingLocation(
      id: 1,
      bgIndex: 2,
      name: 'Pine Forest Lake',
      subtitle: 'Quiet waters ringed by pines.',
      unlockCost: 800,
      coinMultiplier: 1.2,
      rarityBias: 0.08,
    ),
    FishingLocation(
      id: 2,
      bgIndex: 3,
      name: 'Mountain Lake',
      subtitle: 'Crystal-clear alpine water.',
      unlockCost: 3000,
      coinMultiplier: 1.5,
      rarityBias: 0.16,
    ),
    FishingLocation(
      id: 3,
      bgIndex: 4,
      name: 'Tropical Bay',
      subtitle: 'Warm, colorful jungle shores.',
      unlockCost: 8000,
      coinMultiplier: 1.9,
      rarityBias: 0.24,
    ),
    FishingLocation(
      id: 4,
      bgIndex: 5,
      name: 'Coastal Cliffs',
      subtitle: 'Deep blue sea by the cliffs.',
      unlockCost: 18000,
      coinMultiplier: 2.4,
      rarityBias: 0.32,
    ),
    FishingLocation(
      id: 5,
      bgIndex: 6,
      name: 'Open Ocean',
      subtitle: 'Endless waves and big catches.',
      unlockCost: 40000,
      coinMultiplier: 3.0,
      rarityBias: 0.42,
    ),
    FishingLocation(
      id: 6,
      bgIndex: 7,
      name: 'Sunset Lake',
      subtitle: 'Golden waters at dusk.',
      unlockCost: 80000,
      coinMultiplier: 3.8,
      rarityBias: 0.52,
    ),
    FishingLocation(
      id: 7,
      bgIndex: 8,
      name: 'Moonlit Lake',
      subtitle: 'Mysterious catches under the moon.',
      unlockCost: 150000,
      coinMultiplier: 5.0,
      rarityBias: 0.62,
    ),
  ];

  // -------------------------------------------------------------- Upgrades
  static const UpgradeTrack rodTrack = UpgradeTrack(
    id: 'rod',
    title: 'Fishing Rod',
    description: 'Increases coins earned per catch.',
    levels: [
      UpgradeLevel(name: 'Wooden Rod', cost: 0, spriteIndex: 0, value: 1.0),
      UpgradeLevel(name: 'Blue Rod', cost: 1500, spriteIndex: 1, value: 1.35),
      UpgradeLevel(name: 'Pro Red Rod', cost: 6000, spriteIndex: 2, value: 1.8),
    ],
  );

  static const UpgradeTrack reelTrack = UpgradeTrack(
    id: 'reel',
    title: 'Reel',
    description: 'Widens the catch timing window.',
    levels: [
      UpgradeLevel(name: 'Basic Reel', cost: 0, spriteIndex: 3, value: 0.0),
      UpgradeLevel(name: 'Copper Reel', cost: 1000, spriteIndex: 4, value: 1.0),
      UpgradeLevel(name: 'Silver Reel', cost: 3500, spriteIndex: 5, value: 2.0),
      UpgradeLevel(name: 'Sport Reel', cost: 9000, spriteIndex: 6, value: 3.0),
      UpgradeLevel(name: 'Master Reel', cost: 25000, spriteIndex: 8, value: 4.0),
    ],
  );

  static const UpgradeTrack baitTrack = UpgradeTrack(
    id: 'bait',
    title: 'Bait',
    description: 'Fish bite faster and rarer.',
    levels: [
      UpgradeLevel(name: 'Worms', cost: 0, spriteIndex: 30, value: 0.0),
      UpgradeLevel(name: 'Corn Bait', cost: 800, spriteIndex: 31, value: 1.0),
      UpgradeLevel(name: 'Red Berries', cost: 2600, spriteIndex: 32, value: 2.0),
      UpgradeLevel(name: 'Golden Kernels', cost: 7000, spriteIndex: 33, value: 3.0),
      UpgradeLevel(name: 'Pro Pellets', cost: 18000, spriteIndex: 34, value: 4.0),
    ],
  );

  static const List<UpgradeTrack> upgradeTracks = [rodTrack, reelTrack, baitTrack];

  // --------------------------------------------------------------- Bobbers
  static const List<BobberSkin> bobbers = [
    BobberSkin(id: 'classic', name: 'Classic', spriteIndex: 23, price: 0),
    BobberSkin(id: 'orange', name: 'Sunset', spriteIndex: 24, price: 400),
    BobberSkin(id: 'blue', name: 'Ocean', spriteIndex: 25, price: 900),
    BobberSkin(id: 'green', name: 'Forest', spriteIndex: 26, price: 1500),
    BobberSkin(id: 'navy', name: 'Navy', spriteIndex: 27, price: 2500),
    BobberSkin(id: 'red', name: 'Ruby', spriteIndex: 28, price: 4000),
    BobberSkin(id: 'lime', name: 'Lime', spriteIndex: 29, price: 6000),
  ];

  // ------------------------------------------------------ Coin & reward icons
  static String coinIcon = spritePath('coins', 0);
  static String coinStack = spritePath('coins', 11);
  static const Map<Rarity, int> rewardChestSprite = {
    Rarity.common: 0,
    Rarity.uncommon: 1,
    Rarity.rare: 2,
    Rarity.epic: 3,
    Rarity.legendary: 3,
  };

  // ------------------------------------------------------------ Daily rewards
  /// Coins granted for each day of the 7-day login streak (cycles).
  static const List<int> dailyRewards = [200, 400, 700, 1200, 2000, 3000, 6000];

  // ------------------------------------------------------------ Achievements
  static const List<Achievement> achievements = [
    Achievement(
      id: 'first_catch',
      title: 'First Catch',
      description: 'Catch your very first fish.',
      icon: Icons.set_meal,
      metric: AchMetric.totalFish,
      goal: 1,
      reward: 200,
    ),
    Achievement(
      id: 'angler_100',
      title: 'Keen Angler',
      description: 'Catch 100 fish.',
      icon: Icons.phishing,
      metric: AchMetric.totalFish,
      goal: 100,
      reward: 1500,
    ),
    Achievement(
      id: 'angler_1000',
      title: 'Master Angler',
      description: 'Catch 1,000 fish.',
      icon: Icons.military_tech,
      metric: AchMetric.totalFish,
      goal: 1000,
      reward: 10000,
    ),
    Achievement(
      id: 'rich_10k',
      title: 'Getting Rich',
      description: 'Earn 10,000 coins in total.',
      icon: Icons.savings,
      metric: AchMetric.totalCoins,
      goal: 10000,
      reward: 1000,
    ),
    Achievement(
      id: 'tycoon',
      title: 'Coin Tycoon',
      description: 'Earn 100,000 coins in total.',
      icon: Icons.diamond,
      metric: AchMetric.totalCoins,
      goal: 100000,
      reward: 8000,
    ),
    Achievement(
      id: 'legendary',
      title: 'The Legend',
      description: 'Discover a legendary fish.',
      icon: Icons.auto_awesome,
      metric: AchMetric.legendaryCaught,
      goal: 1,
      reward: 3000,
    ),
    Achievement(
      id: 'fishdex_half',
      title: 'Fish Scholar',
      description: 'Discover 24 fish species.',
      icon: Icons.menu_book,
      metric: AchMetric.fishDiscovered,
      goal: 24,
      reward: 2500,
    ),
    Achievement(
      id: 'fishdex_full',
      title: 'Fishdex Complete',
      description: 'Discover all 48 fish species.',
      icon: Icons.workspace_premium,
      metric: AchMetric.fishDiscovered,
      goal: 48,
      reward: 12000,
    ),
    Achievement(
      id: 'coop_10',
      title: 'Chicken Keeper',
      description: 'Collect 10 chickens.',
      icon: Icons.egg,
      metric: AchMetric.chickensOwned,
      goal: 10,
      reward: 2000,
    ),
    Achievement(
      id: 'coop_full',
      title: 'Full Coop',
      description: 'Collect all 30 chickens.',
      icon: Icons.emoji_events,
      metric: AchMetric.chickensOwned,
      goal: 30,
      reward: 15000,
    ),
    Achievement(
      id: 'explorer',
      title: 'World Explorer',
      description: 'Unlock all 8 fishing spots.',
      icon: Icons.travel_explore,
      metric: AchMetric.locationsUnlocked,
      goal: 8,
      reward: 6000,
    ),
    Achievement(
      id: 'hatcher',
      title: 'Egg Hatcher',
      description: 'Open 10 eggs.',
      icon: Icons.egg_alt,
      metric: AchMetric.eggsOpened,
      goal: 10,
      reward: 2000,
    ),
  ];

  // -------------------------------------------------------------- Daily tasks
  /// Generates a fresh set of 3 daily tasks from a day-seed for determinism.
  static List<DailyTask> generateDailyTasks(int daySeed) {
    final rng = Random(daySeed);
    final pool = <DailyTask>[
      DailyTask(type: TaskType.catchAny, target: 15 + rng.nextInt(3) * 5, reward: 500),
      DailyTask(type: TaskType.catchAny, target: 25 + rng.nextInt(3) * 5, reward: 800),
      DailyTask(type: TaskType.catchRare, target: 3 + rng.nextInt(3), reward: 900),
      DailyTask(type: TaskType.earnCoins, target: 3000 + rng.nextInt(5) * 1000, reward: 1000),
      DailyTask(type: TaskType.openEgg, target: 1, reward: 700),
      DailyTask(type: TaskType.catchLegendary, target: 1, reward: 2500),
    ];
    pool.shuffle(rng);
    return pool.take(3).toList();
  }
}
