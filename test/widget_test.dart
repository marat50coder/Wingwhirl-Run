import 'package:flutter_test/flutter_test.dart';

import 'package:wingwhirl_run/data/game_data.dart';
import 'package:wingwhirl_run/theme/app_theme.dart';

void main() {
  test('Game data is well-formed', () {
    // 30 collectible chickens, 48 fish, 8 locations.
    expect(GameData.chickens.length, 30);
    expect(GameData.fish.length, 48);
    expect(GameData.locations.length, 8);

    // Every rarity tier has at least one fish and one chicken.
    for (final r in Rarity.values) {
      expect(GameData.fishOfRarity(r).isNotEmpty, true, reason: 'fish $r');
      expect(GameData.chickensOfRarity(r).isNotEmpty, true, reason: 'chicken $r');
    }
  });

  test('Daily tasks are deterministic per day seed', () {
    final a = GameData.generateDailyTasks(100);
    final b = GameData.generateDailyTasks(100);
    expect(a.length, 3);
    expect(a.map((t) => t.title).toList(), b.map((t) => t.title).toList());
  });
}
