import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/game_data.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';
import '../theme/app_theme.dart';

class CatchResult {
  final FishSpecies fish;
  final int coins;
  final bool isNewSpecies;
  CatchResult(this.fish, this.coins, this.isNewSpecies);
}

class EggResult {
  final EggType egg;
  final ChickenSpecies chicken;
  final bool isNew;
  EggResult(this.egg, this.chicken, this.isNew);
}

/// Holds all player progress and the rules that mutate it. Singleton exposed to
/// the widget tree via [GameState.instance]; screens listen with ListenableBuilder.
class GameState extends ChangeNotifier {
  GameState._();
  static final GameState instance = GameState._();

  final SaveService _save = SaveService();
  final Random _rng = Random();

  // --- Progress ---
  int coins = 300;
  int totalFishCaught = 0;
  int totalCoinsEarned = 0;
  int eggsOpened = 0;
  Rarity? lastCatchRarity;

  final Set<int> caughtFish = {}; // fish species ids discovered
  final Map<int, int> fishCounts = {}; // species id -> times caught
  final Set<int> ownedChickens = {};
  final Set<int> unlockedLocations = {0};
  int currentLocation = 0;

  int rodLevel = 0;
  int reelLevel = 0;
  int baitLevel = 0;

  final Set<String> ownedBobbers = {'classic'};
  String equippedBobber = 'classic';

  final Set<String> claimedAchievements = {};

  bool soundOn = true;
  bool musicOn = true;

  List<DailyTask> dailyTasks = [];
  int _taskDay = 0;

  int dailyRewardIndex = 0; // 0..6 -> next day to claim
  int _lastRewardDay = 0;

  // ------------------------------------------------------------------ Loading
  Future<void> init() async {
    await _save.init();
    _loadFromMap(_save.load());
    _refreshDailyTasks();
    await AudioService.instance.init(sound: soundOn, music: musicOn);
  }

