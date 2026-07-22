import 'package:flutter/material.dart';

/// Central design system for Wingwhirl Run.
///
/// The palette was extracted from the game's own art assets (bright sky-blue
/// water, fresh green shorelines and warm gold coins), producing a cheerful,
/// cozy aquatic look with strong gold accents for rewards.
class AppColors {
  AppColors._();

  // Core brand palette (from asset analysis).
  static const Color skyLight = Color(0xFF8FDCF7);
  static const Color sky = Color(0xFF29ABE2);
  static const Color waterDeep = Color(0xFF0F6FB8);
  static const Color waterDark = Color(0xFF0A4E86);
  static const Color green = Color(0xFF7CB342);
  static const Color greenDark = Color(0xFF558B2F);

  // Accents used for actions & rewards.
  static const Color gold = Color(0xFFFFC23C);
  static const Color goldDeep = Color(0xFFE8991B);
  static const Color coral = Color(0xFFF6663B);

  // Neutrals / text.
  static const Color ink = Color(0xFF0E3A54);
  static const Color inkSoft = Color(0xFF3B6076);
  static const Color panel = Color(0xFFFFFFFF);

  // Rarity colors (progression from grey → gold).
  static const Color rarityCommon = Color(0xFF8FA3B0);
  static const Color rarityUncommon = Color(0xFF44BE7A);
  static const Color rarityRare = Color(0xFF2E9BE6);
  static const Color rarityEpic = Color(0xFFA65CE0);
  static const Color rarityLegendary = Color(0xFFFFB300);

  // Common gradients.
  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyLight, sky, waterDeep],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient goldButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gold, goldDeep],
  );

  static const LinearGradient blueButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sky, waterDeep],
  );

  static const LinearGradient greenButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF8BC34A), greenDark],
  );
}

/// Semantic rarity tiers shared by fish, chickens and eggs.
enum Rarity { common, uncommon, rare, epic, legendary }

extension RarityData on Rarity {
  String get label {
    switch (this) {
      case Rarity.common:
        return 'Common';
      case Rarity.uncommon:
        return 'Uncommon';
      case Rarity.rare:
        return 'Rare';
      case Rarity.epic:
        return 'Epic';
      case Rarity.legendary:
        return 'Legendary';
    }
  }

  Color get color {
    switch (this) {
      case Rarity.common:
        return AppColors.rarityCommon;
      case Rarity.uncommon:
        return AppColors.rarityUncommon;
      case Rarity.rare:
        return AppColors.rarityRare;
      case Rarity.epic:
        return AppColors.rarityEpic;
      case Rarity.legendary:
        return AppColors.rarityLegendary;
    }
  }

  /// Base coin value multiplier for this tier.
  double get valueMultiplier {
    switch (this) {
      case Rarity.common:
        return 1.0;
      case Rarity.uncommon:
        return 2.4;
      case Rarity.rare:
        return 5.5;
      case Rarity.epic:
        return 13.0;
      case Rarity.legendary:
        return 32.0;
    }
  }

  int get sortIndex => index;
}

class AppText {
  AppText._();

  static const String display = 'Fredoka';
  static const String body = 'Nunito';

  static TextStyle title(double size, {Color color = Colors.white}) => TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.05,
        shadows: const [
          Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      );

  static TextStyle heavy(double size, {Color color = Colors.white}) => TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyStyle(double size,
          {Color color = AppColors.ink, FontWeight weight = FontWeight.w600}) =>
      TextStyle(
        fontFamily: body,
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
}

/// Reusable soft shadow for floating panels & cards.
const List<BoxShadow> kSoftShadow = [
  BoxShadow(color: Color(0x33063B5A), blurRadius: 14, offset: Offset(0, 6)),
];

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sky,
      primary: AppColors.sky,
      secondary: AppColors.gold,
    ),
    scaffoldBackgroundColor: AppColors.sky,
    fontFamily: AppText.body,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