  void _loadFromMap(Map<String, dynamic> m) {
    if (m.isEmpty) {
      // First launch: give the starter chicken so the coop is never empty.
      ownedChickens.add(0);
      return;
    }
    coins = m['coins'] ?? coins;
    totalFishCaught = m['totalFish'] ?? 0;
    totalCoinsEarned = m['totalCoins'] ?? 0;
    eggsOpened = m['eggs'] ?? 0;
    currentLocation = m['loc'] ?? 0;
    rodLevel = m['rod'] ?? 0;
    reelLevel = m['reel'] ?? 0;
    baitLevel = m['bait'] ?? 0;
    equippedBobber = m['bobber'] ?? 'classic';
    soundOn = m['sound'] ?? true;
    musicOn = m['music'] ?? true;
    _taskDay = m['taskDay'] ?? 0;
    dailyRewardIndex = m['rewardIndex'] ?? 0;
    _lastRewardDay = m['rewardDay'] ?? 0;

    caughtFish
      ..clear()
      ..addAll(_intList(m['caughtFish']));
    ownedChickens
      ..clear()
      ..addAll(_intList(m['chickens']));
    if (ownedChickens.isEmpty) ownedChickens.add(0);
    unlockedLocations
      ..clear()
      ..addAll(_intList(m['unlocked']))
      ..add(0);
    ownedBobbers
      ..clear()
      ..addAll((m['ownedBobbers'] as List?)?.cast<String>() ?? ['classic'])
      ..add('classic');
    claimedAchievements
      ..clear()
      ..addAll((m['achievements'] as List?)?.cast<String>() ?? const []);

    final counts = m['fishCounts'];
    if (counts is Map) {
      counts.forEach((k, v) => fishCounts[int.tryParse(k.toString()) ?? -1] = v as int);
      fishCounts.remove(-1);
    }
    final tasks = m['tasks'];
    if (tasks is List) {
      dailyTasks = tasks
          .map((e) => DailyTask.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
  }

  List<int> _intList(dynamic v) =>
      (v as List?)?.map((e) => e as int).toList() ?? const [];

  Future<void> _persist() async {
    await _save.save({
      'coins': coins,
      'totalFish': totalFishCaught,
      'totalCoins': totalCoinsEarned,
      'eggs': eggsOpened,
      'loc': currentLocation,
      'rod': rodLevel,
      'reel': reelLevel,
      'bait': baitLevel,
      'bobber': equippedBobber,
      'sound': soundOn,
      'music': musicOn,
      'taskDay': _taskDay,
      'rewardIndex': dailyRewardIndex,
      'rewardDay': _lastRewardDay,
      'caughtFish': caughtFish.toList(),
      'chickens': ownedChickens.toList(),
      'unlocked': unlockedLocations.toList(),
      'ownedBobbers': ownedBobbers.toList(),
      'achievements': claimedAchievements.toList(),
      'fishCounts': fishCounts.map((k, v) => MapEntry(k.toString(), v)),
      'tasks': dailyTasks.map((t) => t.toJson()).toList(),
    });
  }

  // -------------------------------------------------------------- Daily tasks
  int get _todaySeed =>
      (DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay);

  void _refreshDailyTasks() {
    final today = _todaySeed;
    if (dailyTasks.isEmpty || _taskDay != today) {
      _taskDay = today;
      dailyTasks = GameData.generateDailyTasks(today);
      _persist();
    }
  }

  void _progressTasks(TaskType type, int amount, {Rarity? rarity}) {
    for (final t in dailyTasks) {
      if (t.claimed) continue;
      switch (t.type) {
        case TaskType.catchAny:
          if (type == TaskType.catchAny) t.progress += amount;
          break;
        case TaskType.catchRare:
          if (type == TaskType.catchAny &&
              rarity != null &&
              rarity.index >= Rarity.rare.index) {
            t.progress += amount;
          }
          break;
        case TaskType.catchLegendary:
          if (type == TaskType.catchAny && rarity == Rarity.legendary) {
            t.progress += amount;
          }
          break;
        case TaskType.earnCoins:
          if (type == TaskType.earnCoins) t.progress += amount;
          break;
        case TaskType.openEgg:
          if (type == TaskType.openEgg) t.progress += amount;
          break;
      }
      if (t.progress > t.target) t.progress = t.target;
    }
  }

  bool claimTask(DailyTask task) {
    if (!task.completed || task.claimed) return false;
    task.claimed = true;
    coins += task.reward;
    totalCoinsEarned += task.reward;
    AudioService.instance.playSfx(AudioService.mission);
    _persist();
    notifyListeners();
    return true;
  }

  // -------------------------------------------------------------- Daily reward
  /// True when today's login reward hasn't been claimed yet.
  bool get dailyRewardAvailable => _lastRewardDay != _todaySeed;

  /// Coins the player would receive if they claim right now.
  int get dailyRewardAmount =>
      GameData.dailyRewards[dailyRewardIndex % GameData.dailyRewards.length];

  /// Claims today's login reward, advancing the 7-day streak. Returns the
  /// number of coins granted, or 0 if already claimed today.
  int claimDailyReward() {
    if (!dailyRewardAvailable) return 0;
    final amount = dailyRewardAmount;
    coins += amount;
    totalCoinsEarned += amount;
    _lastRewardDay = _todaySeed;
    dailyRewardIndex = (dailyRewardIndex + 1) % GameData.dailyRewards.length;
    _progressTasks(TaskType.earnCoins, amount);
    AudioService.instance.playSfx(AudioService.mission);
    _persist();
    notifyListeners();
    return amount;
  }

  /// Generic coin grant used by the mini-game and other bonuses.
  void grantCoins(int amount) {
    if (amount <= 0) return;
    coins += amount;
    totalCoinsEarned += amount;
    _progressTasks(TaskType.earnCoins, amount);
    _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------- Fishing
  FishingLocation get location => GameData.locations[currentLocation];

  double get rodValue => GameData.rodTrack.levels[rodLevel].value;

  /// Half-width of the timing window in seconds (grows with the reel).
  double get catchWindow => 0.85 + reelLevel * 0.14;

  /// Multiplier applied to the pre-bite wait (lower = faster bites).
  double get biteSpeedFactor => (1.0 - baitLevel * 0.11).clamp(0.5, 1.0);

  /// Rolls a rarity given the current location bias and bait boost.
  Rarity rollRarity() {
    final b = location.rarityBias;
    final bait = GameData.baitTrack.levels[baitLevel].value;
    final weights = <Rarity, double>{
      Rarity.common: 60 * (1 - 0.6 * b),
      Rarity.uncommon: 26 * (1 + 0.3 * b),
      Rarity.rare: 10 * (1 + 2.0 * b + 0.12 * bait),
      Rarity.epic: 3.2 * (1 + 5.0 * b + 0.22 * bait),
      Rarity.legendary: 0.8 * (1 + 12.0 * b + 0.30 * bait),
    };
    final total = weights.values.fold(0.0, (a, c) => a + c);
    var roll = _rng.nextDouble() * total;
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) return entry.key;
    }
    return Rarity.common;
  }

  FishSpecies rollFish() {
    final rarity = rollRarity();
    final pool = GameData.fishOfRarity(rarity);
    return pool[_rng.nextInt(pool.length)];
  }

  /// Registers a successful catch and returns details for the reveal popup.
  CatchResult registerCatch(FishSpecies fish) {
    final value = (fish.baseValue * location.coinMultiplier * rodValue).round();
    coins += value;
    totalCoinsEarned += value;
    totalFishCaught += 1;
    lastCatchRarity = fish.rarity;
    final isNew = caughtFish.add(fish.id);
    fishCounts[fish.id] = (fishCounts[fish.id] ?? 0) + 1;

    _progressTasks(TaskType.catchAny, 1, rarity: fish.rarity);
    _progressTasks(TaskType.earnCoins, value);

    _persist();
    notifyListeners();
    return CatchResult(fish, value, isNew);
  }

  // ----------------------------------------------------------------- Economy
  bool canAfford(int cost) => coins >= cost;

  bool _spend(int cost) {
    if (coins < cost) return false;
    coins -= cost;
    return true;
  }

  bool buyUpgrade(String trackId) {
    final track = GameData.upgradeTracks.firstWhere((t) => t.id == trackId);
    final level = _levelOf(trackId);
    if (level >= track.levels.length - 1) return false;
    final next = track.levels[level + 1];
    if (!_spend(next.cost)) return false;
    _setLevel(trackId, level + 1);
    AudioService.instance.playSfx(AudioService.levelUp);
    _persist();
    notifyListeners();
    return true;
  }

  int _levelOf(String id) => switch (id) {
        'rod' => rodLevel,
        'reel' => reelLevel,
        'bait' => baitLevel,
        _ => 0,
      };

  void _setLevel(String id, int v) {
    switch (id) {
      case 'rod':
        rodLevel = v;
        break;
      case 'reel':
        reelLevel = v;
        break;
      case 'bait':
        baitLevel = v;
        break;
    }
  }

  int levelOf(String id) => _levelOf(id);

  bool unlockLocation(FishingLocation loc) {
    if (unlockedLocations.contains(loc.id)) return true;
    if (!_spend(loc.unlockCost)) return false;
    unlockedLocations.add(loc.id);
    AudioService.instance.playSfx(AudioService.buy);
    _persist();
    notifyListeners();
    return true;
  }

  void selectLocation(FishingLocation loc) {
    if (!unlockedLocations.contains(loc.id)) return;
    currentLocation = loc.id;
    _persist();
    notifyListeners();
  }

  /// Opens an egg (must be affordable) and returns the resulting chicken.
  EggResult? openEgg(EggType egg) {
    if (!_spend(egg.price)) return null;
    eggsOpened += 1;

    final rarity = _rollEggRarity(egg);
    final pool = GameData.chickensOfRarity(rarity);
    // Prefer chickens the player doesn't own yet for that rarity.
    final unseen = pool.where((c) => !ownedChickens.contains(c.id)).toList();
    final chosen = (unseen.isNotEmpty ? unseen : pool)[_rng.nextInt(
        (unseen.isNotEmpty ? unseen : pool).length)];
    final isNew = ownedChickens.add(chosen.id);

    _progressTasks(TaskType.openEgg, 1);
    _persist();
    notifyListeners();
    return EggResult(egg, chosen, isNew);
  }

  Rarity _rollEggRarity(EggType egg) {
    final total = egg.weights.values.fold(0.0, (a, c) => a + c);
    var roll = _rng.nextDouble() * total;
    for (final e in egg.weights.entries) {
      roll -= e.value;
      if (roll <= 0) return e.key;
    }
    return egg.weights.keys.first;
  }

  bool buyBobber(BobberSkin skin) {
    if (ownedBobbers.contains(skin.id)) {
      equippedBobber = skin.id;
      _persist();
      notifyListeners();
      return true;
    }
    if (!_spend(skin.price)) return false;
    ownedBobbers.add(skin.id);
    equippedBobber = skin.id;
    AudioService.instance.playSfx(AudioService.buy);
    _persist();
    notifyListeners();
    return true;
  }

  void equipBobber(String id) {
    if (!ownedBobbers.contains(id)) return;
    equippedBobber = id;
    _persist();
    notifyListeners();
  }

  BobberSkin get currentBobber =>
      GameData.bobbers.firstWhere((b) => b.id == equippedBobber,
          orElse: () => GameData.bobbers.first);

  // ----------------------------------------------------------------- Settings
  void toggleSound() {
    soundOn = !soundOn;
    AudioService.instance.setSoundOn(soundOn);
    _persist();
    notifyListeners();
  }

  void toggleMusic() {
    musicOn = !musicOn;
    AudioService.instance.setMusicOn(musicOn);
    _persist();
    notifyListeners();
  }

  // ------------------------------------------------------------------ Getters
  int get collectionTotal => GameData.chickens.length;
  int get collectionOwned => ownedChickens.length;
  double get collectionProgress =>
      collectionOwned / collectionTotal;

  int get fishDexTotal => GameData.fish.length;
  int get fishDexOwned => caughtFish.length;

  // -------------------------------------------------------------- Achievements
  int _legendaryDiscovered() => caughtFish
      .where((id) =>
          id >= 0 && id < GameData.fish.length &&
          GameData.fish[id].rarity == Rarity.legendary)
      .length;

  int achievementMetric(AchMetric metric) {
    switch (metric) {
      case AchMetric.totalFish:
        return totalFishCaught;
      case AchMetric.totalCoins:
        return totalCoinsEarned;
      case AchMetric.chickensOwned:
        return collectionOwned;
      case AchMetric.locationsUnlocked:
        return unlockedLocations.length;
      case AchMetric.fishDiscovered:
        return fishDexOwned;
      case AchMetric.eggsOpened:
        return eggsOpened;
      case AchMetric.legendaryCaught:
        return _legendaryDiscovered();
    }
  }

  bool isAchievementComplete(Achievement a) =>
      achievementMetric(a.metric) >= a.goal;

  bool isAchievementClaimed(Achievement a) =>
      claimedAchievements.contains(a.id);

  int get achievementsUnclaimed => GameData.achievements
      .where((a) => isAchievementComplete(a) && !isAchievementClaimed(a))
      .length;

  bool claimAchievement(Achievement a) {
    if (!isAchievementComplete(a) || isAchievementClaimed(a)) return false;
    claimedAchievements.add(a.id);
    coins += a.reward;
    totalCoinsEarned += a.reward;
    AudioService.instance.playSfx(AudioService.mission);
    _persist();
    notifyListeners();
    return true;
  }

  Future<void> resetProgress() async {
    coins = 300;
    totalFishCaught = 0;
    totalCoinsEarned = 0;
    eggsOpened = 0;
    lastCatchRarity = null;
    caughtFish.clear();
    fishCounts.clear();
    ownedChickens
      ..clear()
      ..add(0);
    unlockedLocations
      ..clear()
      ..add(0);
    currentLocation = 0;
    rodLevel = reelLevel = baitLevel = 0;
    ownedBobbers
      ..clear()
      ..add('classic');
    equippedBobber = 'classic';
    claimedAchievements.clear();
    _taskDay = 0;
    dailyRewardIndex = 0;
    _lastRewardDay = 0;
    _refreshDailyTasks();
    await _save.clear();
    await _persist();
    notifyListeners();
  }
}
